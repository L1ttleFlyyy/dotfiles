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

__apply_theme() {
    local STATE_FILE="$HOME/.config/colortheme/theme"

    case "${1:-}" in
        light|dark)
            echo "$1" > "$STATE_FILE"
            ;;
        toggle)
            local cur
            cur=$(cat "$STATE_FILE" 2>/dev/null) || cur="dark"
            if [ "$cur" = "light" ]; then echo "dark"; else echo "light"; fi > "$STATE_FILE"
            ;;
        *)
            # Pull mode: detect terminal theme, write statefile only on success
            local detected
            detected=$(bash "$HOME/.config/colortheme/detect-terminal-theme.sh" 2>/dev/null) || true
            if [ -n "$detected" ]; then
                echo "$detected" > "$STATE_FILE"
            fi
            ;;
    esac

    # Read statefile (canonical source) and apply
    MY_CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null) || MY_CURRENT_THEME="dark"
    [[ "$MY_CURRENT_THEME" =~ ^(light|dark)$ ]] || MY_CURRENT_THEME="dark"
    export MY_CURRENT_THEME

    __apply_theme_ls_colors

    # Explicit mode: propagate immediately
    if [ -n "${1:-}" ]; then
        if [ -n "${TMUX:-}" ] && [ -x "$HOME/.config/tmux/tmux-theme-update.sh" ]; then
            bash "$HOME/.config/tmux/tmux-theme-update.sh"
        fi
        echo "Theme set to $MY_CURRENT_THEME"
    fi
}

__apply_theme_local() {
    case "${1:-}" in
        light|dark)
            MY_CURRENT_THEME="$1"
            ;;
        toggle)
            if [ "${MY_CURRENT_THEME:-dark}" = "light" ]; then
                MY_CURRENT_THEME="dark"
            else
                MY_CURRENT_THEME="light"
            fi
            ;;
        *)
            # Pull mode: detect terminal theme, no statefile
            local detected
            detected=$(bash "$HOME/.config/colortheme/detect-terminal-theme.sh" 2>/dev/null) || true
            if [ -n "$detected" ]; then
                MY_CURRENT_THEME="$detected"
            fi
            ;;
    esac

    [[ "${MY_CURRENT_THEME:-dark}" =~ ^(light|dark)$ ]] || MY_CURRENT_THEME="dark"
    export MY_CURRENT_THEME

    __apply_theme_ls_colors

    if [ -n "${1:-}" ]; then
        echo "Theme set to $MY_CURRENT_THEME"
    fi
}
