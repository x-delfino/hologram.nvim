local core_parser = require('nviz.source')

local treesitter_parser = core_parser:new()

function treesitter_parser:new(p)
  p = p or {}
  setmetatable(p, self)
  self.__index = self
  p.buf_parsers = p.buf_parsers or {}
  return p
end

function treesitter_parser:buf_store_node(buf, node)
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


function treesitter_parser:gather_sources(buf, top, bot)
    local tree = self.buf_parsers[buf]:parse()
    assert(#tree > 0, "Parsing current buffer failed!")
    tree = tree[1]
    return self:gather{ buf = buf, top = top, bot = bot, tree = tree }
end

function treesitter_parser:init_buf(buf)
    local buf_parser = vim.treesitter.get_parser(buf, self.lang)
    assert(buf_parser , "Treesitter not enabled in current buffer!")
    self.buf_parsers[buf] = buf_parser
end

return treesitter_parser
