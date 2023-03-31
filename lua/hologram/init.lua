local hologram = {}
local state = require('hologram.state')
local image_store = require('hologram.image')
local image_handler = require('hologram.image_handler')
local fs = require('hologram.fs')
local log = require('hologram.log')
local remote = require('hologram.remote')
local png = require('hologram.png')

local handler = image_handler:new{}
ImageStore = image_store:new{}

function hologram.setup(opts)
    -- Create autocommands
    local augroup = vim.api.nvim_create_augroup('Hologram', {clear = false})

    vim.g.hologram_extmark_ns = vim.api.nvim_create_namespace('hologram_extmark')

    state.update_cell_size()

    if opts.auto_display == true then

	local buf_ref = {}
	-- rerender on buffer changes
--        vim.api.nvim_set_decoration_provider(vim.g.hologram_extmark_ns, {
--            on_win = function(_, win, buf, top, bot)
--		if not buf_ref[win] then buf_ref[win] = {} end
--		if not buf_ref[win][buf] then buf_ref[win][buf] = {} end
--		if top ~= buf_ref[win][buf]['top'] or bot ~= buf_ref[win][buf]['bot'] then
--                    vim.schedule(function() hologram.buf_render_images(buf, top, bot) end)
--		    buf_ref[win][buf]['top'] = top
--		    buf_ref[win][buf]['bot'] = bot
--	        end
--            end
--        })
--
--	-- cleanup when leaving buffer
--        vim.api.nvim_create_autocmd({'BufWinLeave'}, {
--            callback = function(au)
--                hologram.buf_delete_images(au.buf, 0, -1)
--            end,
--        })

	-- initialise when entering buffer
        vim.api.nvim_create_autocmd({'BufWinEnter'}, {
            callback = function(au)
--		-- attach to open buffer
                vim.api.nvim_buf_attach(au.buf, false, {
--		    -- reload images on modified lines
                    on_lines = function(_, buf, _, first, last)
         	        hologram.buf_load_images(buf, first, last)
			handler:update_placeholders(buf)
                        handler:update_placements()
                    end,
--		    -- cleanup images
--                    on_detach = function(_, buf)
--                        hologram.buf_delete_images(buf, 0, -1)
--                    end
                })
                if(hologram.buf_load_images(au.buf, 0, -1)) then
                    handler:update_placements()
	        end
            end
        })

        vim.api.nvim_set_decoration_provider(vim.g.hologram_extmark_ns, {
            on_win = function(_)
                handler:update_placements()
            end
        })

    end
end

function hologram.buf_load_images(buf, top, bot)
    local found = false
    local lines = vim.api.nvim_buf_get_lines(buf, top, bot, false)
    for n, line in ipairs(lines) do
        local source = hologram.find_source(line)
        if source ~= nil then
	    if not png.check_path_PNG(source) then return nil end
            source = fs.get_absolute_path(source)
            local image_id = ImageStore:load(source, {})

	    -- load buffer placement with placeholder
	    local placeholder_id = handler:add_placeholder(buf, ImageStore.images[image_id], top + n, 0)
	    handler.placeholders[placeholder_id]:show_placeholder()
	    found = true
        end
    end
    return found
end

function hologram.find_source(line)
    if line:find('png') then
        local inline_link = line:match('!%[.-%]%(.-%)')
        if inline_link then
            local source = inline_link:match('%((.+)%)')
	    return source
        end
    end
end

return hologram
