--local log = require('nviz.utils.log')
local utils = {}
local log = require'nviz.utils.log'

function utils.round(num)
    return math.floor(num+0.5)
end

-- adapted from http://www.computercraft.info/forums2/index.php?/topic/15790-modifying-a-word-wrapping-function/page__view__findpost__p__197261
function utils.split_words(lines, limit)
	if lines[#lines-1] and #lines[#lines-1] < limit + 2 then
	    lines[#lines-1] = lines[#lines-1] .. ' ' .. lines[#lines]
	    table.remove(lines, #lines)
	end
        while #lines[#lines] > limit do
                lines[#lines+1] = lines[#lines]:sub(limit)
                lines[#lines-1] = lines[#lines-1]:sub(1,limit-1) .. "-"
        end
end

function utils.string_wrap(str, limit)
        local lines, here, found = {}, 1, str:find("(%s+)()(%S+)()")
	limit = limit or 72

        if found then
                lines[1] = string.sub(str,1,found-1)  -- Put the first word of the string in the first index of the table.
        else lines[1] = str end

        str:gsub("(%s+)()(%S+)()",
                function(_, st, word, fi)  -- Function gets called once for every space found.
                        utils.split_words(lines, limit)

                        if fi-here > limit then
                                here = st
                                lines[#lines+1] = word                                                                                   -- If at the end of a line, start a new table index...
                        else lines[#lines] = lines[#lines].." "..word end  -- ... otherwise add to the current table index.
                end)

        utils.split_words(lines, limit)

        return lines
end

function utils.string_center(str, limit, lpad, rpad)
    lpad = lpad or 0
    rpad = rpad or lpad
    local row_chars = limit - (lpad + rpad)
    local centered = {}
    local wrapped = utils.string_wrap(str, row_chars)
    for i, row in ipairs(wrapped) do
        local excess = row_chars - #row
	local line_lpad = lpad + math.ceil(excess/2)
	local line_rpad = limit - #row - line_lpad
        local format_string = string.format("%%%ds%%%ds%%%ds", line_lpad, #row, line_rpad)
        centered[i] = string.format(format_string, "", row, "")
    end
    return centered
end


function utils.buf_screenpos(row, col, win, buf)
    local top = vim.fn.line('w0', win)
    local filler = utils.filler_above(row, win, buf)
    row = row-top+filler+1
    return utils.win_screenpos(row, col, win)
end

function utils.win_screenpos(row, col, win)
    local info = vim.fn.getwininfo(win)[1]
    row = row + info.winrow
    col = col + info.wincol + info.textoff
    return row, col
end

function utils.filler_above(row, win, buf)
    local top = vim.fn.line('w0', win)
    row = row-1 -- row exclusive
    if row <= top then
        return 0
    else
--	log.debug(Settings)
        local filler = vim.fn.winsaveview().topfill
        local exts = vim.api.nvim_buf_get_extmarks(buf,
	    vim.g.nviz_ns,
            {top-1, 0},
            {row-1, -1},
            {details=true}
        )
        for i=1,#exts do
            local opts = exts[i][4]
            if opts.virt_lines then filler = filler + #opts.virt_lines end
        end
        return filler
    end
end

-- shallow
function utils.tbl_compare(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    return true
end

-- big endian
function utils.bytes2int(bufp, little_endian)
    if little_endian then
	local big_end = {}
	for i=#bufp, 1, -1 do
	    big_end[#big_end+1] = bufp[i]
        end
	bufp = big_end
    end
    local bor, lsh = bit.bor, bit.lshift
    return bor(lsh(bufp[1],24), lsh(bufp[2],16), lsh(bufp[3],8), bufp[4])
end

function utils.string_to_bytes(str)
    local bytes = {}
    for i=1,#str,1 do
        bytes[i] = str:byte(i)
    end
    return bytes
end

function utils.get_chunked(data, chunk_size, start, end_char)
    local type = type(data)
    end_char = end_char or #data
    start = start or 1
    local chunks = {}
    local cap = chunk_size
    for i = start+1,end_char,chunk_size do
    	if ((#data - i) + 1) < chunk_size then
	    cap = (#data - i) + 1
        end
--        local chunk = str:sub(i, i + cap - 1):gsub('%s', '') -- the gsub segfaulted
        local chunk = nil
        if type == "string" then
            chunk = data:sub(i-1, i + cap - 1)
	else
	    chunk = {}
	    for ci=i,i+cap-1,1 do
		chunk[#chunk+1] = data[ci]
	    end
	end
        if #chunk > 0 then
            table.insert(chunks, chunk)
        end
    end
    return chunks
end

function utils.invert_table(table)
   local inverted={}
   for k,v in pairs(table) do
     inverted[v]=k
   end
   return inverted
end

function utils.createFlatClass(...)
    -- look up for `k' in list of tables `plist'
    local function search (k, plist)
      for i=1, table.getn(plist) do
        local v = plist[i][k]     -- try `i'-th superclass
        if v then return v end
      end
    end
    local c = {}        -- new class
    -- class will search for each method in the list of its
    -- parents (`arg' is the list of parents)
    setmetatable(c, {__index = function (t, k)
        local v = search(k, arg)
        t[k] = v       -- save for next access
        return v
    end})
    -- prepare `c' to be the metatable of its instances
    c.__index = c
    -- define a new constructor for this new class
    function c:new (o)
        o = o or {}
        setmetatable(o, c)
        return o
    end
    -- return new class
    return c

end

function utils.createClass(...)
    -- look up for `k' in list of tables `plist'
    local function search (k, plist)
      for i=1, table.getn(plist) do
        local v = plist[i][k]     -- try `i'-th superclass
        if v then return v end
      end
    end
    local c = {}        -- new class
    -- class will search for each method in the list of its
    -- parents (`arg' is the list of parents)
    setmetatable(c, {__index = function (t, k)
        return search(k, arg)
    end})
    -- prepare `c' to be the metatable of its instances
    c.__index = c
    -- define a new constructor for this new class
    function c:new (o)
        o = o or {}
        setmetatable(o, c)
        return o
    end
    -- return new class
    return c
end

return utils
