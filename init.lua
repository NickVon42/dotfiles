--[[
=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================

Kickstart.nvim is *not* a distribution.

Kickstart.nvim is a template for your own configuration.
  The goal is that you can read every line of code, top-to-bottom, and understand
  what your configuration is doing.

  Once you've done that, you should start exploring, configuring and tinkering to
  explore Neovim!

  If you don't know anything about Lua, I recommend taking some time to read through
  a guide. One possible example:
  - https://learnxinyminutes.com/docs/lua/

  And then you can explore or search through `:help lua-guide`


Kickstart Guide:

I have left several `:help X` comments throughout the init.lua
You should run that command and read that help section for more information.

In addition, I have some `NOTE:` items throughout the file.
These are for you, the reader to help understand what is happening. Feel free to delete
them once you know what you're doing, but they should serve as a guide for when you
are first encountering a few different constructs in your nvim config.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now :)
--]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.

require("lazy").setup({
  {
    "catppuccin/nvim",
    priority = 1000,
    lazy = false,
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = true,
        dim_inactive = {
          enabled = false,
          shade = "dark",
          percentage = 0.15,
        },
        show_end_of_buffer = true, -- show the '~' characters after the end of buffers
      })
      vim.cmd([[colorscheme catppuccin]])
    end,
  },
  -- NOTE: First, some plugins that don't require any configuration

  --
  -- 'tpope/vim-fugitive',
  -- 'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  {
    "tpope/vim-sleuth",
    event = "BufEnter",
  },

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = "BufEnter",
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        "j-hui/fidget.nvim",
        event = "VeryLazy",
        opts = {},
        config = function()
          require("fidget").setup({
            text = {
              spinner = "arc",
              completed = "", -- message shown when task completes
            },
            align = {
              bottom = false, -- align fidgets along bottom edge of buffer
              right = true, -- align fidgets along right edge of buffer
            },
            timer = {
              spinner_rate = 125, -- frame rate of spinner animation, in ms
              fidget_decay = 2000, -- how long to keep around empty fidget, in ms
              task_decay = 1000, -- how long to keep around completed task, in ms
            },
            window = {
              relative = "editor", -- where to anchor, either "win" or "editor"
              blend = 0,    -- &winblend for the window
              zindex = nil, -- the zindex value for the window
              border = "none", -- style of border for the fidget window
            },
          })
        end,
      },

      -- Additional lua configuration, makes nvim stuff amazing!
      {
        "folke/neodev.nvim",
        ft = "lua",
        config = function()
          -- Setup neovim lua configuration
          require("neodev").setup()
        end,
      },
    },
    config = function()
      -- LSP settings.
      --  This function gets run when an LSP connects to a particular buffer.
      local on_attach = function(_, bufnr)
        -- NOTE: Remember that lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself
        -- many times.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local nmap = function(keys, func, desc)
          if desc then
            desc = "LSP: " .. desc
          end

          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>a", vim.lsp.buf.code_action, "Code [A]ction")

        nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
        nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
        nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- See `:help K` for why this keymap
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

        -- Lesser used LSP functionality
        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap("<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "[W]orkspace [L]ist Folders")

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "Format current buffer with LSP" })
      end

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. They will be passed to
      --  the `settings` field of the server config. You must look up that documentation yourself.
      local servers = {
        clangd = {},
        rust_analyzer = {},
        tsserver = {},
        tailwindcss = {},
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      }

      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- Setup mason so it can manage external tooling
      require("mason").setup()

      -- Ensure the servers above are installed
      local mason_lspconfig = require("mason-lspconfig")

      mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
      })

      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
          })
        end,
      })

      require("lspconfig.autoformat").setup()
      -- This will find your Git repository root and start the tsserver there.
      -- Otherwise, for some inexplicable reason, it appears to start this server in the current user’s home folder.
      require("lspconfig").tsserver.setup({
        root_dir = require("lspconfig.util").root_pattern(".git"),
      })
    end,
  },

  {
    "jose-elias-alvarez/null-ls.nvim",
    event = "BufEnter",
    config = function()
      local null_ls_status_ok, null_ls = pcall(require, "null-ls")

      if null_ls_status_ok then
        local b = null_ls.builtins

        null_ls.setup({
          sources = {
            b.formatting.stylua,
            -- b.completion.spell,
            b.hover.dictionary,
            -- Typescript
            b.formatting.prettierd,
            b.diagnostics.eslint_d,
            b.code_actions.eslint_d,
            -- Rust
            b.formatting.rustfmt,
            -- C++
            b.formatting.clang_format,
          },
        })
      end
    end,
  },

  {
    -- Autocompletion
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      -- disabling luasnip for now
      -- "L3MON4D3/LuaSnip",
      -- "saadparwaiz1/cmp_luasnip"
    },
    config = function()
      -- nvim-cmp setup
      local cmp = require("cmp")
      -- local luasnip = require("luasnip")
      -- luasnip.config.setup({})

      cmp.setup({
        experimental = {
          ghost_text = true,
        },
        window = {
          completion = {
            -- rounded border; thin-style scrollbar
            border = "rounded",
          },
          documentation = {
            border = "rounded",
          },
        },
        -- snippet = {
        --   expand = function(args)
        --     luasnip.lsp_expand(args.body)
        --   end,
        -- },
        mapping = cmp.mapping.preset.insert({
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete({}),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
          }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
              -- elseif luasnip.expand_or_jumpable() then
              --   luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
              -- elseif luasnip.jumpable(-1) then
              --   luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          -- Copilot Source
          { name = "copilot" },
          -- Dont suggest Text from nvm_lsp
          {
            name = "nvim_lsp",
            entry_filter = function(entry, ctx)
              return require("cmp").lsp.CompletionItemKind.Text ~= entry:get_kind()
            end,
          },
          --{ name = "luasnip" },
        }),
      })

      local has_words_before = function()
        if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
          return false
        end
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
            and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
      end
      cmp.setup({
        mapping = {
          ["<Tab>"] = vim.schedule_wrap(function(fallback)
            if cmp.visible() and has_words_before() then
              cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            else
              fallback()
            end
          end),
        },
      })
    end,
  },

  {
    -- Adds git releated signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },

  {
    -- Set lualine as statusline
    "nvim-lualine/lualine.nvim",
    event = "BufEnter",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = true,
        theme = "catppuccin",
        component_separators = "|",
        section_separators = { left = "", right = "" },
      },
    },
  },

  {
    -- Add indentation guides even on blank lines
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    opts = {
      char = "┊",
      show_trailing_blankline_indent = false,
    },
  },

  {
    "ggandor/leap.nvim",
    keys = { "s" },
    config = function()
      require("leap").add_default_mappings()
    end,
  },

  -- "gc" to comment visual regions/lines
  {
    "numToStr/Comment.nvim",
    keys = { "g" },
    config = function()
      require("Comment").setup()
    end,
  },

  --       Old text                    Command         New text
  -- --------------------------------------------------------------------------------
  --     surr*ound_words             ysiw)           (surround_words)
  --     *make strings               ys$"            "make strings"
  --     [delete ar*ound me!]        ds]             delete around me!
  --     remove <b>HTML t*ags</b>    dst             remove HTML tags
  --     'change quot*es'            cs'"            "change quotes"
  --     <b>or tag* types</b>        csth1<CR>       <h1>or tag types</h1>
  --     delete(functi*on calls)     dsf             function calls

  -- for adding/changing ({"<tag> arround lines, words or in visual mode
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },

  -- Fuzzy Finder (files, lsp, etc)
  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    version = "*",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- See `:help telescope` and `:help telescope.setup()`
      require("telescope").setup({
        pickers = {
          buffers = {
            show_all_buffers = true,
            sort_mru = true,
            mappings = {
              i = {
                ["<c-d>"] = "delete_buffer",
              },
            },
          },
        },
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
        },
      })

      -- Enable telescope fzf native, if installed
      pcall(require("telescope").load_extension, "fzf")

      -- See `:help telescope.builtin`
      vim.keymap.set(
        "n",
        "<leader>?",
        require("telescope.builtin").oldfiles,
        { desc = "[?] Find recently opened files" }
      )
      vim.keymap.set(
        "n",
        "<leader><space>",
        require("telescope.builtin").buffers,
        { desc = "[ ] Find existing buffers" }
      )
      vim.keymap.set("n", "<leader>/", function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 0,
          previewer = false,
        }))
      end, { desc = "[/] Fuzzily search in current buffer" })

      vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
      vim.keymap.set("n", "<leader>of", require("telescope.builtin").oldfiles, { desc = "Search [O]ld [F]iles" })
      vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
      vim.keymap.set(
        "n",
        "<leader>sw",
        require("telescope.builtin").grep_string,
        { desc = "[S]earch current [W]ord" }
      )
      vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
      vim.keymap.set(
        "n",
        "<leader>sd",
        require("telescope.builtin").diagnostics,
        { desc = "[S]earch [D]iagnostics" }
      )
    end,
  },

  -- Fuzzy Finder Algorithm which requires local dependencies to be built.
  -- Only load if `make` is available. Make sure you have the system
  -- requireqments installed.
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    -- NOTE: If you are having trouble with this installation,
    --       refer to the README for telescope-fzf-native for more instructions.
    build = "make",
    cond = function()
      return vim.fn.executable("make") == 1
    end,
  },

  {
    "nvim-telescope/telescope-file-browser.nvim",
    keys = { "<leader>ft" },
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      vim.api.nvim_set_keymap(
        "n",
        "<space>ft",
        ":Telescope file_browser<CR>",
        { noremap = true, desc = "[F]ile [T]ree" }
      )
      require("telescope").setup({
        extensions = {
          file_browser = {
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
          },
        },
      })
      require("telescope").load_extension("file_browser")

      -- open file_browser with the path of the current buffer
      -- vim.api.nvim_set_keymap(
      --   "n",
      --   "<space>fb",
      --   ":Telescope file_browser path=%:p:h select_buffer=true",
      --   { noremap = true }
      -- )
    end,
  },

  {
    -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    event = "BufEnter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      pcall(require("nvim-treesitter.install").update({ with_sync = true }))
      -- See `:help nvim-treesitter`

      -- indent level at which it folds
      vim.opt.foldlevel = 10
      vim.opt.foldmethod = "expr"
      vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

      require("nvim-treesitter.configs").setup({
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = { "cpp", "lua", "rust", "tsx", "typescript", "help", "vim" },
        -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
        auto_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<c-space>",
            node_incremental = "<c-space>",
            scope_incremental = "<c-s>",
            node_decremental = "<M-space>",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
        },
      })
    end,
  },
  -- A plugin to improve your rust experience in neovim.
  {
    "simrat39/rust-tools.nvim",
    ft = "rs",
    config = function()
      local rt = require("rust-tools")

      rt.setup({
        server = {
          on_attach = function(_, bufnr)
            -- Hover actions
            vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
            -- Code action groups
            vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
          end,
        },
      })
    end,
  },
  {
    "ThePrimeagen/harpoon",
    keys = { "h", "<leader>h" },
    config = function()
      -- register harpoon as a telescope extension
      require("telescope").load_extension("harpoon")

      vim.keymap.set("n", "<leader>h", "<cmd>Telescope harpoon marks theme=dropdown<cr>", { noremap = true })

      vim.keymap.set("n", "m", function()
        require("harpoon.mark").add_file()
      end, { noremap = true })

      vim.keymap.set("n", "ht", function()
        require("harpoon.term").gotoTerminal(1)
      end, { noremap = true })

      vim.keymap.set("n", "ha", function()
        require("harpoon.ui").nav_file(1)
      end, { noremap = true })
      vim.keymap.set("n", "hr", function()
        require("harpoon.ui").nav_file(2)
      end, { noremap = true })
      vim.keymap.set("n", "hs", function()
        require("harpoon.ui").nav_file(3)
      end, { noremap = true })
    end,
  },
  {
    "folke/persistence.nvim",
    event = "VimEnter",
    name = "persistence",
    config = function()
      require("persistence").setup()

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
        callback = function()
          if vim.fn.getcwd() ~= vim.env.HOME then
            require("persistence").load()
          end
        end,
        nested = true,
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    event = "InsertEnter",
    dependencies = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup({
        formatters = {
          label = require("copilot_cmp.format").format_label_text,
          insert_text = require("copilot_cmp.format").format_insert_text,
          preview = require("copilot_cmp.format").deindent,
        },
      })
    end,
  },
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
        server_opts_overrides = {
          trace = "verbose",
          settings = {
            advanced = {
              listCount = 10,  -- #completions for panel
              inlineSuggestCount = 5, -- #completions for getCompletions
            },
          },
        },
      })
    end,
  },
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`
--
--vim.keymap.set("n", "<leader>cp", "<cmd>Copilot<cr>", { noremap = true, silent = true })
vim.keymap.set(
  "i",
  "<leader>ca",
  "<cmd>lua require('copilot.suggestion').accept()<cr>",
  { noremap = true, silent = true }
)
-- Set highlight on searchvim.o.hlsearch = false
-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true
-- Enable mouse mode
vim.o.mouse = "a"
-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"
-- Enable break indent
vim.o.breakindent = true
vim.opt.smartindent = true
vim.opt.autoindent = true
-- Save undo history
vim.o.undofile = true
-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"
vim.wo.colorcolumn = "100"
-- Decrease update time
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300
-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"
-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true
vim.opt.scrolloff = 8 -- is one of my fav
vim.opt.sidescrolloff = 8

-- turn off neovim intro
vim.o.shortmess = vim.o.shortmess .. "I"

-- [[ Basic Keymaps ]]
--
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- for switching between terminal and vim splits
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
vim.keymap.set("n", "<Tab>", [[<C-w><C-w>]], { noremap = true, silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Remap for saving and quiting buffers
vim.keymap.set("n", "<Leader>w", "<cmd>w<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>wq", "<cmd>wq<CR>", { noremap = true })
vim.keymap.set("n", "<Leader>x", "<cmd>q<CR>", { noremap = true })

-- Disable line number for terminal sessions in neovim
local neovim_terminal = vim.api.nvim_create_augroup("Terminal", { clear = true })
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_command("setlocal nonumber norelativenumber signcolumn=no")
  end,
  group = neovim_terminal,
  pattern = "*",
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
