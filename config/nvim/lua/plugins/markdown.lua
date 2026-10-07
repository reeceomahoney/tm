return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "mdformat" },
      },
      formatters = {
        -- Matches the pre-commit hook: mdformat + mdformat-gfm, wrapped at 80.
        -- Installed with: uv tool install mdformat --with mdformat-gfm
        mdformat = { args = { "--wrap", "80", "-" } },
      },
    },
  },
}
