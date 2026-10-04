# ~/.ssh conventions

Rules for creating SSH keys, `config` entries, and git remotes on every machine.
Synced by chezmoi; keys and `config` are NOT synced (they are per machine).

## Naming

`<org>-<user>-<platform>`, used identically for the key file, its `Host` alias in `config`, and the git remote host.

- org: `nvd` (noovado), `nvc` (noovacons), `nhr` (Nohara), ...
- user: the account the key belongs to (`leo`, `ducdm`, ...)
- platform: `gh` (GitHub), `gl` (GitLab), ...

Examples: `nvd-leo-gh`, `nhr-ducdm-gh`.

## Key comment

- Comment = key name: `ssh-keygen -t ed25519 -C nhr-ducdm-gh -f ~/.ssh/nhr-ducdm-gh`.
- Keys of `leo` (nvd, nvc) live on several machines, so their **comment** adds the machine name
  before the platform: `nvd-leo-ser8-gh`. This tells the machines apart when the key is added to GitHub.
  The file name and `Host` alias stay without the machine (`nvd-leo-gh`): one machine never holds two of them.
- Renaming a key: rename both files, then update the comment with
  `ssh-keygen -c -C <new-comment> -f ~/.ssh/<key>`. The key itself doesn't change, so GitHub still accepts it.

## config

One `Host` block per key, always `IdentitiesOnly yes`:

```
# GitHub <account> (<user>): <what it's for>
Host nhr-ducdm-gh
  HostName github.com
  User git
  IdentityFile ~/.ssh/nhr-ducdm-gh
  IdentitiesOnly yes
```

The leo nvd key also lists the plain `github.com` host (`Host nvd-leo-gh github.com`), so
`git@github.com:` URLs (for example dotfiles) keep working.

## Git remotes

Use the alias, not `git@github.com:`:

```
git clone nhr-ducdm-gh:Nohara-dxdev/cs-preq.git
git remote set-url origin nvd-leo-gh:noovado/NoovaBIM.git
```

Verify with `ssh -T <alias>` and `git ls-remote --heads origin`.

## Never

- Never commit or sync private keys or `config` through chezmoi or git.
- Never copy private keys out of `~/.ssh`.
