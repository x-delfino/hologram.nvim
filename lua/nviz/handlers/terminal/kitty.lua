local terminal_handler = require('nviz.handlers.terminal.core')
local transmit_keys, display_keys, delete_keys = require('nviz.handlers.terminal.control') ()
local utils = require('nviz.utils.utils')
local base64 = require('nviz.utils.base64')
local ESC_CODE = '\x1b'
local START_CODE = ESC_CODE .. '_G'
local END_CODE = ESC_CODE .. '\\'

local kitty_terminal_handler = terminal_handler:new{
    name = 'kitty',
    check_support = function() return true end,
    serialize_message = function(opts)
        --log.info('sending kitty command')
        local ctrl = opts.keys:serialize()
        -- log.debug('  ctrl string: ', ctrl)
        local serialized = ''
        if opts.data then
        --    log.debug('  payload: ',  payload)
            opts.data = base64.encode(opts.data)
            opts.data = utils.get_chunked(opts.data, 4096)
	    if #opts.data > 1 then opts.keys.more = 1 end
            for i=1,#opts.data do
    	    serialized = serialized .. START_CODE ..ctrl..';'..opts.data[i].. END_CODE
                if i == #opts.data-1 then ctrl = 'm=0' else ctrl = 'm=1' end
            end
        else
            serialized = START_CODE ..ctrl.. END_CODE
        end
	return serialized
    end,
    get_load_message = function(image)
        local keys = transmit_keys:new({})
        keys.transmission_type = 'f'
	keys.width = image.width
	keys.height = image.height
	keys.image_id = image.image_id
        return { data = image.data, keys = keys }
    end,
    get_show_message = function(opts)
        local keys = display_keys:new({})
	keys.image_id = opts.holder.image_id
	keys.placement_id = opts.placement.placement_id
--	keys.rows, keys.cols = opts.image_placement:win_get_visible_rows_and_cols(opts.win)
	return {keys = keys}
    end,
    get_delete_message = function(image)
    end,
    get_hide_message = function(opts)
        local keys = delete_keys:new({})
	keys.image_id = opts.image_id
	keys.placement_id = opts.placement_id
	keys.delete_action = "i"
	return {keys = keys}
    end,
    pre_show = function(opts)
--	local row, col = opts.image_holder:get_position()
        local win_holder = opts.image_holder.win_holders[opts.win]
        terminal_handler:win_move_cursor(
	    win_holder.display_win or opts.win,
	    win_holder.display_row-1,
	    win_holder.display_col,
	    opts.image_holder.y_pad
	)
    end,
    post_show = function(_)
        terminal_handler:restore_cursor()
    end
}

return kitty_terminal_handler
