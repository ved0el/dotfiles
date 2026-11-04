# Rex (macOS)

Nested rules (the root AGENTS.md points here). Same style: terse; the why is in the commit.

- **Rex** = the macOS terminal AND multiplexer (always installed, no profile): it replaces Alacritty and
  tmux there (`tmux` is forced off on macOS in `.chezmoi.toml.tmpl`, `.config/alacritty` ignored), config `dot_config/rex/init.lua`
  (tmux keys, ignored off macOS). No cask: the bootstrap curls the first `<enclosure>` `.dmg` of its
  Sparkle appcast into `/Applications/Rex Beta.app` (guarded on the .app); Sparkle updates it after.
