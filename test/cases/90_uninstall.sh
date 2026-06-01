#!/usr/bin/env bash
# Case: `dotfiles uninstall` — full teardown (UC-15). Removes managed symlinks,
# strips the managed ~/.zshenv block, deletes the repo dir, and preserves the
# user's own content. Runs non-interactively (piped stdin → no prompt).

describe "uninstall tears down a full install"
sandbox_init
sandbox_install >/dev/null 2>&1
# Add user content outside the managed block — must survive uninstall.
printf '\nexport MY_OWN_VAR="keepme"\n' >> "$SBX_HOME/.zshenv"
assert_symlink "precondition: ~/.zshrc linked" "$SBX_HOME/.zshrc"

run_dotfiles uninstall
assert_rc          "uninstall exits 0" 0 "$DF_RC"
assert_not_symlink "managed ~/.zshrc symlink removed" "$SBX_HOME/.zshrc"
assert_no_file     "repo directory removed" "$SBX_REPO"
assert_true        "user content preserved" grep -q 'MY_OWN_VAR="keepme"' "$SBX_HOME/.zshenv"
assert_false       "no DOTFILES_ exports remain" grep -q '^export DOTFILES_' "$SBX_HOME/.zshenv"
assert_false       "managed block markers stripped" grep -q 'DOTFILES MANAGED' "$SBX_HOME/.zshenv"
