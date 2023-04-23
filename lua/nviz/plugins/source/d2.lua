local treesitter_parser = require('nviz.plugins.source.treesitter')
local log = require('nviz.utils.log')

local d2_parser = treesitter_parser:new{
    source_type = 'd2',
    lang = 'markdown',
    check_client_support = function(self)
	return true
    end,
    gather = function(self, opts)
        local query = vim.treesitter.query.parse(
	    self.lang,
            [[
                (fenced_code_block
	            (info_string
	                (language) @lang (#eq? @lang "d2")
	            )
	        )  @code_block
	    ]]
	)
	local stored = {}
	for _, match, _ in query:iter_matches(opts.tree:root(), opts.buf, opts.top, opts.bot) do
            for id, node in pairs(match) do
		    log.debug(query.captures[id])
	        if query.captures[id] == 'code_block' then
	            log.debug(vim.treesitter.get_node_text(node, 0))
	            log.debug(self.get_img_caption({node = node, buf = opts.buf}))
                    stored[#stored+1] = self:buf_store_node(opts.buf, node)
		    break
	        end
	    end
        end
	return stored
    end,
    get_src_dims = function(source)
	for node in source.node:iter_children() do
            if node:type() == 'info_string' then
	        local info_string = vim.treesitter.get_node_text(node, 0):match('d2%s+(.+)')
		if info_string then
                    local height = info_string:match('height%s*=%s*(%d+[%a%p]*).*}')
	            local width = info_string:match('width%s*=%s*(%d+[%a%p]*).*}')
	            return height, width
	        end
            end
        end
    end,
    get_img_source = function(source)
	for node in source.node:iter_children() do
            if node:type() == 'code_fence_content' then
                return vim.treesitter.get_node_text(node, source.buf)
            end
        end
    end,
    get_img_caption = function(source)
	for node in source.node:iter_children() do
            if node:type() == 'info_string' then
	        return vim.treesitter.get_node_text(node, source.buf):match('title%s*=%s*[%"%\'](.*)[%"%\'].*}')
            end
        end
    end,
}

return d2_parser
