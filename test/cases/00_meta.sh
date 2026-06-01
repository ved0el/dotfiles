#!/usr/bin/env bash
# Case: version, help, and unknown-command dispatch (no environment needed
# beyond a checked-out repo). Proves the CLI entrypoint + arg parser work.

sandbox_init
sandbox_clone_basic

describe "version"
run_dotfiles version
assert_rc       "version exits 0" 0 "$DF_RC"
assert_contains "version names the tool" "$DF_OUT" "dotfiles"
assert_contains "version prints repo URL" "$DF_OUT" "github.com"

run_dotfiles --version
assert_rc       "--version flag exits 0" 0 "$DF_RC"
assert_contains "--version names the tool" "$DF_ALL" "dotfiles"

describe "help"
run_dotfiles help
assert_rc       "help exits 0" 0 "$DF_RC"
assert_contains "help shows NAME section" "$DF_OUT" "NAME"
assert_contains "help shows SYNOPSIS section" "$DF_OUT" "SYNOPSIS"

run_dotfiles -h
assert_rc       "-h exits 0" 0 "$DF_RC"
assert_contains "-h shows usage" "$DF_OUT" "dotfiles"

describe "unknown command"
run_dotfiles frobnicate
assert_rc       "unknown command exits 1" 1 "$DF_RC"
assert_contains "unknown command is reported" "$DF_ALL" "Unknown command"
