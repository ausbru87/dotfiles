-- Helpers for previews when nvim runs over SSH (Linux server, iPad, etc.):
-- there is no local browser, so we serve the page and show a URL instead.
--   NVIM_PREVIEW_HOST  host/IP put in the URL (default: the IP you SSH'd to)
--   NVIM_PREVIEW_BIND  address the server listens on (default 0.0.0.0)
local M = {}

M.mermaid_port = 8765
M.markdown_port = 8766

function M.is_remote()
  if vim.env.SSH_CONNECTION then
    return true
  end
  return vim.fn.has("linux") == 1 and not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY
end

function M.host()
  if vim.env.NVIM_PREVIEW_HOST then
    return vim.env.NVIM_PREVIEW_HOST
  end
  local ssh = vim.split(vim.env.SSH_CONNECTION or "", " ")
  return ssh[3] or vim.fn.hostname()
end

function M.bind()
  return vim.env.NVIM_PREVIEW_BIND or "0.0.0.0"
end

local server
-- Serve `root` over HTTP (once per session). If the port is already taken by
-- another nvim serving the same root, that server works just as well.
function M.serve(root, port)
  if not server then
    server = vim.fn.jobstart({ "python3", "-m", "http.server", tostring(port), "--bind", M.bind(), "--directory", root })
  end
  return ("http://%s:%d"):format(M.host(), port)
end

function M.show_url(url)
  vim.fn.setreg("+", url)
  vim.notify("Preview: " .. url .. " (copied)", vim.log.levels.INFO)
end

return M
