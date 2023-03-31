local terminal = require('hologram.terminal')
local log = require('hologram.log')
local utils = require('hologram.utils')
local state = require('hologram.state')
local _, display_keys, delete_keys = require('hologram.control') ()

-- IMAGE PLACEMENT
local image_placement = {
--    image_id = nil,
    win = 0,
    row = 0,
    col = 0,
    display_keys = nil,
}

function image_placement:new (placement, keys)
    setmetatable(placement, self)
    self.__index = self
    keys = display_keys:new(keys)
    local y_offset = 0
    local cs = state.cell_size
    if keys['data_width'] == nil or keys['data_height'] == nil then
        local tkeys = ImageStore.images[keys.image_id].transmit_keys
        keys['data_height'], keys['data_width'] = tkeys.data_height, tkeys.data_width
    end
    keys["cols"] = math.ceil(keys.data_width/state.cell_size.x)
    keys["rows"] = math.ceil(keys.data_height/state.cell_size.y)
    if not keys["placement_id"] then
        keys.placement_id = ImageStore.images[keys.image_id]:get_placement_id()
    end

    local win_info = vim.fn.getwininfo(placement.win)[1]
    local buf = vim.api.nvim_win_get_buf(placement.win)
    -- check if visible
    if placement.row < win_info.topline-1 or placement.row > win_info.botline then
        return false
    end

    -- if image is cut off top
    if placement.row == win_info.topline-1 then
        local topfill = vim.fn.winsaveview().topfill
        local cutoff_rows = math.max(0, keys["rows"]-topfill)
--	print(topfill)
        y_offset = cutoff_rows * cs.y
        keys["rows"] = topfill
    end

    -- if image is cut off bottom
    if placement.row == win_info.botline then
        local screen_row = utils.buf_screenpos(placement.row, 0, placement.win, buf)
        local screen_winbot = win_info.winrow+win_info.height
        local visible_rows = screen_winbot-screen_row
        if visible_rows > 0 then
            keys["rows"] = visible_rows
            keys["height"] = visible_rows * cs.y
        else
            return false
        end
    end
--    keys.cols = math.ceil(keys['data_width']/state.cell_size.x)
--    keys.rows = math.ceil(keys['data_height']/state.cell_size.y)
    y_offset = math.ceil(y_offset)
    if y_offset ~= 0 then
        keys.y_offset = y_offset
--    log.debug(vim.inspect(keys))
    end
    placement.display_keys = keys


    local row, col = utils.buf_screenpos(placement.row, placement.col, placement.win, buf)
    terminal.move_cursor(row, col)
    terminal.send_graphics_command(keys, nil, true)
    terminal.restore_cursor()

    return placement
end

function image_placement:remove()
    -- delete image placement
    terminal.send_graphics_command(delete_keys:new{
	placement_id = self.display_keys.placement_id,
	image_id = self.display_keys.image_id,
	delete_action = 'i'
    })
end

--IMAGE PLACEHOLDER INSTANCE
local image_placeholder = {
    buf = nil,
    col = 0,
    cols = nil,
    data_height = nil,
    placeholder_id = nil,
    image_id = nil,
    row = 0,
    rows = nil,
    win_placements = {},
}

function image_placeholder:new (p)
  setmetatable(p, self)
  self.__index = self
  return p
end

function image_placeholder:show_placeholder()
    if vim.api.nvim_buf_is_valid(self.buf) then
        -- set padding block
        local filler = {}
        for _=0,self.rows-1 do
            filler[#filler+1] = {{' ', ''}}
        end
        -- apply padding to marked row -1
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.hologram_extmark_ns, self.row-1, 0, {
            id = self.placeholder_id,
            virt_lines = filler,
        })
    end
end

function image_placeholder:update()
    if vim.api.nvim_buf_is_valid(self.buf) then
        local extmark = vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.hologram_extmark_ns, self.placeholder_id, {})
	self.row = extmark[1]+1
	self.col = extmark[2]
    end
end

function image_placeholder:hide_placeholder()
    -- remove padding  marked row -1
    vim.api.nvim_buf_set_extmark(self.buf, vim.g.hologram_extmark_ns, self.row-1, 0, {
        id = self.placeholder_id,
        virt_lines = nil,
    })
end

function image_placeholder:update_win_placement(win)
    -- add placement to placeholder
    local placement_id = ''
    if self.win_placements[win] then
        placement_id = self.win_placements[win].display_keys.placement_id
    else
        placement_id = ImageStore.images[self.image_id]:get_placement_id()
    end

    local placement = image_placement:new({
            win = win,
            row = self.row,
            col = self.col
    }, {
	    image_id = self.image_id,
            placement_id = placement_id
    })
    self.win_placements[win] = placement
    -- return placement id
    return self.win_placements[win].placement_id
end

function image_placeholder:remove_win_placement(win)
    if self.win_placements[win] then
        -- remove placements from kitty
        self.win_placements[win]:remove()
        -- remove placements from placeholder
        table.remove(self.win_placements, win)
    end
end

-- IMAGE HANDLER
local image_handler = {
    next_placeholder_id = 1,
    placeholders = {}
}

function image_handler:new (i)
  setmetatable(i, self)
  self.__index = self
  return i
end

function image_handler:hide_removed()
    -- filter to active placeholders
    local active_placeholders = {}
    for i, placeholder in ipairs(self.placeholders) do
	if placeholder.win_placements ~= {} then
	    active_placeholders[i] = placeholder
        end
    end
    -- run for each window in current tab
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
	-- gather extmarks in window
	local extmarks = self:_get_win_marks(win)
	-- iterate through active placeholders
	for _, placeholder in ipairs(active_placeholders) do
	    -- filter down to those with a placement in the window
	    if placeholder.win_placements[win] then
		-- remove placement if it is not in current window
	        if not extmarks[placeholder.placeholder_id] then
	            self.placeholders[placeholder.placeholder_id]:remove_win_placement(win)
	        end
	    end
	end
    end
end

function image_handler:update_placeholders(buf)
    for i, placeholder in ipairs(self.placeholders) do
	if placeholder.buf == buf then
	    placeholder:update()
        end
    end
end

function image_handler:_get_win_marks(win)
    -- get extmarks in current window
    local win_info = vim.fn.getwininfo(win)[1]
    local extmarks = vim.api.nvim_buf_get_extmarks(win_info.bufnr,
        vim.g.hologram_extmark_ns,
        {win_info.topline, 0},
        {win_info.botline-1, -1},
    {})
    return extmarks
end

function image_handler:update_placements()
    -- run for each window in current tab
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
	-- gather extmarks (placeholders) in window
        local win_info = vim.fn.getwininfo(win)[1]
        local extmarks = vim.api.nvim_buf_get_extmarks(win_info.bufnr,
            vim.g.hologram_extmark_ns,
	    {0, 0},
            {-1, -1},
        {})
	for _, mark in ipairs(extmarks) do
	    if win_info.topline-2 <= mark[2] and mark[2] <= win_info.botline then
	        self.placeholders[mark[1]]:update_win_placement(win)
            else
		self.placeholders[mark[1]]:remove_win_placement(win)
	    end
	end
    end
end

function image_handler:display_visible()
    -- run for each window in current tab
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
	-- gather extmarks (placeholders) in window
	local extmarks = self:_get_win_marks(win)
	-- iterate through extmarks (placeholders)
	for _, mark in ipairs(extmarks) do
	    -- add placement to placeholder
	    self.placeholders[mark[1]]:update_win_placement(win)
	end
    end
end

function image_handler:add_placeholder(buf, img, row, col)
    local placeholder_id = self.next_placeholder_id
    self.next_placeholder_id = self.next_placeholder_id + 1
    local placeholder = image_placeholder:new{
	buf = buf,
	row = row,
	rows = img.rows,
	col = col,
	cols = img.cols,
	image_id = img.transmit_keys.image_id,
	placeholder_id = placeholder_id
    }
    self.placeholders[placeholder_id] = placeholder
    return placeholder_id
end



return image_handler
