#!/usr/bin/env bash

__apply_theme_init() {
    MY_CURRENT_THEME=""
    MY_CURRENT_THEME_FILE="$HOME/.config/.current_theme"
    MY_CURRENT_THEME_FZF_GRUVBOX=""
    MY_CURRENT_THEME_FZF_CATPPUCCIN=""
}

__apply_theme_cleanup() {
    unset MY_CURRENT_THEME_FILE
    unset MY_CURRENT_THEME_FZF_GRUVBOX
    unset MY_CURRENT_THEME_FZF_CATPPUCCIN
}

__apply_theme_read_theme() {
    if [ -r "$MY_CURRENT_THEME_FILE" ]; then
        MY_CURRENT_THEME=$(head -n1 "$MY_CURRENT_THEME_FILE")
    fi
    if [ "$MY_CURRENT_THEME" = "dark" ] || [ "$MY_CURRENT_THEME" = "light" ]; then
        return
    fi
    MY_CURRENT_THEME="dark"
}

__apply_theme_get_theme() {
    case "$1" in
        "")
            __apply_theme_read_theme
            ;;
        "toggle")
            __apply_theme_read_theme
            if [ "$MY_CURRENT_THEME" = "light" ]; then
                MY_CURRENT_THEME="dark"
            else
                MY_CURRENT_THEME="light"
            fi
            ;;
        "light"|"dark")
            MY_CURRENT_THEME="$1"
            ;;
        *)
            echo "Usage: $0 [toggle|light|dark]"
            return 1
            ;;
    esac
}

__apply_theme_save_theme() {
    mkdir -p "$(dirname ${MY_CURRENT_THEME_FILE})"
    echo "$MY_CURRENT_THEME" > "$MY_CURRENT_THEME_FILE"
}

__apply_theme_tmux() {
    if tmux list-sessions &> /dev/null; then
        tmux set-environment MY_CURRENT_THEME "$MY_CURRENT_THEME"
        tmux show-options -g | grep -E -o "^@\w+\s" | grep -E "@(_ctp|batt_|cpu_|ram_|thm_|catppuccin_)" | sed "s/^/set -Ugq /" | tr "\n" ";" | tmux source-file -
        tmux source-file "$HOME/.config/tmux/tmux.conf"
    fi
}

__detect_theme_osc11() {
    local query response rgb r g b lum saved

    if [ -n "$TMUX" ]; then
        query=$'\ePtmux;\e\e]11;?\a\e\\'
    else
        query=$'\e]11;?\a'
    fi

    saved=$(stty -g 2>/dev/null) || return 1
    stty raw -echo min 0 time 3 2>/dev/null || { stty "$saved" 2>/dev/null; return 1; }
    printf '%s' "$query" > /dev/tty
    response=$(dd bs=1 count=64 < /dev/tty 2>/dev/null)
    stty "$saved" 2>/dev/null

    # Extract rgb:RRRR/GGGG/BBBB
    rgb=${response##*rgb:}
    rgb=${rgb%%[^0-9a-fA-F/]*}
    [ -z "$rgb" ] && return 1

    r=${rgb%%/*}; rgb=${rgb#*/}
    g=${rgb%%/*}; b=${rgb#*/}

    # Normalize to high byte (first 2 hex digits of 4-digit channels)
    [ ${#r} -gt 2 ] && r=${r:0:2}
    [ ${#g} -gt 2 ] && g=${g:0:2}
    [ ${#b} -gt 2 ] && b=${b:0:2}

    # Perceived luminance
    lum=$(( (299 * 16#$r + 587 * 16#$g + 114 * 16#$b) / 1000 ))

    if [ "$lum" -gt 128 ]; then
        echo "light"
    else
        echo "dark"
    fi
}

__apply_theme_precmd() {
    [ -n "$MY_THEME_FIXED" ] && return

    local now=${EPOCHSECONDS:-$(date +%s)}
    [ -n "$__theme_last_check" ] && (( now - __theme_last_check < 30 )) && return
    __theme_last_check=$now

    local detected
    detected=$(__detect_theme_osc11) || return
    [ "$detected" = "$MY_CURRENT_THEME" ] && return

    export MY_CURRENT_THEME="$detected"
    echo "$MY_CURRENT_THEME" > "$HOME/.config/.current_theme"
    __apply_theme_ls_colors

    if [ -n "$TMUX" ]; then
        tmux set-environment MY_CURRENT_THEME "$MY_CURRENT_THEME"
        tmux show-options -g | grep -E -o "^@\w+\s" | grep -E "@(_ctp|batt_|cpu_|ram_|thm_|catppuccin_)" | sed "s/^/set -Ugq /" | tr "\n" ";" | tmux source-file -
        tmux source-file "$HOME/.config/tmux/tmux.conf"
    fi
}

__apply_theme_ls_colors() {
    if command -v vivid &> /dev/null; then
        if [ "$MY_CURRENT_THEME" = "light" ]; then
            export LS_COLORS=$(vivid generate gruvbox-light)
        else
            export LS_COLORS=$(vivid generate tokyonight-night)
        fi
    fi
}

__apply_theme_for_rc() {
    __apply_theme_init
    __apply_theme_read_theme
    export MY_CURRENT_THEME
    __apply_theme_ls_colors
    __apply_theme_cleanup
}

__apply_theme_all() {
    __apply_theme_init
    __apply_theme_get_theme "$1"
    export MY_CURRENT_THEME
    __apply_theme_save_theme
    __apply_theme_ls_colors
    __apply_theme_tmux
    __apply_theme_cleanup
    echo "Theme set to ${MY_CURRENT_THEME}"
}
