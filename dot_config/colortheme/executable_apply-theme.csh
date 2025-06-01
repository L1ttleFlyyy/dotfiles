# tcsh theme script - can be sourced for both RC and manual changes

# temp variables
set MY_CURRENT_THEME = ""
set MY_CURRENT_THEME_FILE = "$HOME/.config/.current_theme"
set MY_THEME_SET_TMUX = ""
set MY_THEME_SAVE_CONFIG = ""
set FZF_GRUVBOX = ""
set FZF_CATPPUCCIN = ""

alias __my_fzf_cleanup ' \
    unset MY_CURRENT_THEME \
    unset MY_CURRENT_THEME_FILE \
    unset MY_THEME_SET_TMUX \
    unset MY_THEME_SAVE_CONFIG \
    unset FZF_GRUVBOX \
    unset FZF_CATPPUCCIN \
'

# Read theme from file
if ( -r "$MY_CURRENT_THEME_FILE" ) then
    set MY_CURRENT_THEME = `head -n1 "$MY_CURRENT_THEME_FILE"`
endif
if ( "$MY_CURRENT_THEME" != "dark" && "$MY_CURRENT_THEME" != "light" ) then
    set MY_CURRENT_THEME = "dark"
endif

# Processing arguments
if ( $#argv > 0 ) then
    set MY_THEME_SET_TMUX = "1"
    switch ("$1")
    case "toggle":
        if ( "$MY_CURRENT_THEME" == "light" ) then
            set MY_CURRENT_THEME = "dark"
        else
            set MY_CURRENT_THEME = "light"
        endif
        set MY_THEME_SAVE_CONFIG = "1"
        breaksw
    case "light":
    case "dark":
        set MY_CURRENT_THEME = "$1"
        set MY_THEME_SAVE_CONFIG = "1"
        breaksw
    default:
        echo "Usage: source $0 [toggle|light|dark]"
        goto end
    endsw
endif

# Always export theme and apply LS_COLORS (for both RC and manual changes)
setenv MY_CURRENT_THEME "$MY_CURRENT_THEME"

which vivid >& /dev/null
if ( $status == 0 ) then
    if ( "$MY_CURRENT_THEME" == "light" ) then
        setenv LS_COLORS `vivid generate gruvbox-light`
    else
        setenv LS_COLORS `vivid generate tokyonight-night`
    endif
endif

# which fzf >& /dev/null
# if ( $status == 0 ) then
#     set FZF_GRUVBOX = " --color=bg+:#F2E5BC,bg:#FBF1C7,spinner:#D65D0E,hl:#B57614 --color=fg:#3C3836,header:#B57614,info:#8F3F71,pointer:#D65D0E --color=marker:#076678,fg+:#282828,prompt:#8F3F71,hl+:#B57614 --color=selected-bg:#EBDBB2 --color=border:#D5C4A1,label:#3C3836"
#     set FZF_CATPPUCCIN = "--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 --color=selected-bg:#494D64 --color=border:#363A4F,label:#CAD3F5"
#     if ( ! $?MY_FZF_OPTS_NO_COLOR ) then
#         set MY_FZF_OPTS_NO_COLOR = ""
#     endif
#     if ( "$MY_CURRENT_THEME" == "light" ) then
#         setenv FZF_DEFAULT_OPTS "$MY_FZF_OPTS_NO_COLOR $FZF_GRUVBOX"
#     else
#         setenv FZF_DEFAULT_OPTS "$MY_FZF_OPTS_NO_COLOR $FZF_CATPPUCCIN"
#     endif
# endif
    
# Save theme to file
if ( "$MY_THEME_SAVE_CONFIG" != "" ) then
    mkdir -p "`dirname $MY_CURRENT_THEME_FILE`"
    echo "$MY_CURRENT_THEME" > "$MY_CURRENT_THEME_FILE"
    echo "Theme set to $MY_CURRENT_THEME"
endif

if ( "$MY_THEME_SET_TMUX" != "" ) then
    tmux list-sessions >& /dev/null
    if ( $status == 0 ) then
        tmux set-environment MY_CURRENT_THEME "$MY_CURRENT_THEME"
        tmux show-options -g | grep -E -o "^@\w+\s" | grep -E "@(_ctp|batt_|cpu_|ram_|thm_|catppuccin_)" | sed "s/^/set -Ugq /" | tr "\n" ";" | tmux source-file -
        tmux source-file "$HOME/.tmux.conf"
        
        # Broadcast to other tmux panes if tmux-broadcast exists
        which tmux-broadcast >& /dev/null
        if ( $status == 0 ) then
            tmux-broadcast "source $HOME/.config/colortheme/apply-theme.csh"
        endif
    endif
endif

end:
__my_fzf_cleanup
unalias __my_fzf_cleanup
