# AGENTS.md — yasb bar: fonts, icons, sizing

Scoped to `dot_config/yasb/` (komorebi/whkd: `dot_config/komorebi/AGENTS.md`). Fonts are in
`styles.css`, icon codepoints in `config.yaml.tmpl`. `yasbc reload` after a change. The "why"
behind each rule is in its commit (`git log -S`); the current design starts at `d09e58e`
(`b1d8ccf`..`aef0e66` was a rework reverted wholesale — read those before re-litigating).

## Glass & colour
- The glass is the STYLESHEET: `.yasb-bar` uses `--crust-glass: rgba(17, 17, 27, 0.55)` over the
  DWM blur yasb already enables. `blur_effect.acrylic` is dead in 2.0.7 — don't use it.
- **Alpha as `rgba()`, NEVER 8-digit hex** — 2.0.7 never converts `#RRGGBBAA`, so Qt reads it
  alpha-first (hook-enforced). Popup menus keep opaque `--crust` (no blur behind them).
- Verify CSS with yasb's own `CSSProcessor(path).process()` (`library.zip` on `sys.path`, Python
  **3.14**) — an unresolved `var()` is dropped silently. Measure rendered pixels on a real
  screenshot; `QWidget.render()` over-composites alpha.
- Raising an icon's base colour means raising its `:hover` too, or hover goes darker.

## Fonts
- Text = **`Noto Sans JP`** (only installed family covering Latin + Vietnamese + Japanese, with
  tabular digits so the clock doesn't jitter), then the Nerd Font. Not installed by the bootstrap.
- Icons = **`JetBrainsMonoNL Nerd Font`**: its glyphs straddle the text's ink band; Segoe Fluent
  towers 3-5px over the cap line and Qt has no vertical-align lever.
- Family name per consumer: `styles.css` uses the typographic name `JetBrainsMonoNL Nerd Font`
  (Qt matches name ID 16; `NF`/`NFM`/`Nerd Font Mono` silently become Tahoma);
  `komorebi.bar.json` uses `JetBrainsMonoNL NF` (DirectWrite ID 1). Check Qt with yasb's bundled
  PyQt6 under the real platform plugin (offscreen has an empty font DB), not
  `InstalledFontCollection`.
- Icon set is **Material (`nf-md-*`) throughout** (one stroke weight; Codicon/FA line art turns to
  mush at 13-15px; `font-weight` changes nothing). Layouts: `F056E` bsp, `F0576` columns, `F056A`
  rows, `F0570` grid, `F056B`/`F0575` stacks, `F056C` ultrawide, `F0574` right-main.
- **Every icon option left at its yasb default is a Segoe codepoint** that draws the wrong Nerd
  Font glyph — pin each one explicitly (defaults: `core/validation/widgets/yasb/<widget>.pyc` in
  `library.zip`). After any icon edit, intersect the config's PUA set with the font's `cmap`.
- cpu/memory/wifi/volume are TEXT tags `C:` `R:` `W:` `V:` — no two in-band glyphs are
  distinguishable. Don't turn them back into icons.

## Size & alignment (measure ink, never trust `font-size`)
Reference: text at 14px inks 11px, band `(0, 11)`. Add a row only with a measured ink number.

| rule | px | ink | note |
|---|---|---|---|
| `*` (text) | 14 | 11 | reference |
| `.icon, .btn` | 13 | ~11 | shared default |
| `.weather-widget .icon`, `.whkd-widget .icon` | 17 | 12 | glyphs small in their em box |
| `.media-widget .btn` | 18 | 12 | transport glyphs |
| `.systray .unpinned-visibility-btn` | 20 | ? | `F013D`/`F013E` |
| `.pomodoro-widget .icon` | 15 | 13 | `F13AB` |
| `.notification-widget .icon` | 16 | 14 | `F009A` |
| `.language-widget .icon` | 14 | 12 | |
| `.home-widget .icon` | 18 | 17 | thin radial glyph needs +2 to look equal |
| `.komorebi-active-layout .label` | 20 | 15 | `padding-right` = title gap, `padding-bottom: 2px` = centring |
| `.power-menu-widget .icon` | 23 | 17 | `F0425` |

- Align ink bands (`ascent - bbox`); 1px off reads as floating.
- **Centre on the BAR (rows 6..39, centre 22.5), not on a neighbouring icon.** Odd ink can only
  reach 22.0/23.0 — 0.5px is the floor.
- Vertical padding moves ink by HALF the value. Shrinking `font-size` pins the top and loses
  pixels off the bottom — size and centring are separate steps.
- `min-width` on `.icon` only, per widget = ink + 2 (a narrow QLabel clips the glyph's LEFT
  side). Not on `.btn` — it spreads the media controls.
- Icon-to-text gap = `min-width` slack + `.icon` `padding-right: 4px` + ONE space; labels ending
  at a span add a trailing **U+00A0** (`&nbsp;` renders literally). Every icon span needs
  `class='icon'` — grep `<span>` and `</span>{` after an icon edit.
- A glyph in `<span class='icon'>` takes `.icon`'s `font-size`/`color`, NOT `.label`'s — style it
  with `.<widget> .icon`.

## Restart traps
- Changing a label's STRUCTURE (adding/removing a span) needs a reload; the widget list is
  built at startup.
- **Frozen volume readout = yasb 2.0.7 bug, not config.** The COM callback registers once, fails
  silently (no log line) when a USB endpoint drops mid-transition, and never retries.
  `yasbc reload` does NOT fix it; `yasbc stop` + `start` does (`yasbr` in `profile.ps1`). The
  `<span>` wrapper around the volume label is not needed.
