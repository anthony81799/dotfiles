local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  install = {
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { "blue" },
  },
  -- ui config
  ui = {
    border = "rounded",
    size = {
      width = 0.8,
      height = 0.8,
    },
    backdrop = 100,
  },
  spec = {
    -- for color highlighting
    -- Tailwind Classes are also supported(properly colored)
    {
      'brenoprata10/nvim-highlight-colors',
      config = function()
        require('nvim-highlight-colors').setup({
          enable_tailwind = true,
        })
      end,
    },
    -- Visible Indentation
    {
      "lukas-reineke/indent-blankline.nvim",
      tag = 'v3.5.4',
      event = "InsertEnter",
      opts = {
        indent = {
          char = "│",
          tab_char = "│",
        },
        scope = { enabled = false },
        exclude = {
          filetypes = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "Trouble",
            "trouble",
            "lazy",
            "mason",
            "notify",
            "toggleterm",
            "lazyterm",
          },
        },
      },
      main = "ibl",
    },
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.6',
      -- or                              , branch = '0.1.x',
      dependencies = { 'nvim-lua/plenary.nvim' },
      opts = {
        set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
      },
    },
    -- for unix commands inside vim
    {
      "tpope/vim-eunuch",
      event = "VeryLazy",
    },
    -- for lsp configuration (Neovim's Native LSP client)
    {
      "neovim/nvim-lspconfig",
      event = { "BufReadPost", "BufNewFile" },
      cmd = { "LspInfo", "LspInstall", "LspUninstall" },
      config = function()
        require("neodev").setup({
          library = {
            enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
            -- these settings will be used for your Neovim config directory
            runtime = true, -- runtime path
            types = true, -- full signature, docs and completion of vim.api, vim.treesitter, vim.lsp and others
            plugins = true, -- installed opt or start plugins in packpath
            -- you can also specify the list of plugins to make available as a workspace library
            -- plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
          },
          setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
          -- With lspconfig, Neodev will automatically setup your lua-language-server
          -- If you disable this, then you have to set {before_init=require("neodev.lsp").before_init}
          -- in your lsp start options
          lspconfig = false,
          -- much faster, but needs a recent built of lua-language-server
          -- needs lua-language-server >= 3.6.0
          pathStrict = true,
        })
      end,
      dependencies = {
        { "folke/neodev.nvim", event = "VeryLazy" },
        {
          "j-hui/fidget.nvim", -- Useful status updates for LSP
          config = function()
            require("fidget").setup {
              sources = { -- Sources to configure
                jdtls = { -- Name of source
                  ignore = true, -- Ignore notifications from this source
                },
              },
            }
          end,
        },
        {
          "williamboman/mason.nvim",
          cmd = {
            "Mason",
            "MasonInstall",
            "MasonUninstall",
            "MasonUninstallAll",
            "MasonLog",
          }, -- Package Manager
          dependencies = "williamboman/mason-lspconfig.nvim",
          config = function()
            local mason = require("mason")
            local mason_lspconfig = require("mason-lspconfig")
            local lspconfig = require("lspconfig")

            require("lspconfig.ui.windows").default_options.border = "rounded"


            mason.setup({
              ui = {
                -- Whether to automatically check for new versions when opening the :Mason window.
                check_outdated_packages_on_open = false,
                border = "single",
                icons = {
                  package_installed = "",
                  package_pending = "",
                  package_uninstalled = "󰚌",
                },
              },
            })


            mason_lspconfig.setup_handlers({
              function(server_name)
                if server_name ~= "jdtls" then
                  local opts = {}

                  local require_ok, server = pcall(require, "plugins.lsp.settings." .. server_name)
                  if require_ok then
                    opts = vim.tbl_deep_extend("force", server, opts)
                  end

                  lspconfig[server_name].setup(opts)
                end
              end,
            })
          end,
        },
      },
    },
    { -- for better syntax highlighting
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      lazy = false,
      config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
          ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "elixir", "javascript", "html" },
          sync_install = false,
          auto_install = true,
          highlight = { enable = true, additional_vim_regex_highlighting = false, },
          indent = { enable = true },
        })
      end
    },
    -- for commenting lines and blocks of code
    {
      "numToStr/Comment.nvim",
      event = "VeryLazy",
      -- enabled = false,
      config = function()
        require("Comment").setup({
          ---Add a space b/w comment and the line
          padding = true,
          ---Whether the cursor should stay at its position
          sticky = true,
          ---Lines to be ignored while (un)comment
          ignore = nil,
          ---LHS of toggle mappings in NORMAL mode
          toggler = {
            ---Line-comment toggle keymap
            line = '<leader>/',
            ---Block-comment toggle keymap
            block = 'gbc',
          },
          ---LHS of operator-pending mappings in NORMAL and VISUAL mode
          opleader = {
            ---Line-comment keymap
            line = '<leader>/',
            ---Block-comment keymap
            block = '<leader>tb',
          },
          ---LHS of extra mappings
          extra = {
            ---Add comment on the line above
            above = 'gcO',
            ---Add comment on the line below
            below = 'gco',
            ---Add comment at the end of line
            eol = 'gcA',
          },
          ---Enable keybindings
          ---NOTE: If given `false` then the plugin won't create any mappings
          mappings = {
            ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
            basic = true,
            ---Extra mapping; `gco`, `gcO`, `gcA`
            extra = true,
          },
          ---Function to call before (un)comment
          pre_hook = nil,
          ---Function to call after (un)comment
          post_hook = nil, --
        })
      end

    },
    -- for autocompletion
    {
      "hrsh7th/nvim-cmp",
      event = {
        "InsertEnter",
        "CmdlineEnter"
      },
      dependencies = {
        "hrsh7th/cmp-buffer",         -- Buffer Completions
        "hrsh7th/cmp-path",           -- Path Completions
        "saadparwaiz1/cmp_luasnip",   -- Snippet Completions
        "hrsh7th/cmp-nvim-lsp",       -- LSP Completions
        "hrsh7th/cmp-nvim-lua",       -- Lua Completions
        "hrsh7th/cmp-cmdline",        -- CommandLine Completions
        "L3MON4D3/LuaSnip",           -- Snippet Engine
        "rafamadriz/friendly-snippets", -- Bunch of Snippets
        "windwp/nvim-autopairs",      -- autopairs
        "onsails/lspkind.nvim",       -- vscode like pictograms
      },
      config = function()
        local cmp = require "cmp"
        local luasnip = require "luasnip"

        require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.fn.stdpath "config" .. "/snippets/snipmate" }
        require("luasnip.loaders.from_vscode").lazy_load()
        -- require("luasnip.loaders.from_vscode").lazy_load { paths = vim.fn.stdpath "config" .. "/snippets/vscode" }

        local kind_icons = {
          Namespace = "󰌗",
          Text = "󰉿",
          Method = "󰆧",
          Function = "󰡱 ",
          Constructor = "",
          Field = "󰜢",
          Private = "",
          Variable = "󰀫",
          Class = "󰠱",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈚",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "󰊄",
          Table = " ",
          Object = "󰅩 ",
          Tag = " ",
          Array = "[]",
          Boolean = " ",
          Number = " ",
          Null = "󰟢 ",
          String = " ",
          Calendar = " ",
          Watch = "󰥔 ",
          Package = "󰏖 ",
          Copilot = " ",
          Codeium = " ",
          TabNine = " ",
          Supermaven = " ",
        }

        cmp.setup {
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body) -- For `luasnip` users.
            end,
          },

          mapping = cmp.mapping.preset.insert {
            ["<C-k>"] = cmp.mapping.select_prev_item(),
            ["<C-j>"] = cmp.mapping.select_next_item(),
            ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1)),
            ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1)),
            ---@diagnostic disable-next-line: missing-parameter
            ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
            -- Abort auto completion
            ["<C-c>"] = cmp.mapping {
              i = cmp.mapping.abort(),
              c = cmp.mapping.close(),
            },
            -- Accept currently selected item. If none selected, `select` first item.
            -- Set `select` to `false` to only confirm explicitly selected items.
            ["<CR>"] = cmp.mapping.confirm { select = false },
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expandable() then
                luasnip.expand()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, {
              "i",
              "s",
            }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, {
              "i",
              "s",
            }),
          },
          formatting = {
            format = function(_, vim_item)
              vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)
              return vim_item
            end,
          },
          sources = {
            { name = "nvim_lsp" },
            { name = "nvim_lua" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path" },
          },
          confirm_opts = {
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
          },
          experimental = {
            ghost_text = true,
          },
        }

        cmp.setup.cmdline(":", {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = "cmdline" },
          },
          formatting = {
            -- fields = { 'abbr' },
            format = function(_, vim_item)
              vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)
              return vim_item
            end,
          },
        })
      end,
    },
    {
      'windwp/nvim-autopairs',
      event = "VeryLazy",
      -- enabled = false,
      dependencies = { "hrsh7th/nvim-cmp" },
      config = function()
        require('nvim-autopairs').setup({
          check_ts = true,
          ts_config = {
            lua = { "string", "source" },
            javascript = { "string", "template_string" },
            java = false,
          },
          disable_filetype = { "TelescopePrompt", "spectre_panel", "vim" },
          fast_wrap = {
            map = "<M-e>",
            chars = { "{", "[", "(", '"', "'" },
            pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
            offset = 0, -- Offset from pattern match
            end_key = "$",
            keys = "qwertyuiopzxcvbnmasdfghjkl",
            check_comma = true,
            highlight = "PmenuSel",
            highlight_grey = "LineNr",
          },
        })
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        local cmp = require('cmp')
        cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' } }))
      end

    },
    -- to undo any changes
    { "mbbill/undotree" },
    { "nvim-tree/nvim-web-devicons", lazy = true },
    {
      'akinsho/bufferline.nvim',
      version = "*",
      -- enabled = false,
      dependencies = 'nvim-tree/nvim-web-devicons',
      event = "BufWinEnter",
      config = function()
        local status_ok, bufferline = pcall(require, "bufferline")
        if not status_ok then return end
        require("bufferline").setup({
          options = {
            offsets = {
              {
                filetype = "neo-tree",
                text = "EXPLORER",
                padding = 0,
                text_align = "center",
                highlight = "Offset",
              },
              {
                filetype = "NvimTree",
                text = "EXPLORER",
                padding = 0,
                text_align = "center",
                highlight = "Offset",
              },
            },
            modified_icon = "●",
            -- close_icon = "",
            -- close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
            max_name_length = 18,
            max_prefix_length = 15,     -- prefix used when a buffer is de-duplicated
            truncate_names = true,      -- whether or not tab names should be truncated
            tab_size = 18,
            diagnostics = "nvim_lsp",   -- | "nvim_lsp" | "coc",
            -- separator_style = "slant", -- | "thick" | "thin" | "slope" | { 'any', 'any' },
            separator_style = { "", "" }, -- | "thick" | "thin" | { 'any', 'any' },
            indicator = {
              -- icon = " ",
              -- style = 'icon',
              -- style = "underline",
            },

            numbers = "none",                      -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
            -- close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
            right_mouse_command = "vert sbuffer %d", -- can be a string | function, see "Mouse actions"
            left_mouse_command = "buffer %d",      -- can be a string | function, see "Mouse actions"
            middle_mouse_command = nil,            -- can be a string | function, see "Mouse actions"
            -- NOTE: this plugin is designed with this icon in mind,
            -- and so changing this is NOT recommended, this is intended
            -- as an escape hatch for people who cannot bear it for whatever reason
            buffer_close_icon = "",
            close_icon = '',
            left_trunc_marker = "",
            right_trunc_marker = "",
            diagnostics_update_in_insert = false,
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
              if count > 9 then return "9+" end
              return tostring(count)
            end,
            color_icons = true,
            show_buffer_icons = true,
            show_buffer_close_icons = true,
            show_close_icon = true,
            show_tab_indicators = true,
            show_duplicate_prefix = true,
            enforce_regular_tabs = false,
            persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
            -- can also be a table containing 2 custom separators
            -- [focused and unfocused]. eg: { '|', '|' }
            always_show_bufferline = true,
            sort_by = "insert_after_current",
            -- sort_by = 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
            --   -- add custom logic
            --   return buffer_a.modified > buffer_b.modified
            -- end
            hover = {
              enabled = true,
              delay = 0,
              reveal = { "close" },
            },
          },
        })
        vim.cmd [[
            nnoremap <silent><TAB> :BufferLineCycleNext<CR>
            nnoremap <silent><S-TAB> :BufferLineCyclePrev<CR>
        ]]
      end
    },
    {
      "akinsho/toggleterm.nvim",
      config = function()
        local execs = {
          { nil, "<space>th", "Horizontal Terminal", "horizontal", 0.3 },
          { nil, "<space>tv", "Vertical Terminal",   "vertical",   0.4 },
          { nil, "<space>tf", "Float Terminal",      "float",      nil },
        }

        local function get_buf_size()
          local cbuf = vim.api.nvim_get_current_buf()
          local bufinfo = vim.tbl_filter(function(buf)
            return buf.bufnr == cbuf
          end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]
          if bufinfo == nil then
            return { width = -1, height = -1 }
          end
          return { width = bufinfo.width, height = bufinfo.height }
        end

        local function get_dynamic_terminal_size(direction, size)
          size = size
          if direction ~= "float" and tostring(size):find(".", 1, true) then
            size = math.min(size, 1.0)
            local buf_sizes = get_buf_size()
            local buf_size = direction == "horizontal" and buf_sizes.height or buf_sizes.width
            return buf_size * size
          else
            return size
          end
        end

        local exec_toggle = function(opts)
          local Terminal = require("toggleterm.terminal").Terminal
          local term = Terminal:new { cmd = opts.cmd, count = opts.count, direction = opts.direction }
          term:toggle(opts.size, opts.direction)
        end

        local add_exec = function(opts)
          local binary = opts.cmd:match "(%S+)"
          if vim.fn.executable(binary) ~= 1 then
            vim.notify("Skipping configuring executable " .. binary .. ". Please make sure it is installed properly.")
            return
          end

          vim.keymap.set( "n", opts.keymap, function()
            exec_toggle { cmd = opts.cmd, count = opts.count, direction = opts.direction, size = opts.size() }
          end, { desc = opts.label, noremap = true, silent = true })
        end

        for i, exec in pairs(execs) do
          local direction = exec[4]

          local opts = {
            cmd = exec[1] or vim.o.shell,
            keymap = exec[2],
            label = exec[3],
            count = i + 100,
            direction = direction,
            size = function()
              return get_dynamic_terminal_size(direction, exec[5])
            end,
          }

          add_exec(opts)
        end

        vim.cmd [[
          augroup terminal_setup | au!
          autocmd TermOpen * nnoremap <buffer><LeftRelease> <LeftRelease>i
          autocmd TermEnter * startinsert!
          augroup end
          ]]

        vim.api.nvim_create_autocmd({ "TermEnter" }, {
          pattern = { "*" },
          callback = function()
            vim.cmd "startinsert"
            _G.set_terminal_keymaps()
          end,
        })

        local opts = { noremap = true, silent = true }
        function _G.set_terminal_keymaps()
          vim.api.nvim_buf_set_keymap(0, "t", "<C-n><C-h>", [[<C-\><C-n><C-W>h]], opts)
          vim.api.nvim_buf_set_keymap(0, "t", "<C-n><C-j>", [[<C-\><C-n><C-W>j]], opts)
          vim.api.nvim_buf_set_keymap(0, "t", "<C-n><C-k>", [[<C-\><C-n><C-W>k]], opts)
          vim.api.nvim_buf_set_keymap(0, "t", "<C-n><C-l>", [[<C-\><C-n><C-W>l]], opts)
          vim.api.nvim_buf_set_keymap(0, "t", "<C-n>", [[<C-\><C-n>]], opts)
        end
      end
    },
    {
      "lewis6991/gitsigns.nvim",
      event = "VeryLazy",
      opts = {
        signs = {
          add = { text = " " },
          change = { text = " " },
          delete = { text = "󰍵" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "│" },
        },
      },
      config = function(_, opts)
        require("gitsigns").setup(opts)
      end,
    },
    -- top-notch colorschemes
    { "notken12/base46-colors" },
    { "rebelot/kanagawa.nvim" },
    { "EdenEast/nightfox.nvim" },
    {
      'AlexvZyl/nordic.nvim',
      lazy = false,
      priority = 1000,
    },
    {
      "neanias/everforest-nvim",
      version = false,
      lazy = false,
      priority = 1000, -- make sure to load this before all the other start plugins
    },
    { "lunarvim/darkplus.nvim" },
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
    },
    { 'mountain-theme/vim' },
    { "oxfist/night-owl.nvim" },
    { "folke/tokyonight.nvim" },
    { "dgox16/oldworld.nvim" },
    { "eldritch-theme/eldritch.nvim" },
    { "savq/melange-nvim" },
    { "Mofiqul/adwaita.nvim" },
    {
      "scottmckendry/cyberdream.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        require("cyberdream").setup({
          -- transparent = true,
          italic_comments = true,
          hide_fillchars = true,
          borderless_telescope = true,
          terminal_colors = true,
        })
        -- vim.cmd("colorscheme cyberdream") -- set the colorscheme
      end,
    },
    -- for better neovim built-in lsp experience
    {
      'nvimdev/lspsaga.nvim',
      event = "VeryLazy",
      config = function()
        require('lspsaga').setup({})
      end,
      dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons',   -- optional
      },
    },
    -- for great git integration in neovim
    -- This is only git plugin a user can need.
    -- Although I provided more below after.
    { "tpope/vim-fugitive" },
    {
      "sindrets/diffview.nvim",
      event = "VeryLazy",
      cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFocusFiles", "DiffviewToggleFiles", "DiffviewRefresh" },
    },
    -- lazygit ui inside Neovim
    {
      "kdheepak/lazygit.nvim",
      -- optional for floating window border decoration
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      event = "VeryLazy",
    },
    -- a plugin, when triggered will show your beloved keybindings,
    -- so that you won't need to memorise them.
    -- needs to be configured properly to show what the keymaps do,
    -- otherwise it will show only the keymaps
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
      end,
      opts = {
        -- your configuration comes here
        -- follow this link - https://github.com/folke/which-key.nvim to know how to configure
        -- which-key based on your own and default plugins keybindings
        -- or leave it empty to use the default settings
      },
    },
    -- ui for messages, commandline & the popupmenu
    {
      "folke/noice.nvim",
      event = "VeryLazy",
      opts = {
        -- add any options here
      },
      dependencies = {
        -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
      },
    },
    {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
        options = {
          theme = "auto",
        },
      },
    },
    -- Beautiful dashboard
    {
      "nvimdev/dashboard-nvim",
      event = "VimEnter",
      opts = function()
        local logo = [[
       ________ ________ ________ ______  ______  ______ ________ __    __ __     __ ______ __       __
      |        \        \        \      \/      \|      \        \  \  |  \  \   |  \      \  \     /  \
      | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓\▓▓▓▓▓▓  ▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ ▓▓\ | ▓▓ ▓▓   | ▓▓\▓▓▓▓▓▓ ▓▓\   /  ▓▓
      | ▓▓__   | ▓▓__   | ▓▓__     | ▓▓ | ▓▓   \▓▓ | ▓▓ | ▓▓__   | ▓▓▓\| ▓▓ ▓▓   | ▓▓ | ▓▓ | ▓▓▓\ /  ▓▓▓
      | ▓▓  \  | ▓▓  \  | ▓▓  \    | ▓▓ | ▓▓       | ▓▓ | ▓▓  \  | ▓▓▓▓\ ▓▓\▓▓\ /  ▓▓ | ▓▓ | ▓▓▓▓\  ▓▓▓▓
      | ▓▓▓▓▓  | ▓▓▓▓▓  | ▓▓▓▓▓    | ▓▓ | ▓▓   __  | ▓▓ | ▓▓▓▓▓  | ▓▓\▓▓ ▓▓ \▓▓\  ▓▓  | ▓▓ | ▓▓\▓▓ ▓▓ ▓▓
      | ▓▓_____| ▓▓     | ▓▓      _| ▓▓_| ▓▓__/  \_| ▓▓_| ▓▓_____| ▓▓ \▓▓▓▓  \▓▓ ▓▓  _| ▓▓_| ▓▓ \▓▓▓| ▓▓
      | ▓▓     \ ▓▓     | ▓▓     |   ▓▓ \\▓▓    ▓▓   ▓▓ \ ▓▓     \ ▓▓  \▓▓▓   \▓▓▓  |   ▓▓ \ ▓▓  \▓ | ▓▓
       \▓▓▓▓▓▓▓▓\▓▓      \▓▓      \▓▓▓▓▓▓ \▓▓▓▓▓▓ \▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓   \▓▓    \▓    \▓▓▓▓▓▓\▓▓      \▓▓


      ]]

        logo = string.rep("\n", 4) .. logo .. "\n\n"

        local opts = {
          theme = "doom",
          hide = {
            -- this is taken care of by lualine
            -- enabling this messes up the actual laststatus setting after loading a file
            statusline = false,
          },
          config = {
            header = vim.split(logo, "\n"),
            -- stylua: ignore
            center = {
              { action = "Telescope find_files", desc = " Find file", icon = " ", key = "<space>ff" },
              { action = "ene | startinsert", desc = " New file", icon = " ", key = "<space>n" },
              { action = "Telescope oldfiles", desc = " Recent files", icon = " ", key = "<space>r" },
              { action = "Telescope live_grep", desc = " Find text", icon = " ", key = "<space>ps" },
              { action = "e ~/.config/nvim/init.lua", desc = " Config", icon = " ", key = "c" },
              { action = "Telescope colorscheme", desc = "  Themes", icon = "", key = "<space>cc" },
              { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
              { action = "qa", desc = " Quit", icon = " ", key = "q" },
            },
            footer = function()
              local stats = require("lazy").stats()
              local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
              return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
            end,
          },
        }

        for _, button in ipairs(opts.config.center) do
          button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
          button.key_format = "  %s"
        end

        -- close Lazy and re-open when the dashboard is ready
        if vim.o.filetype == "lazy" then
          vim.cmd.close()
          vim.api.nvim_create_autocmd("User", {
            pattern = "DashboardLoaded",
            callback = function()
              require("lazy").show()
            end,
          })
        end

        return opts
      end,
    },
    -- plugin to change surroundings of text/code
    {
      "kylechui/nvim-surround",
      version = '*',
      event = "VeryLazy",
      opts = {},
      config = function()
        require("nvim-surround").setup({})
      end
    },
    -- for splitting/joining blocks of code
    {
      'Wansmer/treesj',
      event = "VeryLazy",
      keys = { '<space>m', '<space>j', '<space>s' },
      dependencies = { 'nvim-treesitter/nvim-treesitter' },
      config = function()
        require('treesj').setup({ --[[ your config ]] })
      end,
    },
    -- NOTE : Great Power Comes With Great Responsibility!
    -- in `EFFICIENVIM`, you are given access to harness full power of the terminal
    -- Oil.nvim, Nvim-tree.lua both filesystem plugins can be used whenever wanted.
    -- Also you can call the terminal emulated file manager `Ranger` within Neovim.
    -- REMEMBER: Use this power wisely.
    -- Oil.nvim: file-explorer which makes edit file-system like a buffer
    {
      "stevearc/oil.nvim",
      lazy = false,
      opts = {},
      enabled = true,
      cmd = "Oil",
      keys = {
        { "<space>o", function() require("oil").open() end, desc = "Open folder in Oil" },
      },
    },
    -- NvimTree: file-explorer tree view at left sidebar
    {
      "nvim-tree/nvim-tree.lua",
      name = 'nvim-tree',
    },
    -- call lf within Neovim
    {
    'ptzz/lf.vim',
      dependencies = { 'voldikss/vim-floaterm' },
      config = function()
        vim.g.lf_map_keys = 0
        vim.keymap.set("n", "<leader>lf", function()
          vim.api.nvim_command("Lf")
        end, { desc = "call lf within Neovim" })
      end,
    },
    -- automatic code execution other related works
    {
      "google/executor.nvim",
      event = "VeryLazy",
      dependencies = "MunifTanjim/nui.nvim",
      opts = {},
      cmd = {
        "ExecutorRun",
        "ExecutorSetCommand",
        "ExecutorShowDetail",
        "ExecutorHideDetail",
        "ExecutorToggleDetail",
        "ExecutorSwapToSplit",
        "ExecutorSwapToPopup",
        "ExecutorToggleDetail",
        "ExecutorReset",
      },
    },
    -- Better help with code diagnostics
    {
      "folke/trouble.nvim",
      event = "VeryLazy",
      cmd = { "TroubleToggle", "Trouble" },

      opts = {
        use_diagnostic_signs = true,
        action_keys = {
          close = { "q", "<esc>" },
          cancel = "<c-e>",
        },
      },
    },
    {
      "folke/edgy.nvim",
      event = "VeryLazy",
      optional = true,
      opts = function(_, opts)
        if not opts.bottom then opts.bottom = {} end
        table.insert(opts.bottom, "Trouble")
      end,
    },
    -- provides an explanation for regular expressions
    {
      "tomiis4/Hypersonic.nvim",
      event = "CmdlineEnter",
      cmd = "Hypersonic",
      opts = {},
    },
    -- Color picker plugin for Neovim
    {
      "ziontee113/color-picker.nvim",
      config = function()
        require("color-picker")
      end,
      vim.keymap.set(
        "n",
        "<leader>cp",
        "<cmd>PickColor<cr>",
        { desc = "Pick Color" }
      ) --> Paste the selected color into cursor position
    },
    -- Icon picker plugin for Neovim
    {
      "ziontee113/icon-picker.nvim",
      dependencies = { "stevearc/dressing.nvim" },
      config = function()
        require("icon-picker").setup({ disable_legacy_commands = true })

        local opts = { noremap = true, silent = true }

        vim.keymap.set(
          "n",
          "<Leader><Leader>i",
          "<cmd>IconPickerNormal<cr>",
          opts
        )
        vim.keymap.set(
          "n",
          "<Leader><Leader>y",
          "<cmd>IconPickerYank<cr>",
          opts
        ) --> Yank the selected icon into register
        vim.keymap.set("i", "<C-i>", "<cmd>IconPickerInsert<cr>", opts)
      end
    },
    --[[   -- replace strings in selected files using regex in your project directory
  { "nvim-pack/nvim-spectre", event = "VeryLazy"}, ]]
    -- multicursor support with Vim-Visual-Multi
    -- when in NORMAL Mode, click <Esc> to exit Vim-Visual-Multi
    {
      'mg979/vim-visual-multi',
      branch = 'master',
      event = "VeryLazy",
      config = function()
        -- enabling Ctrl+leftmouse to create a cursor at each & every clicked position in NORMAL Mode
        vim.keymap.set('n', "<C-LeftMouse>", "<Plug>(VM-Mouse-Cursor)", { desc = "vscode style multicursor mode" })
      end
    },
    -- for formatting and linting
    {
      "nvimtools/none-ls.nvim",
      dependencies = {
        "nvimtools/none-ls-extras.nvim",
        "gbprod/none-ls-shellcheck.nvim",
      },
      config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
          debug = true,
          sources = {
            -- null_ls.builtins.formatting.stylua,
            null_ls.builtins.formatting.prettier,
            null_ls.builtins.formatting.black,
            require("none-ls-shellcheck.diagnostics"),
            require("none-ls-shellcheck.code_actions"),
            require("none-ls.diagnostics.eslint_d").with({
              condition = function(utls)
                return utls.root_has_file({
                  ".eslintrc.js",
                  ".eslintrc.mjs",
                  ".eslintrc.cjs",
                  ".eslintrc.yaml",
                  ".eslintrc.yml",
                  ".eslintrc.json",
                })
              end,
            }),
          },
        })

        vim.keymap.set("n", "<space>fr", vim.lsp.buf.format, { desc = "format document" })
      end,
    },
    -- Highlight, list and search todo comments in your projects
    {
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = {},
    },
    -- for previewing markdown files
    {
      "ellisonleao/glow.nvim",
      cmd = "Glow",
      config = function()
        require("glow").setup({
          border = "rounded",
        })
      end,
    },
    -- to enable AI code completion through supermaven
    -- {
    --   "supermaven-inc/supermaven-nvim",
    --   config = function()
    --     require("supermaven-nvim").setup({
    --       keymaps = {
    --         accept_suggestion = "<Tab>",
    --         clear_suggestion = "<C-x>",
    --         accept_word = "<C-j>",
    --       },
    --     })
    --     vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", {fg ="#6CC644"})
    --   end,
    -- },
    -- to enable AI code completion through codeium
		-- {
    --   "Exafunction/codeium.vim",
    --   event = 'BufEnter',
    --   config = function()
    --     -- Changed '<C-g>' here to '<C-y>' to make it work.
    --     vim.keymap.set('i', '<C-y>', function() return vim.fn['codeium#Accept']() end, { expr = true })
    --     vim.keymap.set('i', '<c-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true })
    --     vim.keymap.set('i', '<c-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true })
    --     vim.keymap.set('i', '<c-x>', function() return vim.fn['codeium#Clear']() end, { expr = true })
    --   end
    -- },
		{
			"ThePrimeagen/harpoon",
			branch = "harpoon2",
			dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
			config = function()
				require("harpoon"):setup()
			end,
			keys = {
				{ "<leader>ha", function() require("harpoon"):list():append() end,                                              desc = "harpoon add file" },
				{ "<leader>hl", function()
					local harpoon = require("harpoon")
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end,                                                                                                            desc = "harpoon quick menu" },
				{ "<leader>h1", function() require("harpoon"):list():select(1) end,                                             desc = "harpoon file 1" },
				{ "<leader>h2", function() require("harpoon"):list():select(2) end,                                             desc = "harpoon file 2" },
				{ "<leader>h3", function() require("harpoon"):list():select(3) end,                                             desc = "harpoon file 3" },
				{ "<leader>h4", function() require("harpoon"):list():select(4) end,                                             desc = "harpoon file 4" },
				{ "<leader>hP", function() require("harpoon"):list():prev() end,                                                desc = "toggle previous buffer" },
				{ "<leader>hN", function() require("harpoon"):list():next() end,                                                desc = "toggle next buffer" },
			}
		},
  }
})
