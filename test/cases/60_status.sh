#!/usr/bin/env bash
# Case: `dotfiles status` — human table + machine-readable --json (UC-11).

describe "status table (fresh checkout)"
sandbox_init
sandbox_clone_basic
run_dotfiles status
assert_rc       "status exits 0" 0 "$DF_RC"
assert_contains "table shows profile" "$DF_OUT" "profile"
assert_contains "table shows root"    "$DF_OUT" "root"

describe "status --json schema"
run_dotfiles --json status
assert_rc       "json status exits 0" 0 "$DF_RC"
assert_contains "json has profile" "$DF_OUT" '"profile":"core"'
assert_contains "json has git block" "$DF_OUT" '"git":'
assert_contains "json has branch"    "$DF_OUT" '"branch":"main"'
assert_contains "json has symlinks block" "$DF_OUT" '"symlinks":'
assert_contains "json has packages block" "$DF_OUT" '"packages":'
assert_match    "json active count is numeric" "$DF_OUT" '"active":[0-9]+'

describe "status --json reflects active symlinks after install"
sandbox_init
sandbox_install >/dev/null 2>&1
run_dotfiles --json status
assert_rc    "json status (installed) exits 0" 0 "$DF_RC"
assert_match "at least one active symlink" "$DF_OUT" '"active":[1-9][0-9]*'
assert_match "no broken symlinks" "$DF_OUT" '"broken":0'
