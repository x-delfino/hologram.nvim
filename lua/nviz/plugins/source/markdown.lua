local core_parser = require('nviz.source')
local log = require('nviz.utils.log')

local markdown_parser = core_parser:new{
    source_type = 'markdown',
    lang = 'markdown_inline',
    check_client_support = function(self)
	return true
    end,
    gather = function(self, opts)
        local query = vim.treesitter.query.parse(
	    self.lang,
            [[
                (inline
                    (image) @image_capture
		)
	    ]]
	)
	local stored = {}
        for _, node, _ in query:iter_captures(opts.tree:root(), opts.buf, opts.top, opts.bot) do
            stored[#stored+1] = self:buf_store_node(opts.buf, node)
        end
	return stored
    end,
    get_src_dims = function(source)
	local _, _, end_row, end_col = source.node:range()
	local line = vim.api.nvim_buf_get_lines(source.buf, end_row, end_row+1, false)[1]
	local opts_string = line:match("{(.*)}", end_col)
	if opts_string then
            local height = opts_string:match('height%s*=%s*(%d+[%a%p]*)')
	    local width = opts_string:match('width%s*=%s*(%d+[%a%p]*)')
	    return height, width
        end
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
--    get_position = function(source)
--        local mark = vim.api.nvim_buf_get_extmark_by_id(source.buf, vim.g.nviz_src_ns, source.id, {
--                details = true
--        })
--        return mark[1], mark[2], mark[3].end_row, mark[3].end_col
--    end
}

markdown_parser.buf_parsers = {}

function markdown_parser:new(p)
  setmetatable(p, self)
  self.__index = self
  return p
end

function markdown_parser:buf_store_node(buf, node)
    if self.gathered[buf] then
        for source_id, stored in pairs(self.gathered[buf]) do
	    local stored_range = {stored:get_position()}
	    local node_range = {node:range()}
	    if table.concat(stored_range) == table.concat(node_range) then
		stored:update_node(node)
                return stored
	    end
        end
    end
    return self:add_source({
    	buf = buf,
    	node = node,
	get_img_source = self.get_img_source,
	get_img_caption = self.get_img_caption,
	get_src_dims = self.get_src_dims,
	get_position = self.get_position,
    })
end


function markdown_parser:gather_sources(buf, top, bot)
    local tree = self.buf_parsers[buf]:parse()
    assert(#tree > 0, "Parsing current buffer failed!")
    tree = tree[1]
    return self:gather{ buf = buf, top = top, bot = bot, tree = tree }
end

function markdown_parser:init_buf(buf)
    local buf_parser = vim.treesitter.get_parser(buf, self.lang)
    assert(buf_parser , "Treesitter not enabled in current buffer!")
    self.buf_parsers[buf] = buf_parser
end

return markdown_parser
