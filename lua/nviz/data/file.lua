local utils = require('nviz.utils.utils')
local core_data_processor = require('nviz.data.core')

local file_data_processor = core_data_processor:new{
    name = 'file',
    check_valid_data = function(path)
        local scheme = path:match('(.-):.-')
        if scheme == nil or scheme == 'file' then
            return true
        else
            return false
        end
    end,
    normalize_source = function(path)
	-- get absolute path
        local first_path_char = string.sub(path, 0, 1)
        if not first_path_char == "/" then
            local folder_path = vim.fn.expand("%:p:h")
            path = folder_path .. "/" .. path
        end
        path = vim.loop.fs_realpath(path, nil)
	return path
    end,
    init_data = function(img)
	-- check readable
        local f=io.open(img.img_source,"r")
        if f~=nil then io.close(f) return true else return false end
    end,
    get_data = function(img, bytes)
        local fd = assert(vim.loop.fs_open(img.img_source, 'r', 438))
        local data = assert(vim.loop.fs_read(fd, bytes-1, 0))
        assert(vim.loop.fs_close(fd))
	return utils.string_to_bytes(data)
    end,
}

return file_data_processor
