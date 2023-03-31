local terminal = require('hologram.terminal')
local png = require('hologram.png')
local state = require('hologram.state')
local transmit_keys, _, _ = require('hologram.control') ()



--function transmit_keys:new(k)
--    setmetatable(k, self)
--    self.__index = self
--    return k
--end

-- IMAGE
local image = {
    source = nil,
    transmit_keys = nil,
    cols = nil,
    rows = nil,
    next_placement_id = 1
}

function image:new (i)
  setmetatable(i, self)
  self.__index = self
  return i
end

function image:get_placement_id()
    local placement_id = self.next_placement_id
    self.next_placement_id = placement_id + 1
    return placement_id
end

function image:load(source, keys)
    keys = keys or {}
    keys = transmit_keys:new(keys)
    -- need some logic for determining url vs path
    keys.transmission_type = 'f'
    assert(type(source) == 'string', 'Image source is not a valid string')
    local img = image:new{source = source}
    if keys.data_width == nil and keys.data_height == nil then
        if source:sub(-4) == '.png' and keys.transmission_type == 'f' then
            keys.data_width, keys.data_height = png.path_get_dims_PNG(source)
	elseif keys.transmission_type == 'd' then
	    keys.data_width, keys.data_height = png.data_get_dims_PNG(source)
        end
    end
    img.cols = math.ceil(keys.data_width/state.cell_size.x)
    img.rows = math.ceil(keys.data_height/state.cell_size.y)
    img.transmit_keys = keys
    img:transmit()

    return img
end

function image:transmit()
    local test = terminal.send_graphics_command(self.transmit_keys, self.source, true)
end



-- IMAGE STORE
local image_store = {
    images = {},
    next_id = 1
}

function image_store:new (s)
  setmetatable(s, self)
  self.__index = self
  return s
end

function image_store:load(source, keys)
    keys = keys or {}
    keys['image_id'] = self.next_id
    self.next_id = self.next_id + 1
    self.images[keys.image_id] = image:load(source, keys)
    return keys.image_id
end

return image_store
