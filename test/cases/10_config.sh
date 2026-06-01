#!/usr/bin/env bash
# Case: `dotfiles config` — list/get/set/path/keys, JSON, validation, and the
# marker-delimited managed block in ~/.zshenv (UC-7, UC-16).

sandbox_init
sandbox_clone_basic
ZSHENV="$SBX_HOME/.zshenv"

describe "config list"
run_dotfiles config list
assert_rc       "config list exits 0" 0 "$DF_RC"
assert_contains "list shows profile" "$DF_OUT" "profile"
assert_contains "list shows root"    "$DF_OUT" "root"

describe "config list --json"
run_dotfiles --json config list
assert_rc       "json list exits 0" 0 "$DF_RC"
assert_contains "json has profile=core (default)" "$DF_OUT" '"profile":"core"'
assert_contains "json has extra field"            "$DF_OUT" '"extra"'
assert_contains "json points at sandbox zshenv"   "$DF_OUT" "$SBX_HOME/.zshenv"

describe "config path / keys"
run_dotfiles config path
assert_eq "path prints CONFIG_FILE" "$ZSHENV" "$DF_OUT"
run_dotfiles config keys
assert_contains "keys lists profile" "$DF_OUT" "profile"
assert_contains "keys lists exclude" "$DF_OUT" "exclude"
assert_contains "keys lists extra"   "$DF_OUT" "extra"

describe "config set profile (valid + managed block)"
run_dotfiles config set profile server
assert_rc       "set profile server exits 0" 0 "$DF_RC"
assert_file     "zshenv created" "$ZSHENV"
assert_true     "managed BEGIN marker written" grep -q '# DOTFILES MANAGED BEGIN' "$ZSHENV"
assert_true     "managed END marker written"   grep -q '# DOTFILES MANAGED END' "$ZSHENV"
run_dotfiles config get profile
assert_eq       "get profile reflects server" "server" "$DF_OUT"

describe "config set — validation"
run_dotfiles config set profile bogusprofile
assert_rc       "invalid profile rejected" 1 "$DF_RC"
run_dotfiles config set verbose true
assert_rc       "verbose true accepted" 0 "$DF_RC"
run_dotfiles config set verbose maybe
assert_rc       "verbose non-bool rejected" 1 "$DF_RC"
run_dotfiles config set root /no/such/dir/here
assert_rc       "root must exist" 1 "$DF_RC"
run_dotfiles config set root "$SBX_HOME"
assert_rc       "root accepts existing dir" 0 "$DF_RC"
run_dotfiles config set profile ""
assert_rc       "empty profile rejected" 1 "$DF_RC"
run_dotfiles config get nonsense
assert_rc       "get unknown key exits 1" 1 "$DF_RC"

describe "config set exclude/extra — normalize + clear (UC-7)"
run_dotfiles config set exclude "eza, bat"
assert_rc       "set exclude exits 0" 0 "$DF_RC"
run_dotfiles config get exclude
assert_eq       "exclude whitespace normalized" "eza,bat" "$DF_OUT"
run_dotfiles config set exclude ""
assert_rc       "empty exclude allowed (clears)" 0 "$DF_RC"
run_dotfiles config get exclude
assert_eq       "exclude cleared to empty" "" "$DF_OUT"
run_dotfiles config set extra htop
assert_rc       "set extra exits 0" 0 "$DF_RC"
run_dotfiles config get extra
assert_eq       "extra persisted" "htop" "$DF_OUT"

describe "managed block preserves surrounding user content"
sandbox_init
sandbox_clone_basic
ZSHENV="$SBX_HOME/.zshenv"
printf '%s\n' 'export MY_OWN_VAR="keepme"' '# a personal comment' > "$ZSHENV"
run_dotfiles config set verbose true
assert_rc       "set on pre-existing zshenv exits 0" 0 "$DF_RC"
assert_true     "user export preserved" grep -q 'MY_OWN_VAR="keepme"' "$ZSHENV"
assert_true     "user comment preserved" grep -q 'a personal comment' "$ZSHENV"
begin_count="$(grep -c '# DOTFILES MANAGED BEGIN' "$ZSHENV" 2>/dev/null || true)"
assert_eq       "exactly one managed block" "1" "${begin_count:-0}"
assert_file     "backup created" "${ZSHENV}.backup"
