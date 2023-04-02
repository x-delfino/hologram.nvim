local ffi = require('ffi')
local log = require('nviz.utils.log')
local fs = {}
CacheDir = vim.fn.stdpath('cache') .. '/nviz/'

function fs.init_tmp_dir()
    local cache_dir = vim.loop.fs_stat(CacheDir)
    if not cache_dir then
        vim.loop.fs_mkdir(CacheDir, 16832)
    end
end

function fs.write_tmp_file(template, data)
    local fd, fn = assert(vim.loop.fs_mkstemp(template))
    vim.loop.fs_write(fd, data)
    assert(vim.loop.fs_close(fd))
    return fn
end

function fs.get_dims_PNG(path)
    local fd = assert(vim.loop.fs_open(path, 'r', 438))
    local buf = ffi.new('const unsigned char[?]', 25,
        assert(vim.loop.fs_read(fd, 24, 0)))
    assert(vim.loop.fs_close(fd))

    local width = fs.bytes2int(buf+16)
    local height = fs.bytes2int(buf+20)
    return width, height
end

function fs.check_sig_PNG(path)
    local fd = vim.loop.fs_open(path, 'r', 438)
    if fd == nil then return end

    local sig = ffi.new('const unsigned char[?]', 9,
        assert(vim.loop.fs_read(fd, 8, 0)))

    return sig[0]==137 and sig[1]==80
        and sig[2]==78 and sig[3]==71
        and sig[4]==13 and sig[5]==10
        and sig[6]==26 and sig[7]==0
end

function fs.get_chunked(buf)
    local len = ffi.sizeof(buf)
    local i, j, chunks = 0, 0, {}
    while i < len-4096 do
        chunks[j] = ffi.string(buf+i, 4096)
        i, j = i+4096, j+1
    end
    chunks[j] = ffi.string(buf+i)
    return chunks
end

-- big endian
function fs.bytes2int(bufp)
    local bor, lsh = bit.bor, bit.lshift
    return bor(lsh(bufp[0],24), lsh(bufp[1],16), lsh(bufp[2],8), bufp[3])
end

function fs.get_absolute_path(path)
    if not fs._is_root_path(path) then
        local folder_path = vim.fn.expand("%:p:h")
	local eventual_path = folder_path .. "/" .. path
        path = vim.loop.fs_realpath(eventual_path, nil)
    end
    if fs._is_readable(path) then return path else return nil end
end

function fs._is_root_path(path)
    local first_path_char = string.sub(path, 0, 1)
    if first_path_char == "/" then
      return true
    else
      return false
    end
end

function fs._is_readable(path)
   local f=io.open(path,"r")
   if f~=nil then io.close(f) return true else return false end
end


return fs
