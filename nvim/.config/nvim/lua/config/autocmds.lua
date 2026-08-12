-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
local function load_border_yaml_color()
  local path = vim.fn.expand("/mnt/c/Users/daled/.config/tacky-borders/config.yaml")
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return "#ffffff" end

  local in_active = false

  for _, line in ipairs(lines) do
    if line:match("^%s*active_color:%s*$") then
      in_active = true
    elseif in_active then
      local color = line:match("#%x%x%x%x%x%x")
      if color then
        return color
      end
      -- stop if we leave the block
      if line:match("^%S") then
        in_active = false
      end
    end
  end

  return "#ffffff"
end

local function grayify(hex, factor)
  -- factor: 0 = original color, 1 = full gray
  factor = factor or 0.55

  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)

  local gray = math.floor((r + g + b) / 3)

  r = math.floor(r * (1 - factor) + gray * factor)
  g = math.floor(g * (1 - factor) + gray * factor)
  b = math.floor(b * (1 - factor) + gray * factor)

  return string.format("#%02x%02x%02x", r, g, b)
end

local border_color = load_border_yaml_color()
local muted_border = grayify(border_color, 0.6) -- adjust 0.5–0.7 if needed

vim.api.nvim_set_hl(0, "FloatBorder", {
  fg = muted_border,
  bg = "NONE",
})

vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatTitle", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatShadow", { bg = "NONE" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end
})

vim.opt.spell = false

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "cpp.tpp" },
  callback = function()
    vim.opt_local.indentexpr = ""
    vim.opt_local.cindent = false
    vim.opt_local.smartindent = false
    vim.opt_local.autoindent = true

    -- Disable built-in comment continuation.
    -- We manually handle comments below.
    vim.opt_local.formatoptions:remove({ "r", "o" })

    -- cindent trigger keys
    vim.opt_local.cinkeys:remove(":")

    -- indentexpr trigger keys
    vim.opt_local.indentkeys:remove(":")

    local function termcodes(keys)
      return vim.api.nvim_replace_termcodes(keys, true, false, true)
    end

    local function feedkeys(keys)
      vim.api.nvim_feedkeys(termcodes(keys), "n", false)
    end

    local function indent_unit()
      if vim.bo.expandtab then
        return string.rep(" ", vim.bo.shiftwidth)
      end

      return "\t"
    end

    local function get_comment_prefix(line)
      --     // comment
      local line_comment_indent = line:match("^(%s*)//")
      if line_comment_indent then
        return line_comment_indent .. "// "
      end

      --     /*
      local block_start_indent = line:match("^(%s*)/%*")
      if block_start_indent then
        return block_start_indent .. " * "
      end

      --      * comment
      local block_mid_indent = line:match("^(%s*)%*")
      if block_mid_indent then
        return block_mid_indent .. "* "
      end

      return nil
    end

    local function manual_comment_enter(prefix)
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()

      local before = line:sub(1, col)
      local after = line:sub(col + 1)

      vim.api.nvim_set_current_line(before)
      vim.api.nvim_buf_set_lines(0, row, row, false, {
        prefix .. after,
      })

      vim.api.nvim_win_set_cursor(0, {
        row + 1,
        #prefix,
      })
    end

    local function manual_brace_pair_enter()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_get_current_line()

      local before = line:sub(1, col)
      local after = line:sub(col + 1)

      local base_indent = line:match("^(%s*)") or ""
      local inner_indent = base_indent .. indent_unit()
      local closing = after:gsub("^%s*", "")

      vim.api.nvim_set_current_line(before)
      vim.api.nvim_buf_set_lines(0, row, row, false, {
        inner_indent,
        base_indent .. closing,
      })

      vim.api.nvim_win_set_cursor(0, {
        row + 1,
        #inner_indent,
      })
    end

    local function is_empty_brace_pair()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""

      local before = line:sub(1, col)
      local after = line:sub(col + 1)

      return before:match("{%s*$") and after:match("^%s*}")
    end

    local function blink_accept()
      local ok, cmp = pcall(require, "blink.cmp")
      if not ok then
        return false
      end

      return cmp.accept()
    end

    vim.keymap.set("i", "<CR>", function()
      -- First let blink.cmp accept autocomplete/snippets.
      -- This keeps snippets like stdo working.
      if blink_accept() then
        return
      end

      -- Handles:
      -- {}
      --
      -- into:
      -- {
      --     |
      -- }
      if is_empty_brace_pair() then
        manual_brace_pair_enter()
        return
      end

      local line = vim.api.nvim_get_current_line()
      local comment_prefix = get_comment_prefix(line)

      if comment_prefix then
        manual_comment_enter(comment_prefix)
        return
      end

      -- Normal non-comment Enter behavior.
      feedkeys("<CR>")
    end, {
      buffer = true,
      desc = "C/C++ Enter with comments, braces, and blink completion",
    })
  end,
})
