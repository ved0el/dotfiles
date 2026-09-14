# CLAUDE.md — dotfiles (chezmoi)

Personal dotfiles managed by [chezmoi](https://chezmoi.io). Files in this source
dir are applied to `$HOME`. Repo: `ved0el/dotfiles`.

## Commands

**Edit files HERE (the source dir) — `apply` overwrites `$HOME`.** `czra` captures a `$HOME`
edit after the fact, except on `.tmpl` targets (it writes literal JSON over the `{{ }}`).
Aliases ship in `dot_config/zsh/conf.d/70-aliases.zsh` (zsh) and
`dot_config/powershell/profile.ps1` (pwsh); both self-gate on `chezmoi` existing.

| alias  | command           | use |
|--------|-------------------|-----|
| `cz`   | `chezmoi`         | bare passthrough |
| `cza`  | `chezmoi apply`   | source → `$HOME`; re-runs the bootstrap if its fingerprint changed (installs missing Claude plugins, never updates existing ones) |
| `czd`  | `chezmoi diff`    | what `apply` would change |
| `czs`  | `chezmoi status`  | short per-file status (`R` = a script will run) |
| `cze`  | `chezmoi edit`    | edit a managed file in `$EDITOR` |
| `czra` | `chezmoi re-add`  | capture a `$HOME` edit back into the source repo |
| `czu`  | `chezmoi update`  | git pull, then apply; also the ONLY command that updates Claude plugins |
| `czcd` | `chezmoi cd`      | cd into this repo (to commit/push) |

Verify before apply:
- `chezmoi execute-template '{{ .tools }}|{{ .develop }}|{{ .tmux }}|{{ .wm }}'` — resolved profile data.
- `chezmoi cat-config` — the per-machine config that wins.
- `chezmoi apply -n -v` — dry-run diff. NOTE: the bootstrap script's text (e.g. `skhd`) shows in
  the diff; grep config paths like `^diff --git a/.config/...` to judge actual file application.
- `chezmoi managed | grep X` / `chezmoi ignored` — confirm what applies vs is excluded.

## Layout & naming
- `dot_X` → `~/.X`; `executable_X` → +x; `private_X` → 0600; `*.tmpl` → Go-templated.
- **Non-`dot_` files (README.md, CLAUDE.md) apply to `~/` unless in `.chezmoiignore`.**
- `run_after_update-claude-plugins.{sh,ps1}.tmpl` — refreshes Claude marketplaces/plugins;
  `.chezmoiignore` hides it from every command except `chezmoi update`.
- `run_onchange_after_install-packages.{sh,ps1}.tmpl` — bootstrap (packages + plugins);
  re-runs when its rendered content changes; `after_` = runs once files are applied.

| path | holds |
|------|-------|
| `dot_config/{bat,fd,ripgrep,micro,git,vivid}` | CLI tool configs (`tools` profile) |
| `dot_config/zsh/conf.d/*.zsh`, `dot_config/sheldon`, `dot_zshrc`, `dot_p10k.zsh` | Unix shell (numbered load order) |
| `dot_config/powershell/profile.ps1`, `dot_config/starship.toml` | Windows shell |
| `dot_config/mise/conf.d/*.toml` | tool/runtime manifests (all OSes) |
| `dot_config/{yabai,skhd}` / `dot_config/{komorebi,whkd,yasb}` | tiling WM: macOS / Windows |
| `dot_claude/` | Claude Code `settings.json.tmpl` + both statuslines |
| `dot_local/bin/` | tmux helper scripts (Unix only) |
| `dot_tmux.conf` | tmux (`tmux` profile) |

## What applies where

### Profiles (per-machine toggles — prompted)
- Data keys: `tools`, `develop`, `tmux` (Unix only), `wm` (macOS + Windows).
- Chosen by `chezmoi init` prompts in `.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`
  (overrides the `.chezmoidata.yaml` defaults). Re-run `chezmoi init` to change them;
  `apply` does NOT re-prompt.
- `.chezmoiignore` gates which files apply; the bootstrap gates installs by the same keys.
- Templates reference `.tools/.develop/.tmux/.wm` — they MUST exist or rendering errors
  ("map has no entry for key …"). `.chezmoidata.yaml` guarantees they exist.
- `tmux` is prompted only on non-Windows (forced `false` on Windows). `wm` is prompted on
  macOS (yabai + skhd) and Windows (komorebi + whkd + yasb); forced `false` on Linux.

### OS gate (NOT a prompt — auto-detected via `.chezmoi.os`)
- Three values: `windows` / `darwin` / `linux`. Never prompt for the OS; branch on it.
- **Bootstrap is split by OS family, one script each:**
  - `run_onchange_after_install-packages.sh.tmpl` — macOS (brew) + Linux (apt).
  - `run_onchange_after_install-packages.ps1.tmpl` — Windows (scoop).
  - `.chezmoiignore` ships exactly one (ignores `install-packages.ps1` on Unix and
    `install-packages.sh` on Windows — script target names drop the `run_*`/`.tmpl`).
    A `.sh` on Windows is unrunnable ("%1 is not a valid Win32 application"), so it MUST
    be ignored, not just rendered empty (the shebang line keeps it non-empty).
- chezmoi runs `.ps1` via `[interpreters.ps1]` (set Windows-only in `.chezmoi.toml.tmpl`):
  `powershell -NoLogo -NoProfile -ExecutionPolicy Bypass` — **always WinPS 5.1** at its fixed
  `%SystemRoot%\System32\...` path, never pwsh. 5.1 is guaranteed on a fresh box and never moves;
  the bootstrap is written to run under it (then installs pwsh 7, from winget, for shells).
- **NEVER bake an absolute pwsh path into `.chezmoi.toml.tmpl`** (neither `[interpreters.ps1]` nor
  `[cd]`). pwsh's location depends on the install source and CHANGES under you — scoop
  (`<scoop>\apps\pwsh\current`) → winget/Store (a versioned `WindowsApps\Microsoft.PowerShell_X.Y.Z…`
  dir). A path baked at `chezmoi init` goes stale the moment pwsh moves: `chezmoi apply` then fails
  to run `.ps1` scripts, and `chezmoi cd`/`czcd` can't open a shell. `[interpreters.ps1]` uses the
  stable 5.1 path; `[cd]` uses **bare `pwsh`** so chezmoi resolves it via PATH at runtime (survives
  any pwsh source change with no re-init). (`lookPath "pwsh"` in the template has the same
  bake-at-init trap — don't use it for pwsh.)

## Tools split
- CLI tools + language runtimes → **mise** (`dot_config/mise/conf.d/{tools.toml.tmpl,develop.toml}`),
  cross-platform (macOS/Ubuntu/Raspberry Pi — one list, no per-OS name gaps). `tools.toml` is a
  template only to OS-gate `eza` (see the prebuilt-backend note below).
- `conf.d/windows.toml` — Windows-only mise tools (starship, the aqua `eza`; gated off in
  `.chezmoiignore` on Unix).
- Base via **OS PM** (brew/apt), installed only if missing: `git`, `curl`, `tmux`; Linux also
  gets `zsh` (this repo ships the whole zsh stack, and Debian/Ubuntu don't preinstall it — macOS
  does); macOS adds `mole` (cleanup CLI) and `yabai`/`skhd` (wm). No more `btop`/`tree`/`wget` —
  `btop`→`bottom` (mise) and `tree`→`eza -T` alias. `chsh` is NEVER run (it prompts for a
  password, which would hang a non-interactive bootstrap) — the script just prints the command.
- Windows base → **scoop** (`git mise openssh openssl JetBrainsMono-NF-Mono`) + **winget**
  (`Microsoft.PowerShell`) in the `.ps1` bootstrap. Each is guarded on the COMMAND
  (`Get-Command ssh`/`openssl` — a Git-for-Windows or optional-feature `ssh` already counts), so
  nothing reinstalls. The Nerd Font is the exception: a font ships no command, so it is guarded on
  `scoop list` instead, and it needs the `nerd-fonts` bucket added first. Fonts install per-user
  (HKCU), no elevation.
- **`JetBrainsMono-NF-Mono` ships the WHOLE JetBrainsMono Nerd Font set, NL included.** Its
  manifest downloads `nerd-fonts/releases/.../JetBrainsMono.zip`, so the box ends up with 96
  registered faces — 48 of them the NL (no-ligature) cut. There is NO separate `JetBrainsMonoNL-*`
  scoop package and none is needed; don't go looking for one.
- **Three fonts, one job each: `Noto Sans JP` for text (weight 400), `Segoe Fluent Icons` for
  icons, `JetBrainsMonoNL Nerd Font` only as the icon fallback.** All 15px, no per-widget size
  overrides. `.icon, .btn` names Segoe first; every other rule names Noto first with the Nerd
  Font behind it.
  - **Icons are Segoe because a Nerd Font can never size-match UI text.** Measured at 15px:
    | | advance | ink W | spill | ink H |
    |---|---|---|---|---|
    | Noto Sans JP cap `M` | 12 | 12 | 0 | 12 |
    | Segoe icon (any) | **15** | **15** | **0** | 13–15 |
    | Nerd Font icons | 9 | 12–15 | **3–6** | 10–15 |
    Segoe is drawn on a uniform em box — advance equals ink, every glyph the same optical size,
    nothing to clip. **That em box is also why `.icon` is 17px against the text's 15px**: a
    Segoe glyph fills the box top to bottom while a letter only reaches cap height, so matching
    the numbers makes the icon read SMALLER than the text sitting next to it. 17 is where they
    balance — picked by rendering 15/16/17/18/19 baseline-aligned against real bar strings
    (`25:00`, `100%`, `saufamily`); 18+ starts to dominate. Equal font-size is NOT equal
    optical size. The Nerd Font's advance is the mono cell (9px) while its icon ink is up to
    15px and its ink HEIGHT varies 10–15px per glyph, so icons look different sizes next to each
    other AND next to the text, no matter what `font-size` you set. That is the size mismatch;
    it is a property of the font, not of the stylesheet.
  - **Not every Segoe glyph is the same size — check the ink box, the font name is not enough.**
    Two traps found on the secondary bar:
    - `E871`–`E874`/`E701` (the old wifi ramp) are *signal-strength* art: the ink shrinks with
      the level, **6px tall at 1–24% against 15px at full**, so the icon changed size as the
      signal moved. `E904`–`E908` is the same five-step ramp drawn in a constant 15×17 box.
    - `EEA0` (memory) and `EDA7` (keyboard) were the only glyphs **18px wide against a 17px
      advance**, so they spilled. `E964` and `E765` are the 17-wide equivalents.
    Measure with `ImageFont.getbbox` before adopting a codepoint; `inkH` 15–17 and `inkW` ≤ the
    advance is the bar to clear.
  - **Bar text is 16px against the 17px icons**, and every per-widget `font-weight` on a bar
    widget is deleted. Nine of them (`.cpu-widget`, `.memory-widget`, `.volume-widget`,
    `.wifi-widget`, `.komorebi-active-layout`) carried `bold`/`600` — which is why the SECONDARY
    monitor's bar looked heavier than the primary's even though both read the same stylesheet.
    Per-widget weight is the same trap as per-widget size: delete it, don't tune it.
  - **Segoe has no weather set** — swept `E9C0`–`EA3F` and it is empty; Windows' weather icons
    live in the Weather app's own font. So the weather block is the ONE widget still drawn by
    the Nerd Font, and the padding + `U+00A0` hacks stay for its sake. Everything else on both
    bars is Segoe: home `E80F`, keyboard `EDA7`, cpu `E950`, memory `EEA0`, wifi `E871`–`E874`/
    `E701`, volume `E74F`/`E992`–`E995`, globe `E774`, stopwatch `E916`, pause `E769`, bell
    `EA8F`. Find new ones by rendering a Segoe range to a contact sheet and looking — the names
    in Microsoft's docs are not in the font.
  - **Why Noto Sans JP for text**: it is the only Google family on this box that covers
    everything the bar shows — Latin 95/95, **Vietnamese 90/90** (`U+1EA0`–`U+1EF9`) and full
    Japanese (86 hiragana, 91 katakana, 12,731 kanji). Be Vietnam Pro and Roboto also do 90/90
    Vietnamese but have **zero** CJK. Its digits are tabular (all advance 9.0), so the clock
    does not jitter — check that before swapping in any proportional font.
  - **It is NOT installed by the bootstrap** (scoop has no plain Noto Sans JP; only
    `Noto-CJK-Mega-OTC` and the Nerd-Font-patched `Noto-NF`, which is Latin-only). A fresh box
    therefore falls through to `JetBrainsMonoNL Nerd Font`, which still has Vietnamese 90/90 —
    only Japanese degrades. That is why the Nerd Font stays second in every text rule.
  - **Every icon span carries `class='icon'`** so it gets both the icon font and the padding.
    A bare `<span>` would still find the glyph by fallback but would miss the padding and clip.
  - **`font-weight` CANNOT change how heavy a NERD FONT icon looks.** Measured: the same Nerd Font icon
    rasterises to a byte-identical bitmap in Regular/Medium/SemiBold/Bold (743 ink px for
    `U+F2DB` in all four) because the patcher embeds one SVG per codepoint; text glyphs vary
    24–28% across the same faces. The ONLY lever is picking a heavier icon *set*: the whole
    weather block moved off the thin-line `nf-weather` (`U+E3xx`) range onto Material
    (`nf-md-weather-*`), and the keyboard off outline `U+F11C` onto solid `U+F030C`.
  - **Both bars are styled identically by construction** — `primary-bar` and `secondary-bar`
    share `class_name: yasb-bar`, `dimensions`, `padding` and `blur_effect`; only `screens` and
    the widget lists differ. Both monitors run at 96 DPI / 100%, so 15px is 15px on each. If a
    monitor ever gets a different scale, that is where per-screen drift would come from — check
    `GetDpiForMonitor`, not the stylesheet.
  Rules, in order of how easy they are to break:
  - **The font must cover every icon the config uses, or a mixed bar comes back.** `.icon`
    previously declared `'Segoe Fluent Icons', sans-serif`, but Segoe had only **25 of the 58**
    PUA codepoints in `config.yaml.tmpl` — the other 33 were drawn by whatever Qt picked per
    glyph, each with its own design size. Count it, don't eyeball it: parse `config.yaml.tmpl`
    for PUA codepoints, parse the face's `cmap` (format 12 — a format-4-only parser silently
    returns nothing for a Nerd Font), and intersect. It is **54/54** now.
  - **Getting there meant re-picking 18 glyphs in the config, not just changing the CSS.** Five
    (`U+E992`–`U+E995` volume, `U+F7B6` pomodoro break) were Segoe codepoints no Nerd Font has.
    Thirteen more sat on codepoints BOTH fonts define with different artwork, so dropping Segoe
    silently changed the picture: the weather sun became a database stack (`U+E706`), the
    language globe a droplet (`U+E774`), the whkd keyboard a seedling (`U+EDA7`), the cpu chip a
    stray `V` (`U+E950`), and all nine wifi icons turned into a protractor/spiral/shopping-bag
    set. **Render candidates and LOOK before choosing** — PIL + the .ttf onto a contact sheet
    takes a minute and is the only way to tell `wifi_strength_N` from `wifi_strength_N_alert`
    (`F0920`-style) or `_lock` (`F0921`-style), which differ by one codepoint.
  - `U+E70F` (win key) and `U+EBAA` (weather default) also overlap both fonts but the Nerd
    artwork is right — a Windows logo and a cloud — so they were left alone. Overlap is a
    prompt to look, not an instruction to replace.
  - **Weight 500, not 400.** Qt maps `font-weight: 500` onto the real Medium face
    (`QFontDatabase.styles()` lists Regular/Medium/SemiBold/…); Regular is too wispy at 15px.
  - **One size everywhere**: `*` and `.icon, .btn` are both 15px and every bar widget's own
    `font-size` was deleted (they ranged 12–20px). Popup/menu/card rules keep their own scale —
    they are separate surfaces. Do not reintroduce a per-widget size to fix one widget; that is
    how the drift started.
  - **A Nerd Font icon INKS PAST ITS ADVANCE, so it gets clipped or overlapped unless you hand
    it the next cell.** Measured in Qt at 15px: advance is a flat `9.00` (it is a monospace
    face) while the ink runs to `15.56` — up to **6.6px of spill to the right**, on 51 of the 54
    icons. Nothing spills left; "the left is cut off" is really the *previous* widget's text
    sitting on the icon. Two different fixes, because two different things clip:
    - `padding-right: 6px` on `.icon, .btn` — works where `.icon` lands on a real QLabel
      (whkd, cpu, memory).
    - a trailing **`U+00A0`** in the label template — needed where the icon is an inline
      `<span class='icon'>`, which ignores padding entirely. Affects the labels that END at the
      span (home, whkd, power: sized to the advance, so the glyph is cut at the widget edge)
      and the one with no separator (`volume`, `…</span>{level}`, so `100%` sat on the icon).
      Verify by screenshotting, not by reading the CSS — the padding line looks like it works.
    - **`&nbsp;` does NOT work**: yasb does not expand HTML entities, it renders the literal
      text `&nbsp;` into the bar. Use the actual character.
    - The real cure would be the Propo cut, whose advance matches its ink — but Qt only indexes
      four Nerd Font families here (FiraCode/Hack/JetBrainsMono/JetBrainsMonoNL, all the bare
      cut). `JetBrainsMonoNL Nerd Font Propo` is installed and invisible to Qt, so don't try.
- **Each Nerd Font face carries TWO family names, not interchangeable, pick per consumer:** name
  ID 1 (Win32) `JetBrainsMonoNL NF`, name ID 16 (typographic) `JetBrainsMonoNL Nerd Font`.
  Read them off the face's `name` table, never guess — and never from
  `System.Drawing.Text.InstalledFontCollection`, which only ever lists ID 1 and so calls a
  perfectly working ID-16 name "not installed".
  - **ASK THE ENGINE, it is the only authority.** For yasb that is Qt, and Qt's answer is the
    opposite of `InstalledFontCollection`'s — it indexes ID 16 ONLY. Measured with yasb's own
    bundled PyQt6 (`QFontDatabase.families()` + `QFontInfo(QFont(n)).family()`; the platform
    plugin must be the real one — under `QT_QPA_PLATFORM=offscreen` the DB is EMPTY and every
    name looks dead):
    - `JetBrainsMonoNL Nerd Font` → resolves. `Hack Nerd Font`, `Be Vietnam Pro`,
      `Noto Sans JP`, `Segoe Fluent Icons`, `Segoe UI` → all resolve (only the first is used).
    - `JetBrainsMonoNL NF`, `JetBrainsMonoNL NFM`, `JetBrainsMonoNL NFP`, `… Nerd Font Mono`,
      `… Nerd Font Propo` → **none are in Qt's DB; all silently become Tahoma.** Qt lists exactly
      four Nerd Font families here: FiraCode / Hack / JetBrainsMono / JetBrainsMonoNL, all in the
      long ID-16 form. So in styles.css the bare `JetBrainsMonoNL Nerd Font` is the ONLY usable
      JetBrains name — no NFM/NFP/NF entries, they are dead weight that hides a Tahoma fallback.
  - `dot_config/komorebi/komorebi.bar.json` is a DIFFERENT engine (Rust/DirectWrite) with ONE
    `font_family` string and no fallback, so it takes the ID-1 name `JetBrainsMonoNL NF` — the
    exact opposite of the styles.css value, same font. **`komorebi-bar --fonts` is the built-in
    authority**: it prints every face it can see, as `<family> <style>` (`JetBrainsMonoNL NF
    Regular`, `Hack Nerd Font Regular`), and `font_family` takes the family half. Verified by
    actually running `komorebi-bar --config ~/.config/komorebi/komorebi.bar.json` for a few
    seconds and screenshotting it: Nerd Font glyphs and Vietnamese diacritics both render.
    Nothing launches komorebi-bar in normal use here (yasb is the bar), so re-run that probe
    rather than assuming.
  - The value it replaced, `"JetBrains Mono"`, was NOT in `--fonts` at all — the plain JetBrains
    Mono family is not installed on this box, only the Nerd Font cuts. So komorebi's bar had
    silently been on a fallback face since the config was written.
  - Suffixes: bare **NF** = original advance widths, **NFM** = Nerd Font Mono (icons squeezed to
    one cell), **NFP** = Propo. `NL` = no ligatures, orthogonal to all three. Only the bare cut
    is exposed to Qt at all, so the NFM/NFP distinction is unusable from yasb.
  - **Hack is gone, and the old "Hack for icons" note was wrong.** That verdict came from a
    revert of a commit whose icon rules said `JetBrainsMonoNL Nerd Font Mono`/`NFM` — names Qt
    resolves to **Tahoma**. The badly-fitting glyphs were Tahoma's, never JetBrains'. Hack is
    also unusable for this box's text: it has **6 of the 90** Vietnamese precomposed codepoints
    (`U+1EA0`–`U+1EF9`) against JetBrainsMonoNL's 90, so a Vietnamese window title rendered in
    Hack switches font mid-word (`ô` is Latin-1 and stays, `ở` is not and jumps).
  - The pre-existing line-48 rule was `'JetBrainsMono NFP, Hack Nerd Font'` — the WHOLE string
    quoted as ONE family, so it matched nothing and the bar silently ran on Qt's default
    `monospace`. Two families, two quoted strings.
- **The archive extractor is NOT managed here.** NanaZip is installed by hand via winget
  (`M2Team.NanaZip`), which puts a `7z` app-alias on PATH. An earlier revision made the
  bootstrap `scoop install nanazip`, shim `7z` to its console exe and set `scoop config
  use_external_7zip true` — all removed. Do NOT re-add any of it; scoop pulling its own
  `7zip` package as a decompress dependency is expected and fine. (`use_external_7zip` may
  still be `True` in a machine's scoop config from that era — harmless, machine-local.)
- Prefer prebuilt backends where the registry default builds from source: `eza` is bare on
  macOS/Linux but `"aqua:eza-community/eza"` on Windows (registry default is `cargo:eza` — no
  Windows binary), hence the `{{ if ne .chezmoi.os "windows" }}` gate in `tools.toml.tmpl`.
  Same reason `micro`/`starship` use `aqua:` and `rtk`/`vivid` use `github:`. The backend
  prefix goes in the KEY, never the version value.
- **`rtk` (rtk-ai/rtk)** — `github:rtk-ai/rtk` (prebuilt release binary; the older `ubi:` backend
  works but mise deprecated it). The bootstrap also runs `rtk init -g --auto-patch` to register
  rtk's Claude Code command-rewrite hook globally. `--auto-patch` is REQUIRED: it patches
  `~/.claude/settings.json` without prompting, so the non-interactive bootstrap doesn't hang.
  Idempotent ("hook already present" on re-run); writes machine-local `~/.claude/RTK.md`. The rtk
  PreToolUse hook also ships in the managed `dot_claude/settings.json`, so the run finds it already
  present — `--auto-patch` mainly handles RTK.md + acts as a safety net.
- **`vivid` generates `LS_COLORS`** (mise `github:` backend). Its theme is the full upstream
  catppuccin-mocha with `red`→repo accent `#ff5189` (`dot_config/vivid/themes/
  catppuccin-mocha-red.yml`) — vivid needs a COMPLETE theme, a minimal override errors. zsh
  (`75-tools.zsh`) caches `vivid generate` to `$ZSH_CACHE_DIR/ls_colors` (regenerated when the
  theme changes) and feeds it to completion via `list-colors` (read at completion time, so it
  works despite running after compinit).
- **`delta` is wired into git via an include, NOT a managed `~/.gitconfig`.** Config lives in
  tracked `dot_config/git/delta.gitconfig`; the bootstrap adds an idempotent `include.path` to the
  UNMANAGED `~/.gitconfig` (identity/signing stay machine-local), gated `{{ if .tools }}`.
  `git config --global X` won't show included values without `--includes`, but real `git
  diff`/`log` follow the include fine. Both vivid + delta configs are `tools`-gated in
  `.chezmoiignore` (`.config/vivid`, `.config/git`).
- Completion uses fzf-tab (sheldon plugin, deferred) — it REQUIRES
  `zstyle ':completion:*' menu no` (never `menu select`); its `:fzf-tab:*` zstyles + eza/bat
  previews live in `50-completions.zsh` and inherit the catppuccin `FZF_DEFAULT_OPTS` via
  `use-fzf-default-opts`.
- **Claude Code itself is installed by the bootstrap**, using the documented "Native Install
  (Recommended)" one-liners VERBATIM — `irm https://claude.ai/install.ps1 | iex` on Windows,
  `curl -fsSL https://claude.ai/install.sh | bash` on Unix — only when `claude` is missing. It
  lands in `~/.local/bin` (already on PATH from the top of both scripts) and AUTO-UPDATES in the
  background afterwards. Do NOT swap in `winget install Anthropic.ClaudeCode` / `brew install
  --cask claude-code` / `npm i -g @anthropic-ai/claude-code`: per the docs those do NOT
  auto-update, so the box would silently drift behind. This is NOT optional polish: the
  marketplace/plugin step below is guarded on `claude` existing, so on a fresh box it would be a
  silent no-op AND would never retry, because the run_onchange fingerprint doesn't change
  afterwards. On Windows the install runs inside
  `& { … }` — the upstream installer sets `Set-StrictMode -Version Latest` and
  `$ErrorActionPreference = 'Stop'`, and the block scope keeps those out of the rest of the
  bootstrap (verified: the outer preference is unchanged after the block returns).
- **Claude marketplaces + plugins: `cza` INSTALLS WHAT'S MISSING, `czu` UPDATES WHAT'S THERE.**
  Two scripts, deliberately split:
  - **Install (bootstrap, `run_onchange_after_install-packages.{sh,ps1}`)** — `marketplace add`
    for every `extraKnownMarketplaces` entry not in `claude plugin marketplace list --json`, then
    `claude plugin install -y` for every `enabledPlugins` id not in `claude plugin list --json`.
    Both `list`s are local reads, so a box that already has everything does ZERO network work.
    `-y` is mandatory — the install prompt has no TTY here and would hang the bootstrap.
  - **Update (`run_after_update-claude-plugins.{sh,ps1}`)** — `claude plugin marketplace update`
    plus `claude plugin update <id>` per declared plugin. It is an ALWAYS-run script whose very
    EXISTENCE is gated in `.chezmoiignore` on `{{ ne .chezmoi.command "update" }}`, so only
    `chezmoi update`/`czu` ever sees it: `cza` stays config-only and offline, and an always-run
    script never parks a permanent `R` in `chezmoi status`. (`CHEZMOI_COMMAND` is also set to
    `apply`/`update` at runtime — the ignore gate is used instead because it also kills the
    status noise.)
  - **The old single `claude plugin marketplace update` line did neither job** — measured with a
    throwaway `CLAUDE_CONFIG_DIR`, so re-measure the same way before "simplifying" this back:
    - It does NOT read `extraKnownMarketplaces`. On a fresh box it prints **"No marketplaces
      configured"** and exits — nothing is ever cloned, so every plugin install then fails with
      *"not found in marketplace … your local copy may be out of date"*. Only `marketplace add`
      registers a marketplace (and it writes the entry into settings.json itself).
    - It does NOT refresh plugin code either; it only `git pull`s the marketplace clones under
      `~/.claude/plugins/marketplaces/`. Installed plugin code lives in
      `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` and moves only on `claude
      plugin update` (measured: `marketplace update` left claude-mem at 13.13.1; `plugin update`
      took it to 13.24.23). `plugin update` takes ONE plugin, is idempotent, exits 0 on
      "already latest".
  - **`claude-plugins-official` is declared in `extraKnownMarketplaces` even though it's the
    built-in one.** A fresh box does NOT have it registered (Claude Code adds it on first
    interactive use), so without the declaration the add loop skips it and all 13
    `@claude-plugins-official` plugins fail to install. Declaring it costs nothing on an
    existing box (the presence check skips it) and keeps ONE loop instead of a hardcoded
    special case. Verified end to end against an empty `CLAUDE_CONFIG_DIR`: 5 marketplaces
    added, 17 plugins installed, zero failures; the second run is silent.
  - Both scripts render their id lists from `dot_claude/settings.json.tmpl` via
    `includeTemplate … | fromJson`, so that file stays the single source of truth and there is no
    duplicate list. The RENDERED ids are also the bootstrap's run_onchange fingerprint — it
    re-fires exactly when a marketplace/plugin is declared, not on unrelated settings churn (the
    old `# settings fingerprint … | sha256sum` comment is gone). Add one by editing
    `enabledPlugins`/`extraKnownMarketplaces`, then `cza`. Every call is `|| echo` / `try/catch`
    so a network blip or a not-yet-installed `claude` never aborts setup.
- **`claude-mem` (`thedotmack` marketplace) is fully plugin-managed — beyond the generic
  `claude plugin install` above, the bootstrap needs NO claude-mem step.** Its own plugin `Setup` hook (`version-check.js`) version-checks and
  installs/updates the runtime per session, and its data lives in `~/.claude-mem/` (SQLite DB +
  chroma vectors + `settings.json`/`.env`), which `cza` never touches. So the whole integration
  is just the `enabledPlugins` toggle + the `thedotmack` entry in `extraKnownMarketplaces`; the
  `czu` update script bumps the plugin code in place — it never reinstalls or wipes the local
  memory DB. Do NOT add `npx claude-mem install` to the bootstrap: that's the non-plugin install
  path and would double-register hooks against the plugin's own.
- **Agent skills from repos with no marketplace** are declared as **`repo:skillspec:anchor`
  triples** — `blader/humanizer:humanizer:humanizer`, `tt-a1i/archify:archify:archify`,
  `vercel-labs/skills:find-skills:find-skills`, `mattpocock/skills:*:ask-matt`,
  `Leonxlnx/taste-skill:*:brandkit`. Each field earns its place:
  - **skillspec** = the `--skill` value. A literal name where only one skill is wanted — and it
    is NOT always the repo basename (`vercel-labs/skills` ships `find-skills`), so deriving it
    from the repo silently asks for a skill called "skills". `*` means "every skill this repo
    ships", which tracks upstream on its own: in three days `mattpocock/skills` went 38 → 37
    names and `Leonxlnx/taste-skill` 10 → 13, so a pinned name list would rot AND fail on the
    removed names.
  - **anchor** = the `~/.claude/skills/<dir>` whose presence means "this repo is already done on
    this box". Identical to skillspec for a single-skill entry; a representative skill for a `*`
    entry, because learning a `*` repo's real set costs the network round-trip the check exists
    to avoid. `rm -rf ~/.claude/skills/<anchor>` forces a reinstall.
  They are installed by both bootstraps with the `skills` CLI — `npx skills add <repo> -g`, the official
  method in each repo's own README. Humanizer ALSO offers a `/plugin marketplace add` path; it is
  deliberately NOT used, because archify has no marketplace at all, so the `skills` mechanism has
  to exist regardless — one mechanism for both beats splitting them, and it keeps
  `settings.json.tmpl` (and its fingerprint) untouched. Every flag is load-bearing for a
  non-interactive run and none may be dropped: `npx -y` skips **npx's own** "install skills?"
  prompt on a cold cache, the trailing `-y` skips the **CLI's** confirmation (two separate
  prompts, two separate flags), `--agent claude-code` suppresses the agent picker, `--skill`
  pins the selection, and `--copy` avoids symlinks — Windows symlinks need Developer Mode or
  elevation, which this bootstrap never takes. **`--agent claude-code` is the one that matters
  most**: without it the `skills` CLI installs for codex/gemini/copilot and Claude never sees the
  skill — this box had 50 skills in `~/.agents/skills` (per `~/.agents/.skill-lock.json`, the
  CLI's own record of what came from where) with only `archify` wired to Claude. That is the
  whole reason the two `*` repos are declared here.
  **`npx` comes from mise's `node = "lts"`, which lives in `develop.toml`** — so it is
  develop-gated even though Claude Code itself is base. Hence the rtk-style guard (`command -v
  npx` → `mise --cd "$HOME" exec --` → warn) rather than a `{{ if .develop }}` template gate: a
  tools-only box prints `[skills] … skipped` and carries on instead of silently shipping a
  script that can't run. Skills land in **`~/.claude/skills/<name>`, which chezmoi does NOT
  manage** (`chezmoi managed | grep -c '^.claude/skills'` → 0), so `apply` never fights them —
  and that dir IS the install check: the loop skips any triple whose anchor already exists, so
  `cza` never re-runs npx for a repo that's done (verified end to end: archify skipped,
  humanizer + find-skills + all of mattpocock/skills and taste-skill installed → 54 dirs in
  `~/.claude/skills`, second run silent, exit 0).
  Refreshing them is `czu`'s job — `run_after_update-claude-plugins.{sh,ps1}` runs a single
  `npx -y skills update -g -y`, which covers every GLOBAL skill (a superset of these three), so
  the repo:skill list is NOT duplicated there.

## Windows

### Shell & env
- **Package managers**: **scoop** (per-user, never elevated) installs `git` + `mise`; **winget**
  installs `Microsoft.PowerShell`. CLI tools come from **mise** (same `conf.d/*.toml` as Unix).
- **pwsh 7 comes from winget, NOT scoop.** The `winget` source ships `Microsoft.PowerShell` as an
  **MSIX bundle**, so it installs per-user with NO elevation (the MSI would need admin and would
  hang a non-interactive bootstrap) and drops a `pwsh.exe` app alias into
  `%LOCALAPPDATA%\Microsoft\WindowsApps`, on the user PATH by default. PATH resolution is the
  whole point: `[cd]` (`chezmoi cd`/`czcd`) and Claude Code's `statusLine` both invoke bare
  `pwsh`, so a box without it loses both. Flags are non-negotiable for a non-interactive run:
  `--accept-package-agreements --accept-source-agreements --disable-interactivity --silent`.
  Guarded by `Get-Command winget` (absent on LTSC/older builds) and by `$LASTEXITCODE`, so a
  failure warns instead of aborting. Any already-installed pwsh satisfies the `Get-Command pwsh`
  guard — the bootstrap never replaces one. The migration off scoop is proof the no-baked-path
  rule works: pwsh moved to `C:\Program Files\WindowsApps\Microsoft.PowerShell_<ver>_x64__…\`
  and `czcd` + the statusline kept working with no `chezmoi init` re-run.
- **PowerShell profile**: managed at `dot_config/powershell/profile.ps1`
  (→ `~/.config/powershell/profile.ps1`). The bootstrap dot-sources it from the real
  `$PROFILE` (both pwsh 7 and WinPS 5.1 paths, via OneDrive-aware `GetFolderPath`).
  Edit the managed file, not `$PROFILE`.
- **`XDG_CONFIG_HOME=~/.config`** is persisted (user env) by the bootstrap + set in the
  profile so XDG-aware tools read `~/.config` (mise's config dir resolves to `~/.config/mise`).
  Exported on every platform — Unix sets it in `zsh/conf.d/10-env.zsh` — so configs live under
  `~/.config` identically everywhere. (Do NOT pair it with `MISE_GLOBAL_CONFIG_FILE`; see
  Gotchas → mise.)
- **`powershell.exe` (WinPS 5.1) "not recognized"** → its dir
  `%SystemRoot%\System32\WindowsPowerShell\v1.0` fell off PATH (a Windows default that a trimmed
  Machine PATH can drop), breaking whkd keybinds, `[interpreters.ps1]`, and komorebi autostart.
  **Fix**: add that dir to the User PATH. Not a bootstrap step — a fresh box has it by default;
  only a hand-mangled PATH loses it. (pwsh 7 is unaffected — this is WinPS 5.1 only.)
- **starship** (`dot_config/starship.toml`, Windows-gated like `.config/powershell`) sets
  `scan_timeout = 500`: it globs the CWD once per prompt to pick language modules, and a cold FS
  cache (+ Defender) blows the 30ms default → `[WARN] … Scanning current directory timed out`.
  It's a CEILING, not a cost (warm scan ≈1ms), so raising it slows nothing. Measure with
  `starship timings`, never by guessing. What it shows here:
  - ~5ms outside a git repo, **~100ms inside one** — ~70ms of that is FIXED git-repo-discovery
    cost, independent of repo size, billed to whichever git-aware module runs FIRST (`directory`
    via its default `truncate_to_repo`, else `git_branch`). That toggle MOVES the 70ms, it
    doesn't remove it; only a prompt with no git info at all drops it. Don't "optimize" it.
  - `git_status` (~30ms) is a real `git status` subprocess — the one genuinely cuttable chunk,
    but it's information you want. Left enabled.
  - `docker_context` disabled: 3ms of a ~5ms non-repo prompt, and it renders nothing unless
    you're on a non-default docker context.
- Skipped on Windows: tmux, sheldon, p10k, `.claude/statusline.sh` (Windows uses
  `.claude/statusline.ps1` instead — see Gotchas → Claude Code).

### Window manager (`wm` profile)
scoop installs `komorebi whkd yasb` (extras bucket); configs `dot_config/{whkd,komorebi,yasb}`
apply only on Windows+wm (gated like skhd/yabai).
- **Config homes**: `KOMOREBI_CONFIG_HOME`/`WHKD_CONFIG_HOME`/`YASB_CONFIG_HOME` → `~/.config/<tool>`,
  persisted at User scope by the bootstrap (these apps launch at startup, outside any shell
  profile; else komorebi defaults to `~/komorebi.json`, whkd to `~/.config/whkdrc`).
- **komorebi autostart = a logon scheduled task** named `komorebi`, NOT `komorebic
  enable-autostart` or a shell:startup shortcut. Why those fail: at login scoop's shims aren't
  on PATH, so `komorebic start` (which does `Start-Process komorebi.exe`) can't find
  komorebi.exe — nothing tiles (reproduce: strip `<scoop>\shims` from PATH). The task runs the
  managed launcher `dot_config/komorebi/autostart.ps1`, which resolves `-ShimsDir` at
  registration (`Split-Path (Get-Command komorebic).Source`, while PATH is intact — scoop can
  live anywhere, e.g. `D:\scoop`, and doesn't set `$env:SCOOP`), prepends it to PATH, then starts
  komorebi+whkd ASAP with retry (no up-front sleep), and runs `komorebic replace-configuration`
  once `komorebic state` succeeds — a readiness probe, not a fixed sleep. That reload only covers
  windows ALREADY OPEN at login; it does nothing for windows opened later (see the extension-popup
  gotcha below). Note the command is `replace-configuration` — `reload-configuration` is for the
  LEGACY `komorebi.ahk`/`.ps1` configs and is a silent no-op against a static `komorebi.json`.
- **Task command = `<System32 powershell.exe> -NoProfile -ExecutionPolicy Bypass -WindowStyle
  Hidden -File autostart.ps1 -ShimsDir <shims>`.** WinPS 5.1 because pwsh isn't reliably on the
  task PATH. `-WindowStyle Hidden` is sufficient — no console appears (verified by enumerating
  visible windows during a task run).
- **NEVER wrap the task command in `conhost.exe --headless`.** At LOGON it can't allocate its
  pseudoconsole during early session init: the task dies with `0x80070003` (ERROR_PATH_NOT_FOUND)
  and nothing tiles. The trap is that it works ON DEMAND — `Start-ScheduledTask` reports `0x0`
  while every real logon fails, so diagnose with `(Get-ScheduledTaskInfo -TaskName
  komorebi).LastTaskResult` right after a REBOOT. It was added to kill a console flash that
  actually came from `komorebic start` spawning pwsh; the launcher now starts `komorebi.exe`/
  `whkd.exe` directly, so no flash remains. Also do NOT revert to a VBScript/mshta launcher (both
  deprecated) or a shell:startup shortcut/`komorebi.vbs` (races the task — the bootstrap deletes `komorebi.lnk`).
- **yasb** autostarts via its own installer. Its `config.yaml.tmpl` templates user paths with
  `{{ .chezmoi.homeDir | replace "/" "\\" }}` — never hardcode the username.
- **Browser extension popups are titled `_crx_<extension-id>`, NOT the extension's name.** A
  popped-out Chromium extension window belongs to the BROWSER exe (`brave.exe`, class
  `Chrome_WidgetWin_1`) and its title is Chromium's internal id form — the Bitwarden popup is
  literally `_crx_nngceckbapebfimnlniiiahkandclblb`. So a `Title` rule for `"Bitwarden"` never
  matches, at any `matching_strategy`, and komorebi tiles the popup. The rule here is therefore
  `floating_applications` / `Title` / `StartsWith` / `_crx_` — ONE rule covering every popped-out
  extension from any Chromium browser, with no per-extension id to maintain. The title is final
  at window-creation time (no ` - Brave` suffix, no later rename), so this is not a title-timing
  problem and needs no reload to take effect.
  **Get the real identifiers from komorebi's own log, don't guess**: `%TEMP%\komorebi_plaintext.log*`
  logs every event as `(hwnd: N, title: …, exe: …, class: …)`. Grep it for the app; if the name
  never appears, that IS the finding. **Asymmetry when auditing rules with that log: FLOATED
  windows are still logged (`Picture in picture` shows up), but IGNORED ones are not logged at
  all.** So zero hits disproves a `floating_applications` rule, and proves nothing about an
  `ignore_rules` entry — never delete an ignore rule on log silence alone. Find an extension's id under
  `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Extensions\` (its
  `_locales/en/messages.json` gives the display name) — only needed to narrow the rule to a
  SINGLE extension; the `_crx_` prefix rule needs no id at all.
- **Seelen UI conflict**: komorebi fights any concurrent tiling WM (`seelen-ui.exe`). Keep
  Seelen for its dock but turn OFF its window manager (this box has
  `@seelen/window-manager: enabled:false`), or neither tiles cleanly.

## Gotchas

### chezmoi
- chezmoi **copies** files (not symlinks). Migrating from a symlink manager replaces the link
  with a real copy.
- `~/.config/chezmoi/chezmoi.toml` (from `init`) OVERRIDES `.chezmoidata.yaml`, and `apply`
  does NOT re-prompt profiles — edit that config or re-run `init`.

### mise
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

### Shell (zsh + pwsh)
- **PowerShell resolves ALIASES before FUNCTIONS.** A `function ls { eza … }` in the profile
  is silently shadowed by the shipped `ls`→Get-ChildItem alias (so `ls` keeps built-in output
  even though the function exists). The eza block therefore `Remove-Item Alias:ls -Force` before
  defining the function. Only `ls` collides with a built-in alias (la/ll/lt/lm/… don't; `tree`
  is an .exe, which a function already outranks). zsh is unaffected — it uses `alias ls=…`, not
  a function. If you add a new eza/tool function whose name is also a default PS alias, drop the
  alias too. (`Get-Command ls` showing `CommandType: Alias` instead of `Function` = the bug.)
- **zoxide must init AFTER starship in the PowerShell profile.** zoxide does NOT shadow `cd` —
  it records visited dirs via a hook that WRAPS the existing `prompt` function (capturing it
  once, guarded by `$__zoxide_hooked`). starship REPLACES `prompt` wholesale, so if zoxide inits
  first, starship clobbers the hook and NO directory is ever recorded → `z foo` says "not found"
  while the DB silently freezes (stale entries still resolve, new dirs never appear). Order:
  gh → starship → zoxide (zoxide last among prompt-touching inits). Symptom check:
  `(\$function:prompt) -match '__zoxide_hook'` must be True in a real shell; `zoxide query -l`
  missing a dir you just visited = the bug. TESTING TRAP: `pwsh -Command` already auto-loads the
  profile, so an extra `. $PROFILE` double-loads it and gives a FALSE NEGATIVE (starship replaces
  the prompt again; zoxide's once-only guard skips re-wrapping) — test in a single-load shell.
  (zsh is unaffected: `zoxide init zsh` uses a `chpwd`/`precmd` hook ARRAY, not a wrapped
  function, so order vs starship/p10k doesn't matter the same way.)
- **`cd` → zoxide is guarded by `CLAUDECODE` on BOTH shells.** The profile sets `Set-Alias cd
  __zoxide_z` (+ `cdi`→`__zoxide_zi`) to mirror zsh's `alias cd="z"`/`alias cdi="zi"`, so
  `cd <keyword>` fuzzy-jumps everywhere; `__zoxide_z` still cd's literally for real paths
  (`cd ..`, `cd C:\x`, `cd .\sub`). `-Force` is required to override the built-in read-only
  `cd`→Set-Location alias; `-Option AllScope` follows it into nested scopes. But inside Claude
  Code's tool shell (`CLAUDECODE=1`) a `cd <badpath>` would route through zoxide and leak
  `zoxide: no match found` into piped output, corrupting rtk's JSON rewrites and grep/JSON
  pipelines — so `[[ -z "$CLAUDECODE" ]]` / `-not $env:CLAUDECODE` keeps the real `cd` builtin
  there. (rtk's hook is NOT the culprit — it passes `cd` through untouched; the alias was.)

### Claude Code
- **Statusline: Git Bash flashes a console window on Windows; use the PowerShell port.**
  Claude relaunches the statusLine `command` as a native child on every UI update (verified: the
  spawned process has MSYS `PPID=1`, parented by node, not an outer `bash -c`). MSYS/Cygwin
  `bash.exe` calls `AllocConsole()` when its stdio is piped, BYPASSING Node's `windowsHide` — so
  Git Bash and its `jq`/`awk`/`tail` children flash a console each render, while native console
  apps (pwsh, node, git) spawned the same way stay hidden. Fix: `dot_claude/statusline.ps1`, so
  Windows launches ONE hidden `pwsh.exe`. `dot_claude/executable_statusline.sh` stays the
  macOS/Linux version; **keep the two in sync.** Both are OS-gated in `.chezmoiignore` (`.sh`
  ignored on Windows, `.ps1` on Unix), and `settings.json.tmpl` branches `statusLine.command`
  per-OS — a plain settings.json can't (one hardcoded command is always wrong on one OS: the
  clean-install-Windows bug). Bonus: the bash script's `echo -e` mangles Windows backslash paths
  (`\0` in `C:\Users\0x130` → NUL), so line 1 was already broken there.
- **`~/.claude/settings.json` is a fully-managed template (`dot_claude/settings.json.tmpl`) —
  chezmoi owns it, `apply` overwrites the live file.** It is a template ONLY so `statusLine` can
  branch per-OS; every other key is static. Tradeoffs, know them:
  - **`apply` CLOBBERS live machine-local keys.** Claude rewrites settings.json constantly
    (plugin toggles, marketplaces, ad-hoc approved commands) and those edits revert on the next
    `apply`. Because it's a `.tmpl`, `czra` does NOT round-trip (it would overwrite the `{{ }}`
    with literal JSON) — capture such a change by hand-editing the `enabledPlugins`/
    `extraKnownMarketplaces` blocks in the template, then commit.
  - Tracked = the curated shared state: `env` (`PONYTAIL_DEFAULT_MODE`), `defaultMode`, `hooks`
    (rtk), `statusLine` (per-OS), `permissions.allow` (Bash baseline + codegraph MCP),
    `enabledPlugins`, `extraKnownMarketplaces`, UI prefs (`tui`, `timeFormat`, `editorMode`,
    `preferredNotifChannel`, `advisorModel`, the booleans).
  - Trips `chezmoi status`/`czd` and the `80-chezmoi-drift.zsh` nudge whenever Claude touches it
    — expected; `czd` to see what changed. Do NOT switch to symlink mode: Claude saves
    atomically via rename, replacing any symlink.

### tmux (Unix)
- **Plugins install via `git clone` in the bootstrap — no tmux server.** Do NOT "fix" it to use
  TPM's `bin/install_plugins`: that needs a live server that has sourced the config (for
  `TMUX_PLUGIN_MANAGER_PATH`); during a non-interactive bootstrap a session-less
  `tmux start-server` exits first → TPM aborts "not configured" → 0 plugins, AND it leaves a
  stale server on the default socket → plain `tmux` then dies with "server exited unexpectedly"
  after the next tmux upgrade (old server vs new client). A "plugin install" is just a clone into
  `~/.tmux/plugins/<name>`, so the bootstrap parses `@plugin` lines and clones them. After
  upgrading tmux, `tmux kill-server` (or relog) to drop a stale old-version server.
- **Status-bar `#(…)` runs as the SERVER's user, not the pane's.** So the old
  `status-left … #(whoami)` froze on the login that started the server and never tracked
  `sudo -i`/`su -`. Fix: `~/.local/bin/tmux-user` (`executable_tmux-user`, tmux-only — ignored
  on Windows like `tmux-sessionizer`) takes `#{pane_tty}` and reports the owner of the tty's
  FOREGROUND process group (the first proc with `+` in STAT — works on BSD/macOS + GNU/Linux),
  so the bar switches to `root` the moment you elevate. `status-interval 1` refreshes it.
  NOTE: `#(…)` jobs are async — a one-shot `tmux display-message -p '#(…)'` returns EMPTY the
  first time (the job hasn't finished), so test the script directly or via `tmux run-shell`,
  not display-message. The live status bar re-evaluates and caches, so it always populates.

### Tiling WM (both OSes)
- **The two keymaps are kept in sync — edit them as a pair.** `dot_config/skhd/skhdrc`
  (macOS/yabai) and `dot_config/whkd/whkdrc` (Windows/komorebi) share one mnemonic scheme
  (`alt`=focus, `alt+ctrl`=move, `[`/`]`=prev/next, numbers=jump) so muscle memory carries
  across machines. A change to one almost always needs the mirror change in the other; both
  files' headers document the scheme. Deliberate per-OS divergences (don't "fix" them to match):
  monitor-move is `⌃⌘←/→` on macOS but `win+shift+←/→` on Windows (Win+arrow=Snap, Win+P=
  Projection are reserved); macOS adds `⌥\`` recent-workspace, balance, sticky/pip (no komorebi
  verb).
- **yabai Space (workspace) binds need SIP partially disabled + the scripting addition** — with
  SIP on they silently no-op while every other bind still works (Accessibility only).

## Before committing
- ALWAYS update docs in the same commit as the change they describe:
  - `README.md` — anything user-facing (setup, usage, profiles, commands).
  - `CLAUDE.md` (this file) — naming conventions, profiles, tools split, workflow, gotchas.
- A commit that changes behavior, profiles, naming, or the bootstrap MUST NOT leave the docs stale.
