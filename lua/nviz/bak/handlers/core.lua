local buffer_handler = {
    buf = nil,
    source_handlers = {},
    holder_handlers = {},
    active_holder_handler = nil
}

function buffer_handler:new(b)
  setmetatable(b, self)
  self.__index = self
  return b
end

function buffer_handler:get_holder_by_id(id)
    for _, handler in pairs(self.holder_handlers) do
	for _, holder in pairs(handler.holders) do
	    if holder.holder_id == id then return holder end
	end
    end
end

function buffer_handler:get_holder_by_source_id(source_id)
    for _, handler in pairs(self.holder_handlers) do
	local holder = handler:get_holder_by_source_id(source_id)
	if holder then return holder end
    end
end

function buffer_handler:win_show_holder_by_id(win, id)
    for _, handler in pairs(self.holder_handlers) do
	for _, holder in pairs(handler.holders) do
	    if holder.holder_id == id then
	        handler:win_show_holder(win, holder.holder_id)
	        return true
            end
	end
    end
end

function buffer_handler:win_hide_holder_all(win)
    for _, handler in pairs(self.holder_handlers) do
	handler:win_hide_holder_all(win)
    end
end

function buffer_handler:win_hide_holder_by_id(win, id)
    for _, handler in pairs(self.holder_handlers) do
	for _, holder in pairs(handler.holders) do
	    if holder.holder_id == id then
	        return handler:win_hide_holder(win, holder.holder_id)
            end
	end
    end
end

function buffer_handler:show_holder_by_id(id)
    for _, handler in pairs(self.holder_handlers) do
	for _, holder in pairs(handler.holders) do
	    if holder.holder_id == id then
	        handler:show_holder(holder.holder_id)
	        return true
            end
	end
    end
end

function buffer_handler:hide_holder_by_id(id)
    for _, handler in pairs(self.holder_handlers) do
	for _, holder in pairs(handler.holders) do
	    if holder.holder_id == id then
	        handler:hide_holder(holder.holder_id)
	        return true
            end
	end
    end
end

function buffer_handler:add_holder_from_source(src_handler, src_id)
    local source = src_handler.sources[src_id]
    self.holder_handlers[self.active_holder_handler]:add_holder({
	    buf = self.buf,
	    image_id = source.image_id,
	    source_id = source.source_id,
	    source_namespace = src_handler.namespace,
	    caption = src_handler.get_caption(source)
    })
end

function buffer_handler:gather_sources(top, bot)
    local gathered = {}
    for _, handler in pairs(self.source_handlers) do
	gathered[#gathered+1] = {
	    handler = handler.name,
	    gathered = handler:gather(self.buf, top, bot)
	}
    end
    return gathered
end

function buffer_handler:get_source_handler_by_name(name)
    for _, source_handler in pairs(self.source_handlers) do
	if source_handler.name == name then
	    return source_handler
        end
    end
end

function buffer_handler:get_holder_handler_by_name(name)
    for _, holder_handler in pairs(self.holder_handlers) do
	if holder_handler.name == name then
	    return holder_handler
        end
    end
end

function buffer_handler:add_source_handler(handler_to_add)
    for i, handler in pairs(self.source_handlers) do
	if handler.name == handler_to_add.name then
	    self.source_handlers[i] = handler_to_add
	    return nil
        end
    end
    self.source_handlers[#self.source_handlers+1] = handler_to_add
end

function buffer_handler:add_holder_handler(handler_to_add)
    for i, handler in pairs(self.holder_handlers) do
	if handler.name == handler_to_add.name then
	    self.holder_handlers[i] = handler_to_add
	    return nil
        end
    end
    local holder_handler_id = #self.holder_handlers+1
    if not self.active_holder_handler then
	self.active_holder_handler = holder_handler_id
    end
    self.holder_handlers[holder_handler_id] = handler_to_add
end

function buffer_handler:set_active_holder_handler(handler_to_set)
    for i, handler in pairs(self.holder_handlers) do
	if handler.name == handler_to_set then
	    self.active_holder_handler = i
	    return true
        end
    end
    return false
end

function buffer_handler:find_source_block_match(position)
    for _, handler in pairs(self.source_handlers) do
	local match = handler:find_source_block_match(position)
	if match then return match end
    end
end


-- CORE HANDLER

local core_handler = {
    terminal_handler = nil,
    data_handlers = {},
    image_handlers = {},
    buffer_handlers = {},
    next_image_id = 1,
    next_placement_id = 1,
    next_holder_id = 1
}

function core_handler:new(handler)
  setmetatable(handler, self)
  self.__index = self
  return handler
end

function core_handler:win_show_holder_image(win, holder_id)
    local buf = vim.api.nvim_win_get_buf(win)
    local holder = self.buffer_handlers[buf]:get_holder_by_id(holder_id)
    if not holder.visible then
--        self.buffer_handlers[buf]:show_holder_by_id(holder_id)
        self.buffer_handlers[buf]:win_show_holder_by_id(win, holder_id)
    end
    self.terminal_handler:win_show_image(win, holder)
end

function core_handler:win_hide_handler_holders(win, handler_name)
    local buf = vim.api.nvim_win_get_buf(win)
    local handler = self.buffer_handlers[buf]:get_holder_handler_by_name(handler_name)
    for _, holder in pairs(handler.holders) do
	self:win_hide_holder_by_id(win, holder.holder_id)
    end
end

function core_handler:win_hide_holder_by_id(win, holder_id)
    local buf = vim.api.nvim_win_get_buf(win)
    if self.buffer_handlers[buf]:win_hide_holder_by_id(win, holder_id) then
        self.terminal_handler:win_hide_image(win, holder_id)
    end
--    local holder = self.buffer_handlers[buf]:get_holder_by_id(holder_id)
end

function core_handler:win_hide_holder_image(win, holder_id)
    local buf = vim.api.nvim_win_get_buf(win)
    local holder = self.buffer_handlers[buf]:get_holder_by_id(holder_id)
    self.terminal_handler:win_hide_image(win, holder)
end

function core_handler:gather_sources(buf, top, bot)
    self.buffer_handlers[buf]:gather_sources(top, bot)
end


function core_handler:get_image_id()
    local image_id = self.next_image_id
    self.next_image_id = image_id+1
    return image_id
end

function core_handler:get_placement_id()
    local placement_id = self.next_placement_id
    self.next_placement_id = placement_id+1
    return placement_id
end

function core_handler:get_holder_id()
    local holder_id = self.next_holder_id
    self.next_placement_id = holder_id+1
    return holder_id
end

function core_handler:get_image_by_id(id)
    for _, handler in pairs(self.image_handlers) do
	for _, image in pairs(handler.images) do
	    if image.image_id == id then return image end
        end
    end
end

--function core_handler:check_image_type(image)
--    for _, handler in pairs(self.image_handlers) do
--        if handler.check_valid_data(image) then
--	    return handler.name
--        else return false end
--    end
--end

function core_handler:get_data_handler(data)
    for _, handler in pairs(self.data_handlers) do
        if handler:is_supported(data) then
	    return handler
        end
    end
    return false
end

function core_handler:get_image_handler(data, data_handler)
    data_handler = data_handler or self:get_data_handler(data)
    for _, handler in pairs(self.image_handlers) do
        if handler:is_supported(data, data_handler) then
	    return handler
	end
    end
    return false
end

function core_handler:gather_and_load_sources(buf, top, bot)
    local buf_handler = self.buffer_handlers[buf]
    local gathered = buf_handler:gather_sources(top, bot)
    for _, sources in pairs(gathered) do
	local src_handler = buf_handler:get_source_handler_by_name(sources.handler)
	for _, src_id in pairs(sources.gathered) do
	    self:load_image_from_source(src_handler, src_id)
	    buf_handler:add_holder_from_source(src_handler, src_id)
        end
    end
end


function core_handler:load_image_from_source(src_handler, src_id)
    local source = src_handler.sources[src_id]
    source.image_id = self:load_image(src_handler:get_source_data(source))
end

function core_handler:load_image(data, data_handler)
    data_handler = data_handler or self:get_data_handler(data)
    return self:get_image_handler(data):load_image(self.terminal_handler, data_handler, data, {})
--    self.image_handler:load_image(self.terminal_handler, image_source, {})
end

function core_handler:add_buffer_handler(buf)
    if not self.buffer_handlers[buf] then
	self.buffer_handlers[buf] = buffer_handler:new{buf = buf}
    end
end

function core_handler:add_source_handler(buf, handler_to_add)
    self.buffer_handlers[buf]:add_source_handler(handler_to_add)
end

function core_handler:add_holder_handler(buf, handler_to_add)
    self.buffer_handlers[buf]:add_holder_handler(handler_to_add)
end

function core_handler:add_image_handler(handler_to_add)
    for i, handler in pairs(self.image_handlers) do
	if handler.name == handler_to_add.name then
	    self.image_handlers[i] = handler_to_add
	    return nil
        end
    end
    self.image_handlers[#self.image_handlers+1] = handler_to_add
end

function core_handler:add_data_handler(handler_to_add)
    for i, handler in pairs(self.data_handlers) do
	if handler.name == handler_to_add.name then
	    self.data_handlers[i] = handler_to_add
	    return nil
        end
    end
    self.data_handlers[#self.data_handlers+1] = handler_to_add
end

function core_handler:add_terminal_handler(handler_to_add)
    self.terminal_handler = handler_to_add
end

return core_handler
