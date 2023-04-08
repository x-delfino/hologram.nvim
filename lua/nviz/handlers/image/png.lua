local image_handler = require('nviz.handlers.image.core')
local utils = require('nviz.utils.utils')
local ffi = require('ffi')

local png_image_handler = image_handler:new{
    name = 'png',
    check_magic_bytes = function(bytes)
        return bytes[1]==137 and bytes[2]==80
            and bytes[3]==78 and bytes[4]==71
            and bytes[5]==13 and bytes[6]==10
            and bytes[7]==26 and bytes[8]==10
    end,
    get_dimensions = function(data)
        local dims = utils.get_chunked(data, 4, 16, 23)
    --    local width = utils.bytes2int(header+16)
    --    local height = utils.bytes2int(header+20)
        local width, height= utils.bytes2int(dims[1]), utils.bytes2int(dims[2])
        return width, height
    end
}


--local png = {}
--
--function png.check_path_PNG(path)
--    local fd = vim.loop.fs_open(path, 'r', 438)
--    if fd == nil then return end
--    local sig = ffi.new('const unsigned char[?]', 8,
--        assert(vim.loop.fs_read(fd, 7, 0)))
--    return png._check_sig_PNG(sig)
--end
--
--function png.check_data_PNG(data)
--    local sig = ffi.new('const unsigned char[?]', 8,
--        assert(string.sub(data, 1, 8)))
--    return png._check_sig_PNG(sig)
--end
--
--function png._check_sig_PNG(sig)
--    return sig[0]==137 and sig[1]==80
--        and sig[2]==78 and sig[3]==71
--        and sig[4]==13 and sig[5]==10
--        and sig[6]==26 and sig[7]==0
--end
--
--function png.data_get_dims_PNG(data)
--    local buf = ffi.new('const unsigned char[?]', 25,
--        assert(string.sub(data, 0, 24)))
--    return png._get_dims_PNG(buf)
--end
--
--function png.path_get_dims_PNG(path)
--    local fd = assert(vim.loop.fs_open(path, 'r', 438))
--    local buf = ffi.new('const unsigned char[?]', 25,
--        assert(vim.loop.fs_read(fd, 24, 0)))
--    assert(vim.loop.fs_close(fd))
--
--    return png._get_dims_PNG(buf)
--end
--
--function png._get_dims_PNG(header)
--    local width = png.bytes2int(header+16)
--    local height = png.bytes2int(header+20)
--    return width, height
--end


return png_image_handler
