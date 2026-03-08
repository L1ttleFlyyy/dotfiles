#!/usr/bin/env bash
# Polls state file and reloads tmux only if theme changed.
# Invoked as a silent status-right segment every status-interval.

theme=$(cat ~/.config/colortheme/theme 2>/dev/null) || theme="dark"
current=$(tmux show-env -g _THEME_CACHED 2>/dev/null | cut -d= -f2) || current=""

[ "$theme" = "$current" ] && exit 0

tmux set-env -g _THEME_CACHED "$theme"
tmux show-options -g | grep -Eo "^@\w+\s" | \
    grep -E "@(_ctp|batt_|cpu_|ram_|thm_|catppuccin_)" | \
    sed "s/^/set -Ugq /" | tr "\n" ";" | tmux source-file -
tmux source-file ~/.config/tmux/tmux.conf
