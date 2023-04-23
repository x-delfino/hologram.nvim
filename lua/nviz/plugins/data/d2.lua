local core_data_processor = require('nviz.data')
local job = require('plenary.job')
local fs = require("nviz.utils.fs")
local log = require'nviz.utils.log'
local file_data_processor = require('nviz.plugins.data.file')

local d2_data_processor = core_data_processor:new{
    data_type = 'd2',
    check_valid_data = function(source)
	return source.source_type == 'd2'
    end,
    check_client_support = function(self)
	local handle = io.popen(self.config.cmd_path .. " --version")
	if handle then
            local result = handle:read("*a")
            handle:close()
	    if result ~= '' then return true end
        end
	return false
    end,
    normalize_source = function(source)
	return source:get_img_source()
    end,
    init_data = function(source)
--	local d2_source = vim.split(source:get_img_source(), "\n")
	local d2_source = source:get_img_source()
        local cache_path = fs.get_tmp_file('/file_XXXXXX') .. '.png'
	log.debug(d2_source)
	job:new({
--	    command = 'xargs',
--	    args = {'printf'},
	    command = '/opt/homebrew/bin/d2',
	    args = {
		'--theme', '200',
		'-',
		cache_path
	    },
	    writer = d2_source,
	    on_exit = function(j, return_val)
                log.debug(return_val)
                log.debug(j:result())
	    end
	}):sync()
	source.cache_source = cache_path
	return file_data_processor.init_data(source)
    end,
    get_data = function(img, bytes)
	return file_data_processor.get_data(img, bytes)
    end,
    config = {
	cmd_path = 'd2'
    }
}

return d2_data_processor
