local augroup = vim.api.nvim_create_augroup("UserLsp", { clear = true })
local telescope_builtin = require("telescope.builtin")

local diagnostic_signs = {
	Error = "\u{f057} ",
	Warn = "\u{f071} ",
	Hint = "\u{ea61}",
	Info = "\u{f05a}",
}

vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})

-- Neovim's default Diagnostic* highlights don't match retrobox's palette;
-- re-derive them from retrobox's colors so diagnostics blend with the theme.
local function set_retrobox_diagnostic_colors()
	local palette = {
		red = "#fb5944",
		orange = "#fe8019",
		blue = "#83a598",
		aqua = "#8ec07c",
		green = "#b8bb26",
	}

	vim.api.nvim_set_hl(0, "DiagnosticError", { fg = palette.red })
	vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = palette.orange })
	vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = palette.blue })
	vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = palette.aqua })
	vim.api.nvim_set_hl(0, "DiagnosticOk", { fg = palette.green })

	vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { sp = palette.red, underline = true })
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { sp = palette.orange, underline = true })
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { sp = palette.blue, underline = true })
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { sp = palette.aqua, underline = true })
end

-- Mason hardcodes its own accent palette (gold/cyan/gray on #222222) instead of
-- linking to theme groups; re-derive it from retrobox's colors so its UI blends in.
local function set_retrobox_mason_colors()
	local palette = {
		bg = "#1c1c1c",
		gray = "#928374",
		green = "#b8bb26",
		orange = "#fe8019",
	}

	vim.api.nvim_set_hl(0, "MasonHeader", { bold = true, fg = palette.bg, bg = palette.orange })
	vim.api.nvim_set_hl(0, "MasonHeaderSecondary", { bold = true, fg = palette.bg, bg = palette.green })

	vim.api.nvim_set_hl(0, "MasonHighlight", { fg = palette.green })
	vim.api.nvim_set_hl(0, "MasonHighlightBlock", { bg = palette.green, fg = palette.bg })
	vim.api.nvim_set_hl(0, "MasonHighlightBlockBold", { bg = palette.green, fg = palette.bg, bold = true })

	vim.api.nvim_set_hl(0, "MasonHighlightSecondary", { fg = palette.orange })
	vim.api.nvim_set_hl(0, "MasonHighlightBlockSecondary", { bg = palette.orange, fg = palette.bg })
	vim.api.nvim_set_hl(0, "MasonHighlightBlockBoldSecondary", { bg = palette.orange, fg = palette.bg, bold = true })

	vim.api.nvim_set_hl(0, "MasonMuted", { fg = palette.gray })
	vim.api.nvim_set_hl(0, "MasonMutedBlock", { bg = palette.gray, fg = palette.bg })
	vim.api.nvim_set_hl(0, "MasonMutedBlockBold", { bg = palette.gray, fg = palette.bg, bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup,
	pattern = "retrobox",
	desc = "Re-derive diagnostic and Mason colors from the retrobox palette",
	callback = function()
		set_retrobox_diagnostic_colors()
		set_retrobox_mason_colors()
	end,
})

set_retrobox_diagnostic_colors()
set_retrobox_mason_colors()

do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }

	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
	end

	map("<leader>gd", telescope_builtin.lsp_definitions, "Telescope LSP definitions")

	map("<leader>gD", vim.lsp.buf.definition, "Go to definition")

	map("<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, "Go to definition in vertical split")

	map("<leader>ca", vim.lsp.buf.code_action, "Code action")
	map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")

	map("<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, "Show line diagnostics (float)")
	map("<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, "Show diagnostic under cursor (float)")
	map("<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, "Next diagnostic")

	map("<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, "Previous diagnostic")

	map("K", vim.lsp.buf.hover, "Hover documentation")

	map("<leader>fr", telescope_builtin.lsp_references, "Telescope LSP references")
	map("<leader>ft", telescope_builtin.lsp_type_definitions, "Telescope LSP type definitions")
	map("<leader>fs", telescope_builtin.lsp_document_symbols, "Telescope LSP document symbols")
	map("<leader>fw", telescope_builtin.lsp_workspace_symbols, "Telescope LSP workspace symbols")
	map("<leader>fi", telescope_builtin.lsp_implementations, "Telescope LSP implementations")

	if client:supports_method("textDocument/codeAction", bufnr) then
		map("<leader>oi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50)
		end, "Organize imports and format")
	end
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-Space>"] = { "show", "hide" },
		["<CR>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
	},
	appearance = { nerd_font_variant = "mono" },
	completion = {
		menu = {
			auto_show = function()
				return vim.bo.filetype ~= "markdown"
			end,
		},
	},
	sources = { default = { "lsp", "path", "buffer" } },
	fuzzy = {
		implementation = "prefer_rust",
		prebuilt_binaries = { download = true },
	},
})

vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("pyright", {})
vim.lsp.config("bashls", {})
vim.lsp.config("ts_ls", {})
vim.lsp.config("gopls", {})
vim.lsp.config("clangd", {})

vim.g.rustaceanvim = {
	server = {
		capabilities = require("blink.cmp").get_lsp_capabilities(),
	},
}

do
	local luacheck = require("efmls-configs.linters.luacheck")
	local stylua = require("efmls-configs.formatters.stylua")

	local flake8 = require("efmls-configs.linters.flake8")
	local black = require("efmls-configs.formatters.black")

	local prettier_d = require("efmls-configs.formatters.prettier_d")
	local eslint_d = require("efmls-configs.linters.eslint_d")

	local fixjson = require("efmls-configs.formatters.fixjson")

	local shellcheck = require("efmls-configs.linters.shellcheck")
	local shfmt = require("efmls-configs.formatters.shfmt")

	local cpplint = require("efmls-configs.linters.cpplint")
	local clangfmt = require("efmls-configs.formatters.clang_format")

	local go_revive = require("efmls-configs.linters.go_revive")
	local gofumpt = require("efmls-configs.formatters.gofumpt")

	vim.lsp.config("efm", {
		filetypes = {
			"c",
			"cpp",
			"css",
			"go",
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"jsonc",
			"lua",
			"markdown",
			"python",
			"sh",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
		},
		init_options = { documentFormatting = true },
		settings = {
			languages = {
				c = { clangfmt, cpplint },
				go = { gofumpt, go_revive },
				cpp = { clangfmt, cpplint },
				css = { prettier_d },
				html = { prettier_d },
				javascript = { eslint_d, prettier_d },
				javascriptreact = { eslint_d, prettier_d },
				json = { eslint_d, fixjson },
				jsonc = { eslint_d, fixjson },
				lua = { luacheck, stylua },
				markdown = { prettier_d },
				python = { flake8, black },
				sh = { shellcheck, shfmt },
				typescript = { eslint_d, prettier_d },
				typescriptreact = { eslint_d, prettier_d },
				vue = { eslint_d, prettier_d },
				svelte = { eslint_d, prettier_d },
			},
		},
	})
end

vim.lsp.enable({
	"lua_ls",
	"pyright",
	"bashls",
	"ts_ls",
	"gopls",
	"clangd",
	"efm",
})
