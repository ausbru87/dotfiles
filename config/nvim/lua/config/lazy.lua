local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Extras for every install
local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.toml" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
}

-- Plus lua/profiles/<name>.lua for each profile picked at install time,
-- read from the same places as .shellrc: $DOTFILES_PROFILES, else the
-- installer's ~/.config/dotfiles/profiles.
local profiles = vim.env.DOTFILES_PROFILES or vim.env.DOTFILES_PROFILE
if not profiles then
  local f = io.open((vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config") .. "/dotfiles/profiles")
  profiles = f and f:read("*a") or ""
  if f then
    f:close()
  end
end
local config_dir = vim.fn.stdpath("config")
for name in profiles:gmatch("%S+") do
  if name == "devops" then -- split into k8s and iac
    vim.list_extend(spec, { { import = "profiles.k8s" }, { import = "profiles.iac" } })
  elseif vim.uv.fs_stat(config_dir .. "/lua/profiles/" .. name .. ".lua") then
    spec[#spec + 1] = { import = "profiles." .. name }
  end
end

-- import/override with your plugins
spec[#spec + 1] = { import = "plugins" }

require("lazy").setup({
  spec = spec,
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
