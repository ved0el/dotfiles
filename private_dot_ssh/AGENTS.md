# ~/.ssh conventions

Rules for creating SSH keys, `config` entries, and git remotes on every machine.
Synced by chezmoi; keys and `config` are NOT synced (they are per machine).
Examples below are placeholders (`acme`, `alice`, `example.com`) — never write real org, user,
host, IP or repo names into this file (it's committed).

## Naming

Parts, always broad → narrow:

- org: short code of the org/client (`acme`, `me` for personal), ...
- project: the app/repo (`shop`, `api`, ...)
- env: the server's role — `dev`, `stg`, `prd`, `vps`, `db`, ... (+ a number when there are several: `prd2`)
- user: the account (`alice`, `deploy`, ...)
- platform: `gh` (GitHub), `gl` (GitLab), `ssh` (server-to-server only), ...

Two cases, by WHERE the key lives:

| | key file = git `Host` alias | key comment | server `Host` alias |
|---|---|---|---|
| **local** (own machine): one key per account, used for its git platform AND every server it logs into | `<org>-<user>-<platform>` → `acme-alice-gh` | + machine: `<org>-<user>-<machine>-<platform>` → `acme-alice-desk1-gh` | `<org>[-<project>]-<env>-<user>` → `acme-shop-stg-alice`, `acme-stg-alice` |
| **server**: one key per project (a GitHub deploy key fits one repo only) | `<org>-<project>-<platform>` → `acme-shop-gh` | + server: `<org>-<project>-<env>-<user>-<platform>` → `acme-shop-stg-deploy-gh` | — |

- The file name and `Host` alias never carry the machine/server: one machine never holds two of
  them. The **comment** does — it tells the copies apart when the keys are added to GitHub.
- Server alias: leave out `project` when the server is shared by several projects
  (`acme-stg-alice`). The login user goes in the alias AND in `User`.
- Server key: `project` = ONE repo (a deploy key can't be added to a second repo). A project
  with two repos gets two keys: `acme-shop-gh`, `acme-shop-api-gh`.
- A server that logs into another server (stg → db) follows the **local** row: one key per
  account (`acme-deploy-ssh`, platform `ssh`), comment with the server (`acme-deploy-shop-stg-ssh`).
- Own machines (desktop, laptop, Pi) use their hostname as the alias (`desk1`, `pi1`).

## Key comment

- `ssh-keygen -t ed25519 -C <comment> -f ~/.ssh/<file>`:
  `ssh-keygen -t ed25519 -C acme-alice-desk1-gh -f ~/.ssh/acme-alice-gh` (local),
  `ssh-keygen -t ed25519 -C acme-shop-stg-deploy-gh -f ~/.ssh/acme-shop-gh` (server).
- Renaming a key: rename both files, then update the comment with
  `ssh-keygen -c -C <new-comment> -f ~/.ssh/<key>`. The key itself doesn't change, so GitHub still accepts it.

## config

One `Host` block per key, always `IdentitiesOnly yes`.

Local — the account key serves git and every server it logs into (group servers on one line):

```
# GitHub <account> (<user>): <what it's for>
Host acme-alice-gh
  HostName github.com
  User git
  IdentityFile ~/.ssh/acme-alice-gh
  IdentitiesOnly yes

# acme shop staging + production (alice)
Host acme-shop-stg-alice acme-shop-prd-alice
  User alice
  IdentityFile ~/.ssh/acme-alice-gh
  IdentitiesOnly yes
Host acme-shop-stg-alice
  HostName stg.example.com
Host acme-shop-prd-alice
  HostName prd.example.com
```

Server — one block per project's deploy key:

```
# GitHub deploy key: acme/shop
Host acme-shop-gh
  HostName github.com
  User git
  IdentityFile ~/.ssh/acme-shop-gh
  IdentitiesOnly yes
```

Local only: the main account's key also lists the plain `github.com` host
(`Host acme-alice-gh github.com`), so `git@github.com:` URLs (for example dotfiles) keep working.
Never on a server — with several deploy keys, plain `github.com` would pick the wrong repo's key.

## Git remotes

Use the alias, not `git@github.com:`:

```
git clone acme-alice-gh:acme/app.git          # local
git clone acme-shop-gh:acme/shop.git          # server
git remote set-url origin acme-alice-gh:acme/app.git
```

Verify with `ssh -T <alias>` and `git ls-remote --heads origin`.

## Never

- Never commit or sync private keys or `config` through chezmoi or git.
- Never copy private keys out of `~/.ssh` (a server gets its own deploy key, not a copy).
- Never put real org, user, host, IP or repo names in this file — placeholders only.
