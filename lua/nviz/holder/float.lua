local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
local core_holder = require('nviz.holder.core')

local float_holder = core_holder:new{
    holder_type = 'float',
    show_win = function(self, win)
	local rows, cols = self.source.image:get_rows_cols()
	local float_buf = vim.api.nvim_create_buf(true, true)
	local float_height = rows
	local caption = self.source:get_img_caption()
	if caption then
            local filler = {}
            for _=0,rows-1+(self.pad[1] + self.pad[3]) do
                filler[#filler+1] = ' '
            end
	    local centered = utils.string_center(caption, cols, (self.pad[2] + self.pad[4]))
	    for _, row in ipairs(centered) do filler[#filler+1] = row end
	    -- add padding
            for _=1,self.pad[3] do filler[#filler+1] = ' ' end
	    vim.api.nvim_buf_set_lines(float_buf, 0, -1, true, filler)
	    float_height = #filler
        end
	local win_config = {
	    relative = 'cursor',
	    width = cols,
	    height = float_height,
	    col = 0,
            row = 1,
	    anchor = 'NW',
	    style = 'minimal',
            focusable = false,
	    border = 'rounded',
        }
	local display_win = nil
	if self.wins[win].display_win then
	    vim.api.nvim_win_set_config(self.wins[win].display_win, win_config)
        else
	    win_config.noautocmd = true
            display_win = vim.api.nvim_open_win(float_buf, false, win_config)
	end
	return {0, 0, display_win}
    end,
    hide_win = function(self, win)
        local display_win = self.wins[win].display_win
	local display_buf = vim.api.nvim_win_get_buf(self.wins[win].display_win)
	vim.api.nvim_win_close(display_win, false)

	-- delete marker for image
        vim.api.nvim_buf_del_extmark(display_buf, vim.g.nviz_img_ns, self.wins[win].win_holder_id)

        self.wins[win].display_win = nil
    end,
}

function float_holder:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  return x
end

return float_holder
