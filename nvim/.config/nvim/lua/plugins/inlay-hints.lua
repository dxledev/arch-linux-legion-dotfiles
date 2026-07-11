local function hint_label_text(label)
  if type(label) == "string" then
    return label
  end

  if type(label) ~= "table" then
    return ""
  end

  local parts = {}
  for _, part in ipairs(label) do
    parts[#parts + 1] = part.value or ""
  end

  return table.concat(parts)
end

local function is_array_index_hint(hint)
  local label = hint_label_text(hint.label)

  return label:match("^%s*/?%*?%s*%[%d+%]%s*[:=]?%s*%*?/?%s*$") ~= nil
end

local function filter_array_index_hints(result)
  if type(result) ~= "table" then
    return result
  end

  return vim.tbl_filter(function(hint)
    return not is_array_index_hint(hint)
  end, result)
end

local function setup_array_index_hint_filter()
  if vim.g.array_index_hint_filter_loaded then
    return
  end

  vim.g.array_index_hint_filter_loaded = true

  local default_handler = vim.lsp.handlers["textDocument/inlayHint"] or vim.lsp.inlay_hint.on_inlayhint

  vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
    return default_handler(err, filter_array_index_hints(result), ctx, config)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      setup_array_index_hint_filter()
    end,
  },
}
