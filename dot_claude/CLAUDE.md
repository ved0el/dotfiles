@RTK.md

# CodeGraph

- At the start of work in a git repo that contains source code, check for `.codegraph/` at
  the repo root. If it is missing and `codegraph` is on PATH, run `codegraph init --yes`
  (non-interactive, indexes in seconds, then auto-syncs). Skip `$HOME`, non-git dirs, and
  repos with no source code.
- When `.codegraph/` exists, answer structural questions (how X works, what calls Y, blast
  radius of a change) with `codegraph_explore` (subagents: `codegraph explore "<query>"`)
  before Grep/Read. Treat its returned source as already read.

# Shell tools

The dotfiles install fast modern CLIs (mise) on every OS. In shell commands (Bash and
PowerShell), when the built-in Grep/Glob/Read tools don't fit, prefer them over the classics:

| instead of | use |
|---|---|
| `grep -r`, `Select-String` | `rg` |
| `find`, `Get-ChildItem -Recurse` | `fd` |
| `sed -i` / `sed 's/…/…/'` (simple replace) | `sd` |
| `ls -R`, `tree` | `eza --tree` |
| parsing JSON / YAML by hand | `jq` / `yq` |

Fall back to the classic only when the modern one is missing (`command -v` / `Get-Command`)
or a flag it lacks is needed.
