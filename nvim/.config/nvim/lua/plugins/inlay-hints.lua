local inlay_hint_config = {
  show_struct_field_hints = false,
}

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

local function is_struct_field_hint(hint)
  local label = hint_label_text(hint.label)

  return label:match("^%s*/?%*?%s*%.[_%a][_%w]*%s*[:=]?%s*%*?/?%s*$") ~= nil
end

local function should_hide_hint(hint)
  if is_array_index_hint(hint) then
    return true
  end

  return not inlay_hint_config.show_struct_field_hints and is_struct_field_hint(hint)
end

local function filter_inlay_hints(result)
  if type(result) ~= "table" then
    return result
  end

  return vim.tbl_filter(function(hint)
    return not should_hide_hint(hint)
  end, result)
end

local function setup_inlay_hint_filter()
  if vim.g.custom_inlay_hint_filter_loaded then
    return
  end

  vim.g.custom_inlay_hint_filter_loaded = true

  local default_handler = vim.lsp.handlers["textDocument/inlayHint"] or vim.lsp.inlay_hint.on_inlayhint

  vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
    return default_handler(err, filter_inlay_hints(result), ctx, config)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      setup_inlay_hint_filter()
    end,
  },
}
