local tpp_lint_config = {
  compiler = "/usr/bin/g++",
  max_errors = 1,
  normal_mode_debounce_ms = 150,
  flags = {
    "-std=c++23",
    "-Wall",
    "-Wextra",
    "-pedantic",
    "-Wno-pragma-once-outside-header",
    "-fdiagnostics-color=never",
  },
}

table.insert(tpp_lint_config.flags, "-fmax-errors=" .. tpp_lint_config.max_errors)

local function current_filename()
  return vim.api.nvim_buf_get_name(0)
end

local normal_mode_generations = {}

local function lint_after_normal_mode_change(buffer)
  normal_mode_generations[buffer] = (normal_mode_generations[buffer] or 0) + 1
  local generation = normal_mode_generations[buffer]

  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buffer) or normal_mode_generations[buffer] ~= generation then
      return
    end

    vim.api.nvim_buf_call(buffer, function()
      require("lint").try_lint("tpp_compiler")
    end)
  end, tpp_lint_config.normal_mode_debounce_ms)
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
        "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%f:%l:%c: %m,%-G%.%#",
        { source = "g++" }
      ),
    }

    local group = vim.api.nvim_create_augroup("tpp_lint_normal_mode", { clear = true })
    vim.api.nvim_create_autocmd("TextChanged", {
      group = group,
      pattern = "*.tpp",
      callback = function(event)
        lint_after_normal_mode_change(event.buf)
      end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = group,
      pattern = "*.tpp",
      callback = function(event)
        normal_mode_generations[event.buf] = nil
      end,
    })
  end,
}
