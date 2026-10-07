-- Colorscheme. On Omarchy, follow the system theme; everywhere else use tokyonight.
local omarchy = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(omarchy) == 1 then
  return dofile(omarchy)
end

return {
  { "folke/tokyonight.nvim", opts = { style = "night" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
}
