# Search ignore layers

Four files decide what `fd`, `rg`, `fzf` and `git` will not show you. They have
three different scopes, and the difference is silent: a search that comes back
empty looks exactly like a file that is not there.

| File | Read by | Applies |
| --- | --- | --- |
| `~/.config/fd/ignore` | `fd`; `rg` via `--ignore-file` in `ripgreprc` | always, from any directory |
| `~/.config/git/ignore` | `git` | every repository |
| `~/.ignore` | `fd`, `rg` | only when the search starts at `$HOME` or above |
| `~/.config/rg/ripgreprc` | `rg` via `RIPGREP_CONFIG_PATH` | wires fd's ignore file into rg |

The first two are the same content, rendered from
`.chezmoitemplates/ignore.tmpl`. The third comes from `dot_ignore.tmpl`.

## Why `~/.ignore` is position-dependent

Its entries contain a slash, so gitignore semantics anchor them to the directory
holding the ignore file — `$HOME`. Searching from `$HOME` prunes the whole
subtree; searching from inside it does not, because the search root is never
pruned against itself:

```
$ cd ~            && rg -l RIPGREP_CONFIG_PATH   # chezmoi source not found
$ cd ~/.local/share && rg -l RIPGREP_CONFIG_PATH # chezmoi/dot_config/... found
```

This is the intended behaviour, not a bug. Browsing from `$HOME` wants the
filter; `cd`-ing somewhere specific means you know what you are looking for.
It doubles as the escape hatch, alongside the `fda` / `rga` aliases.

## What belongs where

`.chezmoitemplates/ignore.tmpl` is the general layer: the files a standard
development setup treats as unimportant wherever they appear — build output, VCS
metadata, editor and OS scratch files. Unwanted both when committing and when
searching, hence shared by git and by the search tools.

`dot_ignore.tmpl` serves exactly one situation: searching from `$HOME`, where
the noise is overwhelming and has to be suppressed deliberately. It holds bulky
`$HOME` directories that are merely uninteresting.
A rule earns its place only by being both index-heavy *and* certain to hold
nothing worth searching. A rule that hides what you were looking for costs far
more than the noise it saves, so the list stays short and evidence-based rather
than speculative — `ignore-audit` reports what is actually costing you.

Five entries meet the bar today: `.npm/`, `.local/share/containers/`,
`.claude/remote/`, `.codex/.tmp/` and `.vscode-server/cli/servers/` — a package
cache, container layers, and three runtime caches that no one writes by hand.

Each is deliberately narrower than its parent. `.local/share/` held 143,975
files of which 138,904 were container layers, and ignoring the parent would also
have hidden this repository, which lives at `~/.local/share/chezmoi`. Likewise
`.claude/remote/` leaves `~/.claude/plugins/` searchable, which is where
installed plugin sources actually live, and `.vscode-server/cli/servers/` leaves
`.vscode-server/extensions/` alone.

## Gotchas

- `core.excludesFile` is **not** set anywhere. git finds
  `~/.config/git/ignore` through the XDG default path, so grepping the git
  config for the wiring turns up nothing. `git check-ignore -v <path>` names the
  file and line that matched, and is the fastest way to settle an argument.
- `rg` picks up fd's ignore file only because `ripgreprc` says so. Editing
  `~/.config/fd/ignore` therefore changes `rg` behaviour too, which is easy to
  forget given the filename.
- `fd`'s defaults here are `--follow --hidden` (see `FZF_DEFAULT_COMMAND`), so
  hidden files are searched and only the ignore layers filter them.
