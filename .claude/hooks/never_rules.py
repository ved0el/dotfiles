#!/usr/bin/env python3
"""PreToolUse guard for this repo's NEVER rules (see AGENTS.md and the nested AGENTS.md files).

Hook mode (stdin = Claude Code hook JSON): exit 2 + stderr blocks the edit and tells Claude why.
Only ADDED, non-comment lines are checked, so docs and "# never do X" comments stay legal.
  --scan      check every tracked file as if it were newly written (CI: the repo must be clean)
  --selftest  run the built-in cases
Keep each rule's text in sync with the AGENTS.md section it points to.
"""
import json
import os
import re
import subprocess
import sys

SOURCE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# (id, file regex on the repo-relative path, line regex, message)
RULES = [
    ("mise-env", r"",
     r"(export\s+|\$env:|setx\s+|^\s*)MISE_(GLOBAL_CONFIG_FILE|CONFIG_DIR)\s*=|setx\s+MISE_(GLOBAL_CONFIG_FILE|CONFIG_DIR)\b"
     r"|SetEnvironmentVariable\(\s*['\"]MISE_(GLOBAL_CONFIG_FILE|CONFIG_DIR)['\"]\s*,\s*(?!\s|\$null)",
     "NEVER set MISE_GLOBAL_CONFIG_FILE / MISE_CONFIG_DIR: it silently stops mise's conf.d discovery "
     "outside $HOME. Only unset/remove them. See dot_config/mise/AGENTS.md."),
    ("pwsh-path", r"^\.chezmoi\.toml\.tmpl$",
     r"lookPath\s+\"pwsh\"|[\\/]pwsh(\.exe)?[\"']",
     "NEVER bake an absolute pwsh path into .chezmoi.toml.tmpl: pwsh moves between install sources. "
     "[cd] uses bare `pwsh`, [interpreters.ps1] the fixed WinPS 5.1 path. See AGENTS.md -> OS gate."),
    ("conhost-headless", r"^(run_.*|dot_config/komorebi/.*)$",
     r"conhost(\.exe)?['\"]?\s+--headless",
     "NEVER wrap the komorebi logon task in `conhost.exe --headless`: it dies with 0x80070003 at logon. "
     "See dot_config/komorebi/AGENTS.md."),
    ("claude-mem-install", r"^run_",
     r"claude-mem\s+install",
     "Do NOT add `npx claude-mem install`: claude-mem is plugin-managed and this double-registers its "
     "hooks. See dot_claude/AGENTS.md."),
    ("claude-install", r"^run_",
     r"winget\s+install.*Anthropic\.ClaudeCode|brew\s+install\s+--cask\s+claude-code"
     r"|npm\s+(i|install)\s+(-g|--global)\s+@anthropic-ai/claude-code",
     "Install Claude Code only with the native one-liner: winget/brew/npm installs do NOT auto-update. "
     "See dot_claude/AGENTS.md."),
    ("nanazip", r"^run_",
     r"use_external_7zip|scoop\s+install[^\n]*\bnanazip\b",
     "Do NOT re-add NanaZip / use_external_7zip to the bootstrap: the extractor is installed by hand. "
     "See AGENTS.md -> Tools split."),
    ("fzf-tab-menu", r"^dot_config/zsh/",
     r"zstyle[^\n]*\bmenu\s+select\b",
     "fzf-tab REQUIRES `zstyle ':completion:*' menu no`, never `menu select`. See AGENTS.md -> Tools split."),
    ("yasb-hex-alpha", r"^dot_config/yasb/.*\.css$",
     r"#[0-9a-fA-F]{8}\b",
     "Write yasb alpha as rgba(), NEVER 8-digit hex: yasb 2.0.7 passes #RRGGBBAA to Qt raw, which reads "
     "it alpha-first. See dot_config/yasb/AGENTS.md."),
]
COMMENT = re.compile(r"^\s*(#|//|;|<#|\{\{-?\s*/\*)")


def violations(rel, lines):
    rel = rel.replace("\\", "/")
    if rel.endswith(".md"):  # docs describe the rules; never police prose
        return []
    if rel.endswith(".css"):  # multi-line /* */ comments
        lines = re.sub(r"/\*.*?\*/", "", "\n".join(lines), flags=re.S).splitlines()
    out = []
    for rid, fre, lre, msg in RULES:
        if not re.search(fre, rel):
            continue
        for line in lines:
            if not COMMENT.match(line) and re.search(lre, line):
                out.append((rid, line.strip(), msg))
                break
    return out


def added_lines(tool, inp):
    if tool == "Write":
        return inp.get("content", "").splitlines()
    edits = inp.get("edits") or [inp]
    new = []
    for e in edits:
        old = set(e.get("old_string", "").splitlines())
        new += [l for l in e.get("new_string", "").splitlines() if l not in old]
    return new


def managed_target(path):
    """A $HOME file chezmoi manages -> its source path, else None."""
    home = os.path.normcase(os.path.expanduser("~"))
    p = os.path.normcase(os.path.abspath(path))
    if not p.startswith(home + os.sep) or p.startswith(os.path.normcase(SOURCE) + os.sep):
        return None
    try:
        r = subprocess.run(["chezmoi", "source-path", path], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 and r.stdout.strip() else None


def hook():
    data = json.load(sys.stdin)
    tool, inp = data.get("tool_name", ""), data.get("tool_input") or {}
    path = inp.get("file_path", "")
    if not path:
        return 0
    src = managed_target(path)
    if src:
        print(f"{path} is chezmoi-managed and `apply` overwrites it. Edit the source instead: {src} "
              "(then `chezmoi apply`). See AGENTS.md -> Commands.", file=sys.stderr)
        return 2
    try:
        rel = os.path.relpath(os.path.abspath(path), SOURCE)
    except ValueError:  # other drive on Windows
        return 0
    if rel.startswith(".."):
        return 0
    found = violations(rel, added_lines(tool, inp))
    for rid, line, msg in found:
        print(f"[never-rules:{rid}] {rel}: `{line}`\n{msg}", file=sys.stderr)
    return 2 if found else 0


def scan():
    files = subprocess.run(["git", "-C", SOURCE, "ls-files"], capture_output=True, text=True, check=True).stdout.split()
    bad = 0
    for rel in files:
        try:
            with open(os.path.join(SOURCE, rel), encoding="utf-8") as f:
                lines = f.read().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for rid, line, msg in violations(rel, lines):
            print(f"{rel}: [{rid}] `{line}`", file=sys.stderr)
            bad += 1
    return 1 if bad else 0


def selftest():
    bad = [
        ("dot_config/zsh/conf.d/10-env.zsh", "export MISE_GLOBAL_CONFIG_FILE=~/.config/mise/config.toml"),
        ("dot_config/powershell/profile.ps1", "$env:MISE_CONFIG_DIR = \"$HOME\\.config\\mise\""),
        ("run_x.ps1.tmpl", "[Environment]::SetEnvironmentVariable('MISE_GLOBAL_CONFIG_FILE', $p, 'User')"),
        (".chezmoi.toml.tmpl", "command = {{ lookPath \"pwsh\" | quote }}"),
        (".chezmoi.toml.tmpl", "command = \"C:/Program Files/PowerShell/7/pwsh.exe\""),
        ("run_onchange_after_install-packages.ps1.tmpl", "$exe = 'conhost.exe' --headless powershell.exe"),
        ("run_onchange_after_install-packages.ps1.tmpl", "  $a = New-ScheduledTaskAction -Execute conhost.exe --headless"),
        ("run_onchange_after_install-packages.sh.tmpl", "npx claude-mem install"),
        ("run_onchange_after_install-packages.ps1.tmpl", "winget install Anthropic.ClaudeCode"),
        ("run_onchange_after_install-packages.sh.tmpl", "npm i -g @anthropic-ai/claude-code"),
        ("run_onchange_after_install-packages.ps1.tmpl", "scoop config use_external_7zip true"),
        ("dot_config/zsh/conf.d/50-completions.zsh", "zstyle ':completion:*' menu select"),
        ("dot_config/yasb/styles.css", "  background-color: #11111b8c;"),
    ]
    ok = [
        ("dot_config/zsh/conf.d/10-env.zsh", "unset MISE_GLOBAL_CONFIG_FILE MISE_CONFIG_DIR"),
        ("dot_config/powershell/profile.ps1", "Remove-Item env:MISE_GLOBAL_CONFIG_FILE -ErrorAction Ignore"),
        ("run_x.ps1.tmpl", "[Environment]::SetEnvironmentVariable('MISE_CONFIG_DIR', $null, 'User')"),
        ("run_x.ps1.tmpl", "# NOTE: deliberately DO NOT set MISE_GLOBAL_CONFIG_FILE=anything"),
        ("AGENTS.md", "export MISE_GLOBAL_CONFIG_FILE=x"),
        (".chezmoi.toml.tmpl", "command = \"pwsh\""),
        ("dot_config/komorebi/autostart.ps1", "# `conhost.exe --headless System32\\powershell.exe` was removed"),
        ("dot_config/zsh/conf.d/50-completions.zsh", "zstyle ':completion:*' menu no"),
        ("dot_config/yasb/styles.css", "  color: #ff5189;  --crust-glass: rgba(17, 17, 27, 0.55);"),
        ("dot_config/yasb/styles.css", "/* never #11111b8c,\n   it is read alpha-first */"),
        ("dot_config/komorebi/AGENTS.md", "NEVER wrap it in `conhost.exe --headless`"),
    ]
    for rel, line in bad:
        assert violations(rel, [line]), f"missed: {rel}: {line}"
    for rel, line in ok:
        assert not violations(rel, [line]), f"false positive: {rel}: {line}"
    assert added_lines("Edit", {"old_string": "a\nmenu select", "new_string": "a\nmenu select\nb"}) == ["b"]
    print(f"selftest ok ({len(bad)} blocked, {len(ok)} allowed)")
    return 0


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    sys.exit(selftest() if arg == "--selftest" else scan() if arg == "--scan" else hook())
