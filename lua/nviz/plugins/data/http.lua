local core_data_processor = require('nviz.data')
local log = require'nviz.utils.log'
local file_data_processor = require('nviz.plugins.data.file')
local fs = require("nviz.utils.fs")
local http = require("socket.http")

local http_data_processor = core_data_processor:new{
    data_type = 'url',
    check_client_support = function() return true end,
    check_valid_data = function(source)
        local path = source:get_img_source()
        local scheme = path:match('(.-):.-')
        if scheme == 'https' or scheme == 'http' then
            return true
        else
            return false
        end
    end,
    normalize_source = function(source)
	return source:get_img_source()
    end,
    init_data = function(source)
	local path = source:get_img_source()
        local body, code = http.request(path)
        if not body then error(code) end
        source.cache_source = fs.write_tmp_file('/file_XXXXXX', body)
	return file_data_processor.init_data(source)
    end,
    get_data = function(img, bytes)
	return file_data_processor.get_data(img, bytes)
    end
}

return http_data_processor
