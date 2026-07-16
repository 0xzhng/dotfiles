return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<F9>",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "DAP continue",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "DAP step over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "DAP step into",
      },
      {
        "<F12>",
        function()
          require("dap").step_out()
        end,
        desc = "DAP step out",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "DAP conditional breakpoint",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "DAP REPL",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "DAP run last",
      },
    },
    config = function()
      local dap = require("dap")

      vim.fn.sign_define("DapBreakpoint", {
        text = "B",
        texthl = "DiagnosticError",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapBreakpointCondition", {
        text = "C",
        texthl = "DiagnosticWarn",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapLogPoint", {
        text = "L",
        texthl = "DiagnosticInfo",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapStopped", {
        text = ">",
        texthl = "DiagnosticOk",
        linehl = "Visual",
        numhl = "DiagnosticOk",
      })

      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local codelldb_path = mason_path .. "/packages/codelldb/extension/adapter/codelldb"
      if vim.fn.has("win32") == 1 then
        codelldb_path = codelldb_path .. ".exe"
      end

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb_path,
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      dap.configurations.c = dap.configurations.cpp
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP UI toggle",
      },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup(opts)

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {},
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy"
      local debugpy_python = mason_path .. "/venv/bin/python"
      if vim.fn.has("win32") == 1 then
        debugpy_python = mason_path .. "/venv/Scripts/python.exe"
      end
      require("dap-python").setup(debugpy_python)
    end,
  },
}
