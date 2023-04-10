local utils = require('nviz.utils.utils')

local core_parser = {
    buf = nil,
    name = nil,
    lang = nil,
    parser = nil,
    gathered = nil,
    gather = nil,
    update = nil,
    get_img_source = nil,
    get_img_caption = nil,
    get_position = nil,
    next_source_id = nil,
}

function core_parser:new(p)
    setmetatable(p, self)
    self.__index = self
    p.gathered = {}
    p.next_source_id = 1
    return p
end

function core_parser:get_source_id()
    local source_id = self.next_source_id
    self.next_source_id = source_id + 1
    return source_id
end

local source = {
    buf = nil,
    id = nil,
    image = nil,
    node = nil,
    get_img_source = nil,
    get_img_caption = nil,
    get_position = nil,
}

function source:new(s)
    setmetatable(s, self)
    self.__index = self
    s.win_holders = {}
    return s
end

function core_parser:init()
    local parser = vim.treesitter.get_parser(self.buf, self.lang)
    assert(parser , "Treesitter not enabled in current buffer!")
    parser:parse()
    self.parser = parser
end

function core_parser:add_source(src)
    local source_id = self:get_source_id()
    src.id = source_id
    src = source:new(src)
    self.gathered[source_id] = src
    return src
end

function core_parser:store_node(node)
    for source_id, stored in pairs(self.gathered) do
        if node:equal(stored.node) then
	    return source_id
        end
    end
    return self:add_source({
    	buf = self.buf,
    	node = node,
	get_img_source = self.get_img_source,
	get_img_caption = self.get_img_caption,
	get_position = self.get_position,
    })
end

function core_parser.get_position(src)
    src.node:range(false)
end

function core_parser:gather_sources(top, bot)
    local tree = self.parser:parse()
    assert(#tree > 0, "Parsing current buffer failed!")
    tree = tree[1]
    return self:gather{top = top, bot = bot, tree = tree}
end

function core_parser:get_image_source_by_id(id)
    return self.get_img_source(self.gathered[id])
end

function core_parser:get_image_caption_by_id(id)
    return self.get_img_caption(self.gathered[id])
end

function core_parser:get_position_by_id(id)
    return self.get_position(self.gathered[id])
end

return core_parser
