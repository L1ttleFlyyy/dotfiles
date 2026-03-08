# Neovim Configuration

Minimal, single-file Neovim configuration managed by [chezmoi](https://chezmoi.io/).
Cross-platform (macOS, Linux, Windows) with conditional sections for platform-specific
features (Verilog/SystemVerilog tooling on RHEL, Perforce integration, etc.).

## Design Principles

- **MVP / Minimal**: Only add what is actively used. No speculative features.
- **Trust plugin defaults**: Plugin configs use `opts = {}` wherever possible.
  Custom configuration only where there is a genuine personal workflow need.
- **Prefer mini.nvim**: Small, focused, well-written Lua modules over large
  plugin ecosystems. Currently using mini.diff, mini.animate, mini.indentscope,
  mini.surround, mini.ai, mini.bracketed, and mini.move.
- **Single file**: Everything lives in `init.lua.tmpl --> ../../.chezmoitemplates/nvim-init-lua.tmpl`. No `lua/` directory,
  no split modules. Chezmoi templates handle platform branching.
- **No LSP**: This config intentionally has no LSP setup. Completion comes from
  blink.cmp (buffer words + snippets), not language servers.
- **Requires**: Neovim 0.11+, `tree-sitter-cli` 0.26.1+.

## Plugin List

| Plugin | Purpose |
|--------|---------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager (bootstrapped) |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless `<C-hjkl>` navigation between tmux panes and nvim splits |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | Fuzzy finder (files, grep, buffers, commands) |
| [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) | Light theme |
| [catppuccin](https://github.com/catppuccin/nvim) | Dark theme (macchiato) |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting and indentation (`main` branch rewrite) |
| [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) | Sticky context header (function/class name) |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line (tabline-only layout with buffers, branch, diff) |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine + friendly-snippets |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Completion (buffer + snippets + cmdline) |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | File explorer (buffer-as-filesystem) |
| [mini.diff](https://github.com/echasnovski/mini.diff) | Signcolumn diff signs (git / p4 / save fallback) |
| [mini.animate](https://github.com/echasnovski/mini.animate) | Smooth scroll and window resize animations |
| [mini.indentscope](https://github.com/echasnovski/mini.indentscope) | Visual indent scope indicator |
| [mini.surround](https://github.com/echasnovski/mini.surround) | Surround actions (`sa`/`sd`/`sr`) |
| [mini.ai](https://github.com/echasnovski/mini.ai) | Extended `a`/`i` textobjects (`aa`/`ia` for arguments, `af`/`if` for function calls) |
| [mini.bracketed](https://github.com/echasnovski/mini.bracketed) | Bracket navigation (`]b`/`[b` for buffers, `]d`/`[d` for diagnostics, etc.) |
| [mini.move](https://github.com/echasnovski/mini.move) | Move lines/selections (`Alt+hjkl`, `Alt+arrows`) |
| [smear-cursor.nvim](https://github.com/sphamba/smear-cursor.nvim) | Cursor animation |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding hints popup |
| [vim-plugin-AnsiEsc](https://github.com/powerman/vim-plugin-AnsiEsc) | ANSI escape code rendering (`:AnsiEsc`) |

## Key Mappings

Leader key: `,`

### Navigation

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Navigate between tmux panes / nvim splits |
| `]b` / `[b` | Next / previous buffer |
| `]h` / `[h` | Next / previous diff hunk (or `]c`/`[c` in diff mode) |
| `-` | Open parent directory (oil.nvim) |
| `<leader>e` | Open file explorer (float) |

### Fuzzy Finder

| Key | Action |
|-----|--------|
| `<C-p>` | Find files |
| `<C-f>` | Grep word under cursor |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>fh` | Help tags |
| `<leader>fr` | Recent files |
| `<leader>fc` | Commands |
| `<leader>fk` | Keymaps |
| `<leader>fw` | Grep word under cursor |
| `<leader><C-p>` | Command palette |

### Editing

| Key | Action |
|-----|--------|
| `<M-hjkl>` or `<M-arrows>` | Move line(s) / selection (mini.move) |
| `<leader>/` or `<C-/>` | Toggle comment |
| `<` / `>` (visual) | Indent/dedent (keeps selection) |
| `x` | Delete char (black hole register) |
| `sa` / `sd` / `sr` | Surround add / delete / replace |

### Clipboard (OSC52)

Default `y`/`d`/`p` operate on vim's unnamed register only (no system clipboard sync).

| Key | Action |
|-----|--------|
| `<leader>y` | Yank to system clipboard |
| `<leader>d` | Cut to system clipboard |
| `<leader>p` | Paste from system clipboard |

### Diff / Hunk Operations

| Key | Action |
|-----|--------|
| `]h` / `[h` | Next / previous hunk |
| `<leader>hs` | Stage hunk at cursor (git only) |
| `<leader>hr` | Reset hunk at cursor |
| `<leader>hp` | Toggle diff overlay |

### Misc

| Key | Action |
|-----|--------|
| `<CR>` | Clear search highlight |
| `<leader>n` | Toggle line numbers |

## Colorscheme

Automatic selection based on `~/.config/colortheme/theme` statefile:
- `light` -> gruvbox (light background)
- anything else -> catppuccin macchiato (dark background)

nvim reads the statefile at startup and maintains it via OSC 11 detection.
See `dot_config/colortheme/README.md` for the full architecture.

## Platform-Specific Features (RHEL)

Guarded by chezmoi template `--{- if eq (dig "id" "none" .chezmoi.osRelease) "rhel" }--`:

- Verilog/SystemVerilog treesitter parser and filetype registration
- Treesitter context queries for Verilog constructs
- SystemVerilog snippets (sv-1800-2012)
- Perforce (p4) diff source for mini.diff (git -> p4 -> save fallback chain)

## Custom Commands

- `:DiffOrig` - Compare current buffer against the on-disk version in a vertical split
- `:AnsiEsc` - Render ANSI escape codes in current buffer

## Gotchas

### mini.animate breaks `<`/`>` visual indent reselection

The common `>gv` / `<gv` mapping (indent then reselect) breaks when `mini.animate`
is enabled. The scroll animation intercepts cursor movement between `>` and `gv`,
collapsing the selection. Only reproduces with downward visual selections (cursor at
bottom of range) where the post-indent cursor jump is large enough to trigger scroll
animation.

Fix: use `nvim_feedkeys` with `"nx"` mode to make the operation atomic:

```lua
vim.keymap.set("x", ">", function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(">gv", true, false, true), "nx", false)
end, { silent = true })
```
