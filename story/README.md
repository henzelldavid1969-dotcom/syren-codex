# Story source

Since 9 November 2026 the Story text is edited in the admin (`/admin`,
Story) and goes live when David presses Publish. Each section's text is
held in the database (`story_sections.body`), and the book title, tagline
and back cover in `site_content` (key `book`). The build uses the text
carried by the newest release.

The files here are the original source and the fallback:

- `manuscript.md`: manuscript_final_with_appendix_2026-11-08.md, the canon
  for story facts when it was loaded (contracted narration; Interludes I and
  VI and the Protocol chapters 3, 6, 9, 12 and 15 uncontracted by design).
  It includes Appendix: The Brief as its last section (story section 30).
- `back-cover.md`: the introduction on the Story page.

The build only reads these files when a release does not carry the Story
text. Editing them no longer changes the site. To load a whole new
manuscript into the database instead, replace `manuscript.md`, run
`node supabase/load_content.mjs` and load the SQL it writes; note that this
also replaces the home page copy with `content/home.json`, so check that file
first.

## Figures under tables

A line `<!-- figure: TYPE -->` straight after a table in the Story text draws
that table as a figure on the site, like a chart beside a spreadsheet. It is
invisible in the text. The admin's Story editor has an Insert a figure menu
that adds the line, and its Preview shows where each figure sits. A figure
reads only the rows of the table above it, so editing the table changes the
figure. Types (template.html, `FIG`):

- `levels`: a gauge that fills to each level. First column in metres.
- `timeline`: dated rows on a time axis. Needs a Date column (11 Oct 2028).
- `classes`: one cross-section per row, from deepest water to dry.
- `map`: the rows on a small map. Needs a Grid Ref or Coordinates column.
- `routes`: direction and distance from a centre. Needs a Distance column;
  the direction is read from the route name or the Direction column.
- `seasons`: a Summer and Winter switch. Needs Summer and Winter columns.
- `clock`: times of day on a 24-hour dial. Needs a Time column; reads
  times such as 06:00, ranges such as 23:00 to 03:00, and every four hours.
- `stages`: rows in order (stage 1, 2, ...), with any columns of
  measurements charted across them.
- `chain`: a chain of links, each shaded by its rating. Needs a Rating
  column from 0 to 1; a row without a number is drawn dashed.
- `ratings`: a bar for each row's rating. Needs a Rating column from 0 to 1.
- `log`: timed events on an axis (31 Dec, 18:00), with any readings in
  metres in the Event column drawn as a line.
- `parallel`: two columns side by side; rows where both say the same are
  joined.

An unknown type, or a table without the columns a type needs, draws nothing.
