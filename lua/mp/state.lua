local M = {}

local states = {}

function M.source(source_buffer)
  local state = states[source_buffer]

  if state then
    return state, false
  end

  state = {
    autocmd_group = nil,
    autocmds_created = false,
    executable = 'mp',
    in_new_tab = false,
    last_seq = 0,
    last_width = nil,
    preview_buf = nil,
    preview_win = nil,
    preview_winclosed_autocmd = nil,
    proc = nil,
    resize_delay = 100,
    resize_timer = nil,
    source_buf = source_buffer,
    source_path = nil,
    term_chan = nil,
  }
  states[source_buffer] = state

  return state, true
end

function M.for_context(adapter, source_buffer)
  if source_buffer then
    return states[source_buffer]
  end

  local current_buffer = adapter.current_buffer()

  if states[current_buffer] then
    return states[current_buffer]
  end

  for _, state in pairs(states) do
    if state.preview_buf == current_buffer then
      return state
    end
  end

  return nil
end

function M.get(source_buffer)
  return states[source_buffer]
end

function M.is_current(state)
  return state ~= nil and states[state.source_buf] == state
end

function M.remove(source_buffer)
  states[source_buffer] = nil
end

return M
