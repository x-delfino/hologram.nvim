local core_data_processor = require('nviz.data.core')
local file_data_processor = require('nviz.data.file')
local fs = require("nviz.utils.fs")
local http = require("socket.http")

local http_data_processor = core_data_processor:new{
    name = 'url',
    check_valid_data = function(path)
        local scheme = path:match('(.-):.-')
        if scheme == 'https' or scheme == 'http' then
            return true
        else
            return false
        end
    end,
    init_data = function(img)
        fs.init_tmp_dir()
        local body, code = http.request(img.img_source)
        if not body then error(code) end
        img.cache_path = fs.write_tmp_file(Settings.cache_dir .. '/file_XXXXXX', body)
	return file_data_processor.init_data(img.cache_path)
    end,
    get_data = function(img, bytes)
	return file_data_processor.get_data(img.cache_path, bytes)
    end
}

return http_data_processor
