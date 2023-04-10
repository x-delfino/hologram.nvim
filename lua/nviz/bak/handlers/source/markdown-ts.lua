-- https://github.com/jbyuki/carrot.nvim
local source_handler = require('nviz.handlers.source.core')
local remote = require('nviz.utils.remote')
local fs = require('nviz.utils.fs')
local log = require('nviz.utils.log')

local ts_md_source_handler = source_handler:new{
    name = 'ts-markdown',
    get_data = function(image_source)
    end,
    get_caption = function(image_source)
    end,
    find = function(buf, top, bot)
    end,
    init = function()
        local parser = vim.treesitter.get_parser(0, 'markdown_inline')
        assert(parser , "Treesitter not enabled in current buffer!")

        local tree = parser:parse()
        assert(#tree > 0, "Parsing current buffer failed!")

        tree = tree[1]

	local ts_query_inline_image = [[
	    (inline
	        (image) @image_node
	    )
	]]

        local query = vim.treesitter.query.parse("markdown_inline", ts_query_inline_image)
        local image_links = {}
	-- Query:iter_matches({self}, {node}, {source}, {start}, {stop})
	for id, node, metadata in query:iter_captures(tree:root(), bufnr, first, last) do
            local name = query.captures[id] -- name of the capture in the query
            -- typically useful info about the node:
            local node_type = node:type() -- type of the captured node
	    log.debug(name)
	    log.debug(vim.treesitter.get_node_text(node:named_child(0)))
            local row1, col1, row2, col2 = node:range() -- range of the capture
  -- ... use the info here ...
        end
--        for pattern, match, metadata in query:iter_matches(root, 0) do
--            local caption, source
--            for id, node in pairs(match) do
--		log.debug(node)
--                local name = query.captures[id]
--                local start_row, start_col, end_row, end_col = node:range()
--                if end_row == vim.api.nvim_buf_line_count(0) then
--                  end_row = end_row - 1
--                  end_col = #(vim.api.nvim_buf_get_lines(0, -2, -1, false)[1])
--                end
--
--                local text = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
--		if name == "caption" then
--		    caption = text
--		elseif name == "source" then
--		    source = text
--	        end
--            end
--	    image_links[#image_links+1] = {
--		node
--	    }
--        end
--	log.debug(image_links)
    end,
}


return ts_md_source_handler
