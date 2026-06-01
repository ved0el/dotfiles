#!/usr/bin/env bash
# Case: `dotfiles sync` = update + install in one step (UC-9). Must both pull
# the remote commit AND lay down symlinks + the managed block.

describe "sync pulls remote changes and installs"
sandbox_init
sandbox_make_remote_ahead
run_dotfiles sync
assert_rc           "sync exits 0" 0 "$DF_RC"
assert_file         "remote commit pulled (marker present)" "$SBX_REPO/.sandbox-remote-marker"
assert_file         "managed zshenv written by install step" "$SBX_HOME/.zshenv"
assert_symlink_into "~/.zshrc symlinked by install step" "$SBX_HOME/.zshrc" "$SBX_REPO"

describe "sync is idempotent (safe to re-run)"
run_dotfiles sync
assert_rc           "second sync exits 0" 0 "$DF_RC"
assert_symlink      "~/.zshrc still linked" "$SBX_HOME/.zshrc"
