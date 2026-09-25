# AGENTS.md — Windows tiling WM (komorebi + whkd)

Scoped notes for `dot_config/{komorebi,whkd}` (`wm` profile). yasb has its own `dot_config/yasb/AGENTS.md`; the whkd↔skhd keymap-pairing rule is in the root `AGENTS.md`.

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
- **There is no "don't manage fullscreen windows" switch — games go in `ignore_rules` by exe.**
  Checked against `komorebic static-config-schema` on 0.1.41: the schema has no `fullscreen`
  key at all, and the only levers are the per-application rule lists plus `float_override`
  (float EVERYTHING new, then force-manage the rest via `manage_rules`, i.e. an inverted model
  this repo does not use). So each game gets an `Exe` entry: `Palworld-Win64-Shipping.exe`,
  `DeltaForceClient-Win64-Shipping.exe` + its launcher `DeltaForceClient.exe` (CS2 is a `Title`
  rule instead). A UE game ships the real window as `<Name>-Win64-Shipping.exe` under
  `<install>\<Name>\Binaries\Win64\`, and the root-level exe is usually just the launcher —
  add both, they are separate windows. The community `applications.json`
  (`app_specific_configuration_path`) does NOT cover these; grep it before adding a rule.
- **The generic escape hatch is `alt + ctrl + p` (`komorebic toggle-pause`)**, already bound in
  `whkdrc`. It covers any game with no config edit, so a rule is only worth adding for one you
  play often.
- **Seelen UI conflict**: komorebi fights any concurrent tiling WM (`seelen-ui.exe`). Keep
  Seelen for its dock but turn OFF its window manager (this box has
  `@seelen/window-manager: enabled:false`), or neither tiles cleanly.
