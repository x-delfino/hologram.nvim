local ffi = require('ffi')
local log = require('nviz.utils.log')
local fs = {}

function fs.init_tmp_dir()
    local cache_dir = vim.loop.fs_stat(vim.g.nviz_cache_dir)
    if not cache_dir then
        vim.loop.fs_mkdir(vim.g.nviz_cache_dir, 16832)
    end
    return vim.g.nviz_cache_dir
end

function fs.rm_tmp_dir()
    fs.rm_dir(Settings.cache_dir)
end

function fs.rm_dir(path)
    local dir_contents = vim.loop.fs_scandir(path)
    if dir_contents then repeat
        local item_path, item_type = vim.loop.fs_scandir_next(dir_contents)
	if item_path then
            log.debug(item_path, item_type)
	    local item_fullpath = fs.get_absolute_path(path .. '' .. item_path)
            if item_type == 'file' then
    	        vim.loop.fs_unlink(item_fullpath)
            elseif item_type == 'directory' then
    	        fs.rm_dir(item_fullpath)
		vim.loop.fs_rmdir(item_fullpath)
            end
        end
    until not item_path end
end

function fs.write_tmp_file(template, data)
    local tmp_file = fs.get_tmp_file(template)
    local fd = assert(vim.loop.fs_open(tmp_file, "w", 438))
    vim.loop.fs_write(fd, data)
    assert(vim.loop.fs_close(fd))
    return tmp_file
end

function fs.get_tmp_file(template)
    local cache_dir = fs.init_tmp_dir()
    local fd, fn = assert(vim.loop.fs_mkstemp(cache_dir .. template))
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
