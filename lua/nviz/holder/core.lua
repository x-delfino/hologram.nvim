local log = require('nviz.utils.log')
local core_holder = {
    holder_type = nil,
    id = nil,
    source = nil,
    buf = nil,
    ns = nil,
    pad = nil,
    wins = nil,
    show_win = nil,
    hide_win = nil,
}

function core_holder:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.pad = x.pad or { 0, 0, 0, 0 }
  x.is_visible = false
  x.wins = {}
  return x
end

local win_holder = {
    is_visible = nil,
    placement_id = nil,
    display_win = nil,
    win_holder_id = nil,
}

function win_holder:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.is_visible = false
  return x
end

function core_holder:win_show_holder(win)
    if not self.wins[win] then
	self.wins[win] = win_holder:new{}
    end
    local display_pos = self:show_win(win)
    local display_win = display_pos[3] or win
    local display_buf = vim.api.nvim_win_get_buf(display_win)
    -- set marker for image
    local new_win_holder_id = vim.api.nvim_buf_set_extmark(
        display_buf, vim.g.nviz_img_ns, display_pos[1], display_pos[2],
        {id = self.wins[win].win_holder_id}
    )
    self.wins[win].win_holder_id = new_win_holder_id or self.wins[win].win_holder_id
    self.wins[win].display_win = display_win
    self.wins[win].is_visible = true
end

function core_holder:win_hide_holder(win)
    self:hide_win(win)
    self.wins[win].is_visible = false
end

function core_holder:set_holder(row, col)
    log.debug({self.buf, vim.g.nviz_ns, row, col, self.id})
    vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_ns, row, col, {id = self.id})
    return true
end

return core_holder
