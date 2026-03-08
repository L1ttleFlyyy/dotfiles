# Auto-Theme Architecture

Statefile-centric dark/light theme sync across zsh, nvim, and tmux.

## Source of Truth

`~/.config/colortheme/theme` — contains `light` or `dark`.
Its **mtime** doubles as a rate-limit timestamp for OSC 11 probing.

## Components

### `detect-terminal-theme.sh`
Read-only OSC 11 probe. Queries the terminal background color via escape
sequence, computes luminance, prints `light` or `dark` to stdout.
Prints nothing on failure (timeout, no tty). 1-second timeout.

### `apply-theme.sh`
Sources into zsh. Provides three functions:

| Function | Statefile | Use case |
|---|---|---|
| `__apply_theme_core(sf, action)` | reads/writes `sf` if non-empty | shared implementation |
| `__apply_theme [light\|dark\|toggle]` | yes | Mac, RHEL SSH |
| `__apply_theme_local [light\|dark\|toggle]` | no | RHEL VNC |

- No args = pull mode: runs `detect-terminal-theme.sh`, applies result
- `light`/`dark` = explicit set
- `toggle` = flip current value

### zsh precmd (`__theme_precmd`)
Registered only in statefile mode (Mac, RHEL SSH). Two jobs:

1. **OSC 11 probe** (if statefile mtime > 10s): detect terminal background,
   write result to statefile. Always writes (bumps mtime even if unchanged).
2. **Statefile read**: exports `$MY_CURRENT_THEME` from statefile every prompt.

### nvim (`TermResponse` autocmd)
Parses OSC 11 responses from the terminal. On theme change:
- Sets colorscheme (`catppuccin-macchiato` for dark, `gruvbox` for light)
- Writes statefile (in statefile mode only; skipped on RHEL VNC)

Startup: reads `$MY_CURRENT_THEME` for instant colorscheme (no blink),
then sends OSC 11 query for correction. Re-queries on `FocusGained`.

### tmux (status-line poll segment)
Silent `#(...)` segment in `status-right`, runs every `status-interval` (2s).
Calls `tmux-theme-update.sh` which reads statefile, reloads tmux config
only if theme changed.

## Data Flow

```
Terminal theme changes
    |
    |-- iTerm2 pushes OSC 11 --> nvim TermResponse --> writes statefile
    |                                                       |
    |   (other terminals don't push)                        v
    |                                             tmux polls statefile (2s)
    |                                             zsh reads statefile (every prompt)
    |
    +-- zsh precmd (every 10s) --> OSC 11 query --> writes statefile
```

## Dual Mode (RHEL only)

RHEL hosts run two concurrent workflows on the same machine:

| | SSH (iterm2 -> tmux -> nvim) | VNC (xfce-term -> nvim) |
|---|---|---|
| Mode | statefile | env-var only |
| Detected by | `$SSH_CLIENT` set | `$SSH_CLIENT` unset |
| precmd hook | registered | not registered |
| nvim statefile write | yes | no |
| Default theme | auto-detect | `dark` |

VNC sessions never touch the statefile to avoid corrupting SSH sessions.
