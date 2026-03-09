#!/usr/bin/env bash
# Claude Code status line
# ~/.config/claude/claude-statusline.sh

input=$(cat)


# ── helpers ────────────────────────────────────────────────────────────────────
jq_val() { printf '%s' "$input" | jq -r "$1"; }

# ANSI-16 color helpers (work with terminal's dim palette)
c_reset='\e[0m'
c_green='\e[32m'
c_yellow='\e[33m'
c_red='\e[31m'
c_cyan='\e[36m'
c_blue='\e[34m'
c_dim='\e[2m'
c_bold='\e[1m'

# ── model ──────────────────────────────────────────────────────────────────────
model=$(jq_val '.model.display_name // .model.id // "Claude"')

# ── context progress bar ───────────────────────────────────────────────────────
used_pct=$(jq_val '.context_window.used_percentage // empty')
total=$(jq_val '.context_window.context_window_size // 0')
used_tokens=$(jq_val '
  .context_window as $ctx |
  (($ctx.current_usage.input_tokens // 0)
   + ($ctx.current_usage.cache_creation_input_tokens // 0)
   + ($ctx.current_usage.cache_read_input_tokens // 0))
  | if . == 0 then ($ctx.total_input_tokens // 0) else . end
')

build_bar() {
    local pct="${1:-0}"
    local filled=$(( (pct * 10 + 50) / 100 ))  # round
    [[ $filled -gt 10 ]] && filled=10
    local empty=$(( 10 - filled ))
    local bar=""
    local i
    for (( i=0; i<filled; i++ )); do bar+="▓"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done

    local color
    if   [[ $pct -ge 80 ]]; then color="$c_red"
    elif [[ $pct -ge 60 ]]; then color="$c_yellow"
    else                         color="$c_green"
    fi

    printf "${color}%s${c_reset}" "$bar"
}

# human-readable token count: 20000 → 20k, 1500000 → 1.5M
human_tokens() {
    local n=$1
    if   [[ $n -ge 1000000 ]]; then printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
    elif [[ $n -ge 1000 ]];    then printf "%dk"   $(( n / 1000 ))
    else                             printf "%d"    "$n"
    fi
}

pct_int=$(printf '%.0f' "${used_pct:-0}")
bar=$(build_bar "$pct_int")
if [[ -n "$used_pct" && -n "$total" && "$total" != "0" ]]; then
    used_h=$(human_tokens "$used_tokens")
    total_h=$(human_tokens "$total")
    ctx_part="${bar} ${c_dim}${used_h}/${total_h}${c_reset}"
else
    ctx_part="${bar}"
fi

# ── git status ─────────────────────────────────────────────────────────────────
cwd=$(jq_val '.workspace.current_dir // .cwd // "."')

git_part=""
if branch=$(GIT_DIR="${cwd}/.git" GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
            || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
    # check dirty (untracked+modified), fast
    if GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain 2>/dev/null | grep -q .; then
        git_part="${c_yellow} ${branch}*${c_reset}"
    else
        git_part="${c_green} ${branch}${c_reset}"
    fi
fi

# ── shortened pwd ──────────────────────────────────────────────────────────────
anchor_files=(
    .bzr .citc .git .p4config .hg
    .node-version .python-version .go-version .ruby-version .lua-version
    .java-version .perl-version .php-version .tool-versions
    .mise.toml .shorten_folder_marker .svn .terraform
    CVS Cargo.toml composer.json go.mod package.json stack.yaml
)

short_pwd() {
    local dir="$1"
    local home="$HOME"
    local anchor_root=""

    # walk from dir upward, find the deepest (last) anchor
    local cur="$dir"
    while [[ "$cur" != "/" && "$cur" != "$home" && -n "$cur" ]]; do
        for f in "${anchor_files[@]}"; do
            if [[ -e "${cur}/${f}" ]]; then
                anchor_root="$cur"
                break
            fi
        done
        [[ -n "$anchor_root" ]] && break
        cur="${cur%/*}"
        [[ -z "$cur" ]] && cur="/"
    done

    local display
    if [[ -n "$anchor_root" ]]; then
        # show from anchor_root's parent basename down
        local parent="${anchor_root%/*}"
        if [[ -z "$parent" ]]; then parent="/"; fi
        local rel="${dir#"$anchor_root"}"
        local root_name="${anchor_root##*/}"
        if [[ "$parent" == "$home" || "$parent" == "/" ]]; then
            display="${root_name}${rel}"
        else
            display="…/${root_name}${rel}"
        fi
    else
        # no anchor: tilde-collapse and show last 2 segments
        display="${dir/#$home/\~}"
        # shorten to last 2 path parts if deep
        local IFS='/'
        read -ra parts <<< "${display#\~/}"
        local n=${#parts[@]}
        if [[ $n -gt 2 ]]; then
            display="~/${parts[$((n-2))]}/${parts[$((n-1))]}"
            [[ "${display:0:1}" != "~" ]] && display="…/${parts[$((n-2))]}/${parts[$((n-1))]}"
        fi
    fi

    # re-apply ~ if starts with home
    display="${display/#$home/\~}"
    printf '%s' "$display"
}

pwd_part="${c_blue}$(short_pwd "$cwd")${c_reset}"

# ── assemble ───────────────────────────────────────────────────────────────────
sep="${c_dim} │ ${c_reset}"

out="${c_bold}${model}${c_reset}"
out+="${sep}${ctx_part}"
[[ -n "$git_part" ]] && out+="${sep}${git_part}"
out+="${sep}${pwd_part}"

printf "%b\n" "$out"
