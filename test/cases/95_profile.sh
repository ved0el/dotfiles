#!/usr/bin/env bash
# Case: profile management (UC-14) + legacy-alias migration (NFR-D). Covers the
# `profile` command, listing, validation, and the minimal/full/dev → new-name
# migration that fires on any CLI invocation via set_defaults.

describe "profile list shows the cumulative tiers"
sandbox_init
sandbox_clone_basic
run_dotfiles profile list
assert_rc       "profile list exits 0" 0 "$DF_RC"
assert_contains "lists core"    "$DF_OUT" "core"
assert_contains "lists server"  "$DF_OUT" "server"
assert_contains "lists develop" "$DF_OUT" "develop"

describe "profile set + validation"
run_dotfiles profile server
assert_rc       "set profile server exits 0" 0 "$DF_RC"
run_dotfiles config get profile
assert_eq       "profile now server" "server" "$DF_OUT"
run_dotfiles profile not-a-profile
assert_rc       "invalid profile rejected" 1 "$DF_RC"

describe "legacy profile aliases migrate (minimal → core)"
sandbox_init
sandbox_clone_basic
printf '%s\n' 'export DOTFILES_PROFILE="minimal"' > "$SBX_HOME/.zshenv"
run_dotfiles config get profile
assert_eq       "minimal migrated to core" "core" "$DF_OUT"
assert_contains "migration is announced" "$DF_ALL" "migrated"

describe "legacy profile aliases migrate (full → develop)"
sandbox_init
sandbox_clone_basic
printf '%s\n' 'export DOTFILES_PROFILE="full"' > "$SBX_HOME/.zshenv"
run_dotfiles config get profile
assert_eq       "full migrated to develop" "develop" "$DF_OUT"
