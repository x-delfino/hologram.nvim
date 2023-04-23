local command = {}
local log = require('nviz.utils.log')

function command.load_commands(core_handler)
    vim.api.nvim_create_user_command('NvizListConfig',
      function(opts)
        local setting = opts.fargs[1]
        core_handler:show_config(setting)
      end,
      { nargs='*' }
    )
    vim.api.nvim_create_user_command('NvizGatherSources',
      function(opts)
        local buf = tonumber(opts.fargs[1])
        local top = tonumber(opts.fargs[2])
        local bot = tonumber(opts.fargs[3])
        local parser_name = opts.fargs[4]
        local sources = core_handler:buf_gather_sources(buf, top, bot, parser_name)
        return sources ~= nil
      end,
      { nargs='*' }
    )
    vim.api.nvim_create_user_command('NvizListSources',
        function(opts)
	    local buf = tonumber(opts.args)
	    local sources = core_handler:buf_get_sources(buf)
	    local stripped_sources = {}
	    for _, source in pairs(sources) do
		stripped_sources[#stripped_sources+1] = {
		    id = source.id,
		    ["type"] = source.source_type,
		    source = source:get_img_source(),
		    caption = source:get_img_caption(),
		}
	    end
	    vim.print(stripped_sources)
        end,
	{ nargs=1 }
    )

    vim.api.nvim_create_user_command('NvizListHolders',
        function(opts)
	    local buf = tonumber(opts.fargs[1])
	    local holder_type = opts.fargs[2]

	    local holders = core_handler:list_holders(buf, holder_type)
	    local stripped_holders = {}
	    for _, holder in pairs(holders) do
		    log.debug(holder)
		stripped_holders[#stripped_holders+1] = {
		    id = holder.id,
		    ["type"] = holder.holder_type,
		    source_id = holder.source.id,
		    win_displays = holder.wins
		}
	    end
	    vim.print(stripped_holders)
        end,
	{ nargs='+' }
    )

    vim.api.nvim_create_user_command('NvizAddHolderForSource',
        function(opts)
	    local buf = tonumber(opts.fargs[1])
	    local source_id = tonumber(opts.fargs[2])
	    local holder_type = opts.fargs[3]
	    local row = tonumber(opts.fargs[4])
	    local col = tonumber(opts.fargs[5])

	    local holder = core_handler:add_holder_for_source(
	        buf, source_id, holder_type, row, col
	    )
	    vim.print(holder.id)
        end,
	{ nargs='+' }
    )

    vim.api.nvim_create_user_command('NvizAddWinHolder',
        function(opts)
	    local buf = tonumber(opts.fargs[1])
	    local holder_id = tonumber(opts.fargs[3])
	    local win = tonumber(opts.fargs[2])

	    local win_holder = core_handler:add_win_holder(
	        buf, win, holder_id
	    )
	    vim.print(win_holder.id)
        end,
	{ nargs='+' }
    )

    vim.api.nvim_create_user_command('NvizShowHolder',
        function(opts)
	    local buf = tonumber(opts.fargs[1])
	    local holder_id = tonumber(opts.fargs[2])
	    local win = tonumber(opts.fargs[3])

	    vim.print(core_handler:show_holder_in_win(
	        buf, holder_id, win
	    ))
        end,
	{ nargs='+' }
    )
    vim.api.nvim_create_user_command('NvizHideHolder',
        function(opts)
	    local buf = tonumber(opts.fargs[1])
	    local holder_id = tonumber(opts.fargs[2])
	    local win = tonumber(opts.fargs[3])

	    vim.print(core_handler:hide_holder_in_win(
	        buf, holder_id, win
	    ))
        end,
	{ nargs='+' }
    )

    vim.api.nvim_create_user_command('NvizListWinHolders',
        function(opts)
	    local buf = tonumber(opts.fargs[1])
	    local holder_id = tonumber(opts.fargs[2])

	    local win_holders = core_handler:list_win_holders_by_holder_id(buf, holder_id)
	    local stripped_holders = {}
	    for _, holder in pairs(win_holders) do
		stripped_holders[#stripped_holders+1] = {
		    id = holder.id,
		    placement_id = holder.placement_id,
		    is_visible = holder.is_visible,
		    display_win = holder.display_win,
		}
	    end
	    vim.print(stripped_holders)
        end,
	{ nargs='+' }
    )

    vim.api.nvim_create_user_command('NvizRenderImages',
        function(opts)
	    local win = tonumber(opts.fargs[1])

	    core_handler:render_images(win)
        end,
	{ nargs='?' }
    )
--    vim.api.nvim_create_user_command('NvizBufAddHolder',
--        function(opts)
--            local buf = opts.fargs[1] and tonumber(opts.fargs[1])
--            local parser_name = opts.fargs[2]
--            local source_id = opts.fargs[3] and tonumber(opts.fargs[3])
--            local holder_type = opts.fargs[4]
--            local row = opts.fargs[5] and tonumber(opts.fargs[5])
--            local col = opts.fargs[6] and tonumber(opts.fargs[6])
--            local holder = core_handler:buf_add_holder_for_source_by_id(
--    	    buf, parser_name, source_id, holder_type, row, col
--    	)
--    	print(holder and holder.id)
--        end,
--        { nargs='*' }
--    )
--    
--    vim.api.nvim_create_user_command('NvizWinShowHolder',
--        function(opts)
--            local win = opts.fargs[1] and tonumber(opts.fargs[1])
--            local holder_type = opts.fargs[2]
--            local holder_id = opts.fargs[3] and tonumber(opts.fargs[3])
--    
--    	local status = core_handler:win_show_holder_by_id(
--    	   win, holder_type, holder_id
--    	)
--    	print(status)
--        end,
--        { nargs='*' }
--    )
--    
--    vim.api.nvim_create_user_command('NvizWinRenderImages',
--        function(opts)
--            local win = (opts.fargs[1] and tonumber(opts.fargs[1])) or 0
--            local top = (opts.fargs[2] and tonumber(opts.fargs[2])) or 0
--            local bot = (opts.fargs[3] and tonumber(opts.fargs[3])) or -1
--    
--    	local status = core_handler:win_render_images(
--    	   win, top, bot
--    	)
--    	print(status)
--        end,
--        { nargs='*' }
--    )
--    
--    vim.api.nvim_create_user_command('NvizWinHideHolder',
--        function(opts)
--            local win = opts.fargs[1] and tonumber(opts.fargs[1])
--            local holder_type = opts.fargs[2]
--            local holder_id = opts.fargs[3] and tonumber(opts.fargs[3])
--    
--    	local status = core_handler:win_hide_holder_by_id(
--    	   win, holder_type, holder_id
--    	)
--    	print(status)
--        end,
--        { nargs='*' }
--    )
end

return command
