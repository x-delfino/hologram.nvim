local base64 = require('nviz.utils.base64')
local socket = require("socket")
local log = require('nviz.utils.log')

local terminal = {}

--[[
     All Kitty graphics commands are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--

local ESC_STR = "<ESC>"
local ESC_CODE = '\x1b'
local START_CODE = ESC_CODE .. '_G'
local START_STR = ESC_STR .. '_G'
local END_STR = ESC_STR .. '|'
local END_CODE = ESC_CODE .. '\\'

local CTRL_KEYS = {
    -- General
    action = 'a',
    delete_action = 'd',
    quiet = 'q',

    -- Transmission
    format = 'f',
    transmission_type = 't',
    data_width = 's',
    data_height = 'v',
    data_size = 'S',
    data_offset = 'O',
    image_id = 'i',
    image_number = 'I',
    compressed = 'o',
    more = 'm',

    -- Display
    placement_id = 'p',
    x_offset = 'x',
    y_offset = 'y',
    width = 'w',
    height = 'h',
    cell_x_offset = 'X',
    cell_y_offset = 'Y',
    cols = 'c',
    rows = 'r',
    cursor_movement = 'C',
    z_index = 'z',

    -- TODO: Animation
}


function terminal._parse_graphics_response(resp)
    if resp:match(START_CODE .. '.*' .. END_CODE) then
	local delim = resp:find(';')
	local message = resp:sub(delim+1, -3)
	local keyref = terminal._table_invert(CTRL_KEYS)
	local keystring = resp:sub(4, delim)
	local keys = {}
	-- split by comma (this needs cleaning up)
	for key in keystring:gmatch('([^,]+)') do
	    local keydelim = key:find('=')
	    local k = key:sub(1,keydelim-1)
	    local ref = keyref[k]
	    if ref then k = ref end
	    keys[k] = key:sub(keydelim+1)
        end
	--log.debug(keys)
	--log.info('response: ' .. message)
	return message, keys
    else return nil end
end


function terminal.send_graphics_command(keys, payload, read)
    --log.info('sending kitty command')
    if payload and string.len(payload) > 4096 then keys.more = 1 else keys.more = 0 end
    local ctrl = keys:serialize()
    -- log.debug('  ctrl string: ', ctrl)
    local encoded_payload = ''
    if payload then
    --    log.debug('  payload: ',  payload)
        payload = base64.encode(payload)
        payload = terminal.get_chunked(payload)
	encoded_payload = ''
        for i=1,#payload do
	    encoded_payload = encoded_payload .. START_CODE ..ctrl..';'..payload[i].. END_CODE
            if i == #payload-1 then ctrl = 'm=0' else ctrl = 'm=1' end
        end
    else
        encoded_payload = START_CODE ..ctrl.. END_CODE
    end
    if read and keys.quiet <= 1 then
        return terminal.readwrite(encoded_payload)
    else
        return terminal.write(encoded_payload)
    end
end

-- Split into chunks of max 4096 length
function terminal.get_chunked(str)
    local chunks = {}
	-- #str 5096
    local cap = 4096
    for i = 1,#str,4096 do
    	if ((#str - i) + 1) < 4096 then
	    cap = #str
        end
--        local chunk = str:sub(i, i + cap - 1):gsub('%s', '') -- the gsub segfaulted
        local chunk = str:sub(i, i + cap - 1)
        if #chunk > 0 then
            table.insert(chunks, chunk)
        end
    end
    return chunks
end


terminal.write2 = vim.schedule_wrap(function(data)
    io.stdout:write(data)
    io.stdout:flush()
end)

function terminal.write (data)
    io.stdout:write(data)
    io.stdout:flush()
end

function terminal.readwrite2 (data)
--    local time = socket.gettime()*1000
--    local stdin = vim.loop.new_tty(0, true)
--    local stdout = vim.loop.new_tty(1, false)
--    stdout:write(data)
--    stdin:read_start(function (err, read)
--      assert(not err, err)
--      if read then
--        stdin:close()
--	stdin:read_stop()
--      else
--        stdin:close()
--        stdout:close()
--      end
--    end)
--

    --for milliseconds
    local time = socket.gettime()*1000
    local resp = nil
    io.stdout:write(data)
    resp = terminal.read()
    --read response
    -- while not resp:match(".*" .. START_CODE .. ".*") do --and not ((socket.gettime()*1000 - time) > 500) do
    --     local read = io.stdin:read(1)
    --     if read then
    --         resp = resp .. read
    --     end
    -- end
    -- local extra = resp:gsub(START_CODE .. ".*", "")
    -- io.stdout:write(extra)
    -- resp = resp:gsub(extra, "")
--    while not resp:match('.*' .. END_CODE)  and not ((socket.gettime()*1000 - time) > 500) do
--    while not resp:match('.*\\') do -- and not ((socket.gettime()*1000 - time) > 500) do
--        local read = io.stdin:read(1)
--        if read then
--            resp = resp .. read
--        end
--    end
 --       log.debug(resp2:gsub(ESC_CODE, ESC_STR))
--    io.stdin:close()
    io.stdout:flush()
    if resp then return terminal._parse_graphics_response(resp) else return false end
end

function terminal.readwrite (data)
--terminal.readwrite = vim.schedule_wrap(function(data)
    local time = socket.gettime()*1000
    io.stdout:flush()
    io.stdout:write(data)
    --read response
    local resp = ''
    while not resp:match(".*" .. END_CODE) and not ((socket.gettime()*1000 - time) > 500) do
        local read = io.stdin:read(1)
        if read then
            resp = resp .. read
        end
    end
    if resp then return terminal._parse_graphics_response(resp) else return false end
end

function terminal.read()
    local time = socket.gettime()*1000
    local start = ''
    local resp = ''
    while resp == '' and not ((socket.gettime()*1000 - time) > 1000) do
        local time2 = socket.gettime()*1000
        while start ~= ESC_CODE and not ((socket.gettime()*1000 - time2) > 1000) do
            if start then io.stdout:write(start) end
            start = io.stdin:read(1)
        end
        if start == ESC_CODE then
            time2 = socket.gettime()*1000
            resp = start
--            while resp == '' and not ((socket.gettime()*1000 - time) > 500) do
                while not resp:match(START_CODE .. '.*' .. END_CODE)  and not ((socket.gettime()*1000 - time2) > 1000) do
                    local read = io.stdin:read(1)
                    if read then
                        resp = resp .. read
                    end
                end
--                resp = (ESC_CODE .. resp):match(START_CODE .. '.*' .. END_CODE)
--              if resp == nil then resp = '' end
--            end
            io.stdin:close()
            return resp
        end
    end
end

function terminal.move_cursor(row, col)
--    terminal.write('\x1b[s')
    --terminal.write(ESC_CODE..' 7')
    terminal.write(ESC_CODE..'[s')
    terminal.write(ESC_CODE..'['..row..';'..col..'H')
end

function terminal.restore_cursor()
    --terminal.write(ESC_CODE..' 8')
    terminal.write(ESC_CODE..'[u')
end

return terminal
