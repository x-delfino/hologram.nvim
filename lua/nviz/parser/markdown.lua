local core_parser = require('nviz.parser.core')
local log = require('nviz.utils.log')


local markdown_parser = core_parser:new{
    name = 'markdown',
    lang = 'markdown_inline',
    gather = function(self, opts)
        local query = vim.treesitter.query.parse(
	    self.lang,
            [[
                (inline
                    (image) @image_node
                )
            ]]
	)
	local stored = {}
        for _, node, _ in query:iter_captures(opts.tree:root(), self.buf, opts.top, opts.bot) do
            stored[#stored+1] = self:store_node(node)
        end
	return stored
    end,
    get_img_source = function(source)
	for node in source.node:iter_children() do
	    if node:type() == 'link_destination' then
	        return vim.treesitter.get_node_text(node, 1)
	    end
        end
    end,
    get_img_caption = function(source)
	for node in source.node:iter_children() do
	    if node:type() == 'image_description' then
	        return vim.treesitter.get_node_text(node, 1)
	    end
        end
    end,
    get_position = function(source)
	return source.node:range()
    end
}

function markdown_parser:new(p)
  setmetatable(p, self)
  self.__index = self
  return p
end

return markdown_parser
