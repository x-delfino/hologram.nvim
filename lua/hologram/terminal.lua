local base64 = require('hologram.base64')
local socket = require("socket")
local log = require('hologram.log')

local terminal = {}

--[[
     All Kitty graphics commands are of the form:

   '<ESC>_G<control data>;<payload><ESC>\'

     <control keys> - a=T,f=100....
          <payload> - base64 enc. file data
              <ESC> - \x1b or \27 (*)

     (*) Lua5.1/LuaJIT accepts escape seq. in dec or hex form (not octal).
]]--

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

function terminal._table_invert(table)
   local inverted={}
   for k,v in pairs(table) do
     inverted[v]=k
   end
   return inverted
end


function terminal._parse_graphics_response(resp)
    if resp:match('\x1b_G.*\x1b\\') then
	local delim = resp:find(';')
	local message = resp:sub(delim+1, -3)
	local keyref = terminal._table_invert(CTRL_KEYS)
	local keystring = resp:sub(5, delim)
	local keys = {}
	-- split by comma (this needs cleaning up)
	for key in keystring:gmatch('([^,]+)') do
	    local keydelim = key:find('=')
	    local k = key:sub(1,keydelim-1)
	    local ref = keyref[k]
	    if ref then k = ref end
	    keys[k] = key:sub(keydelim+1)
        end
	log.debug(keys)
	log.info('message: ' .. message)
	return message, keys
    else return nil end
end


function terminal.send_graphics_command(keys, payload)
    if payload and string.len(payload) > 4096 then keys.more = 1 else keys.more = 0 end
    local ctrl = ''
    for k, v in pairs(keys) do
        if v ~= nil then
            ctrl = ctrl..CTRL_KEYS[k]..'='..v..','
        end
    end
    ctrl = ctrl:sub(0, -2) -- chop trailing comma
    if payload then
        payload = base64.encode(payload)
        payload = terminal.get_chunked(payload)
	local encoded_payload = ''
        for i=1,#payload do
	    encoded_payload = encoded_payload .. '\x1b_G'..ctrl..';'..payload[i]..'\x1b\\'
            if i == #payload-1 then ctrl = 'm=0' else ctrl = 'm=1' end
        end
        terminal.readwrite(encoded_payload)
    else
        terminal.readwrite('\x1b_G'..ctrl..'\x1b\\')
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

function terminal.move_cursor(row, col)
    terminal.write('\x1b[s')
    terminal.write('\x1b['..row..':'..col..'H')
end

function terminal.restore_cursor()
    terminal.write('\x1b[u')
end

terminal.write = vim.schedule_wrap(function(data)
    io.stdout:write(data)
    io.stdout:flush()
end)

-- glob together writes to stdout
terminal.readwrite = vim.schedule_wrap(function(data)
    io.stdout:write(data)
    io.stdout:flush()
    --for milliseconds
    local time = socket.gettime()*1000
    --read response
    local resp = " "
    repeat
	local read = io.stdin:read(1)
	if read then
	    if resp then
                resp = resp .. read
	    else resp = read end 
        end
    --stop reading input when end of reply with 0.3s timeout
    until resp:match('.*\x1b\\') or (socket.gettime()*1000 - time) > 200
    return terminal._parse_graphics_response(resp)
end)

return terminal
