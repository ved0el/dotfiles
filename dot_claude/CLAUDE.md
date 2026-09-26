@RTK.md

# CodeGraph

- At the start of work in a git repo that contains source code, check for `.codegraph/` at
  the repo root. If it is missing and `codegraph` is on PATH, run `codegraph init --yes`
  (non-interactive, indexes in seconds, then auto-syncs). Skip `$HOME`, non-git dirs, and
  repos with no source code.
- When `.codegraph/` exists, answer structural questions (how X works, what calls Y, blast
  radius of a change) with `codegraph_explore` (subagents: `codegraph explore "<query>"`)
  before Grep/Read. Treat its returned source as already read.
