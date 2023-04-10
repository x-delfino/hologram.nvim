local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
local core_holder = require('nviz.holder.core')

local inline_holder = core_holder:new{
    holder_type = 'inline',
    show_win = function(self, win)
        local holder_mark = vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_ns, self.id, {})
	local rows, cols = self.source.image:get_rows_cols()
        -- set padding block
        local filler = {}
        for _=0,rows-1+(self.pad[1] + self.pad[3]) do
            filler[#filler+1] = {{' ', nil}}
        end
	-- add caption
	local caption = self.source:get_img_caption()
	if caption then
	    local centered = utils.string_center(caption, cols, 4)
	    for _, row in ipairs(centered) do filler[#filler+1] = {{row, 'Title'}} end
	    -- add padding
            for _=1,self.pad[3] do filler[#filler+1] = {{' ', nil}} end
        end
        -- apply padding to marked row -1
	local mark_details = {
	    id = self.id,
            virt_lines = filler,
            sign_text = Settings.sign_text_displayed
	}
	-- set placeholder with vtext padding
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_ns, holder_mark[1], holder_mark[2], mark_details)
	return {holder_mark[1], holder_mark[2]}
    end,
    hide_win = function(self, win)
        local existing_mark = vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_ns, self.id, {})
	local mark_details = {
	    id = self.id,
            virt_lines = nil,
            sign_text = Settings.sign_text_hidden
	}
	-- remove vtext padding from placeholder
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_ns, existing_mark[1], existing_mark[2], mark_details)
	-- delete marker for image
        vim.api.nvim_buf_del_extmark(self.buf, vim.g.nviz_img_ns, self.wins[win].win_holder_id)
    end,
}

return inline_holder

