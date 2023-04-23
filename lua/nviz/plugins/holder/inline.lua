local utils = require('nviz.utils.utils')
local log = require('nviz.utils.log')
local core_holder = require('nviz.holder')

local inline_holder = core_holder:new{
    holder_type = 'inline',
    show_win = function(self, _)
	local pad = self.config.pad
        local holder_mark = vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_ns, self.id, {})
	local rows, cols = self.source:get_rows_cols()
	local offset_cols = math.ceil(self.source.offset_cols)
	local offset_rows = math.floor(self.source.offset_rows + 0.5)
	local lpad = pad[4] + offset_cols
	local rpad = pad[2] + offset_cols

        -- set pad block
        local filler = {}
        for _=1,math.floor(rows+0.5)+(pad[1] + pad[3]+offset_rows) do
            filler[#filler+1] = {{' ', nil}}
        end
	-- add caption
	local caption = self.source:get_img_caption()
	if caption then
	    local centered = utils.string_center(caption, math.ceil(cols) + (offset_cols * 2), lpad, rpad)
	    for _, row in ipairs(centered) do filler[#filler+1] = {{row, 'WarningMsg'}} end
	    -- add pad
            for _=1,pad[3]+offset_rows do filler[#filler+1] = {{' ', nil}} end
        end
        -- apply pad to marked row -1
	local mark_details = {
	    id = self.id,
            virt_lines = filler,
	}
	if self.config.sign_text then mark_details.sign_text = self.config.sign_text_displayed end
	-- set placeholder with vtext pad
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_inline_ns, holder_mark[1], holder_mark[2], mark_details)
	return {holder_mark[1], holder_mark[2]}
    end,
    hide_win = function(self, _)
        local existing_mark = vim.api.nvim_buf_get_extmark_by_id(self.buf, vim.g.nviz_inline_ns, self.id, {})
	local mark_details = {
	    id = self.id,
            virt_lines = nil,
	}
	if self.config.sign_text then mark_details.sign_text = self.config.sign_text_hidden end
	-- remove vtext pad from placeholder
        vim.api.nvim_buf_set_extmark(self.buf, vim.g.nviz_inline_ns, existing_mark[1], existing_mark[2], mark_details)
    end,
    config = {
	enabled = 'true',
	anchor = 'source',
	pad = {1,1,1,1},
	visible_on = 'win',
	--visible_on = 'cursor',
	y_offset = 1,
	x_offset = 0,
	sign_text = true,
	sign_text_displayed = '\xe2\x97\x89',
	sign_text_hidden = '-',
    }
}

return inline_holder

