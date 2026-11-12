# psmux + claude-rc (Windows)

Nested rules (the root AGENTS.md points here). Same style: terse; the why is in the commit.

- **psmux** reads `~/.tmux.conf`; Windows-only lines are `{{ if eq .chezmoi.os "windows" }}` blocks
  in `dot_tmux.conf.tmpl`. Plugins are copied from the `psmux/psmux-plugins` monorepo into
  `~/.psmux/plugins/` (their `plugin.conf` hardcodes that path) — keep the bootstrap list and the
  `@plugin` lines in sync. Not ported: the sessionizer (`C-b f`).
  Its border label is a literal replace of `#{pane_title}`/`#{pane_index}`/`#P` only (`#P` = pane
  id), so the pane name is the pane title. psmux exposes no "renamed" flag for a window or pane, so only a human names them:
  `allow-set-title`/`allow-rename`/`automatic-rename` off; status-left shows the window number while a window is still `pwsh`, the dir
  while a pane title is still `#{host}` (`#H` isn't expanded inside `#{==:}`). Claude panes are found for restore by the
  session id `statusline.ps1` records in `~/.psmux/claude-sessions/<dir>`, not by their (now unset) titles.
  No extended-keys, so `C-Enter` is bound to `send-keys C-j`; over SSH the client can't send C-Enter at all, so Alacritty's `[keyboard]` binds `Control+Enter` to `chars = "\u001b\r"` (ESC CR = Alt+Enter, which psmux's SSH and console input forwards as `\x1b\r` — Claude's newline; a bare `\n` is parsed as Enter). No `psmux-cpu` (pwsh every status tick).
  psmux re-runs `Set-PSReadLineOption -PredictionSource None` after the profile unless
  `allow-predictions on` (+ `prediction-dimming off`) — both set in the Windows block.
  Restore = `~/.psmux/tm-restore.ps1` (never attaches), run by profile `tm` (+ attach) and, `sshd` only, the
  `psmux-restore` AtLogOn task (only that task passes `-Lock`, which locks the console after an autologon;
  `tm` must never lock — a terminal running `tm` at startup locked every PIN login; autologon = at boot; a logon task needs no elevation, a boot/S4U one does
  and lacks the user's creds — a hand-made boot task running bare `claude` once clobbered the save). `tm` is
  auto-run at the end of the profile on an interactive SSH login — not `pwsh -c`,
  psmux, `CLAUDECODE`; restore runs whenever a saved session isn't running (`psmux ls` exits 0 with no server —
  test its output) (`@continuum-restore` off: one server per session re-fires its once-per-server
  guard); `node` panes go through `~/.psmux/strategies/node_claude.ps1` (title → `custom-title` →
  `Set-Location <dir>; claude --resume` — cd first, a warm pane's own `cd` can lose the race, else a comment line — never empty, resurrect falls back to `node`).
- **`claude-rc`** (`sshd` only): an AtLogOn task (not elevated — admin commands go through gsudo) runs
  `claude remote-control --spawn same-dir --no-create-session-in-dir` hidden in `D:\work` (if it exists, else
  `~`), so a new session can start from claude.ai / the app after a reboot with no SSH login; restored panes
  come back with `--remote-control` (`node_claude.ps1`). Wrapped in `while ($true) { …; Start-Sleep 60 }`:
  Task Scheduler only restarts a task that fails to START, and the server exits 1 on a network drop or
  while a killed one's registration is still live ("already served", ~3 min). Not a psmux pane: a second
  `node` pane in the same dir makes the resurrect strategy skip both.
