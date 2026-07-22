# Chezmoi Notes

## Codex configuration

`dot_codex/modify_config.toml` manages a small policy set in
`~/.codex/config.toml` while preserving runtime-managed settings semantically.

It intentionally uses chezmoi's `fromToml`/`toToml` functions. This may reorder
keys and change indentation. Codex also rewrites the file with its own formatter,
so a byte-level diff may reappear after Codex starts. This formatting churn is an
accepted tradeoff; unmanaged TOML values remain preserved.

## Comparing changes

Agents must not run `chezmoi diff`: it launches an interactive Neovim session.
Pipe `chezmoi cat` into the system `diff` instead:

```sh
chezmoi cat ~/.codex/config.toml | diff -u ~/.codex/config.toml -
```

Use `diff -q` instead of `diff -u` when only the exit status matters.

This README is excluded from the target state by `.chezmoiignore`.
