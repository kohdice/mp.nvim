local M = {
  buffer_is_valid = function(buffer)
    return vim.api.nvim_buf_is_valid(buffer)
  end,
  buffer_option = function(buffer, name)
    return vim.api.nvim_get_option_value(name, { buf = buffer })
  end,
  buffer_path = function(buffer)
    return vim.api.nvim_buf_get_name(buffer)
  end,
  close_window = function(window)
    pcall(vim.api.nvim_win_close, window, true)
  end,
  create_augroup = function(name)
    return vim.api.nvim_create_augroup(name, { clear = true })
  end,
  create_autocmd = function(event, options)
    return vim.api.nvim_create_autocmd(event, options)
  end,
  create_scratch_buffer = function()
    return vim.api.nvim_create_buf(false, true)
  end,
  current_buffer = function()
    return vim.api.nvim_get_current_buf()
  end,
  current_window = function()
    return vim.api.nvim_get_current_win()
  end,
  delete_augroup = function(group)
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end,
  delete_autocmd = function(autocmd)
    pcall(vim.api.nvim_del_autocmd, autocmd)
  end,
  delete_buffer = function(buffer)
    pcall(vim.api.nvim_buf_delete, buffer, { force = true })
  end,
  executable = function(name)
    return vim.fn.executable(name) == 1
  end,
  keymap_set = function(mode, lhs, rhs, options)
    vim.keymap.set(mode, lhs, rhs, options)
  end,
  new_timer = function()
    return vim.uv.new_timer()
  end,
  notify_error = function(message)
    vim.notify(message, vim.log.levels.ERROR, { title = 'Mp' })
  end,
  open_preview_window = function(buffer, options)
    if options.in_new_tab then
      vim.cmd('tab split')
    end

    vim.api.nvim_set_current_buf(buffer)
    return vim.api.nvim_get_current_win()
  end,
  open_terminal = function(buffer)
    return vim.api.nvim_open_term(buffer, {})
  end,
  resized_windows = function()
    return vim.v.event.windows
  end,
  schedule = function(callback)
    vim.schedule(callback)
  end,
  send_terminal = function(channel, data)
    vim.api.nvim_chan_send(channel, data)
  end,
  set_buffer_name = function(buffer, name)
    pcall(vim.api.nvim_buf_set_name, buffer, name)
  end,
  set_buffer_option = function(buffer, name, value)
    vim.api.nvim_set_option_value(name, value, { buf = buffer })
  end,
  set_window_buffer = function(window, buffer)
    vim.api.nvim_win_set_buf(window, buffer)
  end,
  system = function(command, options, callback)
    return vim.system(command, options, callback)
  end,
  timer_close = function(timer)
    if timer and not timer:is_closing() then
      timer:close()
    end
  end,
  timer_start = function(timer, timeout, callback)
    timer:start(timeout, 0, callback)
  end,
  timer_stop = function(timer)
    if timer and not timer:is_closing() then
      timer:stop()
    end
  end,
  window_buffer = function(window)
    return vim.api.nvim_win_get_buf(window)
  end,
  window_is_valid = function(window)
    return vim.api.nvim_win_is_valid(window)
  end,
  window_width = function(window)
    return vim.api.nvim_win_get_width(window)
  end,
}

return M
