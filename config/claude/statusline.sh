#!/usr/bin/env zsh
# =============================================================================
# Claude Code 3-line statusline — tuned for vibe-coding monitoring
# =============================================================================
# Line 1 — IDENTITY:  cwd · branch[*] [↑↓] · model              [⚡AUTO/📋PLAN]
# Line 2 — BURN:      ctx [bar] %  ·  in/out/cache tokens  ·  $cost
# Line 3 — VELOCITY:  +adds -dels · Nm wall (P% api) · style · HH:MM
# =============================================================================

set -u

# -----------------------------------------------------------------------------
# Read JSON input
# -----------------------------------------------------------------------------
input="$(cat)"

# Bail quietly if jq is missing
if ! command -v jq >/dev/null 2>&1; then
    printf '%s' "(install jq for statusline)"
    exit 0
fi

J() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

# -----------------------------------------------------------------------------
# Extract all params up front
# -----------------------------------------------------------------------------
cwd="$(J '.workspace.current_dir // .cwd')"
project_dir="$(J '.workspace.project_dir')"
model_name="$(J '.model.display_name')"
version="$(J '.version')"
output_style="$(J '.output_style.name')"
permission_mode="$(J '.permission_mode')"

cost_usd="$(J '.cost.total_cost_usd')"
duration_ms="$(J '.cost.total_duration_ms')"
api_ms="$(J '.cost.total_api_duration_ms')"
lines_added="$(J '.cost.total_lines_added')"
lines_removed="$(J '.cost.total_lines_removed')"

ctx_pct="$(J '.context_window.remaining_percentage')"
tok_in="$(J '.context_window.input_tokens')"
tok_out="$(J '.context_window.output_tokens')"
tok_cache="$(J '.context_window.cached_tokens')"

# -----------------------------------------------------------------------------
# Color helpers (no-op when not a TTY)
# -----------------------------------------------------------------------------
if [ -t 1 ] || [ "${FORCE_COLOR:-0}" = "1" ]; then
    C_RESET=$'\033[0m'      C_BOLD=$'\033[1m'        C_DIM=$'\033[2m'
    C_RED=$'\033[31m'       C_GRN=$'\033[32m'        C_YEL=$'\033[33m'
    C_BLU=$'\033[34m'       C_MAG=$'\033[35m'        C_CYA=$'\033[36m'
    C_GRY=$'\033[90m'
    C_BRED=$'\033[1;31m'    C_BYEL=$'\033[1;33m'     C_BMAG=$'\033[1;35m'
else
    C_RESET= C_BOLD= C_DIM= C_RED= C_GRN= C_YEL= C_BLU= C_MAG= C_CYA= C_GRY=
    C_BRED= C_BYEL= C_BMAG=
fi

# -----------------------------------------------------------------------------
# Formatters
# -----------------------------------------------------------------------------

# Abbreviate $HOME → ~ and trim to last 3 path segments
fmt_path() {
    local p="$1"
    [ -z "$p" ] && return
    p="${p/#$HOME/~}"
    local segs="${p//[^\/]/}"
    if [ "${#segs}" -gt 3 ]; then
        # keep last 3 segments, prefix with …
        p="…/$(echo "$p" | awk -F/ '{print $(NF-2)"/"$(NF-1)"/"$NF}')"
    fi
    printf '%s' "$p"
}

# 12345 → 12.3k, 1234567 → 1.2M
fmt_num() {
    local n="$1"
    [ -z "$n" ] || [ "$n" = "0" ] && { printf '0'; return; }
    awk -v n="$n" 'BEGIN {
        if (n < 1000)        printf "%d", n
        else if (n < 1e6)    printf "%.1fk", n/1000
        else                 printf "%.1fM", n/1e6
    }'
}

# Pretty duration: 23m, 1h12m, 45s
fmt_duration() {
    local ms="$1"
    [ -z "$ms" ] || [ "$ms" = "0" ] && { printf '0s'; return; }
    awk -v ms="$ms" 'BEGIN {
        s = int(ms/1000)
        h = int(s/3600); m = int((s%3600)/60); ss = s%60
        if (h > 0)      printf "%dh%dm", h, m
        else if (m > 0) printf "%dm", m
        else            printf "%ds", ss
    }'
}

# Build a 10-cell context bar
ctx_bar() {
    local pct="$1"
    [ -z "$pct" ] && { printf '          '; return; }
    awk -v p="$pct" 'BEGIN {
        filled = int(p / 10 + 0.5)
        if (filled > 10) filled = 10
        if (filled < 0)  filled = 0
        for (i=0; i<filled; i++)  printf "▓"
        for (i=filled; i<10; i++) printf "░"
    }'
}

# -----------------------------------------------------------------------------
# Git info
# -----------------------------------------------------------------------------
git_branch=""
git_dirty=""
git_ahead=""
git_behind=""
if [ -n "$cwd" ]; then
    cwd_real="${cwd/#\~/$HOME}"
    if [ -d "$cwd_real/.git" ] || GIT_OPTIONAL_LOCKS=0 git -C "$cwd_real" rev-parse --git-dir >/dev/null 2>&1; then
        git_branch="$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd_real" symbolic-ref --short HEAD 2>/dev/null \
                       || GIT_OPTIONAL_LOCKS=0 git -C "$cwd_real" rev-parse --short HEAD 2>/dev/null)"
        if [ -n "$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd_real" status --porcelain 2>/dev/null)" ]; then
            git_dirty="✱"
        fi
        # Ahead/behind vs upstream
        local_remote="$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd_real" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)"
        if [ -n "$local_remote" ]; then
            git_behind="${local_remote%%[[:space:]]*}"
            git_ahead="${local_remote##*[[:space:]]}"
            [ "$git_ahead"  = "0" ] && git_ahead=""
            [ "$git_behind" = "0" ] && git_behind=""
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Build line 1 — IDENTITY
# -----------------------------------------------------------------------------
line1=""
[ -n "$cwd" ]        && line1+="${C_CYA}$(fmt_path "$cwd")${C_RESET}"
if [ -n "$git_branch" ]; then
    line1+="${C_DIM} · ${C_RESET}${C_MAG}${git_branch}${C_RESET}"
    [ -n "$git_dirty"  ] && line1+="${C_RED}${git_dirty}${C_RESET}"
    [ -n "$git_ahead"  ] && line1+=" ${C_YEL}↑${git_ahead}${C_RESET}"
    [ -n "$git_behind" ] && line1+=" ${C_YEL}↓${git_behind}${C_RESET}"
fi
[ -n "$model_name" ] && line1+="${C_DIM} · ${C_RESET}${C_BYEL}●${model_name}${C_RESET}"

# Permission-mode warning (only if non-default)
case "$permission_mode" in
    auto|bypassPermissions|acceptEdits)
        mode_label="$(printf '%s' "$permission_mode" | tr '[:lower:]' '[:upper:]')"
        line1+="   ${C_BRED}⚡${mode_label}${C_RESET}"
        ;;
    plan)
        line1+="   ${C_BMAG}📋PLAN${C_RESET}"
        ;;
esac

# -----------------------------------------------------------------------------
# Build line 2 — BURN (context, tokens, cost)
# -----------------------------------------------------------------------------
line2=""
if [ -n "$ctx_pct" ]; then
    pct_int=$(awk -v p="$ctx_pct" 'BEGIN { printf "%d", p+0.5 }')
    if   [ "$pct_int" -le 10 ]; then bar_color="$C_RED"
    elif [ "$pct_int" -le 30 ]; then bar_color="$C_YEL"
    else                              bar_color="$C_GRN"
    fi
    line2+="${C_DIM}ctx${C_RESET} ${bar_color}$(ctx_bar "$pct_int")${C_RESET} ${C_BOLD}${pct_int}%${C_RESET}"
fi

tokens_part=""
[ -n "$tok_in"    ] && [ "$tok_in"    != "0" ] && tokens_part+="${C_DIM}in${C_RESET} ${C_GRN}$(fmt_num "$tok_in")${C_RESET}"
[ -n "$tok_out"   ] && [ "$tok_out"   != "0" ] && tokens_part+="${tokens_part:+ ${C_DIM}·${C_RESET} }${C_DIM}out${C_RESET} ${C_YEL}$(fmt_num "$tok_out")${C_RESET}"
[ -n "$tok_cache" ] && [ "$tok_cache" != "0" ] && tokens_part+="${tokens_part:+ ${C_DIM}·${C_RESET} }${C_DIM}cache${C_RESET} ${C_DIM}$(fmt_num "$tok_cache")${C_RESET}"
[ -n "$tokens_part" ] && line2+="${line2:+   }${tokens_part}"

if [ -n "$cost_usd" ]; then
    cost_int=$(awk -v c="$cost_usd" 'BEGIN { printf "%d", c+0.5 }')
    cost_disp=$(awk -v c="$cost_usd" 'BEGIN { printf "%.2f", c }')
    if [ "$cost_disp" != "0.00" ]; then
        if   [ "$cost_int" -ge 5 ]; then cost_color="$C_BRED"
        else                             cost_color="$C_BYEL"
        fi
        line2+="${line2:+   }${cost_color}\$${cost_disp}${C_RESET}"
    fi
fi

# -----------------------------------------------------------------------------
# Build line 3 — VELOCITY (edits, time, api ratio, style, clock)
# -----------------------------------------------------------------------------
line3=""
edits_part=""
[ -n "$lines_added"   ] && [ "$lines_added"   != "0" ] && edits_part+="${C_GRN}+${lines_added}${C_RESET}"
[ -n "$lines_removed" ] && [ "$lines_removed" != "0" ] && edits_part+="${edits_part:+ }${C_RED}−${lines_removed}${C_RESET}"
[ -n "$edits_part" ] && line3+="${edits_part}"

if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
    wall=$(fmt_duration "$duration_ms")
    api_ratio=""
    if [ -n "$api_ms" ] && [ "$api_ms" != "0" ]; then
        api_ratio=$(awk -v a="$api_ms" -v w="$duration_ms" 'BEGIN { if (w>0) printf "%d", (a*100/w)+0.5; else printf "0" }')
    fi
    seg="${C_DIM}${wall} wall${C_RESET}"
    [ -n "$api_ratio" ] && seg+="${C_DIM} (${api_ratio}% api)${C_RESET}"
    line3+="${line3:+ ${C_DIM}·${C_RESET} }${seg}"
fi

# Output style only if non-default
if [ -n "$output_style" ] && [ "$output_style" != "default" ] && [ "$output_style" != "null" ]; then
    line3+="${line3:+ ${C_DIM}·${C_RESET} }${C_DIM}style:${output_style}${C_RESET}"
fi

# Version dim
[ -n "$version" ] && line3+="${line3:+ ${C_DIM}·${C_RESET} }${C_DIM}v${version}${C_RESET}"

# Clock
line3+="${line3:+ ${C_DIM}·${C_RESET} }${C_YEL}$(date +%H:%M)${C_RESET}"

# -----------------------------------------------------------------------------
# Emit (drop empty lines so visible line count = info available)
# -----------------------------------------------------------------------------
[ -n "$line1" ] && printf '%s\n' "$line1"
[ -n "$line2" ] && printf '%s\n' "$line2"
[ -n "$line3" ] && printf '%s'   "$line3"
