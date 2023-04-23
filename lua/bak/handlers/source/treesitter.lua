local parser = {
    buf = nil,
    name = nil,
    lang = nil,
    parser = nil,
    gathered = nil,
    gather = nil,
    update = nil
}

function parser:new(p)
  setmetatable(p, self)
  self.__index = self
  return p
end

return parser
