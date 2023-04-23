local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
local core_data_processor = require('nviz.data')

local file_data_processor = core_data_processor:new{
    data_type = 'file',
    check_client_support = function() return true end,
    check_valid_data = function(source)
	--FIX THIS
	if source.source_type == 'markdown' then
            local path = source:get_img_source()
            local scheme = path:match('(.-):.-')
            if scheme == nil or scheme == 'file' then
	        return true
            end
        end
        return false
    end,
    normalize_source = function(source)
	local path = source:get_img_source()
	-- get absolute path
        local first_path_char = string.sub(path, 0, 1)
        if not first_path_char == "/" then
            local folder_path = vim.fn.expand("%:p:h")
            path = folder_path .. "/" .. path
        end
        path = vim.loop.fs_realpath(path, nil)
	return path
    end,
    init_data = function(source)
	-- check readable
	local path = source.cache_source or source:get_img_source()
        local f=io.open(path,"r")
        if f~=nil then io.close(f) return true else return error('invalid data') end
    end,
    get_data = function(img, bytes)
	local path = img.cache_source or img.img_source
        local fd = assert(vim.loop.fs_open(path, 'r', 438))
        local data = assert(vim.loop.fs_read(fd, bytes-1, 0))
        assert(vim.loop.fs_close(fd))
	return utils.string_to_bytes(data)
    end,
}

return file_data_processor
