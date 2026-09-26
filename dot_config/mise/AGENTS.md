# AGENTS.md — mise

Scoped to `dot_config/mise/`. The NEVER rule is repeated in the root `AGENTS.md` because
`profile.ps1`, `10-env.zsh` and the bootstraps touch it too. The "why" is in the commits
(`git log -S MISE_GLOBAL_CONFIG_FILE`).

- **NEVER set `MISE_GLOBAL_CONFIG_FILE` (nor `MISE_CONFIG_DIR`)** — not even to the default path.
  With it set, mise stops discovering `conf.d/*.toml` whenever CWD is outside `$HOME` (symptom:
  `mise ls` shows tools with a blank config source). `profile.ps1` and `10-env.zsh` unset both
  at shell start; a persisted User-scope value must be deleted by hand.
- `.config/mise/config.toml` is chezmoi-ignored and is where `mise use -g` writes by default, so
  per-machine pins survive `apply`. Never let `mise use -g` write into a tracked `conf.d/*.toml`.
- Global `conf.d` is only discovered with CWD inside `$HOME`: scripts run `mise --cd $HOME …`
  (bootstraps: `install`/`exec`; the pwsh profile: `env`).
- Lessons that generalize: setting an env var to a tool's own default is NOT a no-op (explicit
  paths often switch a tool to single-file mode); reproduce context-sensitive bugs in the failing
  context (here: CWD outside `$HOME`) and verify env fixes in a FRESH process tree.
