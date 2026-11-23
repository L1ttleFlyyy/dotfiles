#!/usr/bin/env bash
set -eu

# Fallback for terminals that never report light/dark to tmux (no DEC mode
# 2031, e.g. Konsole; KDE bug 514293): at attach, take the desktop's setting
# from the XDG portal (color-scheme: 1 dark, 2 light, 0 no preference -> dark).
# No portal (servers, macOS) means no answer and nothing changes.
scheme="$(busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
    org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance color-scheme 2>/dev/null \
    | awk '{print $3}')" || exit 0
case "$scheme" in
    2) theme=light ;;
    0|1) theme=dark ;;
    *) exit 0 ;;
esac
[ "$(tmux show -gv @client_theme_current 2>/dev/null)" = "$theme" ] && exit 0
exec bash "$HOME/.config/tmux/tmux-client-theme.sh" "$theme"
