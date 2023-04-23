local source_handler = require('nviz.handlers.source.core')
local remote = require('nviz.utils.remote')
local fs = require('nviz.utils.fs')

local md_source_handler = source_handler:new{
    name = 'markdown',
    get_data = function(image_source)
        local line = vim.api.nvim_buf_get_lines(image_source.buf, image_source.start_row-1, image_source.end_row, true)[1]
	local source = nil
        local path = line:sub(image_source.start_col, image_source.end_col):match('%((.+)%)')
        if remote.is_url(path) then
            source = remote.download_file(path)
        else
            source = fs.get_absolute_path(path)
        end
        return source
    end,
    get_caption = function(image_source)
        local line = vim.api.nvim_buf_get_lines(image_source.buf, image_source.start_row-1, image_source.end_row, true)[1]
        local caption = line:sub(image_source.start_col, image_source.end_col):match('!%[(.-)%]')
        if caption == "" then caption = nil end
        return caption
    end,
    find = function(buf, top, bot)
        local lines = vim.api.nvim_buf_get_lines(buf, top, bot, false)
        local sources = {}
        for n, line in ipairs(lines) do
            local start_col, end_col = line:find('!%[.-%]%(.-%)')
            if start_col then
                sources[#sources+1] = {
		    { top+n, start_col }, -- start of mark
		    { top+n, end_col } -- end of mark
		}
            end
        end
        return sources
    end
}

return md_source_handler
