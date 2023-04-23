local terminal_handler = require('nviz.terminal')
local state = require('nviz.utils.state')
    state.update_cell_size()
local transmit_keys, display_keys, delete_keys = require('nviz.plugins.terminal.control') ()
local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
local base64 = require('nviz.utils.base64')
local ESC_CODE = '\x1b'
local START_CODE = ESC_CODE .. '_G'
local END_CODE = ESC_CODE .. '\\'

local function test_func()
    local read = ''
    log.debug(io.stdin:read(1))
    log.debug('triggered')
    while not read:match('.*' .. END_CODE) do
        local new = io.stdin:read(1)
	if new then read = read .. new end
    end
    log.debug('received')
end

local kitty_terminal_handler = terminal_handler:new{
    terminal_type = 'kitty',
    check_support = function() return true end,
    init = function(self)
--	vim.api.nvim_set_keymap(
--	    'n',
--	    '<Esc>_G',
--	    '',
--	    --'<Char-57344>',
--	    {
--		callback = vim.schedule(test_func)
--	    }
--	)
--	log.debug('set')
    end,
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
        local keys = transmit_keys:new{
            transmission_type = 'f',
	    width = image.width,
	    height = image.height,
	    image_id = image.id
        }
	local data = image.cache_source or image.img_source
        return { data = data, keys = keys }
    end,
    get_show_message = function(placement, row, col, y_offset)
	local source = placement.holder.source
        local src_height, src_width = source:get_src_dims()
        local img_height, img_width = source.image.height, source.image.width
        local height = nil
        local width = nil
        local height_factor = nil
        local width_factor = nil
        if src_height or src_width then
            if src_height then
                local px = src_height:match("(%d*)px")
                if px then
            	height_factor = img_height/px
            	height = px
                else
                    local perc = src_height:match("(%d*)%%*")
            	if perc then
            	    height_factor = perc/100
            	    height = img_height * height_factor
                    end
                end
            end
            if src_width then
                local px = src_width:match("(%d*)px")
                if px then
            	width_factor = img_width/px
            	width = px
                else
                    local perc = src_width:match("(%d*)%%*")
            	if perc then
            	    width_factor = perc/100
            	    width = img_width * width_factor
                    end
                end
            end
        end
        if width and not height then
            height = img_height * width_factor
        end
        if height and not width then
            width = img_width * height_factor
        end

        width, height = width or img_width, height or img_height
        local rows, cols = height/state.cell_size.y, width/state.cell_size.x



        local keys = display_keys:new({})
	keys.image_id = placement.holder.source.image.id
	keys.placement_id = placement.id


	local win_info =  vim.fn.getwininfo(placement.display_win)[1]
	local y_factor, x_factor = 1, 1
	local offset_rows = 0

        keys.cell_y_offset = math.floor(((math.ceil(rows) - rows) * state.cell_size.y) + 0.5)
        keys.cell_x_offset = math.floor(((math.ceil(cols) - cols) * state.cell_size.x) + 0.5)

	-- if the placement row is the last visible row
	if row+1 == win_info.botline then
	    -- screen position of the image placement
	    local img_screen_pos = vim.fn.screenpos(placement.display_win, row, col)
	    -- screen position of the window
	    local win_screen_pos = vim.fn.win_screenpos(placement.display_win)
	    -- height of display window (in rows)
	    local win_height = vim.fn.winheight(placement.display_win)
	    -- get the relative row of the image. eg. the image is on the nth visible row in window
	    local relative_win_row = img_screen_pos.row - win_screen_pos[1] + 1

	    -- how many rows are visible of the image
	    local visible_image_rows = win_height - relative_win_row - y_offset
	    if visible_image_rows == 0 then return false end
	    if visible_image_rows < rows then
		y_factor = visible_image_rows / rows
		offset_rows = rows - visible_image_rows
	        rows = visible_image_rows
	    end
--	    log.debug{ relative_win_row, win_height, visible_image_rows}
	end
	if offset_rows then
	    keys.height = height - math.floor(offset_rows * state.cell_size.y)
	end
	if rows and cols then
--	    local offset_rows, offset_cols = (keys.rows - rows), (keys.cols - cols)
--	    placement.holder.source.offset_rows, placement.holder.source.offset_cols =
--	        math.floor(offset_rows + 0.5),
--	        math.floor(offset_cols + 0.5)
	    keys.rows, keys.cols = math.ceil(rows), math.ceil(cols)

	--log.debug{
	--    src_height = src_height,
	--    src_width = src_width,
	--    height_factor = height_factor,
	--    width_factor = width_factor,

	---- original image dimensions
	--    image_height = img_height,
	--    image_width = img_width,

	---- dimensions to display in pixels
	--    height = height,
	--    width = width,

	--    key_rows = keys.rows,
	--    key_cols = keys.cols,

	--    keys_cell_y_offset = keys.cell_y_offset,
	--    keys_cell_x_offset = keys.cell_x_offset
        --}
	    
--	    log.debug(keys)
--            keys.cell_y_offset = 10
	    --keys.y_offset = 
        end
	return {keys = keys}
    end,
    get_delete_message = function(image)
    end,
    get_hide_message = function(placement)
        local keys = delete_keys:new({})
	keys.image_id = placement.holder.source.image.id
	keys.placement_id = placement.id
	keys.delete_action = "i"
	return {keys = keys}
    end,
    pre_show = function(win_holder, row, col, y_offset, x_offset)
--	local row, col = opts.image_holder:get_position()
        terminal_handler:win_move_cursor(
	    win_holder.display_win,
	    row, col, y_offset, x_offset
	)
    end,
    post_show = function(_)
        terminal_handler:restore_cursor()
    end
}

return kitty_terminal_handler
