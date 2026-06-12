#!/usr/bin/env zsh
# tools profile — shell integration for the mise-managed CLI tools.
#
# Sourced by ~/.zshrc's conf.d loop (after mise activates, so tool shims are on
# PATH). This is shell config — aliases, env, fzf/zoxide init — NOT package
# lifecycle (install lives in the mise conf.d manifest, profiles/tools/config/mise).
#
# Each block self-gates on `command -v <tool>` so a tool absent from PATH (tools
# profile not applied, or before `mise install` ran) silently no-ops.

# ── bat ──────────────────────────────────────────────────────────────────────
# Use bat as the man pager unless the user already chose one.
if command -v bat &>/dev/null && [[ -z "${MANPAGER:-}" ]]; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ── eza ──────────────────────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
  typeset _e="eza --group-directories-first --icons=auto"
  alias ls="$_e"
  alias la="$_e -a"
  alias ll="$_e -l --git --time-style=relative"
  alias lla="$_e -la --git --time-style=relative"
  alias tree="$_e --tree"   # replaces the `tree` binary (no longer installed)
  alias lt="$_e --tree"
  alias lt2="$_e --tree --level=2"
  alias lt3="$_e --tree --level=3"
  alias lta="$_e --tree -a"
  alias lm="$_e -l --sort=modified --reverse --time-style=relative"
  alias lz="$_e -l --sort=size --reverse"
  unset _e
fi

# ── vivid (LS_COLORS) ─────────────────────────────────────────────────────────
# Generate LS_COLORS from the custom catppuccin-mocha theme (red → repo accent
# #ff5189). Cached + regenerated only when the theme file changes (vivid is ~10ms),
# mirroring the sheldon/compinit caching idiom. zsh completion lists reuse it via
# list-colors, read at completion time so module order vs compinit is irrelevant.
if command -v vivid &>/dev/null; then
  _vivid_theme="${XDG_CONFIG_HOME:-$HOME/.config}/vivid/themes/catppuccin-mocha-red.yml"
  _vivid_cache="$ZSH_CACHE_DIR/ls_colors"
  if [[ ! -r "$_vivid_cache" || "$_vivid_theme" -nt "$_vivid_cache" ]]; then
    vivid generate "$_vivid_theme" >| "$_vivid_cache" 2>/dev/null
  fi
  export LS_COLORS="$(<"$_vivid_cache")"
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
  unset _vivid_theme _vivid_cache
fi

# ── fd ───────────────────────────────────────────────────────────────────────
# --follow: cross symlinks. --hidden: include dotfiles (exclusions live in
# config/fd/ignore so they stay version-controlled out of this env var).
command -v fd &>/dev/null && export FD_OPTIONS="--follow --hidden"

# ── ripgrep ──────────────────────────────────────────────────────────────────
command -v rg &>/dev/null &&
  export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/ripgrep/ripgreprc"

# ── fzf (before zoxide so _ZO_FZF_OPTS can inherit FZF defaults) ──────────────
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_COMMAND="fd --type f"
  # Layout + preview UX. Preview sits right at 60% with a wrapped, scrollable pane,
  # and flips below the list on narrow terminals (<90 cols) so it never gets crushed.
  # Preview controls:
  #   ctrl-/      cycle preview: large (down 75%) → hidden → default (right 60%)
  #   ctrl-f/-b   page the preview down / up
  #   shift-↓/-↑  scroll the preview one line
  #   alt-↓/-↑    jump the preview to bottom / top
  # Query-editing keys (ctrl-u/-w/-a/-e) keep their fzf defaults — none are stolen.
  export FZF_DEFAULT_OPTS="--height=80% --min-height=20 --multi --layout=reverse --cycle \
    --border=rounded --margin=0,1 --info=inline-right --scrollbar='█│' --separator='─' \
    --prompt='❯ ' --pointer='▶' --marker='✚' \
    --preview-window='right,60%,border-left,wrap,<90(down,60%,border-top)' \
    --bind='ctrl-/:change-preview-window(down,75%,border-top|hidden|)' \
    --bind='ctrl-f:preview-page-down,ctrl-b:preview-page-up' \
    --bind='shift-down:preview-down,shift-up:preview-up' \
    --bind='alt-down:preview-bottom,alt-up:preview-top' \
    --color bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#ff5189 \
    --color fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#ff5189 \
    --color marker:#ff5189,fg+:#cdd6f4,prompt:#cba6f7,hl+:#ff5189 \
    --color selected-bg:#45475a,border:#313244,label:#cdd6f4"
  # History search: no preview (the command line is the whole content).
  export FZF_CTRL_R_OPTS="--no-preview"
  # File widget (ctrl-t): syntax-highlighted preview, line numbers, first 500 lines.
  export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:500 {}'"
  # Dir widget (alt-c): a colored, icon'd tree two levels deep.
  export FZF_ALT_C_COMMAND="fd --type d"
  if command -v eza &>/dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons=always --group-directories-first {}'"
  fi

  # Keybindings AFTER env vars so they inherit them.
  eval "$(fzf --zsh)"

  # macOS: Option+C sends ç instead of the ESC-c sequence fzf expects.
  [[ "$(uname)" == "Darwin" ]] && bindkey 'ç' fzf-cd-widget 2>/dev/null
fi

# ── zoxide ───────────────────────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  # Suppress doctor warning: sheldon's zsh-defer loads plugins after our init,
  # which trips zoxide's order check. Functionality is unaffected.
  export _ZO_DOCTOR=0
  eval "$(zoxide init zsh)"
  alias cd="z"
  alias cdi="zi"
  if command -v eza &>/dev/null; then
    export _ZO_FZF_OPTS="--preview 'eza -al --tree --level 1 --group-directories-first \
      --header --no-user --no-time --no-filesize --no-permissions {2..}' \
      --preview-window right,50% --height 35% --reverse --ansi --with-nth 2.."
  fi
fi

# ── gh (GitHub CLI) — completion ──────────────────────────────────────────────
if command -v gh &>/dev/null; then
  eval "$(gh completion -s zsh)"
fi

# Tools needing no shell integration (pure binaries): jq, yq, btop, tree.
# delta is wired into git via dot_config/git/delta.gitconfig (included from
# ~/.gitconfig by the bootstrap) — no shell integration needed here.
