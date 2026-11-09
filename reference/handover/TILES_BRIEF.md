# Home page category tiles: handover brief for Claude Code

Replace the current category tile section on the home page (Locations, Characters, Objects, Lore, Escape routes, Search, Evidence grades) with the seven tiles in `tiles_prototype.html`. Open that file in a browser first. It is a working prototype in the site's own colour variables. Treat it as the visual spec and port it into the real template. Do not change any other section.

Related files in this folder: `tiles_prototype.html` (the spec), `tiles_gen.py` (generates the map, route and Dendron SVG from `map.json`), `map.json` (map data).

## Intent
The old tiles were small icon, title and sentence cards. The new ones use most of each tile for a graphic that is cropped by the card edge, drawn in one line weight and one accent colour. The tone is enigmatic and archival: reference codes, redaction bars, coordinates, datum lines. The plain label stays visible so navigation is never unclear.

## Layout
- 4-column grid, max width 1180px, gap 14px, radius 16px.
- Row 1: Locations (spans 2 columns), Characters, Objects. Minimum height 400px.
- Row 2: Lore, Ways Out, The Index, What We Know. Minimum height 330px.
- At 900px and below: 2 columns, Locations spans both. At 600px and below: 1 column, and the map graphic widens to 90%.
- Each tile is one link to its category page (Search opens the existing search overlay). Card hover: border takes the tile colour, lifts 2px.

## Tile anatomy (all tiles)
1. Header row: custom icon (26px) and the **title** (uppercase, 14px, letter-spacing .13em, no wrapping) on the left, the **live count** on the right in Geist Mono weight 200, 34px, tile colour. Search and What We Know have no count.
2. Code line: tile code in tile colour plus the plain label, mono 11.5px uppercase, for example `LOC · Locations`.
3. One short line of description, 14px, muted.
4. The graphic fills the rest of the tile. Tiles marked "fade" get a bottom gradient into the surface colour.

## Palette (strict: black and acid green only)
These tiles use two colours plus neutral greys. Do not use the category colours (green, blue, gold, purple, red) here.
- Acid green: `--acid: #b8f200`. Used for fills and highlights in both themes: code chips, pin dots, grade circle, water, route dots, Dendron tips, bar fills.
- `--s` is the line and accent colour. It is black (`#111`) in light mode and acid green in dark mode. All strokes, icons, titles' accents, counts, borders on hover use `--s`.
- Text on acid is always black. Redaction is `--redact` (black in both themes).
- Surfaces: light `#f6f6f4` on `#fcfcfb`; dark `#121212` on `#0a0a0a`. Soft acid glow at the top left of each tile (`--glow`).
- In light mode, acid dots and tips get a thin black outline (`--tipstroke`) so they stay visible. In dark mode the outline is off.
- The prototype aliases the old variables (`--loc`, `--chr`, `--obj`, `--lor`, `--rte`, `--gc`, `--ge`, `--gu`) to `--s`, so the tile CSS needs only the new root block at the top of the prototype. Do not change the variables used by the rest of the site.

## The seven tiles

| Tile | Title | Code · label | Count source | Graphic |
|---|---|---|---|---|
| Locations | THE GROUND | LOC · Locations | live location count | Real map outline (Russian perimeter, occupation perimeter, four concentric contour rings), four dashed escape routes that animate, pulsing rings on survivor outposts, crosses for Russian positions, squares for gates, small dots for nodes, diamond for Kościuszko. Large and cropped off the right and bottom edges (graphic about 84 percent of the tile width, 150 percent of its height). Markers are generous: pin dots r4.6, pulse rings r13, crosses 10 units, gates 9 units. Coordinate line at the bottom left. |
| Characters | THE WITNESSES | CHR · Characters | live character count | Fan of five redacted dossier cards (code, silhouette with black bar across the eyes, text lines, grade circle). On hover the fan opens and the front card's bar shortens. |
| Objects | EXHIBITS | OBJ · Objects | live object count | Generative line-art Dendron that grows from the bottom centre, with glowing tips. Regrows on hover. Specimen tag at the bottom right, a full pill (border-radius 99px). |
| Lore | THE WATERLINE | LOR · Lore | live lore count | Gauge with datum lines: 84 m Warsaw falls, 80 m the city divides, 78 m dam failure. Two layers of water that sway, and rise on hover. |
| Escape routes | WAYS OUT | RTE · Escape routes | live route count | The occupation ring and contours, the four real route paths dashed, with a dot travelling along each and N, E, S, FE end labels. |
| Search | THE INDEX | ALL · Search | none | Search box that types a query and shows three results. Each row is vertically centred so the entry name and its code sit on the same line. |
| Evidence grades | WHAT WE KNOW | GRADE · Evidence | none | Three smooth pill-shaped bars. C is solid acid green, E is half-strength acid, U is a dashed outline. A soft frosted layer covers the end of each bar and slides away on hover. Bars grow in on load. |

## Data wiring (the prototype uses placeholders)
- **Counts:** read from the database, never hard code. Prototype values 31, 25, 6, 5, 4 are the current screenshot numbers.
- **Locations and Ways Out:** use the same projection as the map section, taken from `map.json`. `tiles_gen.py` shows the projection (longitude scaled by cos 52.25 degrees). Generate the SVG at build time and inline it. Do not draw the map in the browser.
- **Characters:** cards should pull five real characters (code and grade). The prototype shows CHR/019, 007, 001, 012, 024 as examples. Prefer the five with the most entries or the featured flag. Names must stay redacted in the graphic.
- **Search:** show three real entries. The prototype uses Filtry LOC/013, Rising water LOR/005 and Żerań hub LOC/001. Typing text is "water".
- **What We Know:** bar lengths should reflect the real proportion of C, E and U entries. Prototype values are 86, 58 and 32 percent, and are placeholders. Whatever the real proportions, give each bar a visible minimum fill (at least 18 percent) so none looks empty. 
- **Lore datum values** (78, 80, 84 m and their labels) come from the Protocol 001 datum table in the manuscript. Do not alter them.
- **Dendron:** the SVG is generated once with a fixed random seed (`tiles_gen.py`). Keep it as a static inline asset so it does not change between builds.

## Icons
A custom set, 24px grid, 1.5px stroke, round caps, no fill. They are defined as an inline SVG sprite at the top of the prototype (`i-loc`, `i-chr`, `i-obj`, `i-lor`, `i-rte`, `i-sea`, `i-grd`). They replace the generic icons on these tiles only. Use the sprite as is. A later pass can swap these for hand-drawn versions without changing the markup.

## Motion and accessibility
- Animations: map routes and pins, dossier fan, Dendron growth, waves, search typing and results, redaction slide. All are CSS or SVG with no JavaScript.
- Honour `prefers-reduced-motion`: no animation, Dendron fully drawn, results visible, typing text shown. The prototype already does this.
- Hover reveals are decoration only. Nothing essential may depend on hover, so touch devices see the resting state. The graphics are `aria-hidden`. The link text (title, label, count, description) carries the meaning.
- Keep the page light. The only heavy asset is the Dendron paths (about 40 KB of inline SVG). Do not add images or libraries.

## Not in this pass (for later illustration work)
Painterly or photographic art, faction crests, textures and portraits are being made separately. Leave room: each tile graphic sits in its own absolutely positioned layer, so a generated image can be dropped in behind it later.

## Done when
1. The seven tiles render on the live site in light and dark, at desktop, tablet and phone widths.
2. Counts, character cards, search examples and grade proportions are driven by real data.
3. Titles are as above, with the plain label always visible.
4. Reduced motion works.
5. No other section of the home page has changed.
6. Report anything that did not match the prototype.
