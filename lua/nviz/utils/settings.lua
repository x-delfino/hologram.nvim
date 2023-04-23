local log = require('nviz.utils.log')

local default_settings = {
    plugins = {
	holders = {},
	terminal = '',
	data = {},
	image = {},
	parsers = {}
    },
    general = {
	cache_dir = vim.fn.stdpath('cache') .. '/nviz/',
	log_dir = ''
    },
    defaults = {
	holder = {
	    enabled = true,
	    pad = {0,0,0,0},
	    y_offset = 0,
	    x_offset = 0,
	    visible_on = 'cursor'
        }
    },
    holder = {},
    source = {
        markdown = {
	    enabled = true
        }
    },
    terminal = {
	kitty = {
	    enabled = true
	}
    },
}

local settings = {}

function settings:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x = vim.tbl_deep_extend('keep', x, default_settings)
  return x
end

return settings
