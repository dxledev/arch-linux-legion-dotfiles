local M = {}

M.config = {
  disable_completion_accept_filetypes = {
    css = true,
  },
  filetypes = {
    "html",
    "javascriptreact",
    "typescriptreact",
  },
}

function M.accept_completion(cmp)
  if M.config.disable_completion_accept_filetypes[vim.bo.filetype] then
    return false
  end

  return cmp.accept()
end

local function is_supported_filetype()
  return vim.tbl_contains(M.config.filetypes, vim.bo.filetype)
end

local function indent_unit()
  if vim.bo.expandtab then
    return string.rep(" ", vim.fn.shiftwidth())
  end

  return "\t"
end

local function has_matching_tag_pair(before, after)
  if before:match("<>%s*$") and after:match("^%s*</>") then
    return true
  end

  if before:match("/>%s*$") then
    return false
  end

  local opening_tag = before:match("<([%a_$][%w_:$%.%-]*)[^<>]*>%s*$")
  local closing_tag = after:match("^%s*</([%a_$][%w_:$%.%-]*)%s*>")

  return opening_tag ~= nil and opening_tag == closing_tag
end

local function cursor_context()
  local _, column = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  return {
    before = line:sub(1, column),
    after = line:sub(column + 1),
    base_indent = line:match("^(%s*)") or "",
  }
end

local function indent_keys(indent)
  return indent:gsub("\t", function()
    return vim.keycode("<C-v><Tab>")
  end)
end

local function tag_body_keys(context)
  local inner_indent = context.base_indent .. indent_unit()

  return vim.keycode("<CR><C-u>")
    .. indent_keys(context.base_indent)
    .. vim.keycode("<C-o>O<C-u>")
    .. indent_keys(inner_indent)
end

function M.expand_empty_tag()
  if not is_supported_filetype() then
    return false
  end

  local context = cursor_context()
  if not has_matching_tag_pair(context.before, context.after) then
    return false
  end

  return tag_body_keys(context)
end

return M
