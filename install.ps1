# Windows one-command setup (repo file, never applied to $HOME):
#   irm https://raw.githubusercontent.com/ved0el/dotfiles/main/install.ps1 | iex
# Runs in Windows PowerShell 5.1 (a new machine has no pwsh yet) and in pwsh 7. A normal
# window, NOT "Run as administrator" (the bootstrap stops when elevated). Safe to run again.
# A fresh box stops after stage 1 (scoop, git, pwsh 7): open a new PowerShell 7, `chezmoi apply`.

# TLS 1.2 for this window: an older Windows 10's WinPS 5.1 defaults to TLS 1.0, which GitHub
# refuses (the `irm` that fetched THIS file needed it already — README has the fallback line).
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# chezmoi into ~/.local/bin (the bootstrap puts that dir on the User PATH itself), then apply.
# --keep-going: a failed bootstrap part doesn't skip the other.
$bin = Join-Path $HOME '.local\bin'
Invoke-Expression "&{$(Invoke-RestMethod 'https://get.chezmoi.io/ps1')} -b '$bin'"
& (Join-Path $bin 'chezmoi.exe') init --apply --keep-going ved0el
