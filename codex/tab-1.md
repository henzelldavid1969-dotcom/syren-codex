# The Syren Protocols: Codex (Master Archive)

Nov 7, 2026 · @David Henzell

## Purpose and rules

This archive is the single source for every codex entry. The website, the designed PDF, the ebook back matter and the podcast notes are all produced from it.

- The manuscript is the canon for the story. This archive is the canon for the codex. Where they disagree, the manuscript wins, the entry is corrected, and the difference is noted.
- Each entry is written once, here, and reused everywhere. Nothing is written first on the website.
- Entries are written in the cold, uncontracted voice of the Protocol chapters. Diana's own words appear only where the manuscript puts them.

## Entry format

Every entry carries the same eleven fields, so that any format can be built from them.

| Field | What it holds |
| --- | --- |
| Reference | The codex reference code, for example SYNPTCL/LOC/014 (see Reference scheme below) |
| Name | The entry's title as a reader would look it up |
| Category | The primary and secondary mark from the taxonomy (for example SYNC\_PATH / PROX\_SCAN) |
| Summary | One spoiler-free line, used as the link preview and the podcast note |
| Entry | The full description, in the archive's cold voice |
| Appears in | The chapters and sections where the manuscript mentions it |
| Reliability | The evidence grade (C, E or U, defined below) and the number of sources |
| Cross-references | The linked entries (the REF\_SYNC\_400 links) |
| Condition | Clean, lightly worn, significantly degraded or barely legible |
| Media | The symbol, any recorded sound or voice, any facsimile document |
| Status | Draft, checked against the manuscript, or locked |

## Categories

The taxonomy has four primary marks. They are the data model. Every entry carries one primary mark and, where it applies, one secondary mark.

| Primary mark | Category | Secondary marks |
| --- | --- | --- |
| SYNC\_PATH | Locations | PROX\_SCAN (outposts), TRIGGER\_V1 (Russian positions), ACT\_SYNC (escape routes) |
| PROB\_VAL\_0.9 | Characters | CHROMA\_VAL (primary), TORUS\_VAL (secondary), GRID\_FAIL (antagonists) |
| FLUX\_LOCK\_09 | Objects | SHIFT\_REF\_04 (Dendron Dust), MAG\_REF\_400 (the Dendron), LINK\_SYNC (communications), FLUX\_SYNC (diaries and documents) |
| ION\_PATH | Lore | LOAD\_STRESS, DIFF\_REF\_89 (historical parallels), REF\_SYNC\_400 (cross-references), PORE\_SEQ (zone vocabulary) |

Security is not a category. Screening points and Russian positions are Locations (TRIGGER\_V1), and procedures are Lore. The website's headings are not used.

## Evidence grades

The manuscript marks claims C, E or U with a count of sources. The grades are kept and defined here, so that every entry uses them the same way.

| Grade | Name | Meaning |
| --- | --- | --- |
| C | Confirmed | Directly observed, or reported by two or more independent sources |
| E | Estimated | One source, or a count or judgement made by the archivist |
| U | Unconfirmed | Belief or rumour. No source has seen it |

A grade can be raised or lowered only by a later source, and the change is noted in the entry. The number of sources is written beside the grade, for example C (3).

## Reference scheme

Every codex entry takes a code of the form SYNPTCL/type/serial. The type is LOC, CHR, OBJ or LOR, matching the four primary marks. The serial is three digits, issued in order and never reused. A retired entry keeps its number. Examples: SYNPTCL/LOC/014, SYNPTCL/CHR/003, SYNPTCL/OBJ/001, SYNPTCL/LOR/022.

This follows the code already used for the taxonomy (SYNPTCL/TAX/001). The manuscript's document codes (for example SY/ZZ/0036\_DD) are not changed. They are treated as sources: an entry lists them under Appears in, and each document code can link to its entries.

## Decisions

All six choices are made. The list is kept as the record of what was asked.

- [x] **Categories.** Use the four taxonomy marks as the data model and the five website headings as views, or keep the website's headings as the model.
- [x] **Evidence grades.** The manuscript uses C, E and U with a source count. Each grade needs a one-line definition.
- [x] **Security.** Decide whether it is a category of its own or a view over the screening points, checkpoints and procedures.
- [x] **Spoiler release.** Release entries by date, by reading progress, or both.
- [x] **Reference scheme.** Settle one code format for every entry type, not only diaries and documents.
- [x] **Source material.** The project holds about 150 older files (characters, objects, lore). Decide whether to migrate them in, checking each against the manuscript, before new entries are written.

## Source material

The project holds about 146 older files. None is migrated by copying. Each is classified once, and an entry is written only after it has been checked against the manuscript, which wins wherever they differ.

| Group | Action | Notes |
| --- | --- | --- |
| characters\_\_ (profiles and notes) | Migrate | One entry per character who appears in the manuscript, mark PROB\_VAL\_0.9. Characters who do not appear are reference only. Known stale item: the Zoysa Zielinski profile gives her age as 17, to be checked against the manuscript. |
| locations\_\_ (including the op- outposts) | Migrate | Mark SYNC\_PATH. Check each against the master geojson and the screening points file. The screening points SP-1 to SP-4 are not yet in the geojson. |
| objects\_\_ (Dendron, Dendron Dust, diaries, peeker, signal blocking) | Migrate and merge | Marks MAG\_REF\_400, SHIFT\_REF\_04, FLUX\_SYNC, LINK\_SYNC. The Entity files appear to be an earlier name for the Dendron and are merged into one entry after checking. |
| lore\_\_ | Migrate selectively | Mark ION\_PATH. The Operation Neural Harvest entry is thin and is rewritten from Protocol 005 and the brief appendix. The Death Stranding files are influence notes and stay reference only. |
| Dated notes, 2024 and 2025 | Reference only | Research and influence notes, kept in the project. Nothing is retired without David's say. |
| syren\_recovered/ | Keep the taxonomy and the geojson. Others reference only | The manuscript supersedes the master v1.6, the reading copy, the timeline v1.0 and the 16-chapter structure. |
| claude/ | Migrate the screening points. Production notes reference only | The screening points become Locations entries. |

The order of work: first a pilot batch of three entries, the Dendron, Dendron Dust and Operation Neural Harvest, so that the format is tested before the rest. Then Locations, because the map depends on them, then Characters, Objects and Lore. Each entry is marked Draft until it has been checked against the manuscript, and Locked after that.

## Autonomous calls and manuscript mismatches

Made while David was away. Each can be overruled. The manuscript wins on story facts.

1. Entries are filed only where the manuscript supports them. Older project profiles are not used as sources.
2. Marek Olszewski is described as a child in August 1944, which would make him about 100 in 2034. Author to rule.
3. Zoysa Zieliński is 17 in Marek's kitchen scene and 19 at Dęblin, and is a female captain. The older profile calls her male.
4. Alisia Lewandowska is 14 in one account and 16 in another. The keeper's-house thief is not named in the passage.
5. Nikita's surname is spelled Sokołowski in the brief. The feminine form would be Sokołowska.
6. Artur is about 12 in the manuscript, 11 in the brief.
7. Catalina is 40 in one passage and 41 in another.
8. Dendron Dust as a psychedelic used in rituals is canon, but Protocol 003 section 7 does not yet say so.
9. Fritha's church is linked to St Michael's Cathedral. An outside listener's summary agrees.
10. The words Peeker, signal blocker and biofuel do not occur in the manuscript.
11. Goya is guide and watcher in the manuscript, not commander of field operations.
12. Magda's entry is short because her own Protocol has not been read for it.
13. Check against an outside review (a podcast-style summary of the manuscript): Nikita's age given as eight, Budanov described as an interrogator at Szucha, Sasha aged 23 with tea at 62 degrees, and Lucasz as designer of the flood canal. Not yet confirmed in the manuscript.
