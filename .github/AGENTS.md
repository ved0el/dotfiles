# AGENTS.md — CI (.github/) + Renovate

Scoped notes for `.github/workflows/*` and the root `renovate.json`.

- **Two workflows, split by cost.**
  - **`lint.yml`** runs on every push to `main` and every PR, skips `*.md`-only commits, and
    takes ~5s. It renders both bootstraps and runs `apply --dry-run`, which catches most
    mistakes.
  - **`e2e.yml`** runs a real `chezmoi init --apply` on ubuntu x64, ubuntu arm64, macOS and
    Windows. That takes minutes per OS and is network-heavy, so it is **path-filtered**: it
    runs only when something that changes WHAT GETS INSTALLED moves. That means `run_*`,
    `.chezmoi*`, the mise manifests, the sheldon and tmux plugin lists (the bootstrap clones
    them), `dot_claude/settings.json.tmpl` (the bootstrap renders its plugin ids from it), and
    the workflow file itself.
  - e2e also runs **weekly** (Mon 03:00 UTC) because every mise tool is `latest`, so an
    upstream release can break a fresh install without any commit here. It can also be
    started by hand with `workflow_dispatch`. If you add a file the bootstrap reads, add it to
    e2e's `paths` list.
  - arm64 is kept because it is the only job that catches a mise tool with no linux-arm64
    asset, which is what the Raspberry Pi needs.
  - Both workflows cancel a superseded run.
- **The verify step prints `chezmoi status` and `chezmoi diff` before it fails.** A bare
  `chezmoi verify` exits 1 with NO output, and that is why a red Ubuntu/macOS run went
  undiagnosed from `8afea8e` onward. Read the step log first, not the bootstrap.
- **e2e exports `GITHUB_TOKEN` (the job token) to every step.** mise resolves `latest` and
  downloads `github:`/`aqua:` tools through the GitHub API. Unauthenticated, that allows 60
  requests/hour **per IP**, and hosted runners share IPs. macOS died mid-`mise install` on "API
  rate limit exceeded" before it had installed a single one of this repo's tools. With the
  token the limit is 5000/hour, and it stays read-only per `permissions: contents: read`. Do
  not drop it to "simplify".
- **A second `chezmoi apply --force` runs before verify, on purpose.** Cause:
  `claude plugin marketplace add` rewrites a newly added marketplace's entry in the MANAGED
  `~/.claude/settings.json` and DROPS its `autoUpdate: true` (`ponytail`, `last30days-skill`).
  It has no flag to keep it. Reproduced with a throwaway `CLAUDE_CONFIG_DIR`. An entry with no
  `autoUpdate` of its own, such as `anthropics/skills`, comes back byte-identical, which is why
  a first test against that marketplace showed nothing. It happens on the FIRST run only,
  because the adds are skipped once a marketplace is registered. The next `cza` restores the
  file, and the second apply in CI is exactly that `cza`. Verify then proves the setup
  converges and the bootstrap did not re-run. Fixing it inside the bootstrap was rejected for
  these reasons:
  - Writing the template back from the bootstrap would put the whole of `settings.json` into
    its run_onchange fingerprint.
  - Calling `chezmoi` from inside a chezmoi script would contend for the state lock.
  - Dropping `autoUpdate` from the template would lose the feature.
- **`e2e-windows` runs its steps in `pwsh` on purpose.** That reproduces the PSModulePath leak
  the bootstrap guards against (see the root `AGENTS.md` → Windows → Shell & env). Do not "simplify" the shell to
  `powershell`, because that would hide the bug again.
- **Renovate (`renovate.json`) updates GitHub Actions and nothing else**
  (`enabledManagers: ["github-actions"]`). Dependabot was removed so that only one bot runs.
  mise tools are deliberately NOT managed by Renovate: they stay `latest`/`lts`, and each
  machine upgrades them itself. Details:
  - **Location:** the file is at the repo root and is listed in `.chezmoiignore` beside
    README/AGENTS.md. chezmoi applies every non-dot root file to `~/`, so without that entry it
    would land in `$HOME`. Check with `chezmoi managed | grep -c renovate`, which should print
    0. (`.github/renovate.json` is read just as well; location has no effect on the dashboard.)
  - **Dependency Dashboard:** it is on, because `config:recommended` enables it. It is one
    issue that lists pending, rate-limited and major updates, and it is the only place a held
    major shows up before you act on it.
  - **Pins:** `helpers:pinGitHubActionDigests` keeps every `uses:` pinned by SHA with a
    `# vX.Y.Z` comment. Renovate bumps both together.
  - **Automerge:** minor/patch/digest updates are grouped into one PR and merged by RENOVATE
    itself (`platformAutomerge: false`, `automergeType: pr`), and only after every check on
    the PR is green. Majors stay open for a human.
  - **Do NOT switch to GitHub-native automerge.** This repo has "Allow auto-merge" off and no
    branch protection on `main`. With no required checks, native auto-merge would merge
    immediately without waiting for CI.
  - **Do NOT use `automergeType: branch` either.** CI only triggers on pushes to `main` and on
    PRs, so a Renovate branch would have no checks to wait for.
  - **`minimumReleaseAge: 3 days`** is a supply-chain cooldown, so a release that gets pulled
    back never merges itself.
  - **Validate edits** with `npx -y --package renovate -- renovate-config-validator
    renovate.json`.
  - **Needs the Mend Renovate GitHub App installed on the repo.** Without it this file does
    nothing.
