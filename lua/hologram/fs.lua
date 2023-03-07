local ffi = require('ffi')
local fs = {}
local http = require("socket.http")

function fs.data_get_dims_PNG(data)
    local buf = ffi.new('const unsigned char[?]', 25,
        assert(string.sub(data, 0, 24)))
    return fs._get_dims_PNG(buf)
end

function fs.path_get_dims_PNG(path)
    local fd = assert(vim.loop.fs_open(path, 'r', 438))
    local buf = ffi.new('const unsigned char[?]', 25,
        assert(vim.loop.fs_read(fd, 24, 0)))
    assert(vim.loop.fs_close(fd))

    return fs._get_dims_PNG(buff)
end

function fs._get_dims_PNG(header)
    local width = fs.bytes2int(header+16)
    local height = fs.bytes2int(header+20)
    return width, height
end

function fs._download_file(url)
    local body, code = http.request(url)
    if not body then error(code) end
    return body
end

function fs.get_image(source)
    if fs._is_url(source) then
        local image = fs._download_file(source)
	if fs._url_check_sig_PNG(image) then
	    return image
        end
    else
	local image = fs._get_absolute_path(source)
	if fs._file_check_sig_PNG(image) then
	    return image
        end
    end
end

function fs._is_url(path)
    local scheme = path:match('(.-):.-')
    if scheme == 'https' or scheme == 'http' then
	return true
    else
	return false
    end
end

function fs._url_check_sig_PNG(data)
    local sig = ffi.new('const unsigned char[?]', 8,
        assert(string.sub(data, 1, 8)))
    return fs._check_sig_PNG(sig)
end

function fs._check_sig_PNG(sig)
    return sig[0]==137 and sig[1]==80
        and sig[2]==78 and sig[3]==71
        and sig[4]==13 and sig[5]==10
        and sig[6]==26 and sig[7]==10
end

function fs._file_check_sig_PNG(path)
    local fd = vim.loop.fs_open(path, 'r', 438)
    if fd == nil then return end

    local sig = ffi.new('const unsigned char[?]', 8,
        assert(vim.loop.fs_read(fd, 7, 0)))

    return fs._check_sig_PNG(sig)
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

function fs._get_absolute_path(path)
    if fs._is_root_path(path) then
        return path
    else
        local folder_path = vim.fn.expand("%:p:h")
	local eventual_path = folder_path .. "/" .. path
        local absolute_path = vim.loop.fs_realpath(eventual_path, nil)
        return absolute_path
    end
end

function fs._is_root_path(path)
    local first_path_char = string.sub(path, 0, 1)
    if first_path_char == "/" then
      return true
    else
      return false
    end
end

return fs
