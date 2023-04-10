local settings = require('nviz.utils.settings2')
--local state = require('nviz.utils.state')
--local image_store = require('nviz.core.image')
--local image_handler = require('nviz.core.image_handler')
--local fs = require('nviz.utils.fs')
local log = require('nviz.utils.log')
--local remote = require('nviz.utils.remote')
--local png = require('nviz.handlers.image.png')
--local core_handler = require('nviz.handlers.core')
--local markdown_parser = require('nviz.handlers.parsers.markdown')
--local md_source_handler = require('nviz.handlers.source.markdown')
--local ts_md_source_handler = require('nviz.handlers.source.markdown-ts')
---- local d2_source_handler = require('nviz.handlers.source.d2')
--local inline_holder_handler = require('nviz.handlers.holder.inline')
--local float_holder_handler = require('nviz.handlers.holder.float')
--local png_image_handler = require('nviz.handlers.image.png')
--local http_data_handler = require('nviz.handlers.data.http')
--local file_data_handler = require('nviz.handlers.data.file')
--local kitty_terminal_handler = require('nviz.handlers.terminal.kitty')

--local buffer_handler = require('nviz.core.buffer')
local markdown_parser = require('nviz.parser.markdown')
local float_holder = require('nviz.holder.float')
local inline_holder = require('nviz.holder.inline')
local file_data_processor = require('nviz.data.file')
local png_image_processor = require('nviz.image.png')
local kitty_terminal_handler = require('nviz.terminal.kitty')


local core_handler = require('nviz.core.core')


--ImageHandler = image_handler:new{}
--ImageStore = image_store:new{}
--CoreHandler = core_handler:new{}

-- vim.api.nvim_set_keymap('n', '<Esc>_G', 'i', {} )
Settings = settings

local nviz = {}

vim.api.nvim_create_user_command('NvizConfigSet',
  function(opts)
    local setting = opts.fargs[1]
    local value = opts.fargs[2]
    local sources = core_handler:buf_gather_sources(buf, top, bot, parser_name)
    return sources ~= nil
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('NvizConfigShow',
  function(opts)
    local setting = opts.fargs[1]
    core_handler:show_config(setting)
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('NvizBufGatherSources',
  function(opts)
    local buf = opts.fargs[1]
    local top = opts.fargs[2]
    local bot = opts.fargs[3]
    local parser_name = opts.fargs[4]
    local sources = core_handler:buf_gather_sources(buf, top, bot, parser_name)
    return sources ~= nil
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('NvizBufAddHolder',
    function(opts)
        local buf = opts.fargs[1] and tonumber(opts.fargs[1])
        local parser_name = opts.fargs[2]
        local source_id = opts.fargs[3] and tonumber(opts.fargs[3])
        local holder_type = opts.fargs[4]
        local row = opts.fargs[5] and tonumber(opts.fargs[5])
        local col = opts.fargs[6] and tonumber(opts.fargs[6])

	local holder = core_handler:buf_add_holder_for_source_by_id(
	    buf, parser_name, source_id, holder_type, row, col
	)
	print(holder and holder.id)
    end,
    { nargs='*' }
)

vim.api.nvim_create_user_command('NvizWinShowHolder',
    function(opts)
        local win = opts.fargs[1] and tonumber(opts.fargs[1])
        local holder_type = opts.fargs[2]
        local holder_id = opts.fargs[3] and tonumber(opts.fargs[3])

	local status = core_handler:win_show_holder_by_id(
	   win, holder_type, holder_id
	)
	print(status)
    end,
    { nargs='*' }
)

vim.api.nvim_create_user_command('NvizWinRenderImages',
    function(opts)
        local win = (opts.fargs[1] and tonumber(opts.fargs[1])) or 0
        local top = (opts.fargs[2] and tonumber(opts.fargs[2])) or 0
        local bot = (opts.fargs[3] and tonumber(opts.fargs[3])) or -1

	local status = core_handler:win_render_images(
	   win, top, bot
	)
	print(status)
    end,
    { nargs='*' }
)

vim.api.nvim_create_user_command('NvizWinHideHolder',
    function(opts)
        local win = opts.fargs[1] and tonumber(opts.fargs[1])
        local holder_type = opts.fargs[2]
        local holder_id = opts.fargs[3] and tonumber(opts.fargs[3])

	local status = core_handler:win_hide_holder_by_id(
	   win, holder_type, holder_id
	)
	print(status)
    end,
    { nargs='*' }
)

function nviz.setup(config)
    core_handler:load_config(config)
    vim.g.nviz_ns = vim.api.nvim_create_namespace('nviz')
    vim.g.nviz_img_ns = vim.api.nvim_create_namespace('nviz_img')
    core_handler:load_data_processor(file_data_processor)
    core_handler:load_image_processor(png_image_processor)
    core_handler:load_terminal_handler(kitty_terminal_handler)
    log.debug(core_handler.image_handler.terminal_handler)
    vim.api.nvim_create_autocmd({'BufRead'}, {
	callback = function(event)
	    core_handler:load_buf(event.buf)
	    core_handler:buf_load_parser(event.buf, markdown_parser)
	    core_handler:buf_load_holder_type(event.buf, float_holder)
	    core_handler:buf_load_holder_type(event.buf, inline_holder)
--	    for _, source in pairs(sources) do
--		local holder = core_handler:buf_add_holder_for_source(event.buf, source, 'inline')
--		core_handler:win_show_holder(1000, holder)
--		core_handler:win_hide_holder(1000, holder)

--	    end
--	    log.debug(core_handler.image_handler)
--	    log.debug(core_handler.buffers[1].holder_handler)
--	    log.debug(core_handler.buffers[1].parsers['markdown'].gathered[2])
--	    self:buf_load_parser(event.buf, markdown_parser)
--	    self.buffers[1].parsers[1]:gather_sources(1, -1)
--	    local source = self.buffers[1].parsers[1]:get_image_source_by_id(1)
--	    local caption = self.buffers[1].parsers[1]:get_image_caption_by_id(1)
--	    log.debug({source, caption})
        end,
    })
--    CoreHandler:add_terminal_handler(kitty_terminal_handler)
--    CoreHandler:add_image_handler(png_image_handler)
--    CoreHandler:add_data_handler(file_data_handler)
--    CoreHandler:add_data_handler(http_data_handler)

--    state.update_cell_size()
--    vim.api.nvim_create_autocmd({'BufRead'}, {
--	callback = function(ev)
--            ts_md_source_handler.init()
--	    CoreHandler:add_buffer_handler(ev.buf)
--            CoreHandler:add_source_handler(ev.buf, md_source_handler)
--            CoreHandler:add_source_handler(ev.buf, d2_source_handler)
--	    CoreHandler:add_holder_handler(ev.buf, inline_holder_handler)
--	    CoreHandler:add_holder_handler(ev.buf, float_holder_handler)
--	    CoreHandler:gather_and_load_sources(ev.buf, 0, -1)
--	    CoreHandler:gather_and_load_sources(ev.buf, 0, -1)
--	    local buffer_handler = CoreHandler.buffer_handlers[ev.buf]
--	    if buffer_handler:gather_sources(0, -1) then
--	    end
--        end
--    })
--    local stored_source = nil
--    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorHoldI'}, {
--	callback = function(ev)
--            local win = vim.api.nvim_tabpage_get_win(0)
--	    local cursor = vim.api.nvim_win_get_cursor(win)
--	    local buffer_handler = CoreHandler.buffer_handlers[ev.buf]
----	    CoreHandler:win_hide_handler_holders(win, 'float')
--	    local matched_source = buffer_handler:find_source_block_match({
--		    start_row=cursor[1],
--		    start_col=cursor[2],
--	    })
--
--	    if matched_source ~= stored_source and stored_source ~= nil then
--	        local holder = buffer_handler:get_holder_by_source_id(stored_source.source_id)
--    	        CoreHandler:win_hide_holder_by_id(win, holder.holder_id)
--	    end
--
--	    if matched_source then
--	        local holder = buffer_handler:get_holder_by_source_id(matched_source.source_id)
--	        CoreHandler:win_show_holder_image(win, holder.holder_id)
--		stored_source = matched_source
--	    end
--        end
--    })
end

    -- if Settings.auto_display == true then

    --     -- initialise when entering buffer
    --     vim.api.nvim_create_autocmd({'BufWinEnter'}, {
    --         callback = function(au)
--  --     	-- attach to open buffer
    --             vim.api.nvim_buf_attach(au.buf, false, {
--  --     	    -- reload images on modified lines
    --                 on_lines = vim.schedule_wrap(function(_, buf, _, first, last)
    --                     ImageHandler:reload_buf_positions(buf)
    --                     nviz.buf_mark_images(buf, first, last+1)
    --                 end),
    --             })
    --             nviz.buf_mark_images(au.buf, 0, -1)
    --         end
    --     })
    --     vim.api.nvim_create_autocmd({'VimLeavePre'}, {
    --         callback = function(_)
    --     	fs.rm_tmp_dir()
    --     end
    --     })

    --     vim.api.nvim_set_decoration_provider(Settings.extmark_ns, {
    --         on_win = function(_)
    --             ImageHandler:update_placements()
    --         end
    --     })
    -- end
--end

return nviz
