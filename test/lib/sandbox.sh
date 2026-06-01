#!/usr/bin/env bash
# =============================================================================
# sandbox.sh — hermetic test environments for bin/dotfiles
# =============================================================================
# Every test runs the real `bin/dotfiles` against an isolated $HOME plus a
# throwaway `git clone --local` of the repo placed at $HOME/.dotfiles (matching
# the real DEFAULT_ROOT). No network, no mutation of the developer's checkout.
#
# Package installation (mise/sheldon) is neutralized by a stub `zsh` placed
# first on PATH that exits 0 immediately. This is a DELIBERATE boundary: these
# tests verify command behavior, symlink/config/git flows, and exit codes — NOT
# the real download of language toolchains (network- and time-dependent, and
# out of scope for a deterministic suite). The stubbing is logged by run.sh so
# it is never a silent cap.
#
# Public API:
#   sandbox_init                      — fresh tmp HOME + stub PATH
#   sandbox_clone_basic               — clone repo into $HOME/.dotfiles (clean)
#   sandbox_install                   — clone_basic + run `install` (installed state)
#   sandbox_make_nongit               — drop .git (simulate not-a-repo)
#   sandbox_make_dirty                — uncommitted tracked change
#   sandbox_make_detached             — detached HEAD
#   sandbox_make_midrebase            — fake mid-rebase state
#   sandbox_make_remote_ahead         — bare remote 1 commit ahead of clone
#   sandbox_add_orphan_symlink <name> — orphan link into repo (for clean tests)
#   run_dotfiles <args...>            — invoke CLI; sets DF_RC / DF_OUT / DF_ERR / DF_ALL
#   sandbox_cleanup                   — remove the current sandbox
#
# Globals set: SBX (root), SBX_HOME, SBX_REPO ($HOME/.dotfiles), SBX_STUB_BIN.
# Requires: REPO_SRC (absolute path to the repo under test) — set by run.sh.
# =============================================================================

: "${REPO_SRC:?REPO_SRC must be set by the test runner}"

# Default branch of the repo under test (e.g. "main"). Resolved once.
_SBX_BRANCH="$(git -C "$REPO_SRC" symbolic-ref --short HEAD 2>/dev/null || echo main)"

# Minimal git identity for commits made inside sandboxes (push/commit helpers).
_sbx_git() { git -c user.email=test@dotfiles.local -c user.name='dotfiles test' "$@"; }

sandbox_init() {
    # Tear down any previous sandbox so cases don't leak into each other.
    sandbox_cleanup
    SBX="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")" || {
        echo "FATAL: mktemp failed" >&2; exit 1
    }
    SBX_HOME="$SBX/home"
    SBX_REPO="$SBX_HOME/.dotfiles"
    SBX_STUB_BIN="$SBX/stub-bin"
    mkdir -p "$SBX_HOME" "$SBX_STUB_BIN"

    # Safety: never operate on the developer's real HOME.
    if [[ "$SBX_HOME" == "$HOME" || -z "$SBX_HOME" ]]; then
        echo "FATAL: refusing to run — sandbox HOME resolves to real HOME" >&2
        exit 1
    fi

    # Stub zsh: neutralizes package install/verify (see header).
    cat > "$SBX_STUB_BIN/zsh" <<'STUB'
#!/usr/bin/env bash
# Test stub: pretend zsh ran package files successfully. No tools touched.
exit 0
STUB
    chmod +x "$SBX_STUB_BIN/zsh"

    # If the host has tmux on PATH, `install` would otherwise `git clone` TPM
    # from GitHub (network). Pre-create the TPM dir so that clone is skipped,
    # keeping every test hermetic regardless of host tooling.
    mkdir -p "$SBX_HOME/.tmux/plugins/tpm"
}

# Clone the repo locally into $HOME/.dotfiles. Clean working tree, origin =
# the developer's checkout (a local path → no network on pull).
sandbox_clone_basic() {
    # Idempotent within a case: a re-clone (e.g. via sandbox_install) replaces
    # any prior clone instead of failing on a non-empty target.
    rm -rf "$SBX_REPO" 2>/dev/null || true
    git clone --local --no-hardlinks --quiet "$REPO_SRC" "$SBX_REPO" 2>/dev/null || {
        echo "FATAL: failed to clone $REPO_SRC into sandbox" >&2; exit 1
    }
    _sbx_git -C "$SBX_REPO" checkout --quiet "$_SBX_BRANCH" 2>/dev/null || true
}

# Installed state: clone + run install (packages stubbed). Leaves symlinks and
# the managed ~/.zshenv block in place.
sandbox_install() {
    sandbox_clone_basic
    run_dotfiles install
}

sandbox_make_nongit() {
    rm -rf "$SBX_REPO/.git"
}

sandbox_make_dirty() {
    # Modify a tracked file so `git diff HEAD` is non-empty.
    printf '\n# sandbox local edit\n' >> "$SBX_REPO/README.md"
}

sandbox_make_detached() {
    _sbx_git -C "$SBX_REPO" checkout --quiet --detach HEAD 2>/dev/null || true
}

sandbox_make_midrebase() {
    # update_dotfiles aborts when .git/rebase-merge exists.
    mkdir -p "$SBX_REPO/.git/rebase-merge"
}

# Build a bare remote that is exactly one commit ahead of the working clone.
sandbox_make_remote_ahead() {
    local bare="$SBX/remote.git" scratch="$SBX/scratch"
    git clone --local --bare --quiet "$REPO_SRC" "$bare" 2>/dev/null
    git clone --local --quiet "$bare" "$SBX_REPO" 2>/dev/null
    _sbx_git -C "$SBX_REPO" checkout --quiet "$_SBX_BRANCH" 2>/dev/null || true

    # Advance the remote via a scratch clone (simulates "machine A pushed").
    git clone --local --quiet "$bare" "$scratch" 2>/dev/null
    printf 'sentinel %s\n' "$_SBX_BRANCH" > "$scratch/.sandbox-remote-marker"
    _sbx_git -C "$scratch" add -A
    _sbx_git -C "$scratch" commit --quiet -m "remote ahead: sandbox marker"
    _sbx_git -C "$scratch" push --quiet origin "HEAD:$_SBX_BRANCH" 2>/dev/null
}

# Create an orphaned symlink: points into the repo at a path that does not
# exist, so `clean` should classify it as removable.
sandbox_add_orphan_symlink() {
    local name="${1:-orphan.conf}"
    mkdir -p "$SBX_HOME/.config"
    ln -sf "$SBX_REPO/config/__does_not_exist__/$name" "$SBX_HOME/.config/$name"
}

# DOTFILES_* vars that may be exported in the developer's shell. They MUST be
# scrubbed before each invocation, or the host environment leaks into the
# sandbox (observed: a real machine's DOTFILES_EXTRA bleeding into the managed
# block, breaking hermeticity). NO_RELOAD / NO_BANNER are re-set deliberately.
_SBX_SCRUB=(
    DOTFILES_ROOT DOTFILES_PROFILE DOTFILES_VERBOSE DOTFILES_EXCLUDE
    DOTFILES_EXTRA DOTFILES_REPO DOTFILES_BRANCH DOTFILES_MENU DOTFILES_INSTALL
    DOTFILES_HOOK_ONLY DOTFILES_OUTPUT_FORMAT DOTFILES_QUIET DOTFILES_WRAPPER
    DOTFILES_NO_RELOAD DOTFILES_NO_BANNER DOTFILES_CONFIG_EXCLUDE
    DOTFILES_CLEAN_FORCE DOTFILES_LOG_SCOPE DOTFILES_MENU
    _DOTFILES_INSTALL_MENU _DOTFILES_INSTALL_FLAGS_PROVIDED
)

# Invoke the real CLI inside the sandbox. Captures streams + exit code.
#   DF_RC  — exit code
#   DF_OUT — stdout (ANSI-free: not a TTY + NO_COLOR)
#   DF_ERR — stderr
#   DF_ALL — stdout + stderr concatenated (for loose matching)
run_dotfiles() {
    : > "$SBX/.stdout"; : > "$SBX/.stderr"
    local -a unset_flags=()
    local v
    for v in "${_SBX_SCRUB[@]}"; do unset_flags+=(-u "$v"); done
    env "${unset_flags[@]}" \
        HOME="$SBX_HOME" \
        PATH="$SBX_STUB_BIN:$PATH" \
        NO_COLOR=1 \
        DOTFILES_NO_RELOAD=true \
        DOTFILES_NO_BANNER=true \
        bash "$SBX_REPO/bin/dotfiles" "$@" </dev/null >"$SBX/.stdout" 2>"$SBX/.stderr"
    DF_RC=$?
    DF_OUT="$(cat "$SBX/.stdout")"
    DF_ERR="$(cat "$SBX/.stderr")"
    DF_ALL="${DF_OUT}"$'\n'"${DF_ERR}"
    return 0
}

sandbox_cleanup() {
    [[ -n "${SBX:-}" && -d "${SBX:-}" && "${SBX:-}" == *dotfiles-test.* ]] && rm -rf "$SBX"
    SBX=""
}
