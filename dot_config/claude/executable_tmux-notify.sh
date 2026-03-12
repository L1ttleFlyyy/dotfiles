#!/bin/bash
[ -z "$TMUX" ] && exit 0
read -r input
message=$(echo "$input" | jq -r '.message // "Claude Code"')
printf '\033Ptmux;\033\033]9;%s\007\033\' "$message" > /dev/tty
