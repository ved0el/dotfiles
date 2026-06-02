# CLAUDE.md — dotfiles (chezmoi)

Personal dotfiles managed by [chezmoi](https://chezmoi.io). Files in this source
dir are applied to `$HOME`. Repo: `ved0el/dotfiles`.

## Naming conventions
- `dot_X` → `~/.X`; `executable_X` → +x; `private_X` → 0600; `*.tmpl` → Go-templated.
- `run_onchange_after_install-packages.sh.tmpl` — bootstrap (packages + plugins);
  re-runs when its rendered content changes; `after_` = runs once files are applied.
- **Non-`dot_` files (README.md, CLAUDE.md) apply to `~/` unless in `.chezmoiignore`.**

## Profiles (per-machine toggles)
- Data keys: `tools`, `develop`, `tmux`, `wm` (macOS only).
- Chosen by `chezmoi init` prompts in `.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`
  (overrides the `.chezmoidata.yaml` defaults). Re-run `chezmoi init` to change them.
- `.chezmoiignore` gates which files apply; the bootstrap gates installs by the same keys.
- Templates reference `.tools/.develop/.tmux/.wm` — they MUST exist or rendering errors
  ("map has no entry for key …"). `.chezmoidata.yaml` guarantees they exist.

## Tools split
- CLI tools + language runtimes → **mise** (`dot_config/mise/conf.d/{tools,develop}.toml`),
  cross-platform (macOS/Ubuntu/Raspberry Pi — one list, no per-OS name gaps).
- Base (`git curl wget`), `btop`/`tree`, `tmux`, `yabai`/`skhd` → **OS PM** (brew/apt) in the bootstrap.

## Verify before apply
- `chezmoi execute-template '{{ .tools }}|{{ .develop }}|{{ .tmux }}|{{ .wm }}'` — resolved profile data.
- `chezmoi cat-config` — the per-machine config that wins.
- `chezmoi apply -n -v` — dry-run diff. NOTE: the bootstrap script's text (e.g. `skhd`) shows in
  the diff; grep config paths like `^diff --git a/.config/...` to judge actual file application.
- `chezmoi managed | grep X` / `chezmoi ignored` — confirm what applies vs is excluded.

## Gotchas
- chezmoi **copies** files (not symlinks). Migrating from a symlink manager replaces the link with a real copy.
- `~/.config/chezmoi/chezmoi.toml` (from `init`) OVERRIDES `.chezmoidata.yaml`.
- `apply` does NOT re-prompt profiles — edit the config or re-run `init`.
