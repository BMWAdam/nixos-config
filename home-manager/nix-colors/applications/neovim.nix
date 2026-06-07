{ config, pkgs, inputs, ... }:
{
  # Make nix-colors available
  imports = [
    inputs.nix-colors.homeManagerModules.default
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    # Install plugins
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      telescope-nvim
      lualine-nvim
      nvim-tree-lua
      nvim-web-devicons

      telescope-nvim
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      luasnip
      cmp_luasnip
    ];

    extraPackages = with pkgs; [
      nil
      nixd
      pyright
      clang-tools
    ];

    # Pass colors to Neovim
    extraConfig = ''
      lua << EOF
      vim.g.mapleader = " "  -- spacebar

      local palette = {
        base00 = "${config.colorScheme.palette.base00}",
        base01 = "${config.colorScheme.palette.base01}",
        base02 = "${config.colorScheme.palette.base02}",
        base03 = "${config.colorScheme.palette.base03}",
        base04 = "${config.colorScheme.palette.base04}",
        base05 = "${config.colorScheme.palette.base05}",
        base06 = "${config.colorScheme.palette.base06}",
        base07 = "${config.colorScheme.palette.base07}",
        base08 = "${config.colorScheme.palette.base08}",
        base09 = "${config.colorScheme.palette.base09}",
        base0A = "${config.colorScheme.palette.base0A}",
        base0B = "${config.colorScheme.palette.base0B}",
        base0C = "${config.colorScheme.palette.base0C}",
        base0D = "${config.colorScheme.palette.base0D}",
        base0E = "${config.colorScheme.palette.base0E}",
        base0F = "${config.colorScheme.palette.base0F}",
      }

      -- Example: apply palette to lualine
      require('lualine').setup {
        options = {
          theme = {
            normal = { c = { fg = palette.base05, bg = palette.base00 } },
            insert = { c = { fg = palette.base0B, bg = palette.base00 } },
            visual = { c = { fg = palette.base0D, bg = palette.base00 } },
          }
        }
      }

      -- File tree
      require('nvim-tree').setup {
        view = {
          width = 30,
        },
        renderer = {
          highlight_git = true,
          icons = {
            show = {
              git = true,
              folder = true,
              file = true,
            },
          },
        },
      }

      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
      vim.api.nvim_set_hl(0, 'NvimTreeNormal',   { fg = "#${config.colorScheme.palette.base05}", bg = "#${config.colorScheme.palette.base00}" })
      vim.api.nvim_set_hl(0, 'NvimTreeFolderName', { fg = "#${config.colorScheme.palette.base0D}" })
      vim.api.nvim_set_hl(0, 'NvimTreeGitDirty', { fg = "#${config.colorScheme.palette.base08}" })
      vim.api.nvim_set_hl(0, 'NvimTreeGitNew',   { fg = "#${config.colorScheme.palette.base0B}" })

      vim.opt.number = true
      vim.opt.relativenumber = true

      -- LSP keymaps (applied when any LSP attaches)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          vim.keymap.set('n', 'gd',        vim.lsp.buf.definition,      opts)
          vim.keymap.set('n', 'K',         vim.lsp.buf.hover,           opts)
          vim.keymap.set('n', 'gi',        vim.lsp.buf.implementation,  opts)
          vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename,          opts)
          vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action,     opts)
          vim.keymap.set('n', '[d',        vim.diagnostic.goto_prev,    opts)
          vim.keymap.set('n', ']d',        vim.diagnostic.goto_next,    opts)
        end,
      })

      -- LSP servers
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      vim.lsp.config('nixd',   { capabilities = capabilities })
      vim.lsp.config('pyright', { capabilities = capabilities })
      vim.lsp.config('clangd',  { capabilities = capabilities })

      vim.lsp.enable({ 'nixd', 'pyright', 'clangd' })

      -- Autocompletion
      local cmp = require('cmp')
      local luasnip = require('luasnip')


      cmp.setup {
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>']      = cmp.mapping.confirm { select = true },
          ['<Tab>']     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            else fallback() end
          end, { 'i', 's' }),
          ['<S-Tab>']   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            else fallback() end
          end, { 'i', 's' }),
        },
        sources = cmp.config.sources {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        },
      }

      -- Indentation per filetype (add more as needed)
      local indent = {
        nix    = 2,
        python = 4,
        cpp    = 4,
        c      = 4,
        lua    = 2,
        json   = 2,
        yaml   = 2,
      }

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(ev)
          local width = indent[ev.match]
          if width then
            vim.opt_local.tabstop     = width
            vim.opt_local.shiftwidth  = width
            vim.opt_local.expandtab   = true  -- use spaces, not a real tab char
          end
        end,
      })
      -- Replace visually selected text globally
      vim.keymap.set("v", "<leader>r", '"sy:%s/\\V<C-r>s//g<Left><Left>', {
        desc = "Replace selection globally"
      })
      EOF
    '';
  };
}
