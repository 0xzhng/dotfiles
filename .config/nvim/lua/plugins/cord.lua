return {
  {
    'vyfor/cord.nvim',
    build = ':Cord update', -- keep this as-is
    config = function()
      local function patch_cord_commands()
        local ok, command = pcall(require, 'cord.api.command')
        if not ok or type(command) ~= 'table' then return end

        if command._oslen_async_patched then return end
        command._oslen_async_patched = true

        local async_ok, async = pcall(require, 'cord.core.async')
        local log_ok, log = pcall(require, 'cord.api.log')
        local update_ok, update = pcall(require, 'cord.server.update')
        if not (async_ok and log_ok and update_ok) then return end

        local function run_async(task_name, task)
          async.run(function()
            local ok_task, future = pcall(task)
            if not ok_task then
              log.error(future)
              return
            end

            if type(future) == 'table' and type(future.unwrap) == 'function' then
              local ok_unwrap, err = pcall(function() future:unwrap() end)
              if not ok_unwrap then log.error(err) end
            elseif future ~= nil then
              log.debug(string.format('Cord %s returned %s; skipping await', task_name, type(future)))
            end
          end)
        end

        command.install = function()
          run_async('install', function() return update.install() end)
        end
        command.fetch = function()
          run_async('fetch', function() return update.fetch() end)
        end
        command.build = function()
          run_async('build', function() return update.build() end)
        end
        command.check = function()
          run_async('check', function() return update.check_version() end)
        end
        command.version = function()
          run_async('version', function() return update.version() end)
        end
      end

      patch_cord_commands()

      require('cord').setup({
        idle = {
          enabled = false,
          show_status = false,
          timeout = 99999999,
          ignore_focus = false,
          unidle_on_focus = false,
          smart_idle = false,
          details = '',
          state = '',
          tooltip = '',
          icon = '',
        },
        editor = {
          client = 'lazyvim',
        },
        timestamp = {
          enabled = true,
          reset_on_idle = false,
          reset_on_change = false,
        },
        display = {
          theme = 'default',
        },
      })
    end,
  },
}
