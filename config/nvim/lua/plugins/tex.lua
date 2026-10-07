return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        tex = { "tex-fmt" },
        plaintex = { "tex-fmt" },
      },
      formatters = {
        -- -s: read stdin/write stdout. Wrapping is on by default at -l 80.
        ["tex-fmt"] = { args = { "-s", "--wraplen", "80" } },
      },
    },
  },
}
