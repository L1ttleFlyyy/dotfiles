# Agent Instructions

Read [README.md](README.md) first. It says what this repository is and points at
the per-area documentation, which is where the accumulated gotchas live.

## Source state vs. target state

This is a [chezmoi](https://chezmoi.io/) source directory. Files here are the
*source state*; chezmoi renders them into `$HOME` (the *target state*). Always
edit files in this repository — an edit made to a deployed copy under `$HOME` is
silently overwritten by the next `chezmoi apply`.

Naming maps source to target: `dot_config/tmux/tmux.conf` →
`~/.config/tmux/tmux.conf`, `executable_` → mode 755, `private_` → mode 600,
`.tmpl` → rendered as a template. `chezmoi source-path <target>` resolves the
mapping in either direction when in doubt.

## chezmoi command notes

**`chezmoi diff` requires `--use-builtin-diff`.** `~/.config/chezmoi/chezmoi.toml`
sets `diff.command = "nvim"`, which turns `chezmoi diff` into a difftool: a bare
invocation launches an interactive Neovim session and hangs indefinitely in a
non-interactive shell. Use the builtin diff, which behaves like `git diff` and
writes a unified diff to stdout:

```sh
chezmoi diff --use-builtin-diff --no-pager --no-tty [target...]
```

This is not merely a hang. After one such hung invocation the destination files
were found rewritten to match the source state — the orphaned `nvim -d` appears
to have written them, i.e. it silently applied the change.

**Reach for `chezmoi status` first.** It is the `git status --short` equivalent
(`M`/`A`/`D` columns), never touches the pager or the editor, and usually answers
the question without a diff at all.

**Do not run `chezmoi apply` unless asked.** It writes the user's live
configuration.

## Conventions

- MVP over speculation: add what is actively used, not what might be useful.
- Comments explain *why*, not *what*. A worked-around upstream bug belongs in the
  relevant `Gotchas` section, not only in a commit message.
- Keep platform branching in chezmoi templates rather than in per-platform files.
