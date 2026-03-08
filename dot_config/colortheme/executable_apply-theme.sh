#!/usr/bin/env bash

__apply_theme_ls_colors() {
    if command -v vivid &> /dev/null; then
        if [ "$MY_CURRENT_THEME" = "light" ]; then
            export LS_COLORS=$(vivid generate gruvbox-light)
        else
            export LS_COLORS=$(vivid generate tokyonight-night)
        fi
    fi
}

# Core: resolve + apply theme
# $1 = statefile path (empty = env-var-only mode)
# $2 = action (light|dark|toggle|empty for detect)
__apply_theme_core() {
    local sf="$1" action="${2:-}"
    local cur

    if [ -n "$sf" ]; then
        cur=$(cat "$sf" 2>/dev/null) || cur="dark"
    else
        cur="${MY_CURRENT_THEME:-dark}"
    fi

    case "$action" in
        light|dark) MY_CURRENT_THEME="$action" ;;
        toggle)
            if [ "$cur" = "light" ]; then MY_CURRENT_THEME="dark"; else MY_CURRENT_THEME="light"; fi
            ;;
        *)
            local detected
            detected=$(bash "$HOME/.config/colortheme/detect-terminal-theme.sh" 2>/dev/null) || true
            MY_CURRENT_THEME="${detected:-$cur}"
            ;;
    esac

    [[ "$MY_CURRENT_THEME" =~ ^(light|dark)$ ]] || MY_CURRENT_THEME="dark"
    export MY_CURRENT_THEME

    [ -n "$sf" ] && echo "$MY_CURRENT_THEME" > "$sf"

    __apply_theme_ls_colors
    [ -n "$action" ] && echo "Theme set to $MY_CURRENT_THEME"
}

__apply_theme()       { __apply_theme_core "$HOME/.config/colortheme/theme" "$@"; }
__apply_theme_local() { __apply_theme_core "" "$@"; }
