local data_handler = require('nviz.handlers.data.core')
local file_data_handler = require('nviz.handlers.data.file')
local fs = require("nviz.utils.fs")
local http = require("socket.http")

local http_data_handler = data_handler:new{
    name = 'url',
    check_valid_data = function(path)
        local scheme = path:match('(.-):.-')
        if scheme == 'https' or scheme == 'http' then
            return true
        else
            return false
        end
    end,
    init_data = function(path)
        fs.init_tmp_dir()
        local body, code = http.request(path)
        if not body then error(code) end
        path = fs.write_tmp_file(Settings.cache_dir .. '/file_XXXXXX', body)
	return file_data_handler.init_data(path)
    end,
    get_data = function(source, bytes)
	return file_data_handler.get_data(source, bytes)
    end
}

return http_data_handler
