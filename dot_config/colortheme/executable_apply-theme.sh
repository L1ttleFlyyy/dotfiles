#!/usr/bin/env bash

# Detect/set terminal theme → write statefile
# Usage: __apply_theme [light|dark|toggle]   (no args = auto-detect)
__apply_theme() {
    local sf="$HOME/.config/colortheme/theme"
    local action="${1:-}"
    local cur theme

    cur=$(cat "$sf" 2>/dev/null) || cur="dark"

    case "$action" in
        light|dark) theme="$action" ;;
        toggle)     [ "$cur" = "light" ] && theme="dark" || theme="light" ;;
        *)          theme=$(bash "$HOME/.config/colortheme/detect-terminal-theme.sh" 2>/dev/null) || true
                    theme="${theme:-$cur}" ;;
    esac

    echo "$theme" > "$sf"
}
