-- return {
--   {
--     "mfussenegger/nvim-dap",
--     opts = function()
--       local dap = require("dap")
--
--       dap.adapters.lldb = {
--         type = "executable",
--         command = "/usr/bin/lldb-dap",
--         name = "lldb",
--       }
--
--       dap.configurations.cpp = {
--         {
--           name = "Launch C++ executable",
--           type = "lldb",
--           request = "launch",
--           program = function()
--             return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
--           end,
--           cwd = "${workspaceFolder}",
--           stopOnEntry = false,
--           runInTerminal = true,
--           args = {},
--         },
--       }
--
--       dap.configurations.c = dap.configurations.cpp
--     end,
--   },
-- }
-- return {
--   {
--     "mfussenegger/nvim-dap",
--     opts = function()
--       local dap = require("dap")
--
--       dap.adapters.codelldb = {
--         type = "server",
--         port = "${port}",
--         executable = {
--           command = "codelldb",
--           args = { "--port", "${port}" },
--         },
--       }
--
--       dap.defaults.fallback.terminal_win_cmd = "botright 15split new"
--
--       dap.configurations.cpp = {
--         {
--           name = "Launch C++ executable",
--           type = "codelldb",
--           request = "launch",
--
--           program = function()
--             return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/main", "file")
--           end,
--
--           cwd = "${workspaceFolder}",
--           stopOnEntry = false,
--
--           -- this is the important part for std::cin
--           terminal = "integrated",
--
--           args = {},
--         },
--       }
--
--       dap.configurations.c = dap.configurations.cpp
--     end,
--   },
-- }
return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      -- disable LazyVim's default Widgets mapping
      { "<leader>dw", false },

      -- replace it with DAP Add Watch
      {
        "<leader>dw",
        function()
          local dapui = require("dapui")

          local expr = vim.fn.input("Watch expression: ")
          if expr == "" then
            return
          end

          dapui.open()
          dapui.elements.watches.add(expr)
        end,
        desc = "DAP Add Watch",
      },
    },
    opts = function()
      local dap = require("dap")

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = "codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.defaults.fallback.external_terminal = {
        command = "ghostty",
        args = { "-e" },
      }

      dap.configurations.cpp = {
        {
          name = "Launch C++ executable",
          type = "codelldb",
          request = "launch",

          program = function()
            return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/main", "file")
          end,

          cwd = "${workspaceFolder}",
          stopOnEntry = false,

          -- open program in separate terminal for std::cin
          terminal = "external",

          args = {},
        },
      }

      dap.configurations.c = dap.configurations.cpp
    end,
  },
}
