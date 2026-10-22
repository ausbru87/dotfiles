-- Run by install.sh as: nvim --headless "+luafile lib/nvim-bootstrap.lua"
-- Installs the mason packages and treesitter parsers that the active LazyVim
-- extras ask for (which depend on the selected profiles), so the first
-- interactive start doesn't stall on downloads. Mirrors how LazyVim decides
-- which LSP servers go through mason (lazyvim/plugins/lsp/init.lua).
local timeout = 15 * 60 * 1000

local function log(msg)
  io.stdout:write(msg .. "\n")
end

-- mason: tools listed by extras, plus their LSP servers
local tools = vim.deepcopy(LazyVim.opts("mason.nvim").ensure_installed or {})
local servers = LazyVim.opts("nvim-lspconfig").servers or {}
local to_package = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
for name, sopts in pairs(servers) do
  sopts = sopts == true and {} or sopts
  if name ~= "*" and type(sopts) == "table" and sopts.enabled ~= false and sopts.mason ~= false and to_package[name] then
    tools[#tools + 1] = to_package[name]
  end
end

local registry = require("mason-registry")
local pending, failed = 0, {}
registry.refresh(function()
  for _, name in ipairs(tools) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() and not pkg:is_installing() then
      pending = pending + 1
      pkg:install({}, function(success)
        if not success then
          failed[#failed + 1] = name
        end
        pending = pending - 1
      end)
    end
  end
end)
vim.wait(5000, function()
  return pending > 0
end, 200)
log(("mason: %d package(s) to install"):format(pending))
vim.wait(timeout, function()
  return pending == 0
end, 1000)
if #failed > 0 then
  log("mason: failed: " .. table.concat(failed, ", "))
end

-- treesitter parsers
local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
local ok, ts = pcall(require, "nvim-treesitter")
if ok and ts.install then
  log(("treesitter: ensuring %d parser(s)"):format(#parsers))
  ts.install(parsers):wait(timeout)
end

vim.cmd("qa!")
