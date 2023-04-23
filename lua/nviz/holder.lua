local log = require('nviz.utils.log')
local core_holder = {
    holder_type = nil,
    id = nil,
    source = nil,
    buf = nil,
    ns = nil,
    wins = nil,
    show_win = nil,
    hide_win = nil,
    config = nil,
}

function core_holder:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.is_visible = false
  x.wins = {}
  x.config = x.config or {}
  return x
end

local win_holder = {
    is_visible = nil,
    rendered = nil,
    placement_id = nil,
    display_win = nil,
    holder = nil,
    id = nil,
}

function win_holder:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.is_visible = false
  x.rendered = false
  return x
end

function core_holder:get_win_holder(win)
    if self.win and self.win[win] then
	return win
    else return false end
end

function core_holder:add_win_holder(win, win_holder_id)
    if self.wins[win] then
	return false
    else
	local wh = win_holder:new{
		id = win_holder_id,
		holder = self,
		placement_id = self.source.image:get_placement_id()
	}
        self.wins[win] = wh
	return wh
    end
end

function core_holder:show_win_holder(win)
    if not self.wins[win] then
	return false
    end
    local display_pos = self:show_win(win)
    local display_win = display_pos[3] or win
    local display_buf = vim.api.nvim_win_get_buf(display_win)
    -- set marker for image
    vim.api.nvim_buf_set_extmark(
        display_buf, vim.g.nviz_img_ns, display_pos[1], display_pos[2],
        {id = self.wins[win].id}
    )
    self.wins[win].display_win = display_win
    self.wins[win].is_visible = true
    return true
end

function core_holder:hide_win_holder(win)
    win = win or self.wins
    for wi, w in pairs(self.wins) do
        if w.is_visible then
            w.is_visible = false
            self:hide_win(wi)
            w.display_win = nil
        end
    end
end

function core_holder:set_holder(start_row, start_col, end_row, end_col)
    vim.api.nvim_buf_set_extmark(
        self.buf, vim.g.nviz_ns,
	start_row, start_col,
	{
	    id = self.id,
            end_row = end_row,
            end_col = end_col
        }
    )
    return true
end

return core_holder
