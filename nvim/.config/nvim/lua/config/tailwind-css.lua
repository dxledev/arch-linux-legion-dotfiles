local M = {}

M.config = {
  import_line = '@import "tailwindcss";',
  suppressed_diagnostics = {
    ["Unknown at rule @apply"] = true,
  },
}

local function has_tailwind_import(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if vim.trim(line) == M.config.import_line then
      return true
    end
  end

  return false
end

local function filter_diagnostics(bufnr, diagnostics)
  if not vim.api.nvim_buf_is_loaded(bufnr) or not has_tailwind_import(bufnr) then
    return diagnostics
  end

  return vim.tbl_filter(function(diagnostic)
    return not M.config.suppressed_diagnostics[diagnostic.message]
  end, diagnostics)
end

local function filter_published_diagnostics(params)
  if not params or not params.uri or not params.diagnostics then
    return params
  end

  local filtered = vim.tbl_extend("force", {}, params)
  filtered.diagnostics = filter_diagnostics(vim.uri_to_bufnr(params.uri), params.diagnostics)

  return filtered
end

function M.publish_diagnostics(err, params, ctx, config)
  return vim.lsp.diagnostic.on_publish_diagnostics(err, filter_published_diagnostics(params), ctx, config)
end

function M.document_diagnostics(err, result, ctx, config)
  if not result or not result.items or not ctx.bufnr then
    return vim.lsp.diagnostic.on_diagnostic(err, result, ctx, config)
  end

  local filtered = vim.tbl_extend("force", {}, result)
  filtered.items = filter_diagnostics(ctx.bufnr, result.items)

  return vim.lsp.diagnostic.on_diagnostic(err, filtered, ctx, config)
end

return M
