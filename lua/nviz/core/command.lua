local log = require('nviz.utils.log')

vim.api.nvim_create_user_command('HideImage',
  function(opts)
    local buf = opts.fargs[1]
    if not opts.fargs[1] then
	buf = vim.api.nvim_get_current_buf()
    end
    local row = opts.fargs[2]
    if not opts.fargs[2] then
        row = vim.api.nvim_win_get_cursor(0)[1]
    end
    ImageHandler:hide_placeholder(buf, row)
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('ShowImage',
  function(opts)
    local buf = opts.fargs[1]
    if not opts.fargs[1] then
	buf = vim.api.nvim_get_current_buf()
    end
    local row = opts.fargs[2]
    if not opts.fargs[2] then
        row = vim.api.nvim_win_get_cursor(0)[1]
    end
    log.debug(buf,row)
    ImageHandler:show_placeholder(buf, row)
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('HideBufImages',
  function(opts)
    local buf = opts.fargs[1]
    if not opts.fargs[1] then
	buf = vim.api.nvim_get_current_buf()
    end
    ImageHandler:hide_buf(buf)
  end,
  { nargs='?' }
)

vim.api.nvim_create_user_command('ShowBufImages',
  function(opts)
    local buf = opts.fargs[1]
    if not opts.fargs[1] then
	buf = vim.api.nvim_get_current_buf()
    end
    ImageHandler:show_buf(buf)
  end,
  { nargs='?' }
)

vim.api.nvim_create_user_command('LoadBufImages',
  function(opts)
    local buf = opts.fargs[1]
    if not opts.fargs[1] then
	buf = vim.api.nvim_get_current_buf()
    end
    ImageHandler:load_buf(buf)
  end,
  { nargs='?' }
)

vim.api.nvim_create_user_command('RenderImages',
  function(_)
    ImageHandler:update_placements()
  end,
  {}
)



---- new

vim.api.nvim_create_user_command('NvizHideImage',
  function(opts)
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('NvizShowImage',
  function(opts)
  end,
  { nargs='*' }
)

vim.api.nvim_create_user_command('NvizSet',
  function(opts)
  end,
  { nargs='*' }
)
