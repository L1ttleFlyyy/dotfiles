# Dotfiles

Personal dotfiles managed by [chezmoi](https://chezmoi.io/): a single source tree
covering macOS, Linux (Fedora / Bazzite / RHEL) and Windows, with platform
differences handled by chezmoi templates rather than by separate branches.

Covers zsh, Neovim, tmux, Ghostty / WezTerm, git, and the Claude Code and Codex
CLIs.

## Documentation

- [`.chezmoitemplates/README.md`](.chezmoitemplates/README.md) — the Neovim
  configuration: design principles, plugin list, key mappings, and a `Gotchas`
  section recording upstream bugs worked around here (e.g. mini.animate breaking
  `<`/`>` reselection in visual mode).
- [`dot_config/claude/claude-notification-tips.md`](dot_config/claude/claude-notification-tips.md)
  — getting desktop notifications out of a sandboxed Claude Code running inside
  tmux on a remote host, via tmux passthrough plus Ghostty OSC 777, including the
  approaches that turned out to be dead ends.
- [`docs/theme-architecture.md`](docs/theme-architecture.md) — how the light/dark
  theme propagates across tmux, Neovim, zsh and PowerShell without a shared
  statefile, and the constraints that rule out the obvious alternatives (OSC 11
  passthrough responses do not route back to the originating pane; tmux status
  jobs have no tty to probe with).
- [`AGENTS.md`](AGENTS.md) — instructions for coding agents working in this
  repository. `CLAUDE.md` is a pointer to it.

The first three are worth reading before touching the area they describe; each
exists because the obvious approach failed at least once.

## Codex configuration

`dot_codex/modify_config.toml` manages a small policy set in
`~/.codex/config.toml` while preserving runtime-managed settings semantically.

It intentionally uses chezmoi's `fromToml`/`toToml` functions. This may reorder
keys and change indentation. Codex also rewrites the file with its own formatter,
so a byte-level diff may reappear after Codex starts. This formatting churn is an
accepted tradeoff; unmanaged TOML values remain preserved.

## Claude Code configuration

`dot_claude/modify_private_settings.json` manages a minimal policy set in
`~/.claude/settings.json` (privacy env vars, the notification hook and status
line, a few feature toggles, and `permissions.defaultMode`) while leaving
runtime-managed preferences — `model`, `theme`, `effortLevel`, notification
toggles, and the `permissions.allow`/`deny`/`ask` lists — untouched.

It parses the current file with `fromJson`, sets only the managed paths via
`setValueAtPath`, and re-emits with `toPrettyJson`. Keys are reordered
alphabetically and Claude Code rewrites the file with its own formatter, so a
byte-level diff may reappear; unmanaged values remain preserved. On a fresh
machine (empty stdin) it emits just the policy set and Claude Code fills in the
rest at runtime.

## Comparing changes

`diff.command` is set to `nvim`, so a bare `chezmoi diff` opens an interactive
Neovim session — fine by hand, fatal in a script or an agent. The non-interactive
equivalent, which behaves like `git diff`, is:

```sh
chezmoi diff --use-builtin-diff --no-pager --no-tty [target...]
```

See [`AGENTS.md`](AGENTS.md) for why this matters more than an ordinary hang.

`README.md`, `AGENTS.md` and `CLAUDE.md` are excluded from the target state by
`.chezmoiignore`.
