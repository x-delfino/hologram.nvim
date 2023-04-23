local settings = require('nviz.utils.settings')
local command = require('nviz.command')
local log = require('nviz.utils.log')

local core_handler = require('nviz.core')

Settings = settings

local nviz = {}


function nviz.setup(config)
    for _, plugin in ipairs(config.plugins['holders']) do
	core_handler:load_holder_type(require(plugin))
    end
    for _, plugin in ipairs(config.plugins['image']) do
	core_handler:load_image_type(require(plugin))
    end
    for _, plugin in ipairs(config.plugins['data']) do
	core_handler:load_data_type(require(plugin))
    end
    for _, plugin in ipairs(config.plugins['parsers']) do
	core_handler:load_parser(require(plugin))
    end
    core_handler:load_terminal_handler(require(config.plugins.terminal))
    core_handler:load_config(config)

    vim.g.nviz_ns = vim.api.nvim_create_namespace('nviz')
    vim.g.nviz_img_ns = vim.api.nvim_create_namespace('nviz_img')
    vim.g.nviz_src_ns = vim.api.nvim_create_namespace('nviz_src')
    vim.g.nviz_inline_ns = vim.api.nvim_create_namespace('nviz_inline')
    command.load_commands(core_handler)
    vim.api.nvim_create_autocmd({'BufRead'}, {
	callback = function(event)
            core_handler:add_buffer(event.buf)
	    core_handler:buf_gather_sources(event.buf)
        end,
    })
    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
	callback = function()
	   -- log.debug('running render')
		core_handler:render_images()
        end
    })
    vim.api.nvim_create_autocmd({'WinClosed','WinLeave'}, {
	callback = function(ev)
	--	log.debug(ev)
	--	log.debug('running this!')
	    core_handler:render_images()
	end
    })

    vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
	callback = function(ev)
	    core_handler:buf_gather_sources(ev.buf, 1, -1)
        end
    })
end

return nviz
