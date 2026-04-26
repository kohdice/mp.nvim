if vim.fn.has('nvim-0.12') ~= 1 then
  vim.notify('mp.nvim requires Neovim 0.12.0 or newer', vim.log.levels.ERROR, { title = 'Mp' })
  return
end

vim.api.nvim_create_user_command('Mp', function()
  require('mp').open()
end, {})

vim.api.nvim_create_user_command('MpRefresh', function()
  require('mp').refresh()
end, {})

vim.api.nvim_create_user_command('MpClose', function()
  require('mp').close()
end, {})

vim.api.nvim_create_user_command('MpTab', function()
  require('mp').open({ in_new_tab = true })
end, {})
