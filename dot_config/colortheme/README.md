# Auto-Theme Architecture

Statefile-centric dark/light theme sync across zsh, nvim, tmux, and PowerShell.

## Source of Truth

`~/.config/colortheme/theme` — contains `light` or `dark`.
No environment variables. No shell hooks.

## Components

### `detect-terminal-theme.sh`
Read-only OSC 11 probe. Queries the terminal background color via escape
sequence, computes luminance, prints `light` or `dark` to stdout.
Prints nothing on failure (timeout, no tty). 1-second timeout.

### `apply-theme.sh`
Sources into zsh. Provides one function:

- `__apply_theme [light|dark|toggle]` — detects (no args), sets, or toggles
  theme, writes result to statefile.

Called once at shell startup. Aliased to `apply-theme` for manual use.

### nvim (`TermResponse` autocmd)
The active statefile maintainer. Parses OSC 11 responses from the terminal.
On theme change:
- Sets colorscheme (`catppuccin-macchiato` for dark, `gruvbox` for light)
- Writes statefile

Startup: reads statefile for instant colorscheme (no blink),
then sends OSC 11 query for correction. Re-queries on `FocusGained`.

### tmux (status-line poll segment)
Silent `#(...)` segment in `status-right`, runs every `status-interval` (2s).
Calls `tmux-theme-update.sh` which reads statefile, reloads tmux config
only if theme changed.

### PowerShell
Reads statefile at startup. If statefile is missing, bootstraps it using
`Get-WindowsAppsTheme` (Windows dark/light mode API).

## Data Flow

```
Terminal theme changes
    |
    |-- iTerm2 pushes OSC 11 --> nvim TermResponse --> writes statefile
    |                                                       |
    |   (other terminals don't push)                        v
    |                                             tmux polls statefile (2s)
    |
    +-- zsh startup --> one-time OSC 11 detect --> writes statefile
    +-- manual `apply-theme toggle` --> writes statefile
```

## RHEL Dual Mode

RHEL hosts run two concurrent workflows on the same machine:

| | SSH (iterm2 -> tmux -> nvim) | VNC (xfce-term -> nvim) |
|---|---|---|
| `apply-theme` | runs at startup | not loaded |
| nvim statefile | reads + writes | reads + writes |
| Default theme | auto-detect | dark (nvim startup) |

VNC sessions skip `apply-theme.sh` entirely. nvim handles its own theme
via OSC 11 and statefile independently.
