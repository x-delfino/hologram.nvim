local image_processor = {
    name = nil,
    check_magic_bytes = nil,
    get_dimensions = nil,
}

function image_processor:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  return x
end

function image_processor:is_supported(img)
    local signature = img:get_data(9)
    return self.check_magic_bytes(signature)
end

function image_processor:init_image(img)
    local header = img:get_data(25)
    img.width, img.height = self.get_dimensions(header)
end

return image_processor
