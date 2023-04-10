local state = require('nviz.utils.state')
local log = require('nviz.utils.log')

-- IMAGE_HANDLER

local image_handler = {
    image_processors = nil,
    data_processors = nil,
    terminal_handler = nil,
    images = nil,
    next_image_id = nil
}

function image_handler:new (x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.next_image_id = 1
  x.image_processors = {}
  x.data_processors = {}
  x.images = {}
  return x
end

function image_handler:get_image_id()
    local image_id = self.next_image_id
    self.next_image_id = image_id + 1
    return image_id
end

function image_handler:get_supported_data_processor(data)
    for _, handler in pairs(self.data_processors) do
        if handler:is_supported(data) then
	    return handler
        end
    end
end

function image_handler:get_supported_image_processor(image)
    for _, handler in pairs(self.image_processors) do
        if handler:is_supported(image) then
	    return handler
        end
    end
end

local image = {
    id = nil,
    img_source = nil,
    height = nil,
    width = nil,
    next_placement_id = nil,
    is_loaded = nil
}

function image_handler:add_image_from_source(source)
    local img_source = source:get_img_source()
    local data_processor = self:get_supported_data_processor(img_source)
    if data_processor then
        img_source = data_processor.normalize_source(img_source)

        -- check if already added
        for img_id, img in pairs(self.images) do
            if img.img_source == img_source then
                source.image = img
                return img_id
            end
        end

        -- if not, then add
        local img_id = self:get_image_id()
        local img = image:new{
            img_source = img_source,
	    id = img_id
        }
        data_processor:init_image(img)
        local image_processor = self:get_supported_image_processor(img)
	if image_processor then
            image_processor:init_image(img)
            self.terminal_handler:load_image(img)
            self.images[img_id] = img
            source.image = img
        end
    end
end


function image:get_rows_cols()
    state.update_cell_size()
    local rows, cols = math.ceil(self.width/state.cell_size.y), math.ceil(self.height/state.cell_size.x)
    return rows, cols
end

function image:new (i)
  i = i or {}
  setmetatable(i, self)
  self.__index = self
  return i
end

function image:get_placement_id()
    local placement_id = self.next_placement_id
    self.next_placement_id = placement_id + 1
    return placement_id
end

return image_handler
