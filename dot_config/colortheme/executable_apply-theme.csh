# tcsh theme script - can be sourced for both RC and manual changes

# temp variables
set MY_CURRENT_THEME = ""
set MY_CURRENT_THEME_FILE = "$HOME/.config/.current_theme"
set MY_THEME_SET_TMUX = ""
set MY_THEME_SAVE_CONFIG = ""

alias __apply_theme_cleanup ' \
    unset MY_CURRENT_THEME \
    unset MY_CURRENT_THEME_FILE \
    unset MY_THEME_SET_TMUX \
    unset MY_THEME_SAVE_CONFIG \
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
__apply_theme_cleanup
unalias __apply_theme_cleanup
