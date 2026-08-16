local tpp_lint_config = {
  compiler = "/usr/bin/clang++",
  max_errors = 1,
  change_debounce_ms = 150,
  flags = {
    "-std=c++23",
    "-Wall",
    "-Wextra",
    "-pedantic",
    "-Wno-pragma-once-outside-header",
    "-fdiagnostics-color=never",
  },
}

table.insert(tpp_lint_config.flags, "-ferror-limit=" .. tpp_lint_config.max_errors)

local function current_filename()
  return vim.api.nvim_buf_get_name(0)
end

local change_generations = {}

local function lint_after_change(buffer)
  require("config.clangd-diagnostics").clear_buffer(buffer)

  change_generations[buffer] = (change_generations[buffer] or 0) + 1
  local generation = change_generations[buffer]

  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buffer) or change_generations[buffer] ~= generation then
      return
    end

    vim.api.nvim_buf_call(buffer, function()
      require("lint").try_lint("tpp_compiler")
    end)
  end, tpp_lint_config.change_debounce_ms)
end

return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts.linters_by_ft = opts.linters_by_ft or {}
    opts.linters = opts.linters or {}

    local script = vim.fn.stdpath("config") .. "/scripts/lint-tpp"
    local args = { script, current_filename, tpp_lint_config.compiler }
    vim.list_extend(args, tpp_lint_config.flags)

    opts.linters_by_ft["cpp.tpp"] = { "tpp_compiler" }
    opts.linters.tpp_compiler = {
      cmd = "/usr/bin/bash",
      args = args,
      stdin = true,
      stream = "stderr",
      ignore_exitcode = true,
      parser = require("lint.parser").from_errorformat(
        "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%-G%f:%l:%c: note: %m,%-G%.%#",
        { source = "clang++" }
      ),
    }

    local group = vim.api.nvim_create_augroup("tpp_lint_changes", { clear = true })
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = group,
      pattern = "*.tpp",
      callback = function(event)
        lint_after_change(event.buf)
      end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = group,
      pattern = "*.tpp",
      callback = function(event)
        change_generations[event.buf] = nil
      end,
    })
  end,
}
