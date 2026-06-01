#!/usr/bin/env bash
# =============================================================================
# assert.sh — zero-dependency assertion + reporting primitives
# =============================================================================
# Sourced by test/run.sh (which then sources each test/cases/*.sh). Pure bash,
# 3.2-compatible (macOS /bin/bash): no associative arrays, no `mapfile`, no
# `${var^^}`. Every assertion is non-fatal — it records a pass/fail and lets
# the case continue so one run surfaces every failure, not just the first.
#
# Public API (used by case files):
#   describe "<group title>"                         — section header
#   assert_rc        "<desc>" <expected> <actual>    — exit-code equality
#   assert_eq        "<desc>" "<expected>" "<actual>"
#   assert_ne        "<desc>" "<unexpected>" "<actual>"
#   assert_contains  "<desc>" "<haystack>" "<needle>"
#   assert_not_contains "<desc>" "<haystack>" "<needle>"
#   assert_match     "<desc>" "<string>" "<ere-regex>"
#   assert_symlink   "<desc>" <path>                 — path is a symlink
#   assert_symlink_into "<desc>" <path> <prefix>     — symlink resolves under prefix
#   assert_not_symlink "<desc>" <path>               — path is absent or a real file
#   assert_file      "<desc>" <path>                 — regular file exists
#   assert_no_file   "<desc>" <path>                 — path does not exist
#   assert_true      "<desc>" <cmd...>               — cmd exits 0
#   assert_false     "<desc>" <cmd...>               — cmd exits non-zero
#   pass "<desc>" / fail "<desc>" "<detail>"         — manual result
#
# Counters are global so run.sh can aggregate across case files.
# =============================================================================

# --- Counters (initialized once by run.sh before sourcing cases) ------------
: "${_T_PASS:=0}"
: "${_T_FAIL:=0}"
: "${_T_GROUP:=}"
# _T_FAILURES holds "group :: desc" lines for the final summary.
: "${_T_FAILURES:=}"

# --- Colors (disabled on non-TTY or NO_COLOR) -------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    _A_GREEN=$'\033[32m'; _A_RED=$'\033[31m'; _A_YELLOW=$'\033[33m'
    _A_CYAN=$'\033[36m';  _A_DIM=$'\033[2m';  _A_BOLD=$'\033[1m'
    _A_RESET=$'\033[0m'
else
    _A_GREEN=''; _A_RED=''; _A_YELLOW=''; _A_CYAN=''; _A_DIM=''; _A_BOLD=''; _A_RESET=''
fi

describe() {
    _T_GROUP="$1"
    printf '\n%s%s▸ %s%s\n' "$_A_BOLD" "$_A_CYAN" "$1" "$_A_RESET"
}

# Internal: record a passing assertion.
pass() {
    _T_PASS=$((_T_PASS + 1))
    printf '  %s✓%s %s\n' "$_A_GREEN" "$_A_RESET" "$1"
}

# Internal: record a failing assertion. $2 is optional detail (expected/actual).
fail() {
    _T_FAIL=$((_T_FAIL + 1))
    printf '  %s✗ %s%s\n' "$_A_RED" "$1" "$_A_RESET"
    if [[ -n "${2:-}" ]]; then
        # Indent multi-line detail under the failure.
        printf '%s' "$2" | while IFS= read -r _line; do
            printf '      %s%s%s\n' "$_A_DIM" "$_line" "$_A_RESET"
        done
    fi
    _T_FAILURES="${_T_FAILURES}${_T_GROUP} :: $1"$'\n'
}

assert_rc() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc" "expected exit $expected, got $actual"
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc" "expected: [$expected]"$'\n'"actual:   [$actual]"
    fi
}

assert_ne() {
    local desc="$1" unexpected="$2" actual="$3"
    if [[ "$unexpected" != "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc" "value should differ from: [$unexpected]"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$desc"
    else
        fail "$desc" "missing substring: [$needle]"$'\n'"in output: [$(printf '%s' "$haystack" | head -c 400)]"
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        pass "$desc"
    else
        fail "$desc" "unexpected substring present: [$needle]"
    fi
}

assert_match() {
    local desc="$1" string="$2" regex="$3"
    if [[ "$string" =~ $regex ]]; then
        pass "$desc"
    else
        fail "$desc" "no match for /$regex/"$'\n'"in: [$(printf '%s' "$string" | head -c 400)]"
    fi
}

assert_symlink() {
    local desc="$1" path="$2"
    if [[ -L "$path" ]]; then
        pass "$desc"
    else
        fail "$desc" "not a symlink: $path"
    fi
}

assert_symlink_into() {
    local desc="$1" path="$2" prefix="$3"
    if [[ ! -L "$path" ]]; then
        fail "$desc" "not a symlink: $path"
        return
    fi
    local tgt
    tgt="$(readlink "$path" 2>/dev/null || true)"
    if [[ "$tgt" == "$prefix"* ]]; then
        pass "$desc"
    else
        fail "$desc" "symlink target [$tgt] not under [$prefix]"
    fi
}

assert_not_symlink() {
    local desc="$1" path="$2"
    if [[ ! -L "$path" ]]; then
        pass "$desc"
    else
        fail "$desc" "unexpected symlink: $path -> $(readlink "$path" 2>/dev/null)"
    fi
}

assert_file() {
    local desc="$1" path="$2"
    if [[ -f "$path" ]]; then
        pass "$desc"
    else
        fail "$desc" "regular file not found: $path"
    fi
}

assert_no_file() {
    local desc="$1" path="$2"
    if [[ ! -e "$path" ]]; then
        pass "$desc"
    else
        fail "$desc" "path should not exist: $path"
    fi
}

assert_true() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        pass "$desc"
    else
        fail "$desc" "command failed: $*"
    fi
}

assert_false() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        fail "$desc" "command unexpectedly succeeded: $*"
    else
        pass "$desc"
    fi
}
