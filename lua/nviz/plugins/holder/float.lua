local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
local core_holder = require('nviz.holder')

local float_holder = core_holder:new{
    holder_type = 'float',
    show_win = function(self, win)
	local pad = self.config.pad
	local rows, cols = self.source:get_rows_cols()
	local offset_cols = math.ceil(self.source.offset_cols)
	local offset_rows = utils.round(self.source.offset_rows)
	local lpad = pad[4] + offset_cols
	local rpad = pad[2] + offset_cols
	local float_buf = vim.api.nvim_create_buf(true, true)
	local float_height = utils.round(rows)
	local caption = self.source:get_img_caption()
	if caption then
            local filler = {}
            for _=0,float_height-1+(pad[1] + pad[3]+offset_rows) do
                filler[#filler+1] = ' '
            end
	    local centered = utils.string_center(caption, math.ceil(cols) + (offset_cols * 2), lpad,  rpad)
	    for _, row in ipairs(centered) do filler[#filler+1] = row end
	    -- add padding
            for _=1,pad[3] do filler[#filler+1] = ' ' end
	    vim.api.nvim_buf_set_lines(float_buf, 0, -1, true, filler)
	    float_height = #filler
        end
	local win_config = {
	    relative = 'cursor',
	    width = utils.round(cols) + lpad + rpad,
	    height = float_height,
	    col = 0,
            row = 1,
	    anchor = 'NW',
	    style = 'minimal',
            --focusable = true,
            focusable = false,
	    border = self.config.border,
        }
	local display_win = (self.wins[win] and self.wins[win].display_win) or nil
	if self.wins[win].display_win then
	    vim.api.nvim_win_set_config(self.wins[win].display_win, win_config)
        else
--            win_config.noautocmd = false
            display_win = vim.api.nvim_open_win(float_buf, false, win_config)
	end
	return {0, 0, display_win}
    end,
    hide_win = function(self, win)
        local display_win = self.wins[win].display_win
	vim.api.nvim_win_close(display_win, false)
    end,
    config = {
	enabled = true,
	anchor = 'cursor',
	visible_on = 'cursor',
	pad = {1,1,1,1},
	border = 'rounded',
	y_offset = 1,
	x_offset = 1,
    }
}

function float_holder:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  return x
end

return float_holder
