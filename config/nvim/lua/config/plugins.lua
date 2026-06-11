vim.pack.add({
	"https://www.github.com/echasnovski/mini.nvim",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
	},
	-- Language Server Protocols
	"https://www.github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/creativenull/efmls-configs-nvim",
	{
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/mrcjkb/rustaceanvim",
	"https://github.com/folke/zen-mode.nvim",
	"https://github.com/folke/which-key.nvim",
	{
		src = "https://github.com/MunifTanjim/nui.nvim",
	},
	{
		src = "https://github.com/m4xshen/hardtime.nvim",
		version = vim.version.range("1.*"),
	},
	"https://github.com/folke/trouble.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/stevearc/oil.nvim",
	{
		src = "https://github.com/ThePrimeagen/harpoon",
		version = "harpoon2",
	},
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
})

local setup_treesitter = function()
	local treesitter = require("nvim-treesitter")
	treesitter.setup({})
	local ensure_installed = {
		"vim",
		"vimdoc",
		"rust",
		"c",
		"cpp",
		"go",
		"html",
		"css",
		"javascript",
		"json",
		"lua",
		"markdown",
		"python",
		"typescript",
		"vue",
		"svelte",
		"bash",
	}

	local config = require("nvim-treesitter.config")

	local already_installed = config.get_installed()
	local parsers_to_install = {}

	for _, parser in ipairs(ensure_installed) do
		if not vim.tbl_contains(already_installed, parser) then
			table.insert(parsers_to_install, parser)
		end
	end

	if #parsers_to_install > 0 then
		treesitter.install(parsers_to_install)
	end

	local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			if vim.list_contains(config.get_installed(), vim.treesitter.language.get_lang(args.match)) then
				vim.treesitter.start(args.buf)
			end
		end,
	})
end

setup_treesitter()

require("mini.ai").setup({})
require("mini.comment").setup({})
require("mini.move").setup({})
require("mini.surround").setup({})
require("mini.cursorword").setup({})
require("mini.indentscope").setup({})
require("mini.pairs").setup({})
require("mini.trailspace").setup({})
require("mini.bufremove").setup({})
require("mini.notify").setup({})
require("mini.icons").setup({})

require("mini.diff").setup({
	view = {
		style = "sign",
		signs = { add = "▎", change = "▎", delete = "▎" },
	},
})

require("mini.git").setup({})

local MiniDiff = require("mini.diff")
vim.keymap.set("n", "]h", function()
	MiniDiff.goto_hunk("next")
end, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", function()
	MiniDiff.goto_hunk("prev")
end, { desc = "Prev git hunk" })
vim.keymap.set("n", "<leader>hs", MiniDiff.operator, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hp", function()
	MiniDiff.toggle_overlay()
end, { desc = "Preview diff overlay" })
vim.keymap.set("n", "<leader>hb", function()
	require("mini.git").show_at_cursor()
end, { desc = "Git blame/show" })

require("mason").setup({})

require("mason-tool-installer").setup({
	ensure_installed = {
		-- LSP servers
		"pyright",
		"bash-language-server",
		"typescript-language-server",
		"clangd",

		-- linters/formatters used by the efm config below
		"luacheck",
		"stylua",
		"flake8",
		"black",
		"prettierd",
		"eslint_d",
		"fixjson",
		"shellcheck",
		"shfmt",
		"cpplint",
		"clang-format",
		"revive",
		"gofumpt",
	},
})

require("zen-mode").setup({})
require("which-key").setup({})
require("hardtime").setup({ restriction_mode = "hint" })
require("trouble").setup({})
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set(
	"n",
	"<leader>xX",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Buffer Diagnostics (Trouble)" }
)
vim.keymap.set(
	"n",
	"<leader>cs",
	"<cmd>Trouble symbols toggle focus=false<cr>",
	{ desc = "Symbols (Trouble)" }
)
vim.keymap.set(
	"n",
	"<leader>cl",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	{ desc = "LSP Definitions / references / ... (Trouble)" }
)
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

require("telescope").setup({})
local telescope_builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", telescope_builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", telescope_builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", telescope_builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", telescope_builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fx", function()
	telescope_builtin.diagnostics({ bufnr = 0 })
end, { desc = "Telescope document diagnostics" })
vim.keymap.set("n", "<leader>fX", telescope_builtin.diagnostics, { desc = "Telescope workspace diagnostics" })

require("oil").setup({})
vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>a", function()
	harpoon:list():add()
end, { desc = "Harpoon: add file" })

vim.keymap.set("n", "<C-h>", function()
	harpoon:list():select(1)
end, { desc = "Harpoon: select file 1" })
vim.keymap.set("n", "<C-t>", function()
	harpoon:list():select(2)
end, { desc = "Harpoon: select file 2" })
vim.keymap.set("n", "<C-n>", function()
	harpoon:list():select(3)
end, { desc = "Harpoon: select file 3" })
vim.keymap.set("n", "<C-s>", function()
	harpoon:list():select(4)
end, { desc = "Harpoon: select file 4" })

vim.keymap.set("n", "<C-S-P>", function()
	harpoon:list():prev()
end, { desc = "Harpoon: previous file" })
vim.keymap.set("n", "<C-S-N>", function()
	harpoon:list():next()
end, { desc = "Harpoon: next file" })

local function harpoon_telescope(harpoon_files)
	local conf = require("telescope.config").values
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Harpoon",
			finder = require("telescope.finders").new_table({
				results = file_paths,
			}),
			previewer = conf.file_previewer({}),
			sorter = conf.generic_sorter({}),
		})
		:find()
end

vim.keymap.set("n", "<C-e>", function()
	harpoon_telescope(harpoon:list())
end, { desc = "Harpoon: open Telescope window" })
