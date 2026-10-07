return {
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = vim.fn.has("mac") == 1 and "skim" or "zathura"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_mappings_prefix = "<localleader>"
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        tex = { "tex-fmt" },
      },
    },
  },
}
