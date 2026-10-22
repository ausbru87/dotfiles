-- <leader>cp: over SSH, serve on the network and show the URL instead of
-- trying to open a browser on the server.
local remote = require("config.remote")

return {
  "iamcco/markdown-preview.nvim",
  init = function()
    if not remote.is_remote() then
      return
    end
    vim.g.mkdp_open_to_the_world = 1
    vim.g.mkdp_open_ip = remote.host()
    vim.g.mkdp_port = tostring(remote.markdown_port)
    vim.cmd([[
      function! MkdpShowUrl(url)
        call luaeval('require("config.remote").show_url(_A)', a:url)
      endfunction
    ]])
    vim.g.mkdp_browserfunc = "MkdpShowUrl"
  end,
}
