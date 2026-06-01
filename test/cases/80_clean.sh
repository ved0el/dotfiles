#!/usr/bin/env bash
# Case: `dotfiles clean` — orphaned-symlink sweep (UC-13/UC-17). Dry-run by
# default; --force applies. Must never touch valid links or real files.

sandbox_init
sandbox_install >/dev/null 2>&1

describe "clean detects an orphaned symlink (dry-run does not remove)"
sandbox_add_orphan_symlink "orphan.conf"
assert_symlink  "precondition: orphan link exists" "$SBX_HOME/.config/orphan.conf"
run_dotfiles clean
assert_rc       "clean dry-run exits 0" 0 "$DF_RC"
assert_contains "dry-run lists the orphan" "$DF_ALL" "orphan.conf"
assert_symlink  "orphan NOT removed in dry-run" "$SBX_HOME/.config/orphan.conf"

describe "clean --force removes orphans, keeps valid links"
run_dotfiles clean --force
assert_rc          "clean --force exits 0" 0 "$DF_RC"
assert_no_file     "orphan removed by --force" "$SBX_HOME/.config/orphan.conf"
assert_symlink_into "valid ~/.config/bat link preserved" "$SBX_HOME/.config/bat" "$SBX_REPO"
