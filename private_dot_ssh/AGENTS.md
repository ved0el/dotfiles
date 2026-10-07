# ~/.ssh conventions

Rules for creating SSH keys, `config` entries, and git remotes on every machine.
Synced by chezmoi; keys and `config` are NOT synced (they are per machine).
Examples below are placeholders (`acme`, `alice`, `example.com`) — never write real org, user,
host, IP or repo names into this file (it's committed).

## Naming — git platform keys

`<org>-<user>-<platform>`, used identically for the key file, its `Host` alias in `config`, and the git remote host.

- org: short code of the org/client (`acme`, `me` for personal), ...
- user: the account the key belongs to (`alice`, `bob`, ...)
- platform: `gh` (GitHub), `gl` (GitLab), ...

Examples: `acme-alice-gh`, `me-alice-gh`.

## Naming — servers

`Host` alias = `<org>-<project>-<env>-<user>`, never the IP or the domain. Broad → narrow, so
`<org>-<project>-<env>-<Tab>` lists every login on that box:

- org: same codes as above (`acme`, `me`, ...)
- project: the app/service it runs (`shop`, `api`, ...)
- env/role: `dev`, `stg`, `prd`, `vps`, `db`, ... — add a number only when there are several (`prd2`).
- user: the login user (same as `User` in the block)
- Own machines (desktop, laptop, Pi) use their hostname as the alias (`desk1`, `rasp-dev`).
- `IdentityFile` = the key of the account that logs in (often its `<org>-<user>-gh` one); group
  servers sharing a key on one line (`Host acme-shop-stg-alice acme-shop-prd-alice`).

Examples: `acme-shop-stg-alice`, `acme-shop-stg-deploy`, `me-blog-vps-alice`.

## Key comment

- Comment = key name: `ssh-keygen -t ed25519 -C acme-alice-gh -f ~/.ssh/acme-alice-gh`.
- A key that lives on several machines — or is made ON a server (e.g. to pull from GitHub) — adds
  the machine name before the platform in its **comment**: `acme-alice-desk1-gh`,
  `acme-alice-shop-stg-gh` (server = `<project>-<env>`). This tells the machines apart when the key
  is added to GitHub. The file name and `Host` alias stay without the machine (`acme-alice-gh`):
  one machine never holds two of them.
- Renaming a key: rename both files, then update the comment with
  `ssh-keygen -c -C <new-comment> -f ~/.ssh/<key>`. The key itself doesn't change, so GitHub still accepts it.

## config

One `Host` block per key, always `IdentitiesOnly yes`:

```
# GitHub <account> (<user>): <what it's for>
Host acme-alice-gh
  HostName github.com
  User git
  IdentityFile ~/.ssh/acme-alice-gh
  IdentitiesOnly yes

# acme shop staging server (alice)
Host acme-shop-stg-alice
  HostName stg.example.com
  User alice
  IdentityFile ~/.ssh/acme-alice-gh
  IdentitiesOnly yes
```

The main account's key also lists the plain `github.com` host (`Host acme-alice-gh github.com`),
so `git@github.com:` URLs (for example dotfiles) keep working.

## Git remotes

Use the alias, not `git@github.com:`:

```
git clone acme-alice-gh:acme/app.git
git remote set-url origin acme-alice-gh:acme/app.git
```

Verify with `ssh -T <alias>` and `git ls-remote --heads origin`.

## Never

- Never commit or sync private keys or `config` through chezmoi or git.
- Never copy private keys out of `~/.ssh`.
- Never put real org, user, host, IP or repo names in this file — placeholders only.
