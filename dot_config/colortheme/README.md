# Auto-Theme Architecture

Dark/light theme sync across zsh, nvim, tmux, and PowerShell.

## Source Of Truth

The source of truth is the visible client theme, not a shared file:

- Outside tmux, the terminal emulator answers OSC 11.
- Inside tmux 3.6+, tmux answers OSC 11 from its pane background.
- tmux keeps that pane background in sync with `#{client_theme}`.

There is no `~/.config/colortheme/theme` statefile. A global file cannot model
two tmux servers or terminals with different themes.

## Components

### tmux

tmux owns theme state for each tmux server.

- `client-light-theme` and `client-dark-theme` hooks receive outer terminal
  theme changes.
- `client-attached` and `client-active` initialize/sync from `#{client_theme}`.
- `@client_theme_current` stores the current server-local theme.
- `window-style` and `window-active-style` are set to the selected theme
  background, so applications inside tmux can consume tmux's OSC 11 response.

This avoids background OSC probes from tmux jobs. `#(...)` status jobs have no
interactive tty, so they cannot reliably ask the outer terminal via OSC 11.

### nvim

nvim sends OSC 11 on startup/focus/resume and applies the response:

- Outside tmux, the response comes from the terminal emulator.
- Inside tmux, the response comes from tmux's synced pane background.

nvim does not read or write theme state on disk.

### zsh

zsh does not detect, read, or write theme state. It inherits terminal colors.

### PowerShell

Reads Windows app theme directly with `Get-WindowsAppsTheme` at startup.

## Data Flow

```
Terminal/client theme changes
    |
    +-- tmux client_theme hooks --> set @client_theme_current
    |                              reload tmux theme in this server
    |                              set tmux pane background
    |
    +-- nvim OSC 11 query --------> terminal or tmux response
                                   apply colorscheme
```

## Important Constraints

- Do not use a global statefile for light/dark theme. Two terminals or tmux
  servers can legitimately have different themes at the same time.
- Do not rely on DCS-wrapped OSC 11 passthrough for queries. tmux passthrough
  forwards output to the outer terminal, but the terminal's response is not
  reliably routed back to the originating pane.
- Do not move OSC 11 probing into tmux background jobs. They do not have the
  interactive tty needed for reliable terminal queries.
- Multiple tmux servers can now differ. Multiple clients attached to the same
  tmux server still share tmux's global pane/status theme, so the latest active
  client wins within that server.
