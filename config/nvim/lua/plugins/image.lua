-- Render images and ```mermaid blocks inline (needs Ghostty/Kitty/WezTerm + mmdc)
return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = {
        inline = true, -- render diagrams in place of the code block
        float = true, -- fallback: show in a float when cursor is on it
      },
    },
  },
}
