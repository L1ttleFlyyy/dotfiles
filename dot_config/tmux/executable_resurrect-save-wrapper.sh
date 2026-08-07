#!/usr/bin/env bash
# vim: ft=bash
# Give every pane a title, then hand off to tmux-resurrect's real save script.
#
# Why this exists
# ---------------
# resurrect writes its save file as tab-separated records and parses them with
# `while IFS=$'\t' read ...` (save.sh:192, restore.sh:178). Tab is IFS
# whitespace, so bash collapses runs of tabs. A pane with an empty
# #{pane_title} therefore loses that field entirely and every later field
# shifts left by one:
#
#   pane_title := ":/home/you/project"   <- the cwd
#   dir        := "1"                    <- pane_active
#
# save.sh re-emits the shifted values, so the corruption is baked into the save
# file. On restore, `new-window -c 1` fails and the pane silently opens in
# $HOME, and `select-pane -T` stamps the stray path string on as the title.
# Panes whose program happens to set a title (OSC 2) escape, which makes the
# damage look random.
#
# Upstream already guards window_flags, pane_current_path and full_command with
# a ':' prefix for exactly this reason -- pane_title is the one field that was
# missed. Fixes have been open since 2024-08 (tmux-resurrect #520, #536, #564,
# #581, #583) with none merged: last upstream commit is 2023-03 and the author
# has declined to hand the project over (tmux-plugins/tpm#318).
#
# Backfilling the title sidesteps the field shift without patching the plugin,
# so it survives `prefix + U`. hostname is what tmux itself uses as the default
# pane title, and only *empty* titles are touched -- allow-set-title stays on
# and programs keep full control of their own titles.
set -u

host="$(hostname -s)"

# The format emits a pane id only for panes whose title is empty, so there is
# no field parsing here to reintroduce the very bug we are working around.
tmux list-panes -a -F '#{?pane_title,,#{pane_id}}' | grep . | while read -r pane_id; do
    tmux select-pane -t "$pane_id" -T "$host"
done

plugins="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.local/share/tmux/plugins}"
exec "${plugins}/tmux-resurrect/scripts/save.sh" "$@"
