#!/usr/bin/env bash

# Claude Code Statusline - Real-time stats display
# https://github.com/nomadec/claude-statusline

# Read JSON input from stdin and save it
input=$(cat)

# Extract values
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
current_usage=$(echo "$input" | jq -r '.context_window.current_usage')

# Use full path (replace home with ~)
dir="${cwd/#$HOME/~}"

# Calculate context percentage from current_usage
ctx_percent=""
if [ "$current_usage" != "null" ] && [ "$context_size" != "null" ] && [ "$context_size" -gt 0 ]; then
    input_tokens=$(echo "$current_usage" | jq -r '.input_tokens // 0')
    output_tokens=$(echo "$current_usage" | jq -r '.output_tokens // 0')
    cache_creation=$(echo "$current_usage" | jq -r '.cache_creation_input_tokens // 0')
    cache_read=$(echo "$current_usage" | jq -r '.cache_read_input_tokens // 0')

    total_current=$((input_tokens + output_tokens + cache_creation + cache_read))
    ctx_percent=$((total_current * 100 / context_size))
fi

# Color based on context usage
if [ -n "$ctx_percent" ]; then
    if [ "$ctx_percent" -lt 65 ]; then
        ctx_color="32"  # green
    elif [ "$ctx_percent" -lt 75 ]; then
        ctx_color="33"  # yellow
    else
        ctx_color="31"  # red
    fi
fi

# Get git info
branch=""
git_status=""
upstream=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)

    # Check for upstream
    if git -C "$cwd" rev-parse --abbrev-ref @{u} > /dev/null 2>&1; then
        ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null)
        behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null)
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
            upstream="↑${ahead}↓${behind}"
        elif [ "$ahead" -gt 0 ]; then
            upstream="↑${ahead}"
        elif [ "$behind" -gt 0 ]; then
            upstream="↓${behind}"
        fi
    fi

    # Check status
    if ! git -C "$cwd" -c core.useBuiltinFSMonitor=false diff --quiet 2>/dev/null || \
       ! git -C "$cwd" -c core.useBuiltinFSMonitor=false diff --cached --quiet 2>/dev/null; then
        git_status="!"
        git_color="31"
    elif [ -n "$(git -C "$cwd" -c core.useBuiltinFSMonitor=false ls-files --others --exclude-standard 2>/dev/null)" ]; then
        git_status="?"
        git_color="32"
    fi
fi

# Get ccusage data
session_cost=""
today_cost=""
block_info=""
if command -v npx &> /dev/null; then
    ccusage_out=$(echo "$input" | npx -y ccusage@latest statusline --cost-source cc 2>/dev/null)
    if [ -n "$ccusage_out" ]; then
        # Extract session cost (first dollar amount after money emoji)
        session_cost=$(echo "$ccusage_out" | sed -n 's/.*💰 *\$\([0-9.]*\).*/\1/p')
        if [ -n "$session_cost" ]; then
            session_cost="\$${session_cost}"
        fi
        # Extract today cost
        today_cost=$(echo "$ccusage_out" | sed -n 's/.*\$\([0-9.]*\) today.*/\1/p')
        if [ -n "$today_cost" ]; then
            today_cost="\$${today_cost}"
        fi
        # Extract block cost with time remaining
        block_info=$(echo "$ccusage_out" | grep -oE '\$[0-9]+\.[0-9]+ block \([^)]+\)')
    fi
fi

# Build output
output="\033[32m${dir}\033[0m"

if [ -n "$branch" ]; then
    output="${output} on \033[35m${branch}\033[0m"
    [ -n "$upstream" ] && output="${output}\033[36m${upstream}\033[0m"
    [ -n "$git_status" ] && output="${output}\033[${git_color}m${git_status}\033[0m"
fi

output="${output} [\033[35m${model}\033[0m"

# Add session cost
if [ -n "$session_cost" ]; then
    output="${output} | \033[33m${session_cost}\033[0m"
fi

# Add context percentage
if [ -n "$ctx_percent" ]; then
    output="${output} | CTX: \033[${ctx_color}m${ctx_percent}%\033[0m"
fi

output="${output}]"

# Add daily summary in separate brackets
if [ -n "$today_cost" ] || [ -n "$block_info" ]; then
    output="${output} \033[90m("
    [ -n "$today_cost" ] && output="${output}today: ${today_cost}"
    if [ -n "$block_info" ]; then
        [ -n "$today_cost" ] && output="${output} | "
        output="${output}${block_info}"
    fi
    output="${output})\033[0m"
fi

printf "%b" "$output"
