local M = {}

function M.build_command(path, executable, width)
  return { executable or 'mp', '--width', tostring(width), path }
end

local function has_markdown_extension(path)
  local lower_path = path:lower()

  return lower_path:match('%.md$') ~= nil or lower_path:match('%.markdown$') ~= nil
end

local function is_markdown_buffer(adapter, source_buffer, path)
  return adapter.buffer_option(source_buffer, 'filetype') == 'markdown'
    or has_markdown_extension(path)
end

local function buffer_is_valid(adapter, buffer)
  return buffer ~= nil and adapter.buffer_is_valid(buffer)
end

function M.resolve_target(adapter, source_buffer)
  if not buffer_is_valid(adapter, source_buffer) then
    return nil, 'source buffer is no longer valid'
  end

  local path = adapter.buffer_path(source_buffer)

  if path == '' then
    return nil, 'Mp requires a saved file'
  end

  if adapter.buffer_option(source_buffer, 'modified') then
    return nil, 'current buffer has unsaved changes'
  end

  if not is_markdown_buffer(adapter, source_buffer, path) then
    return nil, 'Mp only supports Markdown buffers'
  end

  return path
end

return M
