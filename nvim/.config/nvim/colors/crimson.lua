local opts = vim.deepcopy(require("config.themes.crimson"))

opts.name = "crimson"

require("aether.config").setup(opts)
require("aether").load()
