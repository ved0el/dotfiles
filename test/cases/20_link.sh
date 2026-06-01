#!/usr/bin/env bash
# Case: `dotfiles link` — symlink creation, idempotency, and refusal to clobber
# a real (non-symlink) file. No git pull, no packages.

sandbox_init
sandbox_clone_basic

describe "link creates symlinks into the repo"
run_dotfiles link
assert_rc           "link exits 0" 0 "$DF_RC"
assert_symlink_into "~/.zshrc links into repo"        "$SBX_HOME/.zshrc"               "$SBX_REPO"
assert_symlink_into "~/.config/bat links into repo"   "$SBX_HOME/.config/bat"          "$SBX_REPO"
assert_symlink_into "~/.config/ripgrep links in repo" "$SBX_HOME/.config/ripgrep"      "$SBX_REPO"
assert_symlink_into "~/.claude/settings.json linked"  "$SBX_HOME/.claude/settings.json" "$SBX_REPO"

describe "link is idempotent (UC-17 — safe to re-run)"
run_dotfiles link
assert_rc           "second link exits 0" 0 "$DF_RC"
assert_symlink      "~/.zshrc still a symlink" "$SBX_HOME/.zshrc"

describe "link refuses to clobber a real file"
sandbox_init
sandbox_clone_basic
printf 'my real zshrc\n' > "$SBX_HOME/.zshrc"   # pre-existing real file
run_dotfiles link
assert_not_symlink  "real ~/.zshrc left as a file" "$SBX_HOME/.zshrc"
assert_true         "real ~/.zshrc content untouched" grep -q 'my real zshrc' "$SBX_HOME/.zshrc"
