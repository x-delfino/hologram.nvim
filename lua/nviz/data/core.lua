local data_processor = {
    name = nil,
    check_valid_data = nil,
    get_data = nil,
    init_data = nil,
    normalize_source = nil
}

function data_processor:new(d)
  setmetatable(d, self)
  self.__index = self
  return d
end

function data_processor:is_supported(data)
    return self.check_valid_data(data)
end

function data_processor:init_image(img)
    self.init_data(img)
    img.get_data = self.get_data
end

return data_processor
