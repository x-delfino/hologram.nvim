local state = require('nviz.utils.state')

local image_handler = {
    name = nil,
    check_magic_bytes = nil,
    get_dimensions = nil,
    images = {}
}

SourceType = {FILE = 1, URL = 2, BASE64 = 3, BYTES = 4}

function image_handler:new(i)
  setmetatable(i, self)
  self.__index = self
  return i
end

local image = {
    image_id = nil,
    data_type = nil,
    data = nil,
    --tmp_file = nil,
    height = nil,
    width = nil,
}

function image:new (i)
  setmetatable(i, self)
  self.__index = self
  i.image_id = CoreHandler:get_image_id()
  return i
end


function image:get_rows_cols()
    state.update_cell_size()
    local rows, cols = math.ceil(self.width/state.cell_size.y), math.ceil(self.height/state.cell_size.x)
    return rows, cols
end

function image_handler:load_image(terminal, data_handler, data, opts)
    local header = data_handler.get_data(data, 25)
    local width, height = self.get_dimensions(header)
    local img = image:new{
	data = data,
	width = width,
	height = height,
	data_type = data_handler.name
    }
    self.images[#self.images+1] = img
    terminal:load_image(img, opts)
    return img.image_id
end

function image_handler:is_supported(data, data_handler)
    local signature = data_handler.get_data(data, 9)
    return self.check_magic_bytes(signature)
end

-- function image_handler:update_dimensions(id)
--     local type_method = {
-- 	[SourceType.FILE] = function()
--             local fd = assert(vim.loop.fs_open(self.source, 'r', 438))
--             local data = ffi.new('const unsigned char[?]', 25,
--             assert(vim.loop.fs_read(fd, 24, 0)))
--             assert(vim.loop.fs_close(fd))
-- 	    return data
--         end,
-- 	[SourceType.URL] = function()
-- 	    if not self.tmp_file then
--                 self.tmp_file = remote.download_file(self.source)
-- 	    end
--             local fd = assert(vim.loop.fs_open(self.tmp_file, 'r', 438))
--             local data = ffi.new('const unsigned char[?]', 25,
--             assert(vim.loop.fs_read(fd, 24, 0)))
--             assert(vim.loop.fs_close(fd))
-- 	    return data
-- 	end,
--     }
--     local data = type_method[self.images[id].source_type]()
--     self.images[id].width, self.images[id].height = self.get_dimensions(data)
-- end


return image_handler
