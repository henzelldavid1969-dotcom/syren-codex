# Syren Codex: brand and type brief for Claude Code (9 November 2026)

Replace the placeholder icon and typography on the site with the following. Put the files from this folder into the site's public assets (icons) and load the fonts as described.

## Icon
Concept: three rings from one point. Circles stand for the protocols, interconnectedness and community, and for the siren ripple. No hard edges.

Geometry (viewBox 0 0 100 100):
- Tile: rounded square, rx 22.
- Outer ring r 32, stroke 6. Inner ring r 20, stroke 6, opacity 0.6. Centre dot r 7.
- Bare mark (no tile): r 42 stroke 7, r 26 stroke 7 opacity 0.6, dot r 9.

Files:
- syren-icon-dark.svg: green rings on black tile. Use in the site header and as the default.
- syren-icon-green.svg: black rings on acid green tile. Use for app icon, social and share images.
- syren-mark.svg: bare rings, for tight spaces and favicon on dark backgrounds.
- PNG exports: syren-icon-dark at 512, 192, 180, 32, 16; syren-icon-green-512; syren-mark at 512 and 64. favicon.ico (16 and 32).
- wordmark-on-dark.png: reference render of ring plus title, for checking the header.

Use: favicon.ico and the 32 and 16 PNGs for the favicon, 180 for apple-touch-icon, 192 and 512 for the web manifest. Colours: acid green #b8f200, black #0a0a0a. Do not add other colours to the mark.

## Type
Three families, all free and open source (Fontsource or Google Fonts). Self host them.
- Titles and the wordmark: Barlow Condensed, weight 600. Wordmark is capitals with letter-spacing 0.2em. Entry and section titles use it in sentence case, no extra tracking.
- Reference codes, labels, grades, status lines, counts: JetBrains Mono, weight 400. Small, uppercase where it is a label, letter-spacing about 0.08 to 0.12em. Examples: SYNPTCL/LOC/013, GRADE C, STATUS DRAFT.
- Body and manuscript text (Story view, entry bodies, summaries): Newsreader, weight 400, with italic. Line-height about 1.6, comfortable measure of 60 to 70 characters.

Header: the dark icon at about 40px, then THE SYREN PROTOCOLS in Barlow Condensed 600, capitals, 0.2em tracking, on one line. On narrow screens drop the tracking to 0.12em before wrapping.

Palette stays black and acid green only, as in TILES_BRIEF.md. Keep reduced-motion support.

Check: view the site at desktop and phone width and confirm the header does not wrap and the favicon is legible at 16px.
