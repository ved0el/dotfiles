# AGENTS.md — yasb bar ("Mocha Islands"): shape, icons, popups, sizing

Scoped to `dot_config/yasb/` (komorebi/whkd: `dot_config/komorebi/AGENTS.md`). `config.yaml.tmpl`
holds widgets and icon codepoints, `styles.css.tmpl` the look, `assets/` the taskbar mark PNGs.
yasb 2.0.8; `yasbc reload` after a structural change (CSS hot-reloads). The previous Nerd-Font
"glass" bar lives in git history before this rework — don't restore its rules from memory.

## Shape & colour
- `style: "adaptive"`: three islands (left / centre / right) hanging off a 3px rail. Shape is
  `-qproperty-*` on `.yasb-bar.adaptive` (leading dash; set a property back to its default
  instead of deleting it — Qt keeps a deleted qproperty until restart). No DWM blur: it would
  blur the transparent gaps too.
- `style_adaptive_exclude` splits an island only if the excluded widget is wider than
  2 x `grouppadding` — narrower gaps are merged back.
- Radii: island/edge 8 = the window corner (Windhawk "Custom Window Corner Radius" radius 8)
  = the inner edge of komorebi's Rounded border, which komorebi hardcodes as `8 + width/2`
  (`border.rs`). Small tier 4 = hover pills, popups `round_corners_type: "small"`, Windhawk
  `smallRadius`.
- Palette Catppuccin Mocha. Accent is FIXED `#89b4fa`, the same hex as komorebi's
  `border_colours.single` — change both together. (yasb `system_colors` reads AccentPalette,
  Windhawk's accent mod reads AccentColorMenu: they never match, so no live accent.)
- **Alpha as `rgba()`, NEVER 8-digit hex** — Qt reads `#RRGGBBAA` alpha-first (hook-enforced).
- Verify CSS with yasb's own `CSSProcessor(path).process()` (`library.zip` on `sys.path`, Python
  **3.14** — `mise.toml` in the themes dir pins it); an unresolved `var()` is dropped silently.
  Measure rendered pixels on a real screenshot.

## Fonts & icons
- Text: `Segoe UI Variable`, then `Noto Sans JP` (Japanese), then `Segoe UI`.
- Icons: **Segoe Fluent Icons** (native set). Nerd Font only where Segoe has no glyph: komorebi
  layouts, notification-menu buttons, whkd special keys, Claude's asterisk (`U+F06C4`) — via
  `--icons-font-fallback: "JetBrainsMono Nerd Font Propo"` (scoop `JetBrainsMono-NF-Propo`, in the
  bootstrap). Propo = each glyph advances by its ink, so no clipping and no min-width hacks.
- Qt matches the FULL family name only: `JetBrainsMono NFP` / `NF` / `Nerd Font Mono` silently
  become Tahoma. The wiki CSS says `"JetBrainsMono NFP"` — always map it to the variable. Check
  with yasb's bundled PyQt6 (`QFontInfo(QFont(name)).family()`); a font installed after logon is
  invisible to Qt until the next logon.
- Segoe has no weather set: open_meteo uses sun `E706` / moon `E708` / cloud `E753` / bolt `E945`.
  Its icon keys are `sunnyDay clearNight cloudyDay/Night rainyDay/Night drizzleDay/Night
  snowyDay/Night foggyDay/Night thunderstormDay/Night default` (extra keys fail validation).
- Layout icons: one solid Material set (`F056E F0576 F056A F0570 F0569 F056B F0575 F056C F0574`,
  tiling `F0640`, monocle/max `F0764`, float `F0136`, pause `F03E5`); the menu's icon column has a
  fixed width so labels align.
- One Mocha colour per widget icon; all labels share `--text`. Secondary readouts colour icon AND
  value (server green, cpu sapphire, ram maroon, disk peach); wifi/volume colour the icon only.
- Before picking a codepoint, render candidates (Qt for Nerd glyphs; GDI+ can't draw them).

## Popups
- Popup CSS = the yasb wiki "Example Style" blocks VERBATIM (popup selectors only), appended after
  the bar rules, then a short "Customisations" block for what the wiki gets wrong here (font
  names, Segoe glyphs drawn with a Nerd font, ClearType fringes on dark-on-white buttons).
- Exceptions rewritten in the control-center language (`rgba(32,32,32,.6)`, 16px gutters,
  hairline dividers, `#47AFF5` active): `.claude-usage-menu`, `.media-menu`.
- Wiki source: `git clone https://github.com/amnweb/yasb.wiki.git`, `widgets/(Widget)-*.md`.

## Taskbar
- Status mark per app = bottom-centred `background-image` PNG (`assets/taskbar-*.png`: 6x3 dot
  running, 12x3 accent pill focused/hovered, 12x3 red flashing); a border always spans the whole
  button. Pinned-not-running = no mark. Redraw the PNGs if the accent changes.
- Size the button for EVERY state (`.app-container`, `.running`, `.grouped`, `.foreground`) — the
  base `.foreground { padding: 0 16px }` otherwise widens it — and reset `background-color` on
  `:hover`. `.taskbar-widget` drops the generic `.widget` margin, or 20px icons lose their bottom.

## Size & alignment (measure ink, never trust `font-size`)
- Bar 42px, rail 3 → island rows 0..41, centre 20.5. Measured: home 20, layout 20.5, ws dots 20.5,
  app icon 20, title text 20.5. Odd ink can only reach x.0 — 0.5px is the floor.
- Vertical padding moves ink by HALF the value (active-window icon: `padding-top: 2px` = +1px).
- A glyph in `<span class='icon'>` takes `.icon`'s size/colour, not `.label`'s. Some widgets
  (cpu/memory/wifi) strip the space after a span — put gaps in CSS padding, not in the label.
- A clock label takes ONE strftime placeholder; a second `{...}` renders literally.

## Widget gotchas
- `claude_usage`: the bar shows local token totals (`{today_tokens}`) — the plan-limit endpoint
  `/api/oauth/usage` is rate-limited (HTTP 429 at 60s polling; every reload fetches again) and
  2.0.8 crashes on null fields (`'NoneType' object is not subscriptable`). Poll ≥ 900s. Claude
  Code's status line gets the same limits for free from its own responses (`rate_limits`).
- Notifications: left = yasb menu (DND toggle + clear-all live in its header; no DND callback
  exists), right = Windows Notification Center. Its `default` icon (`EA8F`) is reused in the empty
  menu, which the wiki CSS draws with a Nerd font — overridden to Segoe.
- Taskbar `monitor_exclusive: true`: each bar lists only the windows on its own monitor.
- `server_monitor` hosts = `.chezmoidata.yaml` `serverMonitor` (name -> host), deep-merged with a
  box's `[data.serverMonitor]` in `chezmoi.toml` (`""` drops one); `.chezmoi.toml.tmpl` re-emits it on init.
- Grouper starts collapsed; `exclude_widgets: []` hides every child until the chevron is clicked.

## Restart traps
- Changing a label's STRUCTURE (adding/removing a span) needs a reload.
- Frozen volume readout = yasb COM-callback bug, not config: `yasbc stop` + `start` (`yasbr` in
  `profile.ps1`); `yasbc reload` does not fix it.
- Clicking a popup right after a reload often does nothing — the bar is still being rebuilt.
