# AGENTS.md — Windows tiling WM (komorebi + whkd)

Scoped to `dot_config/{komorebi,whkd}` (`wm` profile). yasb: `dot_config/yasb/AGENTS.md`; the
whkd↔skhd keymap pairing rule is in the root `AGENTS.md`. The "why" behind each rule is in its
commit (`git log -S`).

## Install & autostart
- scoop (extras bucket) installs `komorebi whkd yasb`; configs apply only on Windows + `wm`.
- `KOMOREBI_CONFIG_HOME` / `WHKD_CONFIG_HOME` / `YASB_CONFIG_HOME` → `~/.config/<tool>`, persisted
  at User scope (the apps start outside any shell profile).
- **komorebi autostart = `komorebic enable-autostart --whkd -c <komorebi.json>`** — a shell:startup
  `komorebi.lnk` running `komorebic-no-console.exe start` (no console → no flash at login; verified
  after a reboot, 2026-10-05). It works because scoop's shims are on the User PATH (`komorebic start`
  does `Start-Process komorebi.exe`); the July 2026 logon task + `autostart.ps1` launcher predate
  that. The bootstrap unregisters the old `komorebi` task so the two can't race.
  - **NEVER wrap a logon launcher in `conhost.exe --headless`** — it fails at LOGON with
    `0x80070003` while working on demand. No VBScript/mshta launcher.
- **Restart = `autostart.ps1 -Restart` in its OWN process** (direct komorebi.exe/whkd.exe launch with retry, then
  `komorebic replace-configuration`) (whkd `alt+ctrl+o`, yasb
  `reload_command`). Never chain `komorebic stop --whkd; komorebic start` inside whkd: `stop --whkd`
  kills whkd and its shell, so `start` never runs.
- `display_index_preferences` keys monitors by **`serial_number_id`** (`komorebic
  monitor-information`), not `device_id`: the device_id changes whenever Windows re-enumerates the
  monitor (e.g. after it is removed in Device Manager), silently dropping the workspace config.
- Removed/absent monitor devnodes (`Get-PnpDevice -Class Monitor` all `Present=False`) → komorebi
  sees one `DISPLAY1`/`UNKNOWN` monitor and yasb (bound to screen names) shows no bar. Fix:
  elevated `pnputil /scan-devices`, then restart komorebi + `yasbc stop`/`start`.
- yasb autostarts via its own installer; `config.yaml.tmpl` builds user paths from
  `{{ .chezmoi.homeDir | replace "/" "\\" }}` — never hardcode the username.

## Rules (`komorebi.json`)
- **Chromium extension popups are titled `_crx_<id>`**, owned by the browser exe. One rule —
  `floating_applications` / `Title` / `StartsWith` / `_crx_` — covers every extension; a rule on
  the extension's name never matches.
- **Revit popups share the main window's class** (`HwndWrapper[...]`, WPF). One composite
  `floating_applications` rule — `Exe` `Revit.exe` AND `Title` `DoesNotStartWith` `Autodesk Revit`
  — floats every dialog/detached view and keeps the main window tiled. The main window is
  shown BEFORE it gets its `Autodesk Revit` title, so `Revit.exe` must also be in
  `object_name_change_applications` (re-evaluated on title change) or it is never managed.
- Get real identifiers from `%TEMP%\komorebi_plaintext.log*` (`hwnd`, `title`, `exe`, `class`).
  FLOATED windows are logged, IGNORED ones are not — never delete an `ignore_rules` entry on log
  silence.
- **No "skip fullscreen" switch exists** — games go in `ignore_rules` by `Exe`. UE games: add both
  `<Name>-Win64-Shipping.exe` and the launcher exe (separate windows).
- `alt + ctrl + g` (`komorebic toggle-pause`) covers any game with no config edit.
- **`applications.json` is NOT tracked**: bootstrap part 1 runs `komorebic
  fetch-app-specific-configuration` (`fetch-asc` by hand to refresh). Own rules go in
  `komorebi.json` — the next fetch overwrites `applications.json`. Grep it before adding a rule.
- **Seelen UI**: keep its window manager OFF (`@seelen/window-manager: enabled:false`) or the two
  WMs fight.
