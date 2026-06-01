#!/usr/bin/env bash
# Case: `dotfiles install` across environments — fresh (UC-1/UC-2), idempotent
# re-run (UC-9), and recovery from a half-installed state (UC-17). Package
# installation is stubbed (see sandbox.sh header).

ZSHENV() { printf '%s' "$SBX_HOME/.zshenv"; }

describe "fresh install (checked-out repo, empty HOME)"
sandbox_init
sandbox_clone_basic
run_dotfiles install
assert_rc           "install exits 0" 0 "$DF_RC"
assert_file         "managed zshenv written" "$SBX_HOME/.zshenv"
assert_true         "managed block present" grep -q '# DOTFILES MANAGED BEGIN' "$SBX_HOME/.zshenv"
assert_symlink_into "~/.zshrc symlinked" "$SBX_HOME/.zshrc" "$SBX_REPO"
assert_symlink_into "~/.config/bat symlinked" "$SBX_HOME/.config/bat" "$SBX_REPO"
assert_file         "machine-local mise config.toml created" "$SBX_HOME/.config/mise/config.toml"

describe "install is idempotent (UC-9 / UC-17)"
run_dotfiles install
assert_rc       "second install exits 0" 0 "$DF_RC"
begin_count="$(grep -c '# DOTFILES MANAGED BEGIN' "$SBX_HOME/.zshenv" 2>/dev/null || true)"
assert_eq       "still exactly one managed block" "1" "${begin_count:-0}"
assert_symlink  "~/.zshrc still linked after re-run" "$SBX_HOME/.zshrc"

describe "recovery: re-install restores a deleted symlink (UC-17)"
rm -f "$SBX_HOME/.zshrc"
assert_no_file  "precondition: ~/.zshrc removed" "$SBX_HOME/.zshrc"
run_dotfiles install
assert_rc           "recovery install exits 0" 0 "$DF_RC"
assert_symlink_into "~/.zshrc restored" "$SBX_HOME/.zshrc" "$SBX_REPO"
