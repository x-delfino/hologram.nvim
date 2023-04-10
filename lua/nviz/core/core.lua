local log = require('nviz.utils.log')
local settings = require('nviz.utils.settings2')
local image_handler = require('nviz.core.image_handler')

-- HOLDER_HANDLER

local holder_handler = {
    holders = nil,
    registered_types = nil,
    next_holder_id = nil,
}

function holder_handler:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.holders = {}
  x.registered_types = {}
  x.next_holder_id = 1
  return x
end

function holder_handler:get_win_holder_by_display_win_and_id(display_win, win_holder_id)
    for _, holder_type in pairs(self.holders) do
	for _, holder in pairs(holder_type) do
	    if holder.wins then
	        for _, w in pairs(holder.wins) do
	            if w.display_win == display_win
			and w.win_holder_id == win_holder_id
		    then
	        	return {holder, w}
	            end
                end
            end
        end
    end
    return nil
end

function holder_handler:get_holder_id()
    local holder_id = self.next_holder_id
    self.next_holder_id = holder_id + 1
    return holder_id
end

function holder_handler:load_holder_type(holder_to_load)
    local holder_type = holder_to_load.holder_type
    if self.registered_types[holder_type] then
	return false
    else
--        local registration = getmetatable(holder_to_load)
--        registration.holder_type = holder_type
--        self.registered_types[holder_type] = registration
        self.registered_types[holder_type] = holder_to_load
        return true
    end
end

function holder_handler:get_holder_type(holder_type)
    for _, registered_type in pairs(self.registered_types) do
	if registered_type.holder_type == holder_type then return registered_type end
    end
    return false
end

function holder_handler:get_holder_for_source(source, holder_type)
    local holders = self.holders[holder_type]
    if holders then
        for _, holder in pairs(holders) do
            if holder.source == source then return holder end
        end
    end
    return false
end

function holder_handler:set_holder_for_source(source, holder_type)
    local holder = self:get_holder_for_source(source, holder_type)
    if not holder then
	return self:add_holder_for_source(source, holder_type)
    else
    end
end

function holder_handler:add_holder_for_source(source, holder_type, row, col)
    if not row and not col then
	row, col = source:get_position()
    end
    if self:get_holder_for_source(source, holder_type) then return nil end
    holder_type = self:get_holder_type(holder_type)
    if holder_type then
	local holder_id = self:get_holder_id()
        local holder = holder_type:new{
	    buf = self.buf,
	    source = source,
	    id = holder_id,
	}
	holder:set_holder(row, col)
	if not self.holders[holder_type.holder_type] then self.holders[holder_type.holder_type] = {} end
        self.holders[holder_type.holder_type][holder_id] = holder
    log.debug(holder_type)
	return holder
    end
end

function holder_handler:win_show_holder(win, holder)
    return holder:win_show_holder(win)
end

function holder_handler:win_show_holder_by_id(win, holder_type, holder_id)
    return self.holders[holder_type][holder_id]:win_show_holder(win)
end

function holder_handler:win_hide_holder_by_id(win, holder_type, holder_id)
    return self.holders[holder_type][holder_id]:win_hide_holder(win)
end

function holder_handler:win_hide_holder(win, holder)
    return holder:win_hide_holder(win)
end


--- BUFFER HANDLER

local buffer_handler = {
    buf = nil,
    parsers = nil,
    holder_handler = nil
}

function buffer_handler:new(x)
    setmetatable(x, self)
    self.__index = self
    x.holder_handler = holder_handler:new{buf = x.buf}
    x.parsers = {}
    -- holders will be a table with the keys as holder types. each value is a table of holders
    return x
end


-- HOLDER FUNCTIONS

function buffer_handler:load_holder_type(holder_to_load)
    return self.holder_handler:load_holder_type(holder_to_load)
end

function buffer_handler:get_holder_for_source(source, holder_type)
    return self.holder_handler:get_holder_for_source(source, holder_type)
end

function buffer_handler:add_holder_for_source(source, holder_type, row, col)
    return self.holder_handler:add_holder_for_source(source, holder_type, row, col)
end

function buffer_handler:add_holder_for_source_by_id(parser_name, source_id, holder_type, row, col)
    local source = self:get_source(parser_name, source_id)
    return self:add_holder_for_source(source, holder_type, row, col)
end

function buffer_handler:set_holder_for_source(source, holder_type, row, col)
    return self.holder_handler:set_holder_for_source(source, holder_type, row, col)
end

function buffer_handler:win_show_holder(win, holder)
    self.holder_handler:win_show_holder(win, holder)
end

function buffer_handler:win_show_holder_by_id(win, holder_type, holder_id)
    self.holder_handler:win_show_holder_by_id(win, holder_type, holder_id)
end

function buffer_handler:win_hide_holder(win, holder)
    self.holder_handler:win_hide_holder(win, holder)
end

function buffer_handler:win_hide_holder_by_id(win, holder_type, holder_id)
    self.holder_handler:win_hide_holder_by_id(win, holder_type, holder_id)
end

function buffer_handler:get_win_holder_by_display_win_and_id(display_win, win_holder_id)
    return self.holder_handler:get_win_holder_by_display_win_and_id(display_win, win_holder_id)
end

-- PARSER FUNCTIONS

function buffer_handler:load_parser(parser)
    if self.parsers[parser.name] then
	return false
    end
    parser.buf = self.buf
    self.parsers[parser.name] = parser
    parser:init()
end

function buffer_handler:gather_sources(top, bot, parser_name)
    top, bot = top or 0, bot or -1
    local parsers = {}
    if parser_name then
	parsers[parser_name] = self.parsers[parser_name]
    else parsers = self.parsers end
    local gathered_sources = {}
    if parsers then
        for _, parser in pairs(parsers) do
            vim.list_extend(gathered_sources, parser:gather_sources(top, bot))
        end
    end
    return gathered_sources 
end

function buffer_handler:get_source(parser_name, source_id)
    local source = self.parsers[parser_name].gathered[source_id]
    return source
end

--- CORE HANDLER


local core_handler = {
    buffers = nil,
    image_handler = nil,
    terminal_handler = nil,
    config = nil,
}

function core_handler:new(x)
  setmetatable(x, self)
  self.__index = self
  x.buffers = {}
  x.image_handler = image_handler:new()
  x.terminal_handler = {}
  return x
end

function core_handler:load_config(config)
    self.config = settings:new(config)
end

function core_handler:show_config(setting)
    vim.print(self.config)
end

function core_handler:load_buf(buf)
    if not self.buffers[buf] then
	self.buffers[buf] = buffer_handler:new{buf = buf}
        return true
    else return false end
end

function core_handler:add_image_from_source(source)
    if source then
	self.image_handler:add_image_from_source(source)
    end
end

function core_handler:win_render_images(win, top, bot)
    win = win and tonumber(win) or 0
    top = top and tonumber(top) or 0
    bot = bot and tonumber(bot) or -1

    local wins = {}
    if win == 0 then
	wins = vim.api.nvim_tabpage_list_wins(0)
    else
	wins = {win}
    end
    for _,w in pairs(wins) do
        local buf = vim.api.nvim_win_get_buf(w)
        local marks = vim.api.nvim_buf_get_extmarks(buf, vim.g.nviz_img_ns, top, bot, {})
        if marks then
            for _, mark in pairs(marks) do
                local win_holder_id = mark[1]
                local results = self:get_win_holder_by_display_win_and_id(w, win_holder_id)
                local holder = results[1]
                local win_holder = results[2]
                if win_holder.is_visible then
            	self.image_handler.terminal_handler:win_show_image(holder, win_holder, mark[2], mark[3])
                end
            end
        end
    end
end

-- IMAGE PROCESSOR FUNCTIONS

function core_handler:load_image_processor(image_processor)
    if self.image_handler.image_processors[image_processor.name] then
	return false
    end
    self.image_handler.image_processors[image_processor.name] = image_processor
end

-- DATA PROCESSOR FUNCTIONS

function core_handler:load_data_processor(data_processor)
    if self.image_handler.data_processors[data_processor.name] then
	return false
    end
    local config = self.config.terminal[data_processor.name]
    data_processor.config = vim.tbl_deep_extend(
        'keep',
        config or {}, data_processor.config or {}
    )
    self.image_handler.data_processors[data_processor.name] = data_processor
end

-- TERMINAL HANDLER FUNCTIONS

function core_handler:load_terminal_handler(terminal_handler, force)
    if self.image_handler.terminal_handler and not force then
	return false
    else
    local config = self.config.terminal[terminal_handler.name]
    terminal_handler.config = vim.tbl_deep_extend(
        'keep',
        config or {}, terminal_handler.config or {}
    )
    self.image_handler.terminal_handler = terminal_handler
    return true
    end
end

-- PARSER FUNCTIONS

function core_handler:buf_load_parser(buf, parser)
    self.buffers[buf]:load_parser(parser)
end

function core_handler:buf_gather_sources(buf, top, bot, parser_name)
    buf = buf or vim.api.nvim_win_get_buf(0)
    local gathered_sources = self.buffers[buf]:gather_sources(top, bot, parser_name)
    for _, source in pairs(gathered_sources) do
	self:add_image_from_source(source)
    end
    return gathered_sources
end

-- HOLDER FUNCTIONS

function core_handler:buf_load_holder_type(buf, holder_to_load)
    return self.buffers[buf]:load_holder_type(holder_to_load)
end

function core_handler:buf_get_holder_for_source(buf, source, holder_type)
    return self.buffers[buf]:get_holder_for_source(source, holder_type)
end

function core_handler:buf_add_holder_for_source(buf, source, holder_type, row, col)
    return self.buffers[buf]:add_holder_for_source(source, holder_type, row, col)
end

function core_handler:buf_add_holder_for_source_by_id(buf, parser_name, source_id, holder_type, row, col)
    return self.buffers[buf]:add_holder_for_source_by_id(parser_name, source_id, holder_type, row, col)
end

function core_handler:buf_set_holder_for_source(buf, source, holder_type, row, col)
    return self.buffers[buf]:set_holder_for_source(source, holder_type, row, col)
end

function core_handler:win_show_holder_by_id(win, holder_type, holder_id)
    local buf = vim.api.nvim_win_get_buf(win)
    self.buffers[buf]:win_show_holder_by_id(win, holder_type, holder_id)
end

function core_handler:win_show_holder(win, holder)
    local buf = vim.api.nvim_win_get_buf(win)
    self.buffers[buf]:win_show_holder(win, holder)
end

function core_handler:win_hide_holder(win, holder)
    local buf = vim.api.nvim_win_get_buf(win)
    self.buffers[buf]:win_hide_holder(win, holder)
end

function core_handler:win_hide_holder_by_id(win, holder_type, holder_id)
    local buf = vim.api.nvim_win_get_buf(win)
    self.buffers[buf]:win_hide_holder_by_id(win, holder_type, holder_id)
end

function core_handler:get_win_holder_by_display_win_and_id(display_win, win_holder_id)
    for _, buf in pairs(self.buffers) do
	local holder = buf:get_win_holder_by_display_win_and_id(display_win, win_holder_id)
	if holder then return holder end
    end
end

return core_handler:new{}
