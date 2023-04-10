local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')

local ESC_CODE = '\x1b'

local placement = {
    id = nil,
    holder = nil,
    win_holder = nil
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
    settings = nil,
}

function terminal_handler:new(t)
  t = t or {}
  setmetatable(t, self)
  self.__index = self
  t.placements = {}
  return t
end

function terminal_handler:get_placement_id()
    local placement_id = self.next_placement_id
    self.next_placement_id = placement_id + 1
    return placement_id
end

function terminal_handler:load_image(image_source)
    local message = self.serialize_message(self.get_load_message(image_source))
    self:write(message)
end

function terminal_handler:delete_image(image_source)
    local message = self.serialize_message(self.get_delete_message(image_source))
    self:write(message)
end

function terminal_handler:hide_image(image_holder)
    local message = self.serialize_message(self.get_hide_message(image_holder))
    self:write(message)
end

function terminal_handler:win_get_placement(holder, win_holder)
    for _, p in pairs(self.placements) do
	if p.holder == holder and p.win_holder == win_holder then return p end
    end
end

function terminal_handler:win_show_image(holder, win_holder, row, col)
    if not win_holder.placement_id then
        win_holder.placement_id = self:get_placement_id()
        self.placements[win_holder.placement_id] = placement:new{
            win_holder = win_holder,
            holder = holder,
            id = win_holder.placement_id,
        }
    end
    local plc = self.placements[win_holder.placement_id]
    local message = self.serialize_message(self.get_show_message(
	 self.placements[win_holder.placement_id]
    ))
    self.pre_show(plc, row, col)
    self:write(message)
    self.post_show(plc)
end

function terminal_handler:write(data)
    log.debug(data:gsub(ESC_CODE, 'ESC'))
    io.stdout:write(data)
    io.stdout:flush()
end

function terminal_handler:win_move_cursor(win, row, col, y_offset)
	log.debug({win, row, col, y_offset})
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
