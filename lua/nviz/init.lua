local nviz = {}
local settings = require('nviz.utils.settings')
local state = require('nviz.utils.state')
local image_store = require('nviz.core.image')
local image_handler = require('nviz.core.image_handler')
local fs = require('nviz.utils.fs')
local log = require('nviz.utils.log')
local remote = require('nviz.utils.remote')
local png = require('nviz.handlers.image.png')
local core_handler = require('nviz.handlers.core')
local md_source_handler = require('nviz.handlers.source.markdown')
local inline_holder_handler = require('nviz.handlers.holder.inline')
local float_holder_handler = require('nviz.handlers.holder.float')
local png_image_handler = require('nviz.handlers.image.png')
local http_data_handler = require('nviz.handlers.data.http')
local file_data_handler = require('nviz.handlers.data.file')
local kitty_terminal_handler = require('nviz.handlers.terminal.kitty')

require('nviz.core.command')

ImageHandler = image_handler:new{}
ImageStore = image_store:new{}
CoreHandler = core_handler:new{}

-- vim.api.nvim_set_keymap('n', '<Esc>_G', 'i', {} )
Settings = settings





function nviz.setup(opts)
    CoreHandler:add_terminal_handler(kitty_terminal_handler)
    CoreHandler:add_image_handler(png_image_handler)
    CoreHandler:add_data_handler(file_data_handler)
    CoreHandler:add_data_handler(http_data_handler)

    state.update_cell_size()
    vim.api.nvim_create_autocmd({'BufRead'}, {
	callback = function(ev)
	    CoreHandler:add_buffer_handler(ev.buf)
            CoreHandler:add_source_handler(ev.buf, md_source_handler)
--	    CoreHandler:add_holder_handler(ev.buf, inline_holder_handler)
	    CoreHandler:add_holder_handler(ev.buf, float_holder_handler)
	    CoreHandler:gather_and_load_sources(ev.buf, 0, -1)
--	    CoreHandler:gather_and_load_sources(ev.buf, 0, -1)
--	    local buffer_handler = CoreHandler.buffer_handlers[ev.buf]
--	    if buffer_handler:gather_sources(0, -1) then
--	    end
        end
    })
    local stored_source = nil
    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorHoldI'}, {
	callback = function(ev)
            local win = vim.api.nvim_tabpage_get_win(0)
	    local cursor = vim.api.nvim_win_get_cursor(win)
	    local buffer_handler = CoreHandler.buffer_handlers[ev.buf]
--	    CoreHandler:win_hide_handler_holders(win, 'float')
	    local matched_source = buffer_handler:find_source_block_match({
		    start_row=cursor[1],
		    start_col=cursor[2],
	    })

	    if matched_source ~= stored_source and stored_source ~= nil then
	        local holder = buffer_handler:get_holder_by_source_id(stored_source.source_id)
    	        CoreHandler:win_hide_holder_by_id(win, holder.holder_id)
	    end

	    if matched_source then
	        local holder = buffer_handler:get_holder_by_source_id(matched_source.source_id)
	        CoreHandler:win_show_holder_image(win, holder.holder_id)
		stored_source = matched_source
	    end
        end
    })
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
