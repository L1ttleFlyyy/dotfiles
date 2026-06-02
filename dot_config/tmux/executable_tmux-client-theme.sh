#!/usr/bin/env bash
set -eu

# Called from tmux 3.6 client theme hooks. Theme state stays inside this tmux
# server; there is deliberately no shared statefile.

theme=${1:-}
case "$theme" in
    light|dark) ;;
    *) exit 0 ;;
esac

case "$theme" in
    light)
        flavor=gruvbox
        bg="#fbf1c7"
        ;;
    dark)
        flavor=macchiato
        bg="#24273a"
        ;;
esac

current_theme=$(tmux show-option -gv @client_theme_current 2>/dev/null || true)
current_flavor=$(tmux show-option -gv @catppuccin_flavor 2>/dev/null || true)
current_style=$(tmux show-option -gv window-style 2>/dev/null || true)

if [ "$current_theme" = "$theme" ] &&
   [ "$current_flavor" = "$flavor" ] &&
   [ "$current_style" = "bg=$bg" ]; then
    exit 0
fi

tmux set -g @client_theme_current "$theme"

# catppuccin uses set -o for defaults, so old generated theme values must be
# cleared before re-sourcing tmux.conf with the new server-local theme.
tmux show-options -g | grep -Eo "^@\w+\s" | \
    grep -E "@(_ctp|batt_|cpu_|ram_|thm_|catppuccin_)" | \
    sed "s/^/set -Ugq /" | tr "\n" ";" | tmux source-file -

exec tmux source-file "$HOME/.config/tmux/tmux.conf"
