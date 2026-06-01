#!/usr/bin/env bash
# Case: `dotfiles update` across git environments (UC-9 and its guard rails).
# update is git-only: it must pull cleanly when behind, and refuse safely in
# every unsafe state rather than corrupting the working tree.

describe "update refuses when not a git repo"
sandbox_init
sandbox_clone_basic
sandbox_make_nongit
run_dotfiles update
assert_rc       "non-git update exits 1" 1 "$DF_RC"
assert_contains "explains it is not a git repo" "$DF_ALL" "Not a git repository"

describe "update pulls cleanly when behind the remote (UC-9)"
sandbox_init
sandbox_make_remote_ahead
assert_no_file  "precondition: marker absent before update" "$SBX_REPO/.sandbox-remote-marker"
run_dotfiles update
assert_rc       "clean update exits 0" 0 "$DF_RC"
assert_file     "remote commit pulled in (marker present)" "$SBX_REPO/.sandbox-remote-marker"
assert_contains "reports it updated" "$DF_ALL" "Updated to"

describe "update refuses a dirty tree without --stash"
sandbox_init
sandbox_clone_basic
sandbox_make_dirty
run_dotfiles update
assert_rc       "dirty update exits 1" 1 "$DF_RC"
assert_contains "explains local changes" "$DF_ALL" "Local changes detected"
assert_true     "local edit preserved" grep -q 'sandbox local edit' "$SBX_REPO/README.md"

describe "update --stash restores local changes"
sandbox_init
sandbox_clone_basic
sandbox_make_dirty
run_dotfiles update --stash
assert_rc       "update --stash exits 0" 0 "$DF_RC"
assert_true     "local edit restored after stash pop" grep -q 'sandbox local edit' "$SBX_REPO/README.md"

describe "update refuses detached HEAD"
sandbox_init
sandbox_clone_basic
sandbox_make_detached
run_dotfiles update
assert_rc       "detached HEAD update exits 1" 1 "$DF_RC"
assert_contains "explains detached HEAD" "$DF_ALL" "Detached HEAD"

describe "update refuses mid-rebase"
sandbox_init
sandbox_clone_basic
sandbox_make_midrebase
run_dotfiles update
assert_rc       "mid-rebase update exits 1" 1 "$DF_RC"
assert_contains "explains mid-rebase" "$DF_ALL" "mid-rebase"
