local utils = require('nviz.utils.utils')

local ESC_CODE = '\x1b'

local placement = {
    win_holder = nil,
    holder = nil,
    placement_id = nil,
}

function placement:new(p)
  setmetatable(p, self)
  self.__index = self
  return p
end

local terminal_handler = {
    name = nil,
    check_support = nil,
    get_load_message = nil,
    get_show_message = nil,
    get_hide_message = nil,
    get_delete_message = nil,
    pre_show = nil,
    post_show = nil,
    serialize_message = nil,
    deserialize_message = nil,
    next_placement_id = 1,
    placements = {}
}

function terminal_handler:new(t)
  setmetatable(t, self)
  self.__index = self
  return t
end

function terminal_handler:get_placement_id()
    local placement_id = self.next_placement_id
    self.next_placement_id = placement_id+1
    return placement_id
end

function terminal_handler:win_get_placement(win, holder_id)
    for _, p in pairs(self.placements) do
	if p.holder_id == holder_id and p.win == win then return p end
    end
end

function terminal_handler:load_image(image_source)
    local message = self.serialize_message(self.get_load_message(image_source))
    self:write(message)
end

function terminal_handler:delete_image(image_source)
    local message = self.serialize_message(self.get_delete_message(image_source))
    self:write(message)
end

function terminal_handler:win_show_image(win, image_holder)
    local plc = self:win_add_placement_from_holder(win, image_holder)
    local message = self.serialize_message(self.get_show_message({
	    holder = image_holder,
	    placement = plc
    }))
    self.pre_show({win = win, image_holder = image_holder})
    self:write(message)
    self.post_show(image_holder)
end

function terminal_handler:win_add_placement_from_holder(win, holder)
    local plc = self:win_get_placement(win, holder.holder_id)
    if not plc then
	plc = placement:new{
		win = win,
		holder_id = holder.holder_id,
		image_id = holder.image_id,
                placement_id = self:get_placement_id()
	}
	self.placements[#self.placements+1] = plc
    end
    return plc
end

function terminal_handler:win_hide_image(win, holder_id)
    local plc = self:win_get_placement(win, holder_id)
    local message = self.serialize_message(self.get_hide_message(plc))
    self:write(message)
end

function terminal_handler:hide_image(image_holder)
    local message = self.serialize_message(self.get_hide_message(image_holder))
    self:write(message)
end

function terminal_handler:write(data)
    io.stdout:write(data)
    io.stdout:flush()
end

function terminal_handler:win_move_cursor(win, row, col, y_offset)
    y_offset = y_offset or 0
    local buf = vim.api.nvim_win_get_buf(win)
    row, col = utils.buf_screenpos(row, col, win, buf)
    self:move_cursor(row+1+y_offset, col)
end

function terminal_handler:move_cursor(row, col)
    -- terminal.write('\x1b[s')
    -- terminal.write(ESC_CODE..' 7')
    print(vim.inspect({row, col}))
    self:write(ESC_CODE..'[s')
    self:write(ESC_CODE..'['..row..';'..col..'H')
end

function terminal_handler:restore_cursor()
    -- terminal.write(ESC_CODE..' 8')
    self:write(ESC_CODE..'[u')
end

return terminal_handler
