#!/bin/bash
# Claude Code Status Line - Inspired by Powerlevel10k
# Shows: model │ context% │ git │ worktree │ cwd │ proxy

SEP=" \033[90m│\033[0m "

# Nerd Font icons (raw UTF-8 bytes — bash 3.2 compat)
icon_brain=$'\xF3\xB1\x9A\xA4'       # U+F16A4 nf-md-robot
icon_git=$'\xEE\x9C\x82'             # U+E702  nf-dev-git_branch
icon_folder=$'\xEF\x81\xBC'          # U+F07C  nf-fa-folder_open
icon_worktree=$'\xEF\x84\xA6'        # U+F126  nf-fa-code_fork
icon_ctx=$'\xF3\xB0\x8D\x9B'         # U+F035B nf-md-chip

# Parse JSON input with single jq call using @sh for efficiency
eval "$(cat | jq -r '
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "model=\(.model.display_name // "")",
  @sh "input_tokens=\(.context_window.current_usage.input_tokens // 0)",
  @sh "cache_create=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
  @sh "cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)",
  @sh "ctx_size=\(.context_window.context_window_size // 200000)",
  @sh "worktree_name=\(.worktree.name // "")"
')"

# Calculate context percentage using bash arithmetic
total_tokens=$((input_tokens + cache_create + cache_read))
if [ "$ctx_size" -gt 0 ]; then
    ctx_int=$((total_tokens * 100 / ctx_size))
else
    ctx_int=0
fi

# --- Model (dynamic extraction: family + version + optional context tag) ---
model_lc=$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')
if   [[ "$model_lc" == *opus* ]];   then family="Opus"
elif [[ "$model_lc" == *sonnet* ]]; then family="Sonnet"
elif [[ "$model_lc" == *haiku* ]];  then family="Haiku"
else family=""
fi

if [ -n "$family" ]; then
    version=$(printf '%s' "$model_lc" | grep -oE '[0-9]+[.-][0-9]+' | head -1 | tr '-' '.')
    model_ctx=$(printf '%s' "$model" | grep -oiE '[0-9]+[km] context' | grep -oiE '[0-9]+[km]' | tr '[:lower:]' '[:upper:]')
    model_short="${family}${version:+ $version}${model_ctx:+ (${model_ctx})}"
else
    model_short="${model:-unknown}"
fi

# --- Human-readable token count: 20000 → 20k, 1500000 → 1.5M ---
human_tokens() {
    local n=$1
    if   [[ $n -ge 1000000 ]]; then printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
    elif [[ $n -ge 1000 ]];    then printf "%dk"   $(( n / 1000 ))
    else                             printf "%d"    "$n"
    fi
}

used=$(human_tokens "$total_tokens")
limit=$(human_tokens "$ctx_size")

# Progress bar: 10-char bar
filled=$((ctx_int / 10))
empty=$((10 - filled))

bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Color: green <60%, yellow 60-80%, red >=80%
if [ "$ctx_int" -lt 60 ]; then
    ctx_color="\033[32m"  # green
elif [ "$ctx_int" -lt 80 ]; then
    ctx_color="\033[33m"  # yellow
else
    ctx_color="\033[31m"  # red
fi

ctx_display="\033[36m${icon_ctx}\033[0m ${ctx_color}${bar}\033[0m \033[36m${used}/${limit}\033[0m"

# Debug mode: set DEBUG_STATUSLINE=1 to see raw values
if [ "$DEBUG_STATUSLINE" = "1" ]; then
    echo "DEBUG: input=$input_tokens cache_create=$cache_create cache_read=$cache_read total=$total_tokens size=$ctx_size" >&2
fi

# --- Directory (simplified p10k-style) ---
shorten_dir() {
    local dir="$1"
    local anchor_files=".git .p4config .bzr .hg .svn CVS Cargo.toml go.mod package.json"

    # Expand ~ for home
    local tilde='~'
    dir="${dir/#$HOME/$tilde}"

    # Split into array
    IFS='/' read -ra parts <<< "$dir"
    local len=${#parts[@]}

    # Find last anchor (searching from end)
    local anchor_idx=-1
    local check_path=""
    for ((i=0; i<len; i++)); do
        if [ "${parts[i]}" = "~" ]; then
            check_path="$HOME"
        elif [ -n "${parts[i]}" ]; then
            check_path="$check_path/${parts[i]}"
        fi

        for marker in $anchor_files; do
            if [ -e "$check_path/$marker" ]; then
                anchor_idx=$i
                break
            fi
        done
    done

    # Determine start index
    local start=0
    if [ "$anchor_idx" -ge 0 ]; then
        start=$anchor_idx
    fi

    # Build shortened path (no segment limit)
    local result=""
    local prefix=""
    if [ "$start" -gt 0 ]; then
        prefix=""
    fi

    for ((i=start; i<len; i++)); do
        if [ -n "${parts[i]}" ]; then
            if [ -n "$result" ]; then
                result="$result/"
            fi
            result="$result${parts[i]}"
        fi
    done

    echo "${prefix}${result}"
}

dir_display=$(shorten_dir "$cwd")

# --- Git (rich p10k-style) ---
git_info=""
if [ -n "$cwd" ] && GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    [ -z "$branch" ] && branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null || echo "detached")

    git_suffix=""

    # ahead/behind remote
    ahead=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count '@{upstream}..HEAD' 2>/dev/null) || ahead=0
    behind=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count 'HEAD..@{upstream}' 2>/dev/null) || behind=0
    [[ "$behind" -gt 0 ]] && git_suffix+=" \033[36m⇣${behind}\033[0m"
    [[ "$ahead"  -gt 0 ]] && git_suffix+=" \033[36m⇡${ahead}\033[0m"

    # stashes
    stashes=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" stash list 2>/dev/null | wc -l)
    stashes=$(( stashes + 0 ))
    [[ "$stashes" -gt 0 ]] && git_suffix+=" \033[36m*${stashes}\033[0m"

    # staged (+), unstaged (!), untracked (?), conflicted (~)
    staged=0 unstaged=0 untracked=0 conflicted=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        x="${line:0:1}" y="${line:1:1}"
        if [[ "$x$y" == "UU" || "$x$y" == "AA" || "$x$y" == "DD" || \
              "$x" == "U" || "$y" == "U" ]]; then
            (( conflicted++ ))
        else
            [[ "$x" == "?" ]]                              && (( untracked++ ))
            [[ "$x" != "?" && "$x" != " " && "$x" != "!" ]] && (( staged++ ))
            [[ "$y" != " " && "$y" != "?" && "$y" != "!" ]] && (( unstaged++ ))
        fi
    done < <(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain 2>/dev/null)

    [[ $conflicted -gt 0 ]] && git_suffix+=" \033[31m~${conflicted}\033[0m"
    [[ $staged     -gt 0 ]] && git_suffix+=" \033[32m+${staged}\033[0m"
    [[ $unstaged   -gt 0 ]] && git_suffix+=" \033[33m!${unstaged}\033[0m"
    [[ $untracked  -gt 0 ]] && git_suffix+=" \033[34m?${untracked}\033[0m"

    # branch color: green=clean, yellow=dirty
    if [[ $staged -gt 0 || $unstaged -gt 0 || $untracked -gt 0 || $conflicted -gt 0 ]]; then
        git_info="\033[33m${icon_git} ${branch}\033[0m${git_suffix}"
    else
        git_info="\033[32m${icon_git} ${branch}\033[0m${git_suffix}"
    fi
fi

# --- Worktree ---
wt_info=""
if [ -n "$worktree_name" ]; then
    wt_info="\033[35m${icon_worktree} ${worktree_name}\033[0m"
fi

# --- Output ---
output="\033[1;35m${icon_brain} ${model_short}\033[0m${SEP}${ctx_display}"

_port="${APPLE_CLAUDE_CODE_PORT:-$PROXY_PORT}"
if [ -n "$_port" ]; then
    output="${output}${SEP}\033[36mhttp://localhost:${_port}\033[0m"
fi

if [ -n "$git_info" ]; then
    output="${output}${SEP}${git_info}"
fi

if [ -n "$wt_info" ]; then
    output="${output}${SEP}${wt_info}"
fi

output="${output}${SEP}\033[34m${icon_folder} ${dir_display}\033[0m"

printf "%b" "$output"
