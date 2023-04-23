local utils = require('nviz.utils.utils')
local job = require('plenary.job')
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
    terminal_type = nil,
    check_support = nil,
    get_load_message = nil,
    get_show_message = nil,
    get_hide_message = nil,
    get_delete_message = nil,
    pre_show = nil,
    post_show = nil,
    serialize_message = nil,
    deserialize_message = nil,
    config = nil,
    rendered = nil,
}

function terminal_handler:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    t.rendered = {}
    return t
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

--function terminal_handler:win_get_placement(holder, win_holder)
--    for _, p in pairs(self.placements) do
--	if p.holder == holder and p.win_holder == win_holder then return p end
--    end
--end
--
function terminal_handler:win_hide_image(win_holder)
    local message = self.serialize_message(self.get_hide_message(
        win_holder
    ))
    self:write(message)
end

function terminal_handler:win_show_image(win_holder, row, col)
    local config = win_holder.holder.config
    local y_offset = config.y_offset + config.pad[1]
    local x_offset = config.x_offset + config.pad[4]
    local message = self.get_show_message(
        win_holder,
        row,
        col,
        y_offset
    )
    if message then
        message = self.serialize_message(message)
        self.pre_show(win_holder, row, col, y_offset, x_offset)
        self:write(message)
        self.post_show(win_holder)
        return true
    end
    return false
end

--    local stdout = vim.loop.new_tty(1, false)
function terminal_handler:write(data)
    --    local stdin = vim.loop.new_tty(0, true)
    --    stdout:write(data)
    --    stdin:read_start(function (err, d)
    --	    log.debug(d)
    --	log.debug('in here')
    --	assert(not err, err)
    --	stdin:close()
    --    end)

    io.stdout:write(data)
    io.stdout:flush()
    --job:new({
    --    command = 'printf',
    --    args = {'"what"'}
    --}):sync()
end


function terminal_handler:win_move_cursor(win, row, col, y_offset, x_offset)
    local buf = vim.api.nvim_win_get_buf(win)
    row, col = utils.buf_screenpos(row, col, win, buf)
    self:move_cursor(row + y_offset, col + x_offset)
end

function terminal_handler:move_cursor(row, col)
    -- terminal.write('\x1b[s')
    -- terminal.write(ESC_CODE..' 7')
    self:write(ESC_CODE .. '[s')
    local ignored_events = vim.opt.eventignore
    vim.opt.eventignore = { 'CursorMoved', 'CursorMovedI' }
    self:write(ESC_CODE .. '[' .. row .. ';' .. col .. 'H')
    vim.opt.eventignore = ignored_events
end

function terminal_handler:restore_cursor()
    -- terminal.write(ESC_CODE..' 8')
    local ignored_events = vim.opt.eventignore
    vim.opt.eventignore = { 'CursorMoved', 'CursorMovedI' }
    self:write(ESC_CODE .. '[u')
    vim.opt.eventignore = ignored_events
end

return terminal_handler
