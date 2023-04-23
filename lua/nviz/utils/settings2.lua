local settings = {
}

function settings:load()
    self.inline_placement_sign_text = vim.g.nviz_inline_placement_sign_text or true
    self.inline_placement_sign_text_displayed = vim.g.nvim_inline_placement_sign_text_displayed or '\xe2\x97\x89'
    self.inline_placement_sign_text_hidden = vim.g.nvim_inline_placement_sign_text_hidden or '-'
    self.cache_dir = vim.g.nvim_cache_dir or vim.fn.stdpath('cache') .. '/nviz/'
    self.auto_display = vim.g.nviz_auto_display or true
    self.enabled_handlers = vim.g.nviz_enabled_handlers or { { file = 'markdown', source = { 'image_link' } } }
    self.inline_image_padding_y = vim.g.nviz_inline_image_padding_y or 1
    self.extmark_ns = vim.api.nvim_create_namespace('nviz_extmark')
    self:validate()
end

function settings:validate()
    if self.sign_text then self.sign_text_hidden, self.sign_text_displayed = nil, nil end
end

settings:load()

return settings
