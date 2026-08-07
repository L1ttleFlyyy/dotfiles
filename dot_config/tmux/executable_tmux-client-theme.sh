#!/usr/bin/env bash
set -eu

# Called from tmux 3.6 client theme hooks. Theme state stays inside this tmux
# server; there is deliberately no shared statefile.

theme=${1:-}
case "$theme" in
    light|dark) ;;
    *) exit 0 ;;
esac

# Deduplication lives in the tmux hooks (see tmux.conf), where the test and the
# set are atomic. Setting it here too keeps manual invocation working.
tmux set -g @client_theme_current "$theme"

# catppuccin uses set -o for defaults, so old generated theme values must be
# cleared before re-sourcing tmux.conf with the new server-local theme.
tmux show-options -g | grep -Eo "^@\w+\s" | \
    grep -E "@(_ctp|batt_|cpu_|ram_|thm_|catppuccin_)" | \
    sed "s/^/set -Ugq /" | tr "\n" ";" | tmux source-file -

exec tmux source-file "$HOME/.config/tmux/tmux.conf"
