# Rex (macOS)

Nested rules (the root AGENTS.md points here). Same style: terse; the why is in the commit.

- **Rex** = the macOS terminal AND multiplexer (always installed, no profile): it is
  the multiplexer there, config `dot_config/rex/init.lua`
  (tmux-style `ctrl+b` keys, ignored off macOS). No cask: the bootstrap curls the first `<enclosure>` `.dmg` of its
  Sparkle appcast into `/Applications/Rex Beta.app` (guarded on the .app); Sparkle updates it after.
