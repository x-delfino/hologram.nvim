local ffi = require('ffi')
local png = {}

function png.check_path_PNG(path)
    local fd = vim.loop.fs_open(path, 'r', 438)
    if fd == nil then return end
    local sig = ffi.new('const unsigned char[?]', 8,
        assert(vim.loop.fs_read(fd, 7, 0)))
    return png._check_sig_PNG(sig)
end

function png.check_data_PNG(data)
    local sig = ffi.new('const unsigned char[?]', 8,
        assert(string.sub(data, 1, 8)))
    return png._check_sig_PNG(sig)
end

function png._check_sig_PNG(sig)
    return sig[0]==137 and sig[1]==80
        and sig[2]==78 and sig[3]==71
        and sig[4]==13 and sig[5]==10
        and sig[6]==26 and sig[7]==0
end

function png.data_get_dims_PNG(data)
    local buf = ffi.new('const unsigned char[?]', 25,
        assert(string.sub(data, 0, 24)))
    return png._get_dims_PNG(buf)
end

function png.path_get_dims_PNG(path)
    local fd = assert(vim.loop.fs_open(path, 'r', 438))
    local buf = ffi.new('const unsigned char[?]', 25,
        assert(vim.loop.fs_read(fd, 24, 0)))
    assert(vim.loop.fs_close(fd))

    return png._get_dims_PNG(buf)
end

function png._get_dims_PNG(header)
    local width = png.bytes2int(header+16)
    local height = png.bytes2int(header+20)
    return width, height
end

-- big endian
function png.bytes2int(bufp)
    local bor, lsh = bit.bor, bit.lshift
    return bor(lsh(bufp[0],24), lsh(bufp[1],16), lsh(bufp[2],8), bufp[3])
end

return png
