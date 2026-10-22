-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Mermaid: render the ```mermaid block under the cursor (or every block in the
-- file if the cursor isn't in one) to SVG and open it in the browser.
local function mermaid_blocks()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local blocks, start = {}, nil
  for i, l in ipairs(lines) do
    if not start and l:match("^%s*```+%s*mermaid") then
      start = i
    elseif start and l:match("^%s*```+%s*$") then
      local b = { from = start, to = i, text = table.concat(lines, "\n", start + 1, i - 1) }
      if cur >= start and cur <= i then
        return { b }
      end
      table.insert(blocks, b)
      start = nil
    end
  end
  return blocks
end

vim.keymap.set("n", "<leader>md", function()
  local blocks = mermaid_blocks()
  if #blocks == 0 then
    return vim.notify("No mermaid blocks found", vim.log.levels.WARN)
  end
  -- not tempname(): nvim deletes that dir on exit, possibly before the browser loads it
  local remote = require("config.remote")
  local root = vim.fn.stdpath("cache") .. "/mermaid"
  local stamp = tostring(os.time())
  local dir = root .. "/" .. stamp
  vim.fn.mkdir(dir, "p")
  local svgs, pending = {}, #blocks
  for i, b in ipairs(blocks) do
    local src, out = dir .. "/" .. i .. ".mmd", dir .. "/" .. i .. ".svg"
    vim.fn.writefile(vim.split(b.text, "\n"), src)
    -- --no-sandbox config lets Chromium run as root on Linux servers
    local cmd = { "mmdc", "-q", "-i", src, "-o", out, "-b", "white" }
    local pptr = vim.fn.stdpath("config") .. "/mermaid-puppeteer.json"
    if vim.fn.filereadable(pptr) == 1 then
      vim.list_extend(cmd, { "-p", pptr })
    end
    vim.system(cmd, {}, function(res)
      vim.schedule(function()
        svgs[i] = res.code == 0 and table.concat(vim.fn.readfile(out), "\n")
          or ("<pre>mmdc failed (line " .. b.from .. "):\n" .. (res.stderr or "") .. "</pre>")
        pending = pending - 1
        if pending > 0 then
          return
        end
        local html = { "<!doctype html><meta charset=utf-8><title>" .. vim.fn.expand("%:t") .. "</title>",
          "<style>body{margin:24px;font-family:sans-serif;background:#fff}section{margin-bottom:48px}svg{max-width:none!important;height:auto}</style>" }
        for j, s in ipairs(svgs) do
          table.insert(html, "<section><small>diagram " .. j .. "</small><br>" .. s .. "</section>")
        end
        local page = dir .. "/index.html"
        vim.fn.writefile(vim.split(table.concat(html, "\n"), "\n"), page)
        if remote.is_remote() then
          remote.show_url(remote.serve(root, remote.mermaid_port) .. "/" .. stamp .. "/index.html")
        else
          vim.ui.open(page)
        end
      end)
    end)
  end
end, { desc = "Mermaid: open diagram in browser" })
