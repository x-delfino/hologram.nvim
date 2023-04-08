local log = require('nviz.utils.log')
local utils = require('nviz.utils.utils')
local holder_handler = require('nviz.handlers.holder.core')
local state = require('nviz.utils.state')

state.update_cell_size()

local float_holder_handler = holder_handler:new{
    name = 'float',
    show = function(opts)
	local win_holder = opts.win_holders[opts.win]
	local rows, cols = opts.image:get_rows_cols()
	local float_buf = vim.api.nvim_create_buf(true, true)

        local filler = {}
        for _=0,rows-1+(Settings.inline_image_padding_y*2) do
            filler[#filler+1] = ' '
        end
	-- add caption
	local caption_position = {}
	if opts.caption then
	    caption_position[1] = #filler
	    local centered = utils.string_center(opts.caption, cols, 4)
	    for _, row in ipairs(centered) do filler[#filler+1] = row end
	    caption_position[2] = #filler
	    -- add padding
            for _=1,Settings.inline_image_padding_y do filler[#filler+1] = ' ' end
        end

	vim.api.nvim_buf_set_lines(float_buf, 0, -1, true, filler)
	local win_config = {
	    relative = 'cursor',
	    width = cols,
	    height = #filler,
	    col = 0,
            row = 1,
	    anchor = 'NW',
	    style = 'minimal',
            focusable = false,
	--    noautocmd = true,
	    border = 'rounded',
        }
	for i=caption_position[1],caption_position[2],1 do
	    vim.api.nvim_buf_add_highlight(float_buf, opts.holder_namespace, 'caption', i, 0, -1)
	end
	if win_holder.display_win then
	    vim.api.nvim_win_set_config(win_holder.display_win, win_config)
        else
            win_holder.display_win = vim.api.nvim_open_win(float_buf, false, win_config)
        end
	win_holder.display_row = 1
	win_holder.display_col = 1
	win_holder.visible = true
    end,
    hide = function(opts)
        local display_win = opts.win_holders[opts.win].display_win
	vim.api.nvim_win_close(display_win, false)
        opts.win_holders[opts.win].display_win = nil
    end,
    get_holder_position = function(_)
	return nil
    end,
    get_display_position = function(opts)
	local display_win = opts.holder.win_holders[opts.win].tracker
	local col = 1
	return {display_win, row, col}
    end
}

return float_holder_handler
