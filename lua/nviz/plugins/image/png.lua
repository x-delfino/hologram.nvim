local image_processor = require('nviz.image')
local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')

local png_image_processor = image_processor:new{
    image_type = 'png',
    check_magic_bytes = function(bytes)
        return bytes[1]==137 and bytes[2]==80
            and bytes[3]==78 and bytes[4]==71
            and bytes[5]==13 and bytes[6]==10
            and bytes[7]==26 and bytes[8]==10
    end,
    get_dimensions = function(bytes)
        local dims = utils.get_chunked(bytes, 4, 16, 23)
        local width, height= utils.bytes2int(dims[1]), utils.bytes2int(dims[2])
        return width, height
    end
}

return png_image_processor
