local terminal_handler = require('nviz.terminal.core')
local transmit_keys, display_keys, delete_keys = require('nviz.terminal.control') ()
local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
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
        log.debug(image)
        local keys = transmit_keys:new{
            transmission_type = 'f',
	    width = image.width,
	    height = image.height,
	    image_id = image.id
        }
        return { data = image.img_source, keys = keys }
    end,
    get_show_message = function(placement)
	    log.debug(placement.holder.source)
        local keys = display_keys:new({})
	keys.image_id = placement.holder.source.image.id
	keys.placement_id = placement.id
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
    pre_show = function(placement, row, col)
	log.debug({placement.win_holder.display_win, row, col})
--	local row, col = opts.image_holder:get_position()
        terminal_handler:win_move_cursor(
	    placement.win_holder.display_win,
	    row, col
	)
    end,
    post_show = function(_)
        terminal_handler:restore_cursor()
    end
}

return kitty_terminal_handler
