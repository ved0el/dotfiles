# AGENTS.md — CI (.github/) + Renovate

Scoped to `.github/workflows/*` and the root `renovate.json`. The "why" behind each rule is in
its commit (`git log -S`).

## Workflows
- **`lint.yml`** (~5s, every push/PR, skips `*.md`-only): renders every `run_onchange_after_*`
  script, `apply --dry-run`, NEVER-rules `--selftest` + `--scan`.
- **`e2e.yml`**: real `chezmoi init --apply` on ubuntu x64, ubuntu arm64 (the Raspberry Pi's
  only check for missing linux-arm64 assets), macOS and Windows. **Path-filtered** to what changes
  installs: `run_*`, `.chezmoi*` (incl. `.chezmoitemplates/`), mise manifests, sheldon/tmux
  plugin lists, `dot_claude/modify_settings.json`, the workflow. A new file the bootstrap reads
  goes into `paths`. Also weekly (every mise tool is `latest`) and `workflow_dispatch`.
- Both cancel a superseded run.
- **The verify step prints `chezmoi status` + `diff` before failing** — bare `chezmoi verify`
  exits 1 silently. Read that step's log first.
- **Keep `GITHUB_TOKEN` exported in e2e**: mise resolves `github:`/`aqua:` tools through the API,
  and unauthenticated shared-IP runners hit the 60/hour limit mid-install.
- **The second `chezmoi apply --force` before verify is required**: `claude plugin marketplace
  add` drops a new marketplace's `autoUpdate` from the live settings on the first run only; the
  second apply (= the next `cza`) restores it and proves the bootstrap does not re-run.
- **`e2e-windows` runs its steps in `pwsh` on purpose** — it reproduces the PSModulePath leak the
  bootstrap guards against. Don't switch it to `powershell`.

## Renovate (`renovate.json`)
- Updates GitHub Actions only (`enabledManagers: ["github-actions"]`); no Dependabot; mise tools
  stay `latest`/`lts`. Needs the Mend Renovate app installed.
- Lives at the repo root and MUST stay in `.chezmoiignore` (`chezmoi managed | grep -c renovate`
  → 0).
- `helpers:pinGitHubActionDigests`: `uses:` pinned by SHA + `# vX.Y.Z`. Dependency Dashboard on.
- Minor/patch/digest are grouped and merged by RENOVATE after all checks pass
  (`platformAutomerge: false`, `automergeType: pr`); majors wait for a human.
  - **NOT GitHub-native automerge**: no branch protection/required checks, so it would merge
    before CI.
  - **NOT `automergeType: branch`**: CI only runs on `main` pushes and PRs, so there'd be no checks.
- `minimumReleaseAge: 3 days` (supply-chain cooldown).
- Validate: `npx -y --package renovate -- renovate-config-validator renovate.json`.
