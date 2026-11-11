# AGENTS.md — agent-browser (the agents' browser tool)

Scoped to `dot_agent-browser/`, `dot_local/bin/executable_bp` and `bp` in `profile.ps1`. The agent
rules (sessions, profiles, never Zen) are in `dot_claude/CLAUDE.md`; repo-wide rules: root `AGENTS.md`.

- **Install = mise** (`aqua:vercel-labs/agent-browser`, `tools` profile). Never `agent-browser install`
  in the bootstrap: it drives Brave; its own Chrome for Testing is a by-hand fallback when Brave is absent.
- `config.json.tmpl` finds Brave at APPLY time (`stat` / `lookPath`, never a baked path). Brave is
  installed after files apply, so a fresh box gets `executablePath` on its 2nd apply.
- **Security keys stay on**: `contentBoundaries`, `maxOutput`, `idleTimeout`, `actionPolicy` →
  `policy.json` (denies eval / download / upload / state). The policy binds the user too — a by-hand
  `state save` passes its own `--action-policy`; Claude is denied that flag (`claude-settings.json`).
- **`policy.json` lists DAEMON ACTION NAMES** (`evaluate`, `cookies_get`, `state_save`, …), not the
  docs' categories (`eval`, `state`): a category name matches nothing and silently allows all. The
  names are the `"action"` values in upstream `cli/src/commands.rs`. Verify after a change: in a
  throwaway session, `agent-browser --json eval 1` must fail with "denied by policy".
- `--allowed-domains` can't combine with `--profile`: client profiles rely on the policy alone.
- Profiles live in `~/.local/share/browser-profiles/<name>` — unmanaged, never synced (cookies are
  encrypted per OS user). `bp` (sh) and `bp` (pwsh) open one by hand: **edit them as a pair**.
- `AGENT_BROWSER_ENCRYPTION_KEY` is a per-machine secret — never in this repo.
