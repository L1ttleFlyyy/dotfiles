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
        tmux source-file "$HOME/.tmux.conf"
        # broadcast to tmux pane
        command -v tmux-broadcast &> /dev/null && tmux-broadcast "export MY_CURRENT_THEME=${MY_CURRENT_THEME} && __apply_theme_for_rc";
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

__apply_theme_fzf() {
    if command -v fzf &> /dev/null; then
        MY_CURRENT_THEME_FZF_GRUVBOX=" --color=bg+:#F2E5BC,bg:#FBF1C7,spinner:#D65D0E,hl:#B57614 --color=fg:#3C3836,header:#B57614,info:#8F3F71,pointer:#D65D0E --color=marker:#076678,fg+:#282828,prompt:#8F3F71,hl+:#B57614 --color=selected-bg:#EBDBB2 --color=border:#D5C4A1,label:#3C3836"
        MY_CURRENT_THEME_FZF_CATPPUCCIN="--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 --color=selected-bg:#494D64 --color=border:#363A4F,label:#CAD3F5"
        if [[ "$MY_CURRENT_THEME" == "light" ]]; then
            export FZF_DEFAULT_OPTS="$MY_FZF_OPTS_NO_COLOR $MY_CURRENT_THEME_FZF_GRUVBOX"
        else
            export FZF_DEFAULT_OPTS="$MY_FZF_OPTS_NO_COLOR $MY_CURRENT_THEME_FZF_CATPPUCCIN"
        fi
    fi
}

__apply_theme_for_rc() {
    __apply_theme_init
    __apply_theme_read_theme
    export MY_CURRENT_THEME
    __apply_theme_ls_colors
    __apply_theme_fzf
    __apply_theme_cleanup
}

__apply_theme_all() {
    __apply_theme_init
    __apply_theme_get_theme "$1"
    export MY_CURRENT_THEME
    __apply_theme_save_theme
    __apply_theme_ls_colors
    __apply_theme_fzf
    __apply_theme_tmux
    __apply_theme_cleanup
    echo "Theme set to ${MY_CURRENT_THEME}"
}
