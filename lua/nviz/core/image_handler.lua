local terminal = require('nviz.core.terminal')
local log = require('nviz.utils.log')
local utils = require('nviz.utils.utils')
local state = require('nviz.utils.state')
local _, display_keys, delete_keys = require('nviz.handlers.terminal.control') ()


-- IMAGE PLACEMENT
local image_placement = {
--    image_id = nil,
    win = 0,
    row = 0,
    col = 0,
    display_keys = nil,
    extra_padding = nil
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
        return nil
    end

    -- if image is cut off top
    if placement.row == win_info.topline-1 then
        local screen_win = win_info.winrow
        local topfill = vim.fn.winsaveview().topfill
        local visible_rows = topfill - screen_win - placement.extra_padding
        if visible_rows > 0 then
            y_offset = (keys["rows"] - visible_rows) * cs.y
            keys["rows"] = visible_rows
	else return nil end
    end


    -- if image is cut off bottom
    if placement.row == win_info.botline then
        local screen_row = utils.buf_screenpos(placement.row, 0, placement.win, buf)
        local screen_winbot = win_info.winrow+win_info.height
        local visible_rows = screen_winbot-screen_row
        if visible_rows > 0 and visible_rows < keys["rows"] then
            keys["rows"] = visible_rows
            keys["height"] = visible_rows * cs.y
        end
    end
    y_offset = math.ceil(y_offset)
    if y_offset ~= 0 then
        keys.y_offset = y_offset
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

-- IMAGE HANDLER
local image_handler = {
    next_placeholder_id = 1,
    bufs = {},
    placeholders = {}
}

function image_handler:new (i)
  setmetatable(i, self)
  self.__index = self
  return i
end

function image_handler:hide_buf(buf)
    for _, placeholder in pairs(self.bufs[buf].placeholders) do
        placeholder:hide()
    end
end

function image_handler:show_buf(buf)
    for _, placeholder in pairs(self.bufs[buf].placeholders) do
        placeholder:show()
    end
end

function image_handler:load_buf(buf)
    for _, placeholder in pairs(self.bufs[buf].placeholders) do
        placeholder:load_image()
    end
end

function image_handler:update_placements()
    -- run for each window in current tab
    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
	-- gather extmarks (placeholders) in window
        local win_info = vim.fn.getwininfo(win)[1]
        local extmarks = vim.api.nvim_buf_get_extmarks(win_info.bufnr,
            vim.g.nviz_extmark_ns,
	    {0, 0},
            {-1, -1},
        {})
	for _, mark in ipairs(extmarks) do
            local placeholder_visible = self.bufs[win_info.bufnr].placeholders[mark[1]].visible
	    if placeholder_visible then
	        local _ = self.bufs[win_info.bufnr].placeholders[mark[1]]:update_win_placement(win)
            else
		self.bufs[win_info.bufnr].placeholders[mark[1]]:remove_win_placement(win)
	    end
	end
    end
end


local image_placeholder = {
    buf = nil,
    cols = nil,
    rows = nil,
    img_src = nil,
    id = nil,
    win_placements = nil,
    visible = false,
    extra_padding = nil,
}

function image_placeholder:remove_placements()
    for win, _ in pairs(self.win_placements) do
	self:remove_win_placement(win)
    end
end

function image_placeholder:remove_win_placement(win)
    if self.win_placements[win] then
        -- remove placements from kitty
        self.win_placements[win]:remove()
        -- remove placements from placeholder
        table.remove(self.win_placements, win)
    end
end

function image_placeholder:update_win_placement(win)
    if self.visible then
        -- add placement to placeholder
        local placement_id = ''
        if self.win_placements[win] then
            placement_id = self.win_placements[win].display_keys.placement_id
        else
            placement_id = ImageStore.images[self.img_src.image_id]:get_placement_id()
        end

        local placement = image_placement:new({
                win = win,
                row = self.img_src.start_row,
		extra_padding = self.extra_padding,
                col = 0
        }, {
                image_id = self.img_src.image_id,
                placement_id = placement_id
        })
        if placement then
            self.win_placements[win] = placement
            -- return placement id
            return self.win_placements[win].placement_id
        end
    end
    return self:remove_win_placement(win)
end

function image_placeholder:new (p)
  setmetatable(p, self)
  self.__index = self
  vim.api.nvim_buf_set_extmark(p.buf, vim.g.nviz_extmark_ns, p.img_src.start_row-1, p.img_src.start_col, {
      id = p.id,
      sign_text = HiddenSign
--      end_row = p.img_src.end_row-1,
--      end_col = p.img_src.end_col
  })
  p.win_placements = {}
  return p
end

function image_placeholder:unmark()
  vim.api.nvim_buf_del_extmark(self.buf, vim.g.nviz_extmark_ns, self.id)
end

function image_placeholder:show()
    self:reload_position()
    if not self.img_src.image_id then self:load_image() end
    if vim.api.nvim_buf_is_valid(self.buf) then
        -- set padding block
        local filler = {}
        for _=0,self.rows-1 do
            filler[#filler+1] = {{' ', nil}}
        end
	-- add caption
	if self.img_src.caption then
            filler[#filler+1] = {{' ', nil}}
	    local centered = utils.string_center(self.img_src.caption, self.cols, 4)
	    for _, row in ipairs(centered) do
                filler[#filler+1] = {{row, nil}}
	    end
        end
        -- apply padding to marked row -1
	local extmark = {
	    id = self.id,
            virt_lines = filler,
            sign_text = DisplayedSign
            --end_col = self.img_src.end_col
	}
--        if self.img_src.end_row then extmark.end_row = self.img_src.end_row-1 end
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_extmark_ns, self.img_src.start_row-1, self.img_src.start_col, extmark)
        self.visible = true
        self.extra_padding = #filler - self.rows-1
    end
end

function image_placeholder:reload_position()
    local extmark =  vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_extmark_ns, self.id, {details = true})
    if self.id == 2 then
        log.debug(self.img_src.start_row)
        log.debug(extmark[1])
    end
    self.img_src.start_row = extmark[1]+1
    self.img_src.start_col = extmark[2]
    if self.id == 2 then
        log.debug(self.img_src.start_row)
    end
--    self.img_src.end_col = extmark[3].end_col
--    if extmark[3].end_row then self.img_src.end_row = extmark[3].end_row+1 end
	--log.debug(self)
end

function image_placeholder:load_image()
    self.img_src:load_image()
    self.rows, self.cols = ImageStore.images[self.img_src.image_id].rows, ImageStore.images[self.img_src.image_id].cols
end

function image_placeholder:hide()
    self:reload_position()
    self:remove_placements()
    if vim.api.nvim_buf_is_valid(self.buf) then
        -- apply padding to marked row -1
	local extmark = {
	    id = self.id,
--            end_row = self.img_src.end_row-1,
--            end_col = 0,
            virt_lines = nil,
            sign_text = HiddenSign
	}
	--self:reload_position()
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_extmark_ns, self.img_src.start_row-1, self.img_src.start_col, extmark)
        --vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_extmark_ns, 3, 0, extmark)
--        error(vim.inspect(vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_extmark_ns, extmark.id, {details = true})))
    end
    self.extra_padding = nil
    self.visible = false
end

function image_handler:hide_placeholder(buf, row)
    for _, placeholder in pairs(self.bufs[buf].placeholders) do
	if placeholder.img_src.start_row <= row and row <= placeholder.img_src.end_row then
            placeholder:hide()
        end
    end
end

function image_handler:show_placeholder(buf, row)
    for _, placeholder in pairs(self.bufs[buf].placeholders) do
	if placeholder.img_src.start_row == row then -- and row <= placeholder.img_src.end_row then
		log.debug('here')
            placeholder:show()
        end
    end
end

function image_handler:reload_buf_positions(buf)
    if self.bufs[buf] then
        for i, _ in pairs(self.bufs[buf].placeholders) do
            self.bufs[buf].placeholders[i]:reload_position()
        end
    end
end

function image_handler:remove_placeholder(buf, id)
    self.bufs[buf].placeholders[id]:remove_placements()
    self.bufs[buf].placeholders[id]:unmark()
    self.bufs[buf].placeholders[id] = nil
end

function image_handler:get_marks(buf, top, bot)
    local marks, existing_marks = pcall(function () return vim.api.nvim_buf_get_extmarks(buf, vim.g.nviz_extmark_ns, {top, 0}, {bot, -1}, {})end)
    if marks then return existing_marks else return {} end
end

function image_handler:add_placeholder(img_source)
    local placeholder_id = self.next_placeholder_id
    self.next_placeholder_id = self.next_placeholder_id + 1

    local extmarks = vim.api.nvim_buf_get_extmarks(
        img_source.buf,
        vim.g.nviz_extmark_ns,
	{img_source.start_row-1, img_source.start_col},
        {img_source.end_row, img_source.end_col},
	{details = true}
    )
    if next(extmarks) then
	placeholder_id = extmarks[1][1]
	if img_source.hash == self.bufs[img_source.buf].placeholders[placeholder_id].hash then
            return placeholder_id
        else
	    self:remove_placeholder(img_source.buf, placeholder_id)
	end
    end
    local placeholder = image_placeholder:new{
        img_src = img_source,
        buf = img_source.buf,
        id = placeholder_id
    }
    if not self.bufs[img_source.buf] then self.bufs[img_source.buf] = {placeholders = {}} end
    self.bufs[img_source.buf].placeholders[placeholder_id] = placeholder
    return placeholder_id
end


return image_handler
