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
- `client-attached` initializes from `#{client_theme}`, covering a client that
  was absent while the theme flipped.
- `@client_theme_current` stores the current server-local theme. Each hook tests
  it and sets it in the same tmux command queue, so the test-and-set is atomic
  and overlapping events cannot both kick off a re-source.
- There is deliberately no `client-active` hook. The light/dark notification is
  pushed by the terminal (DEC mode 2031) whether or not it is focused, so focus
  changes carry no new information — they only produced bursts of concurrent
  re-sources, which raced inside tpm and surfaced as `tpm returned 1`.

This avoids background OSC probes from tmux jobs. `#(...)` status jobs have no
interactive tty, so they cannot reliably ask the outer terminal via OSC 11.

### Unresolved: pane background vs. OSC 11 proxying

`window-style` and `window-active-style` were originally set to the selected
theme background, so that applications inside tmux could read the theme back out
of tmux's OSC 11 response. They are now unconditionally `bg=default`, so panes
inherit the outer terminal background instead — this is what keeps a transparent
nvim and blank shell space seamless when the host terminal's theme is neither
catppuccin nor gruvbox.

These two goals conflict, and the second one won without the first being
re-checked. Whether tmux still answers OSC 11 usefully with `bg=default` has not
been verified. If nvim inside tmux stops following the theme, look here first.

### nvim

nvim sends OSC 11 on startup/focus/resume and applies the response:

- Outside tmux, the response comes from the terminal emulator.
- Inside tmux, the response comes from tmux's synced pane background.

nvim sends one bounded synchronous startup query before applying the first
colorscheme. This preserves the useful handoff behavior that the old statefile
provided, without storing a global theme. If the startup query does not answer
quickly, nvim falls back to dark and later `TermResponse` events still correct
the theme.

nvim does not read or write theme state on disk.

### zsh

zsh does not detect, read, or write theme state. It inherits terminal colors.

### PowerShell

Reads Windows app theme directly with `Get-WindowsAppsTheme` at startup.

## Data Flow

```
Terminal/client theme changes
    |
    +-- tmux client_theme hooks --> set @client_theme_current (atomic)
    |                              re-source tmux.conf in this server
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
