# Syren Codex: Entry Protocol (v0.1, draft for David to overrule)

Purpose: every entry in the archive is compiled to the same criteria, held in one database, and rendered by one page template. A reader should never be able to tell which entry was written first or by whom.

## 1. Core fields (every entry, every category)

| Field | Rule |
|---|---|
| reference | SYNPTCL/LOC, CHR, OBJ or LOR plus a three digit number. Never reused. |
| name | The name as the manuscript uses it. Alternate names go in aliases. |
| category | LOC, CHR, OBJ or LOR. |
| mark | Taxonomy tag (see section 4). |
| grade | C confirmed, E estimated, U unconfirmed. Required before status can be Filed. |
| source_count | Number of independent manuscript passages behind the grade. |
| summary | One sentence, 30 words at most. Used on cards and in search. |
| entry | The body. Plain prose in archive voice: cold, uncontracted, no em dashes. Only facts the sources support. |
| appears_in | Structured list of manuscript locations (chapter, interlude or appendix). Each links into the Story view. |
| reliability | One line explaining the grade, including anything in the project brief only. |
| relations | Typed links to other entries (see section 3). |
| status | Draft, Filed or Verified. |
| media | Four separate fields, see section 1a. |
| icon | One icon name from the site set, or a Lottie file. |
| archivist_note | Optional. Anything the reader should know that the sources do not say. |
| updated | Date, set automatically. |

## 1a. Media fields (same four on every entry)

| Field | Rule |
|---|---|
| images | Up to 10. JPG, PNG or WebP. Each has alt text, caption and credit. The first is the cover. Shown as a 5 by 2 grid, with empty slots as placeholders. |
| audio | Any number. WAV or MP3. Each has a label (for example Dry, Wet), a meta line (source, place, date, duration, format) and an optional note. Shown as panels with a native player. |
| video | Any number. MP4. Each has a caption. Shown as a 16 by 9 player. |
| files | Any number. PDF first, other documents allowed. Each has a label, page count and size. Shown as a download list. |
| lottie | Optional. One animation per entry, used as the icon or header. |

Empty media fields render as labelled placeholders so the structure is visible before any file exists. Files are stored in the database's file storage, never inside the page code. Presentation reference: the Gdansk Fields entry design (reference code in mono, title, italic summary, bordered facts grid, tag chips, audio panels).

## 2. Category blocks (fixed order, shown as a "Key facts" table)

- **Locations:** control (survivor, occupier, contested, neutral), ground class (A to D, only if the manuscript gives it), function, coordinates (lon, lat, with a flag for approximate), water condition, who is here (relations), events here.
- **Characters:** age (with grade if only in the brief), role, group, commandment theme, first appearance, own Protocol, distinguishing trait, fate in the story.
- **Objects:** type (document, artefact, organism, substance), holder, origin, function, where last seen.
- **Lore:** type (programme, event, concept, history), period, parties involved, consequences.

A key fact that the sources do not support is left blank and shown as "Not recorded". It is never guessed.

## 3. Relations (typed, two-way)

located_at, lives_at, appears_with, member_of, holds, created_by, part_of, opposes, mentioned_in. Every relation shows on both entries. A relation to an entry that does not exist is an error, not a dead link (this is how the stale LOC cross-references happened).

## 4. Taxonomy marks

Locations SYNC_PATH (PROX_SCAN outposts, TRIGGER_V1 Russian positions, ACT_SYNC escape routes). Characters PROB_VAL_0.9 (CHROMA_VAL primary, TORUS_VAL secondary, GRID_FAIL antagonists). Objects FLUX_LOCK_09 (SHIFT_REF_04 Dust, MAG_REF_400 Dendron and Entity, LINK_SYNC comms, FLUX_SYNC diaries and documents). Lore ION_PATH (LOAD_STRESS, DIFF_REF_89, REF_SYNC_400, PORE_SEQ).

## 5. Page template (identical for every entry)

1. Header: icon or image, reference, mark, grade badge, name, summary.
2. Media strip, only if media exists.
3. Key facts table (category block).
4. Entry body.
5. Appearances: chapters that mention it, linking into the Story view.
6. Connected entries, grouped by relation type.
7. Evidence panel: grade, source count, reliability line.
8. Record footer: status, last updated, archivist note.
9. Map button on any entry with coordinates, or any entry related to a place.

## 6. Rules the system enforces

- An entry cannot be marked Filed unless reference, name, category, mark, grade, summary, entry, appears_in and reliability are all present.
- Verified is set only by David.
- Every list view has a "Needs work" filter showing Drafts and entries with empty required fields, with a completeness count per category.
- Reference numbers are assigned by the database, not typed.
- Entries are edited in the database editor, never in the page code.

## 7. Immediate gap to close

The site currently shows only summary and entry for Locations, Objects and Lore, while Characters carry the full field set. The Codex Doc holds fuller records for the Locations, Objects and Lore entries. Load those, bring all 67 up to this protocol, and fix the known cross-reference numbering faults (CHR/022 should be CHR/019, LOR/004 should be LOR/003, LOR/008 and CHR/024 Mrs Kaczmarek point at nothing).
