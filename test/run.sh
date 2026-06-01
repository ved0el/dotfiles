#!/usr/bin/env bash
# =============================================================================
# run.sh — dotfiles test runner (zero external dependencies)
# =============================================================================
# Discovers and runs test/cases/*.sh, each in an isolated subprocess so one
# crashing case can't take down the suite. Aggregates pass/fail counts and
# exits non-zero if anything failed.
#
# Usage:
#   test/run.sh                 run every case
#   test/run.sh -f <substr>     run only cases whose filename contains <substr>
#   test/run.sh -l, --list      list discovered cases and exit
#   test/run.sh --shellcheck    run shellcheck over the scripts (if installed)
#   test/run.sh -h, --help      this help
#
# Exit code: 0 = all assertions passed, 1 = one or more failed / error.
# =============================================================================

set -uo pipefail

# --- Resolve paths ----------------------------------------------------------
_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
TEST_DIR="$(cd "$(dirname "$_SELF")" && pwd)"
LIB_DIR="$TEST_DIR/lib"
CASES_DIR="$TEST_DIR/cases"
# The developer's checkout (parent of test/). Overridable for CI.
REPO_REAL="${DOTFILES_TEST_REPO:-$(cd "$TEST_DIR/.." && pwd)}"
# REPO_SRC is what sandboxes clone. The parent runner builds a "staging" repo
# (HEAD + uncommitted working-tree changes, committed once) and re-exports
# REPO_SRC to point at it, so the suite tests the working tree without
# requiring a commit. Child (--__case) processes inherit it via the environment.
REPO_SRC="${REPO_SRC:-$REPO_REAL}"
export REPO_SRC

# =============================================================================
# Internal single-case mode: `run.sh --__case <file> <results> <faillog>`
# Sourced libs + the case run here, isolated from the parent runner.
# =============================================================================
if [[ "${1:-}" == "--__case" ]]; then
    _case_file="$2"; _results_file="$3"; _fail_log="$4"
    # Intentionally NOT `set -e`: assertions are non-fatal by design.
    # shellcheck source=lib/assert.sh
    . "$LIB_DIR/assert.sh"
    # shellcheck source=lib/sandbox.sh
    . "$LIB_DIR/sandbox.sh"
    _T_PASS=0; _T_FAIL=0; _T_FAILURES=""
    trap 'sandbox_cleanup' EXIT
    # shellcheck source=/dev/null
    . "$_case_file"
    printf '%s %s\n' "$_T_PASS" "$_T_FAIL" > "$_results_file"
    [[ -n "$_T_FAILURES" ]] && printf '%s' "$_T_FAILURES" >> "$_fail_log"
    exit 0
fi

# --- Colors -----------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    R_GREEN=$'\033[32m'; R_RED=$'\033[31m'; R_YELLOW=$'\033[33m'
    R_CYAN=$'\033[36m'; R_BOLD=$'\033[1m'; R_DIM=$'\033[2m'; R_RESET=$'\033[0m'
else
    R_GREEN=''; R_RED=''; R_YELLOW=''; R_CYAN=''; R_BOLD=''; R_DIM=''; R_RESET=''
fi

usage() {
    sed -n '2,20p' "$_SELF" | sed 's/^# \{0,1\}//'
}

# --- Discover cases ---------------------------------------------------------
discover_cases() {
    local filter="${1:-}"
    local f
    for f in "$CASES_DIR"/*.sh; do
        [[ -f "$f" ]] || continue
        if [[ -n "$filter" && "$(basename "$f")" != *"$filter"* ]]; then
            continue
        fi
        printf '%s\n' "$f"
    done
}

run_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf '%s⚠ shellcheck not installed — skipping lint%s\n' "$R_YELLOW" "$R_RESET"
        printf '  install: brew install shellcheck | apt install shellcheck\n'
        return 0
    fi
    printf '%s▸ shellcheck%s\n' "$R_BOLD$R_CYAN" "$R_RESET"
    local rc=0
    # bin/dotfiles is bash; test libs are bash. log.sh is POSIX sh.
    shellcheck -s bash "$REPO_SRC/bin/dotfiles" || rc=1
    shellcheck -s bash "$LIB_DIR"/*.sh "$CASES_DIR"/*.sh "$_SELF" || rc=1
    if [[ $rc -eq 0 ]]; then
        printf '%s✓ shellcheck clean%s\n' "$R_GREEN" "$R_RESET"
    fi
    return $rc
}

# --- Arg parsing ------------------------------------------------------------
FILTER=""
DO_SHELLCHECK=false
LIST_ONLY=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--filter) FILTER="${2:-}"; shift 2 ;;
        -l|--list)   LIST_ONLY=true; shift ;;
        --shellcheck) DO_SHELLCHECK=true; shift ;;
        -h|--help)   usage; exit 0 ;;
        *) printf 'unknown option: %s\n' "$1" >&2; usage; exit 2 ;;
    esac
done

if $LIST_ONLY; then
    discover_cases "$FILTER" | while IFS= read -r f; do basename "$f"; done
    exit 0
fi

# --- Header -----------------------------------------------------------------
printf '%s╭───────────────────────────────────────────────╮%s\n' "$R_BOLD$R_CYAN" "$R_RESET"
printf '%s│  dotfiles test suite                          │%s\n' "$R_BOLD$R_CYAN" "$R_RESET"
printf '%s╰───────────────────────────────────────────────╯%s\n' "$R_BOLD$R_CYAN" "$R_RESET"
printf '%srepo:%s %s\n' "$R_DIM" "$R_RESET" "$REPO_SRC"
printf '%snote:%s package install (mise/sheldon) is stubbed — these tests cover\n' "$R_YELLOW" "$R_RESET"
printf '      command behavior, symlink/config/git flows, and exit codes.\n'

# --- Preflight: repo must be a clonable git repo ----------------------------
if [[ ! -d "$REPO_REAL/.git" ]]; then
    printf '%s✗ repo is not a git repository: %s%s\n' "$R_RED" "$REPO_REAL" "$R_RESET" >&2
    printf '  the suite clones the repo locally; a .git dir is required.\n' >&2
    exit 1
fi

# --- Build the staging repo (HEAD + working-tree changes) -------------------
# Sandboxes clone from here, so uncommitted edits are tested. Clean tree.
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test-staging.XXXXXX")"
RESULTS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test-results.XXXXXX")"
FAIL_LOG="$RESULTS_DIR/failures.log"
: > "$FAIL_LOG"
trap 'rm -rf "$RESULTS_DIR" "$STAGING"' EXIT

git clone --local --no-hardlinks --quiet "$REPO_REAL" "$STAGING/repo" 2>/dev/null || {
    printf '%s✗ failed to build staging clone%s\n' "$R_RED" "$R_RESET" >&2; exit 1
}
# Overlay uncommitted tracked changes from the working tree, then commit so the
# staging clone is clean (update/status tests need a clean baseline).
if ! git -C "$REPO_REAL" diff --quiet HEAD 2>/dev/null; then
    git -C "$REPO_REAL" diff HEAD 2>/dev/null | git -C "$STAGING/repo" apply --whitespace=nowarn 2>/dev/null || \
        printf '%s⚠ could not overlay working-tree changes — testing HEAD%s\n' "$R_YELLOW" "$R_RESET"
fi
git -C "$STAGING/repo" -c user.email=test@dotfiles.local -c user.name='dotfiles test' \
    commit --quiet -am "staging: working tree under test" 2>/dev/null || true
REPO_SRC="$STAGING/repo"
export REPO_SRC

case_count=0
while IFS= read -r case_file; do
    [[ -n "$case_file" ]] || continue
    case_count=$((case_count + 1))
    res="$RESULTS_DIR/$(basename "$case_file").res"
    bash "$_SELF" --__case "$case_file" "$res" "$FAIL_LOG"
done < <(discover_cases "$FILTER")

if [[ $case_count -eq 0 ]]; then
    printf '\n%s⚠ no test cases found%s (filter: %s)\n' "$R_YELLOW" "$R_RESET" "${FILTER:-none}"
    exit 1
fi

# --- Aggregate --------------------------------------------------------------
total_pass=0; total_fail=0
for res in "$RESULTS_DIR"/*.res; do
    [[ -f "$res" ]] || continue
    read -r p f < "$res"
    total_pass=$((total_pass + ${p:-0}))
    total_fail=$((total_fail + ${f:-0}))
done

shellcheck_rc=0
if $DO_SHELLCHECK; then
    echo
    run_shellcheck || shellcheck_rc=1
fi

# --- Summary ----------------------------------------------------------------
printf '\n%s─────────────────────────────────────────────────%s\n' "$R_DIM" "$R_RESET"
if [[ $total_fail -gt 0 ]]; then
    printf '%sFailures:%s\n' "$R_BOLD$R_RED" "$R_RESET"
    while IFS= read -r line; do
        [[ -n "$line" ]] && printf '  %s✗%s %s\n' "$R_RED" "$R_RESET" "$line"
    done < "$FAIL_LOG"
    echo
fi
printf '%s%d passed%s, %s%d failed%s  (%d cases)\n' \
    "$R_GREEN" "$total_pass" "$R_RESET" \
    "$( [[ $total_fail -gt 0 ]] && printf '%s' "$R_RED" || printf '%s' "$R_DIM" )" \
    "$total_fail" "$R_RESET" "$case_count"

if [[ $total_fail -gt 0 || $shellcheck_rc -ne 0 ]]; then
    exit 1
fi
exit 0
