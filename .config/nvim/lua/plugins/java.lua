return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  config = function()
    local jdtls_ok, jdtls = pcall(require, "jdtls")
    if not jdtls_ok then
      return
    end

    local mason_ok, mason_registry = pcall(require, "mason-registry")
    if not mason_ok then
      return
    end

    if not mason_registry.is_installed("jdtls") then
      return
    end

    local mason_root = vim.fn.expand("$MASON")
    if mason_root == "" or mason_root == "$MASON" then
      mason_root = vim.fn.stdpath("data") .. "/mason"
    end

    local jdtls_path = mason_root .. "/share/jdtls"
    local launcher = jdtls_path .. "/plugins/org.eclipse.equinox.launcher.jar"
    if vim.fn.filereadable(launcher) ~= 1 then
      launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
      if launcher == "" then
        return
      end
      launcher = vim.split(launcher, "\n")[1]
    end

    local root_dir = require("jdtls.setup").find_root({
      ".git",
      "mvnw",
      "gradlew",
      "pom.xml",
      "build.gradle",
      "build.gradle.kts",
    })

    if not root_dir then
      return
    end

    local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
    local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

    local config_dir = jdtls_path .. "/config"

    local bundles = {}
    local function add_jars(pattern)
      local matches = vim.fn.glob(pattern)
      if matches == "" then
        return
      end
      for _, jar in ipairs(vim.split(matches, "\n")) do
        if jar ~= "" then
          table.insert(bundles, jar)
        end
      end
    end

    if mason_registry.is_installed("java-debug-adapter") then
      add_jars(mason_root .. "/share/java-debug-adapter/*.jar")
    end

    if mason_registry.is_installed("java-test") then
      add_jars(mason_root .. "/share/java-test/*.jar")
    end

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if cmp_ok then
      capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
    end

    local config = {
      cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-Xms1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens",
        "java.base/java.util=ALL-UNNAMED",
        "--add-opens",
        "java.base/java.lang=ALL-UNNAMED",
        "-jar",
        launcher,
        "-configuration",
        config_dir,
        "-data",
        workspace_dir,
      },
      root_dir = root_dir,
      capabilities = capabilities,
      settings = {
        java = {},
      },
      init_options = {
        bundles = bundles,
      },
    }

    jdtls.start_or_attach(config)

    if type(jdtls.setup_dap) == "function" then
      pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
    end

  end,
}
