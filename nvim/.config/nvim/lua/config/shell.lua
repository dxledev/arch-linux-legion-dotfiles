local M = {}

M.config = {
  detection_events = { "TextChanged", "TextChangedI", "TextChangedP" },
  filetypes = { "sh", "bash", "zsh", "fish", "csh", "tcsh", "nu", "elvish" },
  indent_size = 4,
}

local function is_shell_filetype(filetype)
  return vim.tbl_contains(M.config.filetypes, filetype)
end

local function set_shell_indent(buffer)
  local indent_size = M.config.indent_size

  vim.bo[buffer].tabstop = indent_size
  vim.bo[buffer].shiftwidth = indent_size
  vim.bo[buffer].softtabstop = indent_size
  vim.bo[buffer].expandtab = true
  vim.bo[buffer].autoindent = true
end

local function set_detected_filetype(buffer, filetype, on_detect)
  if on_detect then
    on_detect(buffer)
  end

  vim.api.nvim_buf_call(buffer, function()
    vim.cmd.setfiletype(filetype)
  end)
end

local function detect_shell_filetype(buffer)
  if not vim.api.nvim_buf_is_valid(buffer) or vim.bo[buffer].filetype ~= "" then
    return
  end

  local first_line = vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1]
  if not first_line or first_line:sub(1, 2) ~= "#!" then
    return
  end

  local filetype, on_detect = vim.filetype.match({ buf = buffer })
  if not is_shell_filetype(filetype) then
    return
  end

  set_detected_filetype(buffer, filetype, on_detect)
end

local function configure_loaded_shell_buffers()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) and is_shell_filetype(vim.bo[buffer].filetype) then
      set_shell_indent(buffer)
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("shell_filetype", { clear = true })

  vim.api.nvim_create_autocmd(M.config.detection_events, {
    group = group,
    desc = "Detect shell filetype from a newly entered shebang",
    callback = function(event)
      detect_shell_filetype(event.buf)
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = M.config.filetypes,
    desc = "Use four-space shell indentation",
    callback = function(event)
      set_shell_indent(event.buf)
    end,
  })

  configure_loaded_shell_buffers()
end

return M
