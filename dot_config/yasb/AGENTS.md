# AGENTS.md — yasb bar: fonts, icons, sizing

Scoped notes for `dot_config/yasb/`. komorebi/whkd notes: `dot_config/komorebi/AGENTS.md`.

One text font and one icon font, both declared in `dot_config/yasb/styles.css`; the icon
codepoints live in `dot_config/yasb/config.yaml.tmpl`. Run `yasbc reload` after any change here,
and read the two restart traps at the end before concluding something is broken.

- **The bar is glass, and that is a STYLESHEET setting, not a config one.** `Bar.__init__`
  already sets `WA_TranslucentBackground` and already calls `enable_blur()` whenever
  `blur_effect.enabled` is true, so the DWM blur was running all along - an opaque
  `background-color` was simply painted over it. `.yasb-bar` therefore takes
  `--crust-glass: rgba(17, 17, 27, 0.55)` over `--glass-edge` for the lit hairline; the alpha
  IS the effect. Do NOT reach for `blur_effect.acrylic` to get this: 2.0.7's `enable_blur()`
  takes no acrylic argument (it picks `ACCENT_ENABLE_BLURBEHIND` on build >= 22000,
  `ACCENT_ENABLE_ACRYLICBLURBEHIND` below), and upstream marks the key
  "no longer supported" - it is dead either way.
- **Write bar alpha as `rgba()`, NEVER as 8-digit hex.** `CSSProcessor` defines
  `_css_to_qt_hex_alpha` (`#RRGGBBAA` -> Qt's `#AARRGGBB`) but **`process()` never calls it** in
  2.0.7 - confirmed by reading `process`'s own name table. So `#11111b8c` reaches Qt raw, is
  read alpha-first, and silently renders as a ~7% blue instead of a 55% near-black. `rgba()`
  needs no preprocessing at all; Qt accepts it, `rgba(r,g,b,55%)` and `#AARRGGBB` identically.
  The popup menus (`.home-menu`, `.language-menu`, `.komorebi-layout-menu`) keep opaque
  `--crust` on purpose - they are separate windows with no blur behind them, so alpha there
  only reads as muddy.
- **Verify a stylesheet change by driving yasb's OWN `CSSProcessor`, not by eye.** Put
  `library.zip` on `sys.path` under **Python 3.14** (the bundled bytecode's magic; 3.13 fails
  with "bad magic number"), call `CSSProcessor(path).process()`, and assert on the resolved
  rule - that catches an unresolved `var()`, which Qt drops silently and which would leave the
  bar fully transparent. To check a rendered result, screenshot the real bar and measure it;
  `QWidget.render()` composites a frame more than once, so an alpha of 0.55 reads as ~0.8 there
  and absolute pixel values from it mean nothing.

- **Text = `Noto Sans JP`, icons = `JetBrainsMonoNL Nerd Font`, and the Nerd Font is also second
  in every text rule.** Noto is the only Google family installed here that covers everything the
  bar shows: Latin 95/95, **Vietnamese 90/90** (`U+1EA0`-`U+1EF9`), full Japanese (86 hiragana,
  91 katakana, 12,731 kanji). Be Vietnam Pro and Roboto match it on Vietnamese but have ZERO
  CJK; Hack has **6 of the 90** Vietnamese codepoints, so Vietnamese window titles switch font
  mid-word in it. Noto's digits are tabular (all advance 9.0) so the clock does not jitter -
  check that before swapping in any proportional font. Noto is NOT installed by the bootstrap
  (scoop has no plain Noto Sans JP), so a fresh box falls through to the Nerd Font and loses
  only Japanese.
- **Icons are a Nerd Font rather than a UI icon font because only a Nerd Font shares the text's
  line.** Ink band relative to the shared baseline (0 = sitting on it):

  | | ink bottom | ink top |
  |---|---|---|
  | text cap `M`/`8` | 0 | 11 |
  | text `x` | 0 | 8 |
  | Segoe Fluent Icons | 0 | **13-15** |
  | Nerd Font icons | **-1 ... -2** | **11-12** |

  Segoe fills its em box and sits ON the baseline, so it towers 3-5px over the cap line at any
  size (shrinking it to match means a 10px icon). Nerd Font icons are patched onto the text
  font's own metrics and straddle the text band instead. Qt offers no `vertical-align` or
  `line-height` lever on an inline `<span>`, so the font IS the fix. The price: the glyph inks
  ~6.6px past its 9px advance (see `min-width` below), and Segoe and Nerd Font define many of
  the SAME PUA codepoints with DIFFERENT artwork, so 36 of them had to be re-picked. Verify
  coverage by intersecting the config's PUA set with the face's `cmap` after any icon edit.
- **The family name is spelled differently per consumer, on purpose.** `styles.css` uses the
  typographic name `JetBrainsMonoNL Nerd Font` (Qt matches name **ID 16** only - `... NF`,
  `NFM`, `NFP`, `... Nerd Font Mono` all silently become **Tahoma**); `komorebi.bar.json` uses
  the Win32 name `JetBrainsMonoNL NF` (DirectWrite = **ID 1**).
  `System.Drawing.Text.InstalledFontCollection` lists ID 1 only, so it is the WRONG tool to
  check Qt with - ask Qt through yasb's bundled PyQt6, under the real platform plugin
  (`QT_QPA_PLATFORM=offscreen` reports an empty font DB). `komorebi-bar --fonts` prints the
  names komorebi can actually see.
- **Sizes are set by measured INK, never by `font-size`** - each glyph fills a different share
  of its em box. Reference: the text cap/digit at 14px inks **11px tall, band `(0, 11)`**.

  | rule | px | ink | why |
  |---|---|---|---|
  | `*` (text) | 14 | 11 | the reference |
  | `.icon, .btn` | 13 | ~11 | shared default; 15px made every icon overshoot the cap |
  | `.weather-widget .icon` | 17 | 12 | the cloud inks only 9 at 13px |
  | `.whkd-widget .icon` | 17 | 12 | keyboard, same |
  | `.media-widget .btn` | 18 | 12 | transport glyphs ink 8 at 13px |
  | `.systray .unpinned-visibility-btn` | 20 | ? | double chevrons `F013D`/`F013E`; ink not re-measured |
  | `.pomodoro-widget .icon` | 15 | 13 | solid stopwatch `F13AB` |
  | `.notification-widget .icon` | 16 | 14 | solid bell `F009A`; outline+badge `EB9A` reads smaller at the same height |
  | `.language-widget .icon` | 14 | 12 | |
  | `.home-widget .icon` | 18 | 17 | control; thin radial glyph, needs +2 over layout to LOOK equal |
  | `.komorebi-active-layout .label` | 20 | 15 | control; `padding-right` IS the window title's left gap, `padding-bottom: 2px` is its centring |
  | `.power-menu-widget .icon` | 23 | 17 | control; `F0425` uniquely sits at band bottom 0 at EVERY size |

  The first four are normalisation for glyphs that are unusually small in their em box - not the
  per-widget drift that was swept out. Add a row only with a measured ink number beside it.
- **Align by ink band, measured, not by eye.** `ascent - bbox` for the text cap and for the
  candidate glyph; one pixel off reads as visibly floating (`F0EE0` at `(-1, 12)` beside a
  neighbour at `(0, 11)`). Check the band the same way you check the `cmap`.
- **Centre a glyph on the BAR, never on the icon next to it.** The bar body is rows `y 6..39`
  (fill `7..38` plus a 1px border each side, at `height: 34` + `padding.top: 6`), so its centre
  is **22.5**. The komorebi layout icon had always sat at 23.5-24.0; aligning the home icon to
  *it* made the pair agree with each other and stay visibly low in the bar, which is the bug a
  fresh pair of eyes reports. Measure the bar's own rows first - dump a pixel column at an x
  with no glyph and read where the fill starts and stops - then align every icon to that.
  A glyph with **even** ink lands on 22.5 exactly (bell 14, power 16); **odd** ink cannot, it
  can only reach 22.0 or 23.0, so 0.5px is the floor there, not a miss worth chasing.
- **Vertical padding moves ink by HALF what you write.** The padding grows the widget and the
  bar re-centres it, eating the other half: `padding-top: 2px` shifted the home glyph exactly
  1px, 4px shifted it 2px. Measure the 2px step before trusting the ratio on a new widget.
  Also note shrinking `font-size` does NOT shrink a glyph about its centre - 19px->17px took
  the home icon's band from `(15,31)` to `(15,29)`, i.e. it lost the 2px off the BOTTOM with
  the top pinned, so a size change and a centring change are two separate steps.
- **`min-width` lives on `.icon` alone, sized per widget to that icon's ink + 2.** A too-narrow
  icon QLabel clips the glyph's **LEFT** side, not its right: the wifi wedge inks 15px inside a
  9px advance and its label is right-aligned, so the overflow was cut off the leading edge.
  Symptom to recognise - a symmetric glyph rendering lopsided while the same codepoint is
  symmetric in a standalone render. The shared `18px` left 2px of slack behind a 16px-wide cloud
  but 6px behind a 12px glyph, and that 4px WAS the uneven icon-to-text gap; narrow icons carry
  `min-width: 14px`. Do NOT put it on `.icon, .btn` - `.btn` is the media transport with its own
  tight `padding: 0 2px`, and an 18px box spreads the three controls apart.
- **The icon-to-text gap is three pieces and every label must contribute all three**: the slack
  `min-width` leaves after the ink, `.icon`'s `padding-right: 4px`, and ONE space in the label
  template. That lands at 7-12px; the spread is the first text character's left side bearing
  (`9`/`s` tight, `6`/`1` roomy) and cannot be equalised. Labels that END at the span carry a
  trailing **U+00A0**, because an inline span ignores padding - `&nbsp;` does NOT work, yasb
  renders the literal text. Every icon-bearing `<span>` needs `class='icon'` or it finds the
  glyph by fallback and misses the box entirely. Grep for `<span>` without the class, and for
  `</span>{`, after any icon edit.
- **A glyph inside `<span class='icon'>` takes `.icon`'s `font-size` and `color`, NOT the
  widget's `.label` rule.** This cost four rounds on the power button: it was raised
  14 -> 17 -> 22 -> 29 on `.power-menu-widget .label` with no visible change at all, because the
  glyph was still reading `.icon`'s 13px. Style a widget's icon with `.<widget> .icon`; writing
  it on `.label` fails silently - same trap for `color`, the red had to be restated on `.icon`.
- **Raising an icon's base colour means raising its `:hover` too.** The home glyph ran
  `--overlay1` -> `--overlay2` on hover, i.e. dim -> less dim. Lifting the base to `--text` and
  leaving that pair would have made it go DARKER on hover; it is `--text` -> `#ffffff` now.
  Brightness also changes what "the same size" looks like: the +2 ink this glyph carries was
  calibrated while it was dim, and at full `--text` it briefly read oversized - the fix was
  centring, not shrinking, so re-measure before trusting a size complaint after a colour change.
- **cpu/memory/wifi/volume are the TEXT tags `C:` `R:` `W:` `V:`, not icons.** Every glyph in
  this font that sits in the text's ink band is some flavour of chip (`F061A`, `F035B`, `F0EE0`,
  `F0A0C` ...), so cpu and ram could never be told apart at bar size; the ones that ARE distinct
  (`F4BC`, `F2DB`) sit 2-3px out of band and float. A tag is unambiguous AND aligned by
  construction, because it is text. Do not "improve" this back into icons without first finding
  two in-band glyphs a stranger can name.
- **The icon set is Material (`nf-md-*`) throughout.** The rule is one STROKE WEIGHT, not one
  family - mixing is fine when the result stays coherent - but Material won every slot on
  comparison, including the komorebi layouts: its `view-*` block maps onto them exactly
  (`F056E` bsp, `F0576` columns, `F056A` rows, `F0570` grid, `F056B`/`F0575` stacks, `F056C`
  ultrawide, `F0574` right-main), and it is solid where Codicon was hairline. A Nerd Font is
  FIVE icon families in one file with different stroke weights: audit by rendering every
  codepoint at the real bar size next to a 3x blow-up - Codicon `EBxx` and Font Awesome
  `F0xx`/`F2xx` line art turns to mush at 13-15px. `font-weight` cannot help: the same icon
  rasterises byte-identically in Regular/Medium/SemiBold/Bold.
- **The frozen volume readout is a yasb BUG, not this config - do not try to fix it in
  config.** Verified 2026-09-16 on yasb **2.0.7** (latest; upstream `main`'s
  `src/core/widgets/services/volume/service.py` is byte-identical to the shipped bytecode, and
  no issue is open for it). Mechanism, read from `library.zip`:
  - `AudioOutputService.register_widget()` calls `_register_callbacks()` **once**, only when the
    FIRST volume widget registers. There is no retry and `VolumeConfig` has no `update_interval`
    - the readout is purely COM-callback driven.
  - Every failure path is `except Exception: pass` with **no log line**, so a dead callback
    leaves `yasb.log` completely clean. Do not go looking for an error there.
  - `_on_device_change()` assigns `self._volume_callback` BEFORE calling
    `RegisterControlChangeNotify()`. If that raises - which is exactly what a default endpoint
    disappearing mid-transition does - the attribute is left non-None while nothing is actually
    registered, and `_register_callbacks()`'s `not self._volume_callback` guard then skips it
    forever.
  - This box's default device is **Speakers (Realtek USB Audio)**; a USB endpoint drops out on
    dock/monitor sleep, so it hits that path routinely.
  - **`yasbc reload` does NOT re-register it; `yasbc stop` then `yasbc start` does** - that is
    what the `yasbr` function in `dot_config/powershell/profile.ps1` is for. Confirmed by
    driving the real endpoint with yasb's own bundled pycaw (`library.zip` + `lib` on
    `sys.path`; the loose `psutil._psutil_windows.pyd` must be preloaded by hand because psutil
    itself is zipimported): frozen at 42% while the system went 100% -> 30%, then tracking
    77% -> 25% after a restart. Synthetic `keybd_event` volume keys do NOT move the system
    volume and make a useless harness.
  - **The old "the volume label must be wrapped in a `<span>`" claim is WRONG** - `_update_label`
    splits on `(<span.*?>.*?</span>)` and calls `setText` on the plain-text branch too, so
    `V: {level}` updates fine when the callback is alive. The span only ever changed the timing
    of a restart.
- **Changing a label's STRUCTURE needs a reload, not just an apply.** yasb splits the label on
  `(<span...</span>)` and builds one QLabel per part at startup, so adding or removing a span
  while it is running leaves the old widget list in place and the value freezes.
- History: `b1d8ccf`..`aef0e66` is an earlier rework that was reverted wholesale; everything
  from `d09e58e` on is the current design. `git show` those before re-litigating any of it.
