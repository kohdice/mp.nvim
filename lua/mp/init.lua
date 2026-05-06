local M = {}

local default_adapter = require('mp.adapter')
local source = require('mp.source')
local state_store = require('mp.state')

local terminal_clear = '\27[2J\27[3J\27[H'

function M.build_command(path, executable, width)
  return source.build_command(path, executable, width)
end

local function buffer_is_valid(adapter, buffer)
  return buffer ~= nil and adapter.buffer_is_valid(buffer)
end

local function window_is_valid(adapter, window)
  return window ~= nil and adapter.window_is_valid(window)
end

local function list_contains(list, value)
  if type(list) ~= 'table' then
    return false
  end

  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end

  return false
end

local function notify_error(adapter, message, notify)
  if notify ~= false then
    adapter.notify_error(message)
  end
end

local function render_error_notify_option(options)
  if options.notify_render_errors ~= nil then
    return options.notify_render_errors
  end

  return options.notify
end

local function close_timer(adapter, state)
  if state.resize_timer then
    adapter.timer_stop(state.resize_timer)
    adapter.timer_close(state.resize_timer)
    state.resize_timer = nil
  end
end

local function clear_preview_window_autocmd(adapter, state)
  if state.preview_winclosed_autocmd then
    adapter.delete_autocmd(state.preview_winclosed_autocmd)
    state.preview_winclosed_autocmd = nil
  end
end

local function ensure_autocmd_group(adapter, state)
  if not state.autocmd_group then
    state.autocmd_group = adapter.create_augroup('mp_preview_' .. tostring(state.source_buf))
  end

  return state.autocmd_group
end

local function kill_process(state, wait_timeout)
  local proc = state.proc

  if proc and type(proc.kill) == 'function' then
    pcall(function()
      proc:kill('term')
    end)
  end

  if wait_timeout and proc and type(proc.wait) == 'function' then
    pcall(function()
      proc:wait(wait_timeout)
    end)
  end

  state.proc = nil
end

local function map_preview_keys(adapter, state)
  adapter.keymap_set({ 'n', 't' }, 'q', function()
    M.close({
      adapter = adapter,
      source_buf = state.source_buf,
    })
  end, {
    buffer = state.preview_buf,
    desc = 'Close mp preview',
    nowait = true,
    silent = true,
  })
end

local function setup_preview_buffer(adapter, state)
  state.preview_buf = adapter.create_scratch_buffer()
  state.term_chan = nil

  adapter.set_buffer_option(state.preview_buf, 'bufhidden', 'hide')
  adapter.set_buffer_option(state.preview_buf, 'swapfile', false)
  adapter.set_buffer_name(state.preview_buf, 'mp://' .. state.source_buf)
  map_preview_keys(adapter, state)
end

local function ensure_preview_buffer(adapter, state)
  if not buffer_is_valid(adapter, state.preview_buf) then
    setup_preview_buffer(adapter, state)
  end

  return state.preview_buf
end

local function watch_preview_window(adapter, state)
  clear_preview_window_autocmd(adapter, state)

  state.preview_winclosed_autocmd = adapter.create_autocmd('WinClosed', {
    group = state.autocmd_group,
    pattern = tostring(state.preview_win),
    callback = function()
      M.close({
        adapter = adapter,
        close_window = false,
        notify = false,
        restore_source = false,
        source_buf = state.source_buf,
      })
    end,
  })
end

local function ensure_preview_window(adapter, state)
  local preview_buffer = ensure_preview_buffer(adapter, state)

  if
    window_is_valid(adapter, state.preview_win)
    and adapter.window_buffer(state.preview_win) == preview_buffer
  then
    return state.preview_win
  end

  state.preview_win = adapter.open_preview_window(preview_buffer, {
    in_new_tab = state.in_new_tab,
  })
  watch_preview_window(adapter, state)

  return state.preview_win
end

local function ensure_terminal(adapter, state)
  ensure_preview_window(adapter, state)

  if not state.term_chan then
    state.term_chan = adapter.open_terminal(state.preview_buf)
  end

  return state.term_chan
end

local function send_preview(adapter, state, data)
  if not buffer_is_valid(adapter, state.preview_buf) or not state.term_chan then
    return
  end

  adapter.send_terminal(state.term_chan, terminal_clear .. (data or ''))
  adapter.set_buffer_option(state.preview_buf, 'modified', false)
end

local function render_state(adapter, state, options)
  options = options or {}

  local preview_window
  local width

  if options.resize_only then
    preview_window = ensure_preview_window(adapter, state)
    width = adapter.window_width(preview_window)

    if width == state.last_width then
      return true
    end
  end

  local path, target_error = source.resolve_target(adapter, state.source_buf)
  if not path then
    notify_error(adapter, target_error, options.notify)
    return nil, target_error
  end

  if not adapter.executable(state.executable) then
    local executable_error = state.executable .. ' executable not found'
    notify_error(adapter, executable_error, options.notify)
    return nil, executable_error
  end

  state.source_path = path

  if not preview_window then
    preview_window = ensure_preview_window(adapter, state)
    width = adapter.window_width(preview_window)
  end

  state.last_width = width

  state.last_seq = state.last_seq + 1
  local seq = state.last_seq

  kill_process(state)
  ensure_terminal(adapter, state)

  state.proc = adapter.system(M.build_command(path, state.executable, width), {
    text = true,
  }, function(result)
    adapter.schedule(function()
      if not state_store.is_current(state) or seq ~= state.last_seq then
        return
      end

      state.proc = nil

      if result.code == 0 then
        send_preview(adapter, state, result.stdout)
        return
      end

      local stderr = result.stderr
      if stderr == nil or stderr == '' then
        stderr = 'mp exited with code ' .. tostring(result.code) .. '\n'
      end

      send_preview(adapter, state, stderr)
      notify_error(
        adapter,
        'mp exited with code ' .. tostring(result.code),
        render_error_notify_option(options)
      )
    end)
  end)

  return true
end

local function create_autocmds(adapter, state)
  if state.autocmds_created then
    return
  end

  ensure_autocmd_group(adapter, state)

  adapter.create_autocmd('BufWritePost', {
    buffer = state.source_buf,
    group = state.autocmd_group,
    callback = function()
      M.refresh({
        adapter = adapter,
        notify = false,
        notify_render_errors = true,
        source_buf = state.source_buf,
      })
    end,
  })

  adapter.create_autocmd('BufWipeout', {
    buffer = state.source_buf,
    group = state.autocmd_group,
    callback = function()
      M.close({
        adapter = adapter,
        close_window = true,
        notify = false,
        restore_source = false,
        source_buf = state.source_buf,
      })
    end,
  })

  adapter.create_autocmd('WinResized', {
    group = state.autocmd_group,
    callback = function()
      if not state_store.is_current(state) then
        return
      end

      if not list_contains(adapter.resized_windows(), state.preview_win) then
        return
      end

      if not state.resize_timer then
        state.resize_timer = adapter.new_timer()
      end

      adapter.timer_stop(state.resize_timer)
      adapter.timer_start(state.resize_timer, state.resize_delay, function()
        adapter.schedule(function()
          M.refresh({
            adapter = adapter,
            notify = false,
            notify_render_errors = true,
            resize_only = true,
            source_buf = state.source_buf,
          })
        end)
      end)
    end,
  })

  state.autocmds_created = true
end

function M.resolve_current_buffer_target(adapter)
  adapter = adapter or default_adapter

  return source.resolve_target(adapter, adapter.current_buffer())
end

function M.open(options)
  options = options or {}

  local adapter = options.adapter or default_adapter
  local executable = options.executable or 'mp'
  local source_buffer = options.source_buf or adapter.current_buffer()

  local state, created = state_store.source(source_buffer)
  local previous_executable = state.executable
  local previous_in_new_tab = state.in_new_tab
  local previous_resize_delay = state.resize_delay

  state.executable = executable
  state.in_new_tab = options.in_new_tab == true
  state.resize_delay = options.resize_delay or state.resize_delay

  ensure_autocmd_group(adapter, state)

  local ok, err = render_state(adapter, state, options)
  if not ok then
    if created then
      if state.autocmd_group then
        adapter.delete_augroup(state.autocmd_group)
      end

      state_store.remove(source_buffer)
    else
      state.executable = previous_executable
      state.in_new_tab = previous_in_new_tab
      state.resize_delay = previous_resize_delay
    end

    return nil, err
  end

  create_autocmds(adapter, state)

  return true
end

function M.refresh(options)
  options = options or {}

  local adapter = options.adapter or default_adapter
  local state = state_store.for_context(adapter, options.source_buf)

  if not state then
    local preview_error = 'no active mp preview'
    notify_error(adapter, preview_error, options.notify)
    return nil, preview_error
  end

  return render_state(adapter, state, options)
end

function M.close(options)
  options = options or {}

  local adapter = options.adapter or default_adapter
  local state = state_store.for_context(adapter, options.source_buf)

  if not state then
    return true
  end

  close_timer(adapter, state)
  clear_preview_window_autocmd(adapter, state)
  kill_process(state, 50)

  if state.autocmd_group then
    adapter.delete_augroup(state.autocmd_group)
    state.autocmd_group = nil
    state.autocmds_created = false
  end

  local should_restore_source = options.restore_source ~= false
  if
    should_restore_source
    and window_is_valid(adapter, state.preview_win)
    and buffer_is_valid(adapter, state.source_buf)
  then
    adapter.set_window_buffer(state.preview_win, state.source_buf)
  elseif options.close_window == true and window_is_valid(adapter, state.preview_win) then
    adapter.close_window(state.preview_win)
  end

  if buffer_is_valid(adapter, state.preview_buf) then
    adapter.delete_buffer(state.preview_buf)
  end

  state_store.remove(state.source_buf)

  return true
end

function M.get_state(source_buffer)
  source_buffer = source_buffer or default_adapter.current_buffer()

  return state_store.get(source_buffer)
end

return M
