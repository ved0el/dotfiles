#!/usr/bin/env bash
# Case: `dotfiles doctor` — read-only health check (UC-12). Must report state
# and must never mutate the system.

describe "doctor on a fresh checkout is read-only"
sandbox_init
sandbox_clone_basic
run_dotfiles doctor
assert_contains "shows Doctor section" "$DF_ALL" "Doctor"
assert_contains "checks symlinks"      "$DF_ALL" "Symlinks"
assert_contains "reports an issue count" "$DF_ALL" "issues"
assert_no_file  "doctor did not create ~/.zshenv" "$SBX_HOME/.zshenv"

describe "doctor after install reports healthy"
sandbox_init
sandbox_install >/dev/null 2>&1
run_dotfiles doctor
assert_rc       "doctor (installed) exits 0" 0 "$DF_RC"
assert_contains "checks the repo"   "$DF_ALL" "Repo"
assert_contains "checks symlinks"   "$DF_ALL" "Symlinks"
