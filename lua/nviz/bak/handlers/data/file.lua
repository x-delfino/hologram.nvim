local data_handler = require('nviz.handlers.data.core')
local utils = require('nviz.utils.utils')
local ffi = require('ffi')

local file_data_handler = data_handler:new{
    name = 'file',
    check_valid_data = function(path)
        local scheme = path:match('(.-):.-')
        if scheme == nil or scheme == 'file' then
            return true
        else
            return false
        end
    end,
    get_data = function(source, bytes)
        local fd = assert(vim.loop.fs_open(source, 'r', 438))
        local data = assert(vim.loop.fs_read(fd, bytes-1, 0))
        assert(vim.loop.fs_close(fd))
	return utils.string_to_bytes(data)
    end,
    init_data = function(source)
	-- get absolute path
        local first_path_char = string.sub(source, 0, 1)
        if not first_path_char == "/" then
            local folder_path = vim.fn.expand("%:p:h")
            source = folder_path .. "/" .. source
        end
        source = vim.loop.fs_realpath(source, nil)
	-- check readable
        local f=io.open(source,"r")
        if f~=nil then io.close(f) return true else return false end
    end
}

return file_data_handler
