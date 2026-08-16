local routing_config = {
  included_message_prefix = "In included file:",
  related_location_message = "Error occurred here",
}

local route_states = {}

local function route_key(client_id, source_uri)
  return string.format("%d:%s", client_id, source_uri)
end

local function clear_state(state)
  for buffer in pairs(state.buffers) do
    if vim.api.nvim_buf_is_valid(buffer) then
      vim.diagnostic.reset(state.namespace, buffer)
    end
  end

  state.buffers = {}
end

local function route_state(client_id, source_uri)
  local key = route_key(client_id, source_uri)
  local state = route_states[key]

  if state then
    clear_state(state)
    return state
  end

  state = {
    buffers = {},
    namespace = vim.api.nvim_create_namespace("clangd.included." .. vim.fn.sha256(key):sub(1, 12)),
  }
  route_states[key] = state
  return state
end

local function included_location(diagnostic, source_uri)
  local message = diagnostic.message or ""
  if message:sub(1, #routing_config.included_message_prefix) ~= routing_config.included_message_prefix then
    return nil
  end

  for _, information in ipairs(diagnostic.relatedInformation or {}) do
    local location = information.location
    if
      information.message == routing_config.related_location_message
      and location
      and location.uri
      and location.uri ~= source_uri
    then
      return location
    end
  end
end

local function buffer_for_uri(uri)
  local buffer = vim.fn.bufadd(vim.uri_to_fname(uri))
  if buffer == 0 then
    return nil
  end

  vim.fn.bufload(buffer)
  return buffer
end

local function byte_column(buffer, position, position_encoding)
  local line = vim.api.nvim_buf_get_lines(buffer, position.line, position.line + 1, false)[1] or ""
  local ok, column = pcall(vim.str_byteindex, line, position_encoding, position.character, false)
  return ok and column or position.character
end

local function message_without_prefix(message)
  return vim.trim(message:sub(#routing_config.included_message_prefix + 1))
end

local function to_vim_diagnostic(diagnostic, location, buffer, position_encoding)
  local range = location.range

  return {
    lnum = range.start.line,
    col = byte_column(buffer, range.start, position_encoding),
    end_lnum = range["end"].line,
    end_col = byte_column(buffer, range["end"], position_encoding),
    severity = diagnostic.severity,
    message = message_without_prefix(diagnostic.message),
    source = diagnostic.source,
    code = diagnostic.code,
    user_data = { lsp = diagnostic },
  }
end

local function route_included_diagnostics(result, ctx, state)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local position_encoding = client and client.offset_encoding or "utf-16"
  local remaining = {}
  local routed = {}

  for _, diagnostic in ipairs(result.diagnostics or {}) do
    local location = included_location(diagnostic, result.uri)
    local buffer = location and buffer_for_uri(location.uri)

    if buffer then
      routed[buffer] = routed[buffer] or {}
      table.insert(routed[buffer], to_vim_diagnostic(diagnostic, location, buffer, position_encoding))
    else
      table.insert(remaining, diagnostic)
    end
  end

  for buffer, diagnostics in pairs(routed) do
    vim.diagnostic.set(state.namespace, buffer, diagnostics)
    state.buffers[buffer] = true
  end

  return remaining
end

local function setup_cleanup()
  local group = vim.api.nvim_create_augroup("clangd_included_diagnostic_cleanup", { clear = true })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(event)
      local client_id = event.data and event.data.client_id
      if not client_id then
        return
      end

      local key = route_key(client_id, vim.uri_from_bufnr(event.buf))
      local state = route_states[key]
      if state then
        clear_state(state)
        route_states[key] = nil
      end
    end,
  })
end

setup_cleanup()

local M = {}

function M.clear_buffer(buffer)
  for _, state in pairs(route_states) do
    if state.buffers[buffer] then
      vim.diagnostic.reset(state.namespace, buffer)
      state.buffers[buffer] = nil
    end
  end
end

function M.publish_diagnostics(err, result, ctx, config)
  if type(result) ~= "table" or type(result.uri) ~= "string" then
    return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
  end

  local state = route_state(ctx.client_id, result.uri)
  local forwarded_result = vim.deepcopy(result)
  forwarded_result.diagnostics = route_included_diagnostics(result, ctx, state)

  return vim.lsp.handlers["textDocument/publishDiagnostics"](err, forwarded_result, ctx, config)
end

return M
