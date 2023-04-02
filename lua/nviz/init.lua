local nviz = {}
local state = require('nviz.utils.state')
local image_store = require('nviz.core.image')
local image_handler = require('nviz.core.image_handler')
local fs = require('nviz.utils.fs')
local log = require('nviz.utils.log')
local remote = require('nviz.utils.remote')
local png = require('nviz.handlers.image.png')
require('nviz.core.command')

ImageHandler = image_handler:new{}
ImageStore = image_store:new{}

DisplayedSign = '\xE2\x97\x89'
HiddenSign = '-'

-- vim.api.nvim_set_keymap('n', '<Esc>_G', 'i', {} )


local image_source = {
    buf = nil,
    start_row = nil,
    start_col = nil,
    end_row = nil,
    end_col = nil,
    source_type = nil,
    hash = nil,
    caption = nil,
    image_id = nil,
}

function image_source:new (s)
  setmetatable(s, self)
  self.__index = self
  if not s.end_row then s.end_row = s.start_row end
  if not s.end_col then s.end_col = s.start_col end
  return s
end

function image_source:load_image()
    self.image_id = ImageStore:load(self:get_source(), {})
end

local md_source = image_source:new{}

function md_source:get_source()
    local line = vim.api.nvim_buf_get_lines(self.buf, self.start_row-1, self.start_row, true)[1]
    local source = nil
    local path = line:sub(self.start_col, self.end_col+1):match('%((.+)%)')
    if remote.is_url(path) then
	self.source_type = 'url'
	source = remote.download_file(path)
    else
        source = fs.get_absolute_path(path)
	self.source_type = 'file'
    end
    return source
end

function nviz.buf_image_finder(find_func, buf, top, bot)
    local sources = find_func(buf, top, bot)
    return sources
end

function nviz.buf_mark_images(buf, top, bot)
    local image_sources = nviz.buf_image_finder(nviz.markdown_finder, buf, top, bot)
    local existing_marks = ImageHandler:get_marks(buf, top, bot)
    local placeholder_ids = {}
    for i, source in pairs(image_sources) do
        placeholder_ids[i] = ImageHandler:add_placeholder(source)
    end
    if existing_marks then
        for _, mark in ipairs(existing_marks) do
            local keep = false
            for _, id in ipairs(placeholder_ids) do
                if mark[1] == id then keep = true end
            end
            if not keep then ImageHandler:remove_placeholder(buf, mark[1]) end
        end
    end
end

function nviz.markdown_finder(buf, top, bot)
    local lines = vim.api.nvim_buf_get_lines(buf, top, bot, false)
    local sources = {}
    for n, line in ipairs(lines) do
	local start_col, end_col = line:find('!%[.-%]%(.-%)')
	if start_col then
	    local image_reference = line:sub(start_col, end_col)
	    local caption, _ = image_reference:match('!%[(.-)%]%((.-)%)')
	    if caption == "" then caption = nil end

            sources[n] = md_source:new{
                buf = buf,
                start_row = top + n,
                start_col = start_col,
                end_col = end_col,
    	        hash = vim.fn.sha256(image_reference),
		caption = caption
            }
        end
    end
    return sources
end


function nviz.setup(opts)
    -- Create autocommands
--    local augroup = vim.api.nvim_create_augroup('Hologram', {clear = false})

    vim.g.nviz_extmark_ns = vim.api.nvim_create_namespace('nviz_extmark')

    state.update_cell_size()

    if opts.sign_text == true then
	if opts.sign_text_displayed then DisplayedSign = opts.sign_text_displayed end
	if opts.sign_text_hidden then HiddenSign = opts.sign_text_hidden end
    else HiddenSign, DisplayedSign = nil, nil end

    if opts.auto_display == true then

	-- initialise when entering buffer
        vim.api.nvim_create_autocmd({'BufWinEnter'}, {
            callback = function(au)
--		-- attach to open buffer
                vim.api.nvim_buf_attach(au.buf, false, {
--		    -- reload images on modified lines
                    on_lines = vim.schedule_wrap(function(_, buf, _, first, last)
                        ImageHandler:reload_buf_positions(buf)
	                nviz.buf_mark_images(buf, first, last+1)
                    end),
--		    -- cleanup images
--                    on_detach = function(_, buf)
--                        nviz.buf_delete_images(buf, 0, -1)
--                    end
                })
	        nviz.buf_mark_images(au.buf, 0, -1)
            end
        })

        vim.api.nvim_set_decoration_provider(vim.g.nviz_extmark_ns, {
            on_win = function(_)
	        ImageHandler:update_placements()
            end
        })
    end
end

return nviz
