# Syren Codex site: build brief for the first code session

## What this is
A free, searchable website for the lore archive of The Syren Protocols (David Henzell's novel, flooded and occupied Warsaw, 2034 to 2036). The approved design is a single-file prototype, `codex-site/template.html`, built by `build.py`. Visual reference: the Supabase homepage (left-aligned hero, joined bento grid with illustrations, tabbed table, code-style panel, template cards, voices carousel), thin Geist type, line icons, dark and light themes.

## What David wants
- Every entry is a record entered to a strict schema, shown on the site, and the site grows as he adds records, text, images, sound, video and Lottie files.
- No spend. Free database, free hosting. Not Framer or Webflow.
- The map is the crux of the experience. It stays prominent and reads from the same records. A better map (real base layers) is a later, separate project.
- David edits content himself afterwards, with no code. Choose tools that give him a spreadsheet-style editor and file upload.

## Source of truth
- Manuscript wins on story facts. The Codex Doc "The Syren Protocols: Codex (Master Archive)" (doc id 7f83d21e-9bcd-4349-a793-4dfd92a722d0) holds the 67 filed entries: Characters 25, Locations 31, Objects 6, Lore 5.
- Prototype data: `characters.md` (25 full entries), `hand.py` (locations, objects, lore as compact records), `map.json` (31 map points, perimeters, routes), `mapdata.py` (builds map.json from the project geojson).

## Schema to model
Entry: ref (SYNPTCL/LOC|CHR|OBJ|LOR/###), type, name, mark (taxonomy tag), grade (C, E, U or empty), summary, entry (long text), appears_in, reliability, cross_references (relations to other entries), status, icon, lottie, media (image, audio, video, with captions).
Map point: code, name, kind (outpost, node, gate, occupier, other), lon, lat, linked entry, note.
Taxonomy marks: Locations SYNC_PATH (PROX_SCAN, TRIGGER_V1, ACT_SYNC), Characters PROB_VAL_0.9 (CHROMA_VAL, TORUS_VAL, GRID_FAIL), Objects FLUX_LOCK_09, Lore ION_PATH.

## Proposed stack
Supabase free plan (Postgres, storage, table editor) plus a static front end on Cloudflare Pages or Vercel free. Check current free-plan limits and pause behaviour before committing.

## First session goals
1. Create the schema and storage buckets. Row-level security: public read, owner write.
2. Load the 67 entries and 31 map points from the prototype data. Do not rewrite entry text.
3. Make the front end read from the database (build-time export first, live reads later). Keep the design as approved.
4. Entry pages render media (image, audio, video, Lottie) when present.
5. Deploy to free hosting and give David the link and a one-page guide to editing entries and uploading files.

## Known faults to fix
- Cross-references in the Locations tab of the Codex Doc use old planned numbering: CHR/022 should be CHR/019 (Wiktor Szeliga), LOR/004 should be LOR/003 (Warsaw Uprising), LOR/008 and CHR/024 (Mrs Kaczmarek) point at entries that do not exist.
- Several location entries are thin and have no grade.
- Occupier positions on the map are approximate, taken from real Warsaw sites.

## Style rules for any text you write
British English, plain spare prose, no em dashes. Archive voice is cold and uncontracted. Be warm and gentle with David, lead corrections plainly and kindly, and answer the question asked.
