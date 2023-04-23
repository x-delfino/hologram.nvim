local source_handler = require('nviz.handlers.source.core')

local d2_source_handler = source_handler:new{
    name = 'd2',
    get_data = function(image_source)
    end,
    get_caption = function(image_source)
    end,
    find = function(buf, top, bot)
	-- need to make this more efficient. and probably make it available for other handlers
        local lines = vim.api.nvim_buf_get_lines(buf, top, bot, false)
        local sources = {}
	local block_position = {}
        for n, line in ipairs(lines) do
            local start_col, end_col = line:find('^```d2$')
            if start_col then
		block_position.start_row = top+n
		block_position.start_col = start_col
		break
	    end
        end
	if block_position.start_row then
	    for n=block_position.start_row-top+1,#lines,1 do
                local start_col, end_col = lines[n]:find('^```$')
	        if end_col then
	    	block_position.end_row = top+n
	    	block_position.end_col = end_col
	    	break
	        end
            end
	    local buffer_size = vim.api.nvim_buf_line_count(buf)
            local extra_lines = vim.api.nvim_buf_get_lines(buf, bot, buffer_size, false)
            for n, line in ipairs(extra_lines) do
                local start_col, end_col = lines[n]:find('^```$')
	        if end_col then
	    	block_position.end_row = top+n
	    	block_position.end_col = end_col
	    	break
	        end
            end
        end
		
--                sources[#sources+1] = {
--		    { top+n, start_col }, -- start of mark
--		    { top+n, end_col } -- end of mark
--		}
        end
        return sources
    end
}

return d2_source_handler
