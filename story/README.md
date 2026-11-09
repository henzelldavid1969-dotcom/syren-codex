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
