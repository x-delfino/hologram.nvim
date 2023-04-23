local log = require('nviz.utils.log')
local settings = require('nviz.utils.settings')
local plenary = require('plenary.async')
local state = require('nviz.utils.state')
    state.update_cell_size()



-- IMAGE_HANDLER

local source_handler = {
    config = nil,
    parsers = nil,
    sources = nil,
}

function source_handler:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.config = x.config or {}
  x.parsers = {}
  x.sources = {}
  return x
end

function source_handler:load_parser(parser_to_load)
    local source_type = parser_to_load.source_type
    if self.parsers[source_type] then
	return false
    else
	if parser_to_load:check_client_support() then
            self.parsers[source_type] = parser_to_load
            return true
        end
    end
end

function source_handler:buf_gather_sources(buf, top, bot, source_type)
    top, bot = top or 0, bot or -1
    local parsers = {}
    if source_type then
	parsers[source_type] = self.parsers[source_type]
    else parsers = self.parsers end
    local gathered_sources = {}
    if parsers then
        for _, parser in pairs(parsers) do
            vim.list_extend(gathered_sources, parser:gather_sources(buf, top, bot))
        end
    end
    return gathered_sources
end

function source_handler:add_buffer(buf, parser)
    local parsers = {parser}
    if not parser then
	parsers = self.parsers
    end
    if parsers then
        for _, p in pairs(parsers) do
            if not self.parsers[p.source_type].buf_parsers[buf] then
                self.parsers[p.source_type]:init_buf(buf)
                return true
            else return false end
        end
    end
end

local data_handler = {
    registered_types = nil,
    config = nil,
}

function data_handler:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.config = x.config or {}
  x.registered_types = {}
  return x
end

function data_handler:load_data_type(type_to_load)
    local data_type = type_to_load.data_type
    if self.registered_types[data_type] then
	return false
    else
        self.registered_types[data_type] = type_to_load
        return true
    end
end

function data_handler:init_source(source)
    for _, data_type in pairs(self.registered_types) do
	if data_type.check_valid_data(source) then
	    source.normalize_source = data_type.normalize_source
	    source.init_data = data_type.init_data
	    source.get_data = data_type.get_data
	    source.data_type = data_type.data_type
	    return true
	end
    end
    source.normalize_source = nil
    source.init_data = nil
    source.get_data = nil
    source.data_type = nil
    error('no valid data handler found')
end

local image_handler = {
    images = nil,
    registered_types = nil,
    next_image_id = nil,
    config = nil,
}

function image_handler:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.config = x.config or {}
  x.images = {}
  x.registered_types = {}
  x.next_image_id = 1
  return x
end

function image_handler:get_image_id()
    local image_id = self.next_image_id
    self.next_image_id = image_id + 1
    return image_id
end

function image_handler:load_image_type(type_to_load)
    local image_type = type_to_load.image_type
    if self.registered_types[image_type] then
	return false
    else
        self.registered_types[image_type] = type_to_load
        return true
    end
end

local image = {
    id = nil,
    img_source = nil,
    cache_source = nil,
    get_data = nil,
    height = nil,
    width = nil,
    next_placement_id = nil,
    is_loaded = nil
}

function image:get_placement_id()
    local placement_id = self.next_placement_id
    self.next_placement_id = placement_id + 1
    return placement_id
end

function image_handler:add_image_from_source(source)
    if source.reload_image then
        local img_source = source:normalize_source()
        -- check if already added
        for img_id, img in pairs(self.images) do
            if img.img_source == img_source then
                source.image = img
                return img
            end
        end
        source:init_data()
        -- if not, then add
        local img = image:new{
                img_source = img_source,
                id = self:get_image_id(),
                cache_source = source.cache_source,
                get_data = source.get_data,
        }
        for _, image_type in pairs(self.registered_types) do
            if image_type:is_supported(img) then
                image_type:init_image(img)
                break
            end
        end
        self.images[#self.images+1] = img
        source.image = img
        return img
    end
end


function image:get_rows_cols()
    local rows, cols = math.ceil(self.width/state.cell_size.y), math.ceil(self.height/state.cell_size.x)
    return rows, cols
end

function image:new (i)
  i = i or {}
  setmetatable(i, self)
  self.__index = self
  i.next_placement_id = 1
  return i
end

-- HOLDER_HANDLER

local holder_handler = {
    holders = nil,
    win_holder_ref = nil,
    registered_types = nil,
    next_holder_id = nil,
    config = nil,
}

function holder_handler:new(x)
  x = x or {}
  setmetatable(x, self)
  self.__index = self
  x.config = x.config or {}
  x.holders = {}
  x.win_holder_ref = {}
  x.registered_types = {}
  x.next_holder_id = 1
  x.next_win_holder_id = 1
  return x
end

function holder_handler:get_holder_id()
    local holder_id = self.next_holder_id
    self.next_holder_id = holder_id+1
    return holder_id
end

function holder_handler:get_win_holder_id()
    local win_holder_id = self.next_win_holder_id
    self.next_win_holder_id = win_holder_id+1
    return win_holder_id
end

function holder_handler:get_holder_for_source(source, holder_type)
    local holders = self.holders[source.buf]
    if holders then
        for _, holder in pairs(holders) do
            if holder.source == source and
		holder.holder_type == holder_type then
	        return holder
	    end
        end
    end
    return false
end

function holder_handler:add_holder_for_source(source,
	holder_type,
	start_row,
	start_col,
	end_row,
	end_col
    )
    local ssr, ssc, ser, sec = source:get_position()
    start_row, start_col = start_row or ssr, start_col or ssc
    end_row, end_col = end_row or ser or start_row, end_col or sec or start_col
    if self:get_holder_for_source(source, holder_type) then return nil end
    local holder = self.registered_types[holder_type]:new{
	buf = source.buf,
	source = source,
	id = self:get_holder_id()
    }
    holder:set_holder(start_row, start_col, end_row, end_col)
    source.holders[holder.id] = holder
    self.holders[source.buf][holder.id] = holder
    return holder
end

function holder_handler:add_win_holder(win, holder)
    if not holder:get_win_holder(win) then
	local wh = holder:add_win_holder(win, self:get_win_holder_id())
	if wh then
	    self.win_holder_ref[wh.id] = wh
	end
	return wh
    end
end

function holder_handler:list_win_holders(holder)
    if not holder then
	return self.win_holder_ref
    else
	return holder.wins
    end
end

function holder_handler:get_win_holder(id)
    return self.win_holder_ref[id]
end

function holder_handler:show_holder_in_win(buf, holder, win)
    holder =
        ((type(holder) == 'string' or type(holder) == 'number') and self.holders[buf][tonumber(holder)]) or
	type(holder) == 'table' and holder
    self:add_win_holder(win, holder)
    return holder:show_win_holder(win)
end

function holder_handler:hide_holder_in_win(buf, holder, win)
    holder =
        ((type(holder) == 'string' or type(holder) == 'number') and self.holders[buf][tonumber(holder)]) or
	type(holder) == 'table' and holder
    if holder then return holder:hide_win_holder(win) end
end

function holder_handler:list_win_holders_by_holder_id(buf, holder_id)
    local holder = self.holders[buf][holder_id]
    return holder.wins
end

function holder_handler:load_holder_type(holder_to_load)
    local holder_type = holder_to_load.holder_type
    if self.registered_types[holder_type] then
	return false
    else
        holder_to_load.config = vim.tbl_deep_extend(
            'keep',
            self.config[holder_type] or {},
            holder_to_load.config or {},
	    self.defaults or {}
        )
        self.registered_types[holder_type] = holder_to_load
    end
end

function holder_handler:add_buffer(buf)
    if not self.holders[buf] then
	self.holders[buf] = {}
	return true
    else return false end
end

function holder_handler:list_holders(buf, holder_type)
    local holders = {}
    for _, holder in pairs(self.holders[buf]) do
	if holder and (holder_type == nil or holder.holder_type == holder_type) then
	    holders[#holders+1] = holder
	end
    end
    return holders
end

function holder_handler:buf_get_holder(buf, holder_id)
    return self.holders[buf][holder_id]
end


local core_handler = {
    buffers = nil,
    terminal_handler = nil,
    holder_handler = nil,
    image_handler = nil,
    data_handler = nil,
    source_handler = nil,
    config = nil,
    placements = nil,
}

function core_handler:new(x)
  setmetatable(x, self)
  self.__index = self
  x.buffers = {}
  x.placements = {}
  x.holder_handler = holder_handler:new()
  x.image_handler = image_handler:new()
  x.data_handler = data_handler:new()
  x.source_handler = source_handler:new()
  return x
end

function core_handler:load_config(config)
    self.config = settings:new(config)
    vim.g.nviz_cache_dir = self.config.general.cache_dir
    self:trickle_config()
end

function core_handler:trickle_config()
    self.holder_handler.config = vim.tbl_deep_extend(
        'keep',
	self.config.holder or {},
	self.holder_handler.config or {}
    )
    self.holder_handler.defaults = vim.tbl_deep_extend(
        'keep',
	self.config.defaults.holder or {},
	self.holder_handler.defaults or {}
    )
    self.terminal_handler.config = vim.tbl_deep_extend(
        'keep',
	self.config.terminal[self.terminal_handler.name] or {},
	self.terminal_handler.config or {}
    )
end

function core_handler:show_config(setting)
    vim.print(self.config)
end

function core_handler:add_buffer(buf)
    for _, b in pairs(self.buffers) do
	if b == buf then return false end
    end
    self.holder_handler:add_buffer(buf)
    self.source_handler:add_buffer(buf)
    self.buffers[#self.buffers+1] = buf
    return true
end

function core_handler:buf_gather_sources(buf, top, bot, source_type)
    local sources = self.source_handler:buf_gather_sources(buf, top, bot, source_type)
    for _, s in pairs(sources) do
	if s.reload_image then
	    local s_status, s_result = pcall(function() self.data_handler:init_source(s) end)
	    if s_status then
	        local i_status, i_result = pcall(function() self.image_handler:add_image_from_source(s) end)
		if i_status then
	            self.terminal_handler:load_image(s.image)
	        else error(i_result) end
	    else error(s_result) end
	    s.reload_image = false
        end
    end
end

function core_handler:buf_get_sources(buf, parser_name)
    local parsers =
        self.source_handler.parsers[parser_name]
        or self.source_handler.parsers
    local sources = {}
    for _, p in pairs(parsers) do
	vim.list_extend(sources or {}, p:buf_get_sources(buf) or {})
    end
    return sources
end

function core_handler:buf_get_source(buf, source_id, parser_name)
    local parsers =
        self.source_handler.parsers[parser_name]
        or self.source_handler.parsers
    for _, p in pairs(parsers) do
	local source = p:buf_get_source(buf, source_id)
	if source then return source end
    end
    return false
end

function core_handler:add_holder_for_source(buf, source, holder_type, row, col)
    source =
        ((type(source) == 'string' or type(source) == 'number') and self:buf_get_source(buf, source)) or
	source
    return self.holder_handler:add_holder_for_source(source, holder_type, row, col)
end

function core_handler:buf_get_holder(buf, holder_id)
    return self.holder_handler:buf_get_holder(buf, holder_id)
end

function core_handler:add_win_holder(buf, win, holder)
    if type(holder) == 'string' or type(holder) == 'number' then
	holder = self:buf_get_holder(buf, tonumber(holder))
    end
    return self.holder_handler:add_win_holder(win, holder)
end

function core_handler:get_win_holder(id)
    return self.holder_handler:get_win_holder(id)
end

function core_handler:list_holders(buf, holder_type)
    return self.holder_handler:list_holders(buf, holder_type)
end

function core_handler:list_win_holders_by_holder_id(buf, holder_id)
    return self.holder_handler:list_win_holders_by_holder_id(buf, holder_id)
end

function core_handler:show_holder_in_win(buf, holder_id, win)
    local win_holder = self.holder_handler:show_holder_in_win(buf, holder_id, win)
    self:render_images()
    return win_holder
end

function core_handler:hide_holder_in_win(buf, holder_id, win)
    self.holder_handler:hide_holder_in_win(buf, holder_id, win)
    self:render_images()
end

function core_handler:render_images()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local tmp_placement_store = {}
    for _,win in pairs(wins) do
	local win_info = vim.fn.getwininfo(win)[1]
        local buf = vim.api.nvim_win_get_buf(win)


	-- process holders in visible range of window
	local placements = {}
        local marks = vim.api.nvim_buf_get_extmarks(
	    buf, vim.g.nviz_img_ns,
	    {win_info.topline-1, 0}, {win_info.botline, -1}, {}
	)
        if marks then
            for _, mark in pairs(marks) do
                local win_holder_id = mark[1]
                local win_holder = self:get_win_holder(win_holder_id)
                if win_holder.is_visible then
            	    if self.terminal_handler:win_show_image(win_holder, mark[2], mark[3]) then
		        placements[#placements+1] = win_holder.id
			break
		    else
		end
		    self.terminal_handler:win_hide_image(self:get_win_holder(win_holder.id))
	        end
            end
        end
	local remove = {}

	-- clear removed placements from window
        if self.placements[win] then
            for _, stored_id in pairs(self.placements[win]) do
		local keep = false
                for _, id in ipairs(placements) do
                    if id == stored_id then
			keep = true
			break
                    end
                end
		if not keep then remove[#remove+1] = stored_id end
            end
        end
        for _, id in ipairs(remove) do
       	    self.terminal_handler:win_hide_image(self:get_win_holder(id))
        end
        tmp_placement_store[win] = placements
    end
    for stored_w, stored_p in pairs(self.placements) do
	if not tmp_placement_store[stored_w] then
	    for _, id in pairs(stored_p) do
       	        self.terminal_handler:win_hide_image(self:get_win_holder(id))
	    end
	end
    end
    self.placements = tmp_placement_store
end


function core_handler:load_terminal_handler(terminal_handler, force)
    if self.terminal_handler and not force then
	return false
    else
        self.terminal_handler = terminal_handler
	self.terminal_handler:init()
        return true
    end
end

function core_handler:load_holder_type(holder_to_load)
    self.holder_handler:load_holder_type(holder_to_load)
    local toggle_visibility = {
        cursor = function()
            vim.api.nvim_create_autocmd({'CursorMoved', 'CursorHoldI'}, {
        	callback = function(ev)
                    local win = vim.api.nvim_tabpage_get_win(0)
          	    local cursor = vim.api.nvim_win_get_cursor(win)
         	    local marks = vim.api.nvim_buf_get_extmarks(ev.buf, vim.g.nviz_ns, 0, -1, {details = true})
        	    for _, mark in ipairs(marks) do
			if self:buf_get_holder(ev.buf, mark[1]).holder_type ==  holder_to_load.holder_type then
    		            local mark_details = mark[4]
    		            if mark[2] <= cursor[1]-1 and
    			        mark[3] <= cursor[2] and
    		                mark_details.end_row >= cursor[1]-1 and
    		                mark_details.end_col >= cursor[2]
    		            then
    		    	        self:show_holder_in_win(ev.buf, mark[1], win)
		            else
			        self:hide_holder_in_win(ev.buf, mark[1], win)
    		            end
			end
    		    end
                end,
            })
        end
    }
    _ = toggle_visibility[holder_to_load.config.visible_on]
        and toggle_visibility[holder_to_load.config.visible_on]()
end

function core_handler:load_image_type(type_to_load)
    return self.image_handler:load_image_type(type_to_load)
end

function core_handler:load_data_type(type_to_load)
    return self.data_handler:load_data_type(type_to_load)
end

function core_handler:load_parser(parser_to_load)
    return self.source_handler:load_parser(parser_to_load)
end

return core_handler:new{}
