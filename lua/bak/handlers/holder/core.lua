local state = require('nviz.utils.state')
local utils = require('nviz.utils.utils')

local image_win_holder = {
    win = nil,
    tracker = nil,
    visible = false,
    display_win = nil,
    display_row = nil,
    display_col = nil
}

function image_win_holder:new(w)
  setmetatable(w, self)
  self.__index = self
  return w
end

local image_holder = {
    image_id = nil,
    holder_id = nil,
    holder_namespace = nil,
    caption = nil,
    source_id = nil,
    source_namespace = nil,
    buf = nil,
    y_pad = nil,
    --visible = false,
    --tracker = nil,
    win_holders = nil
}

function image_holder:new(p)
  setmetatable(p, self)
  self.__index = self
  p.y_pad = Settings.inline_image_padding_y
  p.holder_id = CoreHandler:get_holder_id()
  p.win_holders = {}
 return p
end

function image_holder:win_get_display_position(win)
    return
        self.get_display_position({win=win, holder=self})
end



function image_holder:win_get_visible_rows_and_cols(win)
    local y_offset = 0
    local image = CoreHandler:get_image_by_id(self.image_id)
    local visible_img_cols = math.ceil(image.width/state.cell_size.x)
    local visible_img_rows = math.ceil(image.height/state.cell_size.y)
    local win_info = vim.fn.getwininfo(win)[1]
    local buf = vim.api.nvim_win_get_buf(win)
    local cs = state.cell_size
    local row, _ = self:get_position()

    -- check if visible
    if row < win_info.topline-2 or row > win_info.botline then
        return nil
    end

    -- if image is cut off top
    if row == win_info.topline-2 then
        local topfill = vim.fn.winsaveview().topfill
        local visible_mark_rows = topfill - win_info.winrow -- holder.extra_padding  -- holder.y_padding
        if visible_mark_rows > 0 then
            y_offset = (visible_img_rows - visible_mark_rows) * cs.y
            visible_img_rows = visible_mark_rows
	else return nil end
--	holder.y_padding = 0
    end

    -- if image is cut off bottom
    if row == win_info.botline then
        local screen_row = utils.buf_screenpos(row, 0, win, buf)
        local screen_winbot = win_info.winrow+win_info.height
        local visible_rows = screen_winbot-screen_row -- holder.y_padding
        if visible_rows > 0 and visible_rows < visible_img_rows then
            visible_img_rows = visible_rows
        end
    end
    return visible_img_rows, visible_img_cols
end

function image_holder:get_position()
    local namespace, id = nil, nil
    if self.holder_namespace == 99 then
	namespace = self.holder_namespace
	id = self.holder_id
    else
	namespace = self.source_namespace
	id = self.source_id
    end
--    error(vim.inspect({self.buf, namespace, id}))
    local mark = vim.api.nvim_buf_get_extmark_by_id(self.buf ,namespace, id, {})
    return mark[1], mark[2]
end

local holder_handler = {
    name = nil,
    show = nil,
    hide = nil,
    namespace = nil,
    holders = nil
}

function holder_handler:new(d)
  setmetatable(d, self)
  self.__index = self
  d.namespace = vim.api.nvim_create_namespace('nviz_holder_' .. d.name)
  d.holders = {}
  return d
end

function holder_handler:win_get_display_position(win, id)
    local holder = self.holders[id]
    self.get_display_position({win=win, holder=holder})
end

function holder_handler:win_show_holder(win, id)
    local holder = self.holders[id]
    local opts = { win = win }
    opts.image = CoreHandler:get_image_by_id(holder.image_id)
    opts.holder_namespace = self.namespace
--    local holder_position = self.get_holder_position(holder)
--    if holder_position then
--        opts.start_row, opts.start_col = holder_position[2], holder_position[3]
--    end
    vim.api.nvim_set_hl(0, 'caption', {italic = true, fg = '#66728a'})
    if not holder.win_holders[win] then
	holder.win_holders[win] = image_win_holder:new{win = win}
    end
    opts.win_holders = holder.win_holders
--    error(vim.inspect(holder))
    self.show(vim.tbl_extend('keep', holder, opts))
end

function holder_handler:show_holder(id)
    local holder = self.holders[id]
    local opts = {}
    opts.image = CoreHandler:get_image_by_id(holder.image_id)
--    local mark = vim.api.nvim_buf_get_extmark_by_id(holder.buf,
--	holder.source_namespace,
--	holder.source_id,
--	{}
--    )
    opts.holder_namespace = self.namespace
    opts.start_row, opts.start_col = self.get_holder_position(holder)
    vim.api.nvim_set_hl(0, 'caption', {italic = true, fg = '#66728a'})
    holder.tracker = self.show(vim.tbl_extend('keep', opts, holder))
    holder.visible = true
end

function holder_handler:hide_holder(id)
    local holder = self.holders[id]
    local opts = {}
    local mark = vim.api.nvim_buf_get_extmark_by_id(holder.buf,
	holder.source_namespace,
	holder.source_id,
	{}
    )
    opts.holder_namespace = self.namespace
    opts.start_row, opts.start_col = mark[1], mark[2]
    self.hide(vim.tbl_extend('keep', opts, holder))
    holder.visible = false
end

function holder_handler:win_hide_holder(win, id)
    local holder = self.holders[id]
    local win_holder = holder.win_holders[win]
    if (win_holder and win_holder.visible) then
        local opts = {}
        opts.image = CoreHandler:get_image_by_id(holder.image_id)
        opts.holder_namespace = self.namespace
        opts.start_row, opts.start_col = self.get_holder_position(holder)
        opts.tracker = win_holder.tracker
        opts.win = win
        opts.win_holders = holder.win_holders

        self.hide(vim.tbl_extend('keep', opts, holder))
        win_holder.visible = false
	return true
    end
    return false
end

function holder_handler:win_hide_holder_all(win)
    for _, holder in pairs(self.holders) do
	self:win_hide_holder(win, holder.holder_id)
    end
end

function holder_handler:add_holder(holder)
    holder.holder_namespace = self.namespace
    self.holders[#self.holders+1] = image_holder:new(holder)
end

function holder_handler:get_holder_by_source_id(source_id)
    for _, holder in pairs(self.holders) do
	if holder.source_id == source_id then
	    return holder
        end
    end
end

return holder_handler
