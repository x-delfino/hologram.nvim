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
    extra_padding = nil,
    y_padding = nil
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
        local visible_rows = topfill - screen_win - placement.extra_padding  -- placement.y_padding
        if visible_rows > 0 then
            y_offset = (keys["rows"] - visible_rows) * cs.y
            keys["rows"] = visible_rows
	else return nil end
	placement.y_padding = 0
    end


    -- if image is cut off bottom
    if placement.row == win_info.botline then
        local screen_row = utils.buf_screenpos(placement.row, 0, placement.win, buf)
        local screen_winbot = win_info.winrow+win_info.height
        local visible_rows = screen_winbot-screen_row - placement.y_padding
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
    terminal.move_cursor(row + placement.y_padding, col)
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
            Settings.extmark_ns,
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
    local marks, existing_marks = pcall(function () return vim.api.nvim_buf_get_extmarks(buf, Settings.extmark_ns, {top, 0}, {bot, -1}, {})end)
    if marks then return existing_marks else return {} end
end

function image_handler:add_placeholder(img_source)
    local placeholder_id = self.next_placeholder_id
    self.next_placeholder_id = self.next_placeholder_id + 1

    local extmarks = vim.api.nvim_buf_get_extmarks(
        img_source.buf,
        Settings.extmark_ns,
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
