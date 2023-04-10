local log = require('nviz.utils.log')

local source_handler = {
    name = nil,
    get_data = nil,
    get_caption = nil,
    find = nil,
    namespace = nil,
    sources = {},
    next_source_id = 1
}

function source_handler:new(s)
  setmetatable(s, self)
  self.__index = self
  s.namespace = vim.api.nvim_create_namespace('nviz_source_' .. s.name)
  return s
end

function source_handler:get_source_data_by_id(source_id)
    return self.get_data(self.sources[source_id])
end

function source_handler:get_source_data(source)
    return self.get_data(source)
end

function source_handler:load_image(source_id)
    local image_source = self.get_source_data(self.sources[source_id])
    self.sources[source_id].image_id = CoreHandler.load_image(image_source)
end

function source_handler:get_source_id()
    local source_id = self.next_source_id
    self.next_source_id = source_id + 1
    return source_id
end

local image_source = {
    buf = nil,
    start_row = nil,
    start_col = nil,
    end_col = nil,
    end_row = nil,
    hash = nil,
    image_id = nil,
    source_id = nil
}

function image_source:new(s)
  setmetatable(s, self)
  self.__index = self
  return s
end

function image_source:get_position(namespace)
    local mark = vim.api.nvim_buf_get_extmark_by_id(self.buf, namespace, self.source_id, {details=true})
    local position = {
	    start_row = mark[1],
	    start_col = mark[2],
            end_row = mark[3].end_row,
            end_col = mark[3].end_col
    }
    return position
end


function image_source:mark_source(namespace)
  vim.api.nvim_buf_set_extmark(self.buf, namespace, self.start_row-1, self.start_col, {
      id = self.source_id,
      end_row = self.end_row-1,
      end_col = self.end_col
  })
--  error(vim.inspect({self.buf, namespace, self.source_id}))
--  error(vim.inspect(vim.api.nvim_buf_get_extmark_by_id(self.buf, namespace, self.source_id, {})))
end

function source_handler:new_source(opts)
    opts = opts or {}
    opts.source_id = opts.source_id or self:get_source_id()
    local source = image_source:new(opts)
    return source
end

function source_handler:get_position_by_id(id)
    return self.sources[id]:get_position(self.namespace)
end

function source_handler:load_source(opts)
    local source = self:new_source(opts)
    source.hash = self:compute_hash(source)
    source:mark_source(self.namespace)
    self.sources[source.source_id] = source
    return source.source_id
end

function source_handler:mark_sources()
    for _, source in ipairs(self.sources) do
	source:mark_source()
    end
end

function source_handler:find_source_block_match(position)
    position.end_row, position.end_col =
        position.end_row or position.start_row,
	position.end_col or position.start_col
    for _, source in pairs(self.sources) do
	local source_position = self:get_position_by_id(source.source_id)
	if
	  position.start_row-1 <= source_position.end_row and
	  position.end_row-1 >= source_position.start_row
	then return source end
    end
end

function source_handler:compute_hash(img_source)
    local lines = vim.api.nvim_buf_get_lines(img_source.buf, img_source.start_row-1, img_source.end_row, false)
    lines[1] = lines[1]:sub(img_source.start_col, -1)
    lines[#lines] = lines[#lines]:sub(1, img_source.end_col)
    local content = table.concat(lines)
    local hash = vim.fn.sha256(content)
    return hash
end

function source_handler:gather(buf, top, bot)
    local source_ids = {}
    local found_sources = self.find(buf, top, bot)
    for _, found_source_pos in pairs(found_sources) do
	local source_id = self:load_source{
            buf = buf,
            start_row = found_source_pos[1][1],
	    end_row = found_source_pos[2][1],
            start_col = found_source_pos[1][2],
            end_col = found_source_pos[2][2],
        }
	source_ids[#source_ids+1] = source_id
    end
    return source_ids
end

-- function source_handler.buf_image_finder(find_func, buf, top, bot)
--     local sources = find_func(buf, top, bot)
--     return sources
-- end
-- 
-- function source_handler.buf_mark_images(buf, top, bot)
--     local image_sources = source_handler.buf_image_finder(md_source_handler.find_source, buf, top, bot)
--     local existing_marks = ImageHandler:get_marks(buf, top, bot)
--     local placeholder_ids = {}
--     for i, source in pairs(image_sources) do
--         placeholder_ids[i] = ImageHandler:add_placeholder(source)
--     end
--     if existing_marks then
--         for _, mark in ipairs(existing_marks) do
--             local keep = false
--             for _, id in ipairs(placeholder_ids) do
--                 if mark[1] == id then keep = true end
--             end
--             if not keep then ImageHandler:remove_placeholder(buf, mark[1]) end
--         end
--     end
-- end

return source_handler
