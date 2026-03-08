#!/usr/bin/env bash
set -eu

# OSC 11 terminal background detection → stdout
# Read-only probe: prints "light" or "dark" to stdout on success, nothing on failure.
# Kept as separate bash script: needs BASH_REMATCH, $((16#xx))

debug=0
[[ "${1:-}" == "--debug" ]] && debug=1

dbg() { (( debug )) && printf '[detect-terminal-theme] %s\n' "$*" >&2 || true; }

dbg "tty=$(tty 2>/dev/null || echo none) TMUX=${TMUX:+set} TERM=$TERM"

# Save/restore TTY state (canonical mode must be off for OSC read)
OLD_STTY=$(stty -g < /dev/tty 2>/dev/null || true)
trap 'stty "$OLD_STTY" < /dev/tty 2>/dev/null || true' EXIT
stty -echo -icanon < /dev/tty 2>/dev/null || { dbg "stty failed"; exit 0; }

# Drain any pending input before querying
while IFS= read -rn1 -t 0.1 _ < /dev/tty 2>/dev/null; do :; done

# Query terminal background via OSC 11
# Plain OSC works both inside and outside tmux.
# DCS passthrough (\ePtmux;...) does NOT route responses back.
dbg "sending OSC 11 query"
printf '\e]11;?\a' > /dev/tty

# Read response char-by-char (handles both BEL and ST terminators)
response=""
prev=""
while IFS= read -rn1 -t 1 char < /dev/tty; do
    if [[ "$char" == $'\a' ]]; then break; fi
    if [[ "$char" == '\' && "$prev" == $'\e' ]]; then
        response="${response%?}"
        break
    fi
    prev="$char"
    response+="$char"
done
dbg "raw response: $(printf '%s' "$response" | cat -v)"

if [[ "$response" =~ rgb:([0-9a-fA-F]{2,4})/([0-9a-fA-F]{2,4})/([0-9a-fA-F]{2,4}) ]]; then
    r=${BASH_REMATCH[1]:0:2} g=${BASH_REMATCH[2]:0:2} b=${BASH_REMATCH[3]:0:2}
    dbg "hex r=$r g=$g b=$b"
    r=$((16#$r)) g=$((16#$g)) b=$((16#$b))
    lum=$(( (2126*r + 7152*g + 722*b) / 10000 ))
    dbg "luminance=$lum (>128 = light)"
    if (( lum > 128 )); then echo "light"; else echo "dark"; fi
else
    dbg "no RGB match — detection failed"
    exit 0
fi
