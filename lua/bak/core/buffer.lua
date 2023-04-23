local buffer_handler = {
    buf = nil,
    parsers = nil
}

function buffer_handler:new(b)
    setmetatable(b, self)
    self.__index = self
    b.parsers = {}
    return b
end

function buffer_handler:load_parser(parser)
    local match = false
    for _, p in pairs(self.parsers) do
	if p.name == parser.name then
	    match = true
	    break
        end
    end
    if match then return false else
	parser.buf = self.buf
	self.parsers[#self.parsers+1] = parser
	parser:init()
	return true
    end
end

return buffer_handler
