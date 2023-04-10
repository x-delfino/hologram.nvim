local log = require('nviz.utils.log')

local default_settings = {
    general = {
	cache_dir = vim.fn.stdpath('cache') .. '/nviz/',
	log_dir = ''
    },
    holder = {
        inline = {
	    enabled = true,
	    anchor = 'source',
	    padding = {0,0,0,0},
	    visible_on = 'win',
	    sign_text = true,
	    sign_text_displayed = '\xe2\x97\x89',
	    sign_text_hidden = '-',
	},
	float = {
	    enabled = true,
	    anchor = 'cursor',
	    visible_on = 'hover',
	    padding = {0,0,0,0}
	},
    },
    parser = {
        markdown = {
	    enabled = true
        }
    },
    terminal = {
	kitty = {
	    enabled = true
	}
    },
    source = {},
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
