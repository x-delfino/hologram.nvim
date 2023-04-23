local utils = require('nviz.utils.utils')
local state = require('nviz.utils.state')
    state.update_cell_size()
local log = require('nviz.utils.log')

local core_parser = {
    buf = nil,
    source_type = nil,
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
    p = p or {}
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
    hash = nil,
    get_img_source = nil,
    get_img_caption = nil,
    get_position = nil,
    source_type = nil,
    reload_image = nil,
    holders = nil
}


function source:new(s)
    setmetatable(s, self)
    self.__index = self
    s.hash = vim.fn.sha256(s:get_img_source())
    s.holders = {}
    s.reload_image = true
    return s
end

function source:get_position()
   local mark = vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_src_ns, self.id, {
           details = true
   })
   return mark[1], mark[2], mark[3].end_row, mark[3].end_col
end

function source:get_rows_cols()
    local src_height, src_width = self:get_src_dims()
    local img_height, img_width = self.image.height, self.image.width
    local height = nil
    local width = nil
    local height_factor = nil
    local width_factor = nil
    if src_height or src_width then
	if src_height then
	    local px = src_height:match("(%d*)px")
	    if px then
		height_factor = img_height/px
		height = px
	    else
	        local perc = src_height:match("(%d*)%%*")
		if perc then
		    height_factor = perc/100
		    height = img_height * height_factor
	        end
	    end
	end
	if src_width then
	    local px = src_width:match("(%d*)px")
	    if px then
		width_factor = img_width/px
		width = px
	    else
	        local perc = src_width:match("(%d*)%%*")
		if perc then
		    width_factor = perc/100
		    width = img_width * width_factor
	        end
	    end
	end
    end
    if width and not height then
	height = img_height * width_factor
    end
    if height and not width then
	width = img_height * height_factor
    end
    width, height = width or img_width, height or img_height
    local rows, cols = height/state.cell_size.y, width/state.cell_size.x
    self.offset_rows, self.offset_cols = (math.ceil(rows) - rows), (math.ceil(cols) - cols)
    return height/state.cell_size.y, width/state.cell_size.x
    --return math.ceil(width/state.cell_size.y), math.ceil(height/state.cell_size.x)
    --return math.ceil(img_width/state.cell_size.y), math.ceil(img_height/state.cell_size.x)
end

function source:update_node(node)
    local img_source = self:get_img_source()
    if self.hash ~= vim.fn.sha256(img_source) then
	for _, holder in pairs(self.holders) do
	    holder:hide_win_holder()
	end
	self.reload_image = true
    end
    self.node = node
end

function core_parser:add_source(src)
    self.gathered[src.buf] = self.gathered[src.buf] or {}
    local source_id = self:get_source_id()
    src.id = source_id
    src.source_type = self.source_type
    src = source:new(src)
    local start_row, start_col, end_row, end_col = src.node:range(false)
    vim.api.nvim_buf_set_extmark(src.buf, vim.g.nviz_src_ns, start_row, start_col, {
	    id = src.id,
	    end_row = end_row,
	    end_col = end_col,
    })
    self.gathered[src.buf][source_id] = src
    return src
end

function core_parser:buf_get_sources(buf)
    return self.gathered[buf]
end

function core_parser:buf_get_source(buf, source_id)
    return self.gathered[buf][source_id]
end

-- function core_parser:get_image_source_by_id(id)
--     return self.get_img_source(self.gathered[id])
-- end
-- 
-- function core_parser:get_image_caption_by_id(id)
--     return self.get_img_caption(self.gathered[id])
-- end
-- 
-- function core_parser:get_position_by_id(id)
--     return self.get_position(self.gathered[id])
-- end

return core_parser
