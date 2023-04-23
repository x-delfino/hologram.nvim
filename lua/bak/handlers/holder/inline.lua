local log = require('nviz.utils.log')
local utils = require('nviz.utils.utils')
local holder_handler = require('nviz.handlers.holder.core')
local state = require('nviz.utils.state')

state.update_cell_size()

local inline_holder_handler = holder_handler:new{
    name = 'inline',
    show = function(opts)
        local mark = vim.api.nvim_buf_get_extmark_by_id(opts.buf,
            opts.source_namespace,
            opts.source_id,
            {}
        )
	local start_row, start_col = mark[1], mark[2]
	local win_holder = opts.win_holders[opts.win]
	local rows, cols = opts.image:get_rows_cols()
        -- set padding block
        local filler = {}
        for _=0,rows-1+(opts.y_pad*2) do
            filler[#filler+1] = {{' ', nil}}
        end
	-- add caption
	if opts.caption then
	    local centered = utils.string_center(opts.caption, cols, 4)
	    for _, row in ipairs(centered) do filler[#filler+1] = {{row, 'caption'}} end
	    -- add padding
            for _=1,opts.y_pad do filler[#filler+1] = {{' ', nil}} end
        end
        -- apply padding to marked row -1
	local extmark = {
	    id = opts.holder_id,
            virt_lines = filler,
            sign_text = Settings.sign_text_displayed
	}
        vim.api.nvim_buf_set_extmark(opts.buf, opts.holder_namespace, start_row, start_col, extmark)
	win_holder.display_row = start_row
	win_holder.display_col = start_col
	win_holder.visible = true
	return true
    end,
    hide = function(opts)
	local mark = vim.api.nvim_buf_get_extmark_by_id(
	    opts.buf,
	    opts.holder_namespace,
	    opts.holder_id,
	    {details = true}
	)
	local mark_details = {
	    id = opts.holder_id,
            virt_lines = nil,
            sign_text = Settings.sign_text_hidden
	}
        local win_holder = opts.win_holders[opts.win]
        vim.api.nvim_buf_set_extmark(opts.buf, opts.holder_namespace, win_holder.display_row, win_holder.display_col, mark_details)
    end,
    get_holder_position = function(opts)
        local mark = vim.api.nvim_buf_get_extmark_by_id(opts.buf,
            opts.source_namespace,
            opts.source_id,
            {}
        )
	return {opts.win ,mark[1], mark[2]}
    end,
    get_display_position = function(opts)
        local mark = vim.api.nvim_buf_get_extmark_by_id(opts.holder.buf,
            opts.holder.source_namespace,
            opts.holder.source_id,
            {}
        )
	return {opts.win ,mark[1], mark[2]}
    end
}

return inline_holder_handler


--local image_placeholder = {
--    buf = nil,
--    cols = nil,
--    rows = nil,
--    img_src = nil,
--    id = nil,
--    win_holders = nil,
--    visible = false,
--    extra_padding = nil,
--}
--
--function image_placeholder:remove_holders()
--    for win, _ in pairs(self.win_holders) do
--	self:remove_win_holder(win)
--    end
--end
--
--function image_placeholder:remove_win_holder(win)
--    if self.win_holders[win] then
--        -- remove holders from kitty
--        self.win_holders[win]:remove()
--        -- remove holders from placeholder
--        table.remove(self.win_holders, win)
--    end
--end
--
--function image_placeholder:update_win_holder(win)
--    if self.visible then
--        -- add holder to placeholder
--        local holder_id = ''
--        if self.win_holders[win] then
--            holder_id = self.win_holders[win].display_keys.holder_id
--        else
--            holder_id = ImageStore.images[self.img_src.image_id]:get_holder_id()
--        end
--
--        local holder = image_holder:new({
--                win = win,
--                row = self.img_src.start_row,
--                col = 0,
--		extra_padding = self.extra_padding,
--		y_padding = Settings.inline_image_padding_y,
--        }, {
--                image_id = self.img_src.image_id,
--                holder_id = holder_id
--        })
--        if holder then
--            self.win_holders[win] = holder
--            -- return holder id
--            return self.win_holders[win].holder_id
--        end
--    end
--    return self:remove_win_holder(win)
--end
--
--function image_placeholder:new (p)
--  setmetatable(p, self)
--  self.__index = self
--  vim.api.nvim_buf_set_extmark(p.buf, Settings.extmark_ns, p.img_src.start_row-1, p.img_src.start_col, {
--      id = p.id,
--      sign_text = Settings.sign_text_hidden
----      end_row = p.img_src.end_row-1,
----      end_col = p.img_src.end_col
--  })
--  p.win_holders = {}
--  return p
--end
--
--function image_placeholder:unmark()
--  vim.api.nvim_buf_del_extmark(self.buf, Settings.extmark_ns, self.id)
--end
--
--function image_placeholder:show()
--    self:reload_position()
--    if not self.img_src.image_id then self:load_image() end
--    if vim.api.nvim_buf_is_valid(self.buf) then
--        -- set padding block
--        local filler = {}
--        for _=0,self.rows-1+(Settings.inline_image_padding_y*2) do
--            filler[#filler+1] = {{' ', nil}}
--        end
--	-- add caption
--	if self.img_src.caption then
--	    local centered = utils.string_center(self.img_src.caption, self.cols, 4)
--	    for _, row in ipairs(centered) do filler[#filler+1] = {{row, nil}} end
--	    -- add padding
--            for _=1,Settings.inline_image_padding_y do filler[#filler+1] = {{' ', nil}} end
--        end
--        -- apply padding to marked row -1
--	local extmark = {
--	    id = self.id,
--            virt_lines = filler,
--            sign_text = Settings.sign_text_displayed
--            --end_col = self.img_src.end_col
--	}
----        if self.img_src.end_row then extmark.end_row = self.img_src.end_row-1 end
--        vim.api.nvim_buf_set_extmark(self.buf, Settings.extmark_ns, self.img_src.start_row-1, self.img_src.start_col, extmark)
--        self.visible = true
--        self.extra_padding = #filler - self.rows-1
--    end
--end
--
--function image_placeholder:reload_position()
--    local extmark =  vim.api.nvim_buf_get_extmark_by_id(self.buf, Settings.extmark_ns, self.id, {details = true})
--    if self.id == 2 then
--        log.debug(self.img_src.start_row)
--        log.debug(extmark[1])
--    end
--    self.img_src.start_row = extmark[1]+1
--    self.img_src.start_col = extmark[2]
--    if self.id == 2 then
--        log.debug(self.img_src.start_row)
--    end
----    self.img_src.end_col = extmark[3].end_col
----    if extmark[3].end_row then self.img_src.end_row = extmark[3].end_row+1 end
--	--log.debug(self)
--end
--
--function image_placeholder:load_image()
--    self.img_src:load_image()
--    self.rows, self.cols = ImageStore.images[self.img_src.image_id].rows, ImageStore.images[self.img_src.image_id].cols
--end
--
--function image_placeholder:hide()
--    self:reload_position()
--    self:remove_holders()
--    if vim.api.nvim_buf_is_valid(self.buf) then
--        -- apply padding to marked row -1
--	local extmark = {
--	    id = self.id,
----            end_row = self.img_src.end_row-1,
----            end_col = 0,
--            virt_lines = nil,
--            sign_text = Settings.sign_text_hidden
--	}
--	--self:reload_position()
--        vim.api.nvim_buf_set_extmark(self.buf, Settings.extmark_ns, self.img_src.start_row-1, self.img_src.start_col, extmark)
--        --vim.api.nvim_buf_set_extmark(self.buf, Settings.extmark_ns, 3, 0, extmark)
----        error(vim.inspect(vim.api.nvim_buf_get_extmark_by_id(self.buf, Settings.extmark_ns, extmark.id, {details = true})))
--    end
--    self.extra_padding = nil
--    self.visible = false
--end

