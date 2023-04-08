local data_handler = {
    name = nil,
    check_valid_data = nil,
    get_data = nil,
    init_data = nil
}

function data_handler:new(d)
  setmetatable(d, self)
  self.__index = self
  return d
end

function data_handler:is_supported(data)
    return self.check_valid_data(data)
end

return data_handler
