local log = require('nviz.utils.log')

local CTRL_KEYS = {
    general = {
        action = 'a',
        quiet = 'q',
    },

    transmission = {
        format = 'f',
        transmission_type = 't',
        data_width = 's',
        data_height = 'v',
        data_size = 'S',
        data_offset = 'O',
        image_id = 'i',
        image_number = 'I',
        compressed = 'o',
        more = 'm',
    },

    display = {
        placement_id = 'p',
        x_offset = 'x',
        y_offset = 'y',
        image_id = 'i',
        width = 'w',
        height = 'h',
        cell_x_offset = 'X',
        cell_y_offset = 'Y',
        cols = 'c',
        rows = 'r',
        cursor_movement = 'C',
        z_index = 'z',
    },

    delete = {
        delete_action = 'd',
        placement_id = 'p',
        image_id = 'i',
    }

    -- TODO: Animation
}

local command_keys = {
}

function command_keys:new(k)
    setmetatable(k, self)
    self.__index = self
    return k
end

function command_keys:serialize()
    local serialized = ''
    for _, schema in pairs({ CTRL_KEYS.general, self.schema}) do
	    log.debug(self)
        for k, v in pairs(schema) do
            if self[k] ~= nil then
                serialized = serialized..v..'='..self[k]..','
            end
        end
    end
    serialized = serialized:sub(0, -2) -- chop trailing comma
    return serialized
end

local transmit_keys = command_keys:new{
    schema = CTRL_KEYS.transmission,
    action = 't',
    format = 100,
    quiet = 2,
    transmission_type = 'f',
    data_width = nil,
    data_height = nil,
    data_size = nil,
    data_offset = nil,
    image_id = nil,
    image_number = nil,
    compressed = nil
}

local display_keys = command_keys:new{
    schema = CTRL_KEYS.display,
    action = 'p',
    quiet = 1,
    placement_id = nil,
    image_id = nil,
    x_offset = nil,
    y_offset = nil,
    width = nil,
    height = nil,
    cell_x_offset = nil,
    cell_y_offset = nil,
    cols = nil,
    rows = nil,
    cursor_movement = 1,
    z_index = 0
}

local delete_keys = command_keys:new{
    schema = CTRL_KEYS.delete,
    action = 'd',
    quiet = 2,
    placement_id = nil,
    image_id = nil,
    image_number = nil,
    delete_action = nil,
    x_offset = nil,
    y_offset = nil,
    z_index = 0
}

return function() return transmit_keys, display_keys, delete_keys end
