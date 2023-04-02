local terminal = require('nviz.core.terminal')
local utils = {}


--http://www.computercraft.info/forums2/index.php?/topic/15790-modifying-a-word-wrapping-function/
function utils.split_words(lines, limit)
        while #lines[#lines] > limit do
                lines[#lines+1] = lines[#lines]:sub(limit+1)
                lines[#lines-1] = lines[#lines-1]:sub(1,limit)
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

function utils.string_center(str, limit, padding)
     padding = padding or 4
     local row_chars = limit - padding
     local centered = {}
     local wrapped = utils.string_wrap(str, row_chars)
     for i, row in ipairs(wrapped) do
	 local line_padding = row_chars - #row
	 local side_padding = line_padding/2 + padding/2
	 local format_string = string.format("%%%ds%%%ds%%%ds", side_padding, #row, side_padding)
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
        local filler = vim.fn.winsaveview().topfill
        local exts = vim.api.nvim_buf_get_extmarks(buf,
            vim.g.nviz_extmark_ns,
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

return utils
