local M = {}

local capture_group = "@comment.documentation.return"
local is_setup = false

local function apply_highlight()
  vim.api.nvim_set_hl(0, capture_group, { link = "@string" })
end

local function first_token(match, _, source, predicate, metadata)
  local capture_id = predicate[2]
  local nodes = match[capture_id]
  local node = nodes and nodes[1]
  if not node then
    return
  end

  local text = vim.treesitter.get_node_text(node, source)
  local token_start, token_end = text:find("%S+")
  if not token_start then
    return
  end

  local start_row, start_col = node:range()
  metadata[capture_id] = metadata[capture_id] or {}
  metadata[capture_id].range = {
    start_row,
    start_col + token_start - 1,
    start_row,
    start_col + token_end,
  }
end

function M.setup()
  if is_setup then
    return
  end

  is_setup = true
  vim.treesitter.query.add_directive("doxygen-first-token!", first_token)

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("CppDocumentationHighlights", { clear = true }),
    callback = apply_highlight,
  })

  apply_highlight()
end

return M
