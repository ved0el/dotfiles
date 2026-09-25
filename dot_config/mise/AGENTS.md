# AGENTS.md — mise

Scoped notes for `dot_config/mise/`. The one-line NEVER rule is repeated in the root `AGENTS.md` because profile.ps1, 10-env.zsh and the bootstraps touch it too.

- **NEVER set `MISE_GLOBAL_CONFIG_FILE`.** mise's default global config is already
  `~/.config/mise/config.toml`, so setting it is redundant — and it actively breaks `conf.d`:
  with it set, mise stops auto-discovering the global config DIRECTORY (the `conf.d/*.toml`
  tool manifests) whenever a shell's CWD is outside `$HOME` (e.g. a terminal whose start
  directory is a drive root). Symptom: `mise ls` shows tools with a blank config source —
  only `config.toml` is read. Proven by toggling the var from a dir outside `$HOME`. Leave it
  unset everywhere; `profile.ps1` and `10-env.zsh` `unset` both vars at shell start, so a shell
  that inherits a stale value heals. (The bootstrap no longer clears the persisted User-scope
  var — if a box has one, delete it by hand.) (`MISE_CONFIG_DIR` is likewise
  unnecessary. Don't reintroduce either var to "pin" conf.d; pinning is what caused the bug.)
- `.config/mise/config.toml` is in `.chezmoiignore` → chezmoi never manages it, and `mise use
  -g` writes there by DEFAULT (no env var needed), so ad-hoc per-machine pins survive `apply`.
  NEVER let `mise use -g` land in a tracked `conf.d/*.toml` (it makes `apply` prompt "changed
  since chezmoi last wrote it" and reverts the pin).
- mise only auto-discovers the global `conf.d/*.toml` when CWD is inside `$HOME`; the bootstraps
  therefore run `mise --cd $HOME install` so a fresh-machine install isn't blank when chezmoi
  runs the script from elsewhere. The PowerShell profile injects tools via `mise --cd $HOME env`,
  so tools work in every shell regardless of its start directory.
- **Two lessons this bug bought — they generalize:**
  1. **Setting an env var to a tool's OWN DEFAULT is not a harmless no-op.** A tool that
     auto-discovers config by walking a directory often narrows to single-file mode the moment
     you hand it an explicit path. If the value equals the default, DELETE it; guard/`unset`.
  2. **Reproduce context-sensitive bugs in the ACTUAL failing context; verify env fixes in a
     FRESH process tree.** This one only appeared with CWD outside `$HOME` — testing from the
     repo dir hid it and gave a wrong first diagnosis. A child shell inherits stale env, so a
     fix can look broken or look fixed purely from inheritance.
