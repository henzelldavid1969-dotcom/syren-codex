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
- **Characters:** age (with grade if only in the brief), role, group, tuning (one of a list of options, edited in the admin), first appearance, own Protocol, distinguishing trait, fate in the story.
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

## 8. Story structure and chapter labels

The Story view and every "Appears in" row use one list of sections. Each section has a kind, a group, the full title (exactly as the manuscript heading reads), and a short label of at most 24 characters for the sidebar and the right column. Labels are entered once, here, and never typed again on an entry.

Short label pattern: `Ch 9 · The Dendron`, `Int I · Wiktor Szeliga`, `Front · Foreword`. Protocol chapters carry the Protocol number in the label's tail: `Ch 3 · The Zone · P001`.

### Groups (the collapsible sidebar sections)

The five Protocol chapters (3, 6, 9, 12, 15) each close a part of the book, so the story is grouped into five parts, each ending in its Protocol chapter, plus Before and After. Only the group holding the current page is open.

| Group | Contents |
|---|---|
| Before the story | Copyright, Dedication, Foreword |
| Part 1 · The Zone | Prologue, Diary 001, Chapters 1 to 3, Interlude I |
| Part 2 · The Occupation | Chapters 4 to 6, Interlude II, Interlude: The Second Flood |
| Part 3 · The Dendron | Chapters 7 to 9, Interlude III |
| Part 4 · The Codex | Interlude IV, Chapters 10 to 12, Interlude V |
| Part 5 · The Aftermath | Chapters 13 to 16, Interlude VI |
| After the story | Acknowledgments, Appendix: The Brief |

### Sections in reading order

| Order | Kind | Full title | Short label | Group |
|---|---|---|---|---|
| 1 | front | Copyright | Front · Copyright | Before |
| 2 | front | Dedication | Front · Dedication | Before |
| 3 | front | Foreword | Front · Foreword | Before |
| 4 | prologue | Prologue: The Barn | Pro · The Barn | Part 1 |
| 5 | diary | Diary 001: The Arrival | Diary 001 · Arrival | Part 1 |
| 6 | chapter | Chapter 1: The Blasphemer | Ch 1 · The Blasphemer | Part 1 |
| 7 | interlude | Interlude I: Wiktor Szeliga, Block C | Int I · Szeliga, Block C | Part 1 |
| 8 | chapter | Chapter 2: The Photographer | Ch 2 · The Photographer | Part 1 |
| 9 | protocol | Chapter 3: The Zone (Protocol 001) | Ch 3 · The Zone · P001 | Part 1 |
| 10 | chapter | Chapter 4: The Engineer | Ch 4 · The Engineer | Part 2 |
| 11 | interlude | Interlude II: Sasha Lebedev, Observation Post R0 | Int II · Lebedev, R0 | Part 2 |
| 12 | chapter | Chapter 5: The Pilgrim | Ch 5 · The Pilgrim | Part 2 |
| 13 | interlude | Interlude: The Second Flood | Int · Second Flood | Part 2 |
| 14 | protocol | Chapter 6: The Occupation (Protocol 002) | Ch 6 · Occupation · P002 | Part 2 |
| 15 | chapter | Chapter 7: The Musician | Ch 7 · The Musician | Part 3 |
| 16 | interlude | Interlude III: Major Budanov, Aleja Szucha | Int III · Budanov | Part 3 |
| 17 | chapter | Chapter 8: The Medic | Ch 8 · The Medic | Part 3 |
| 18 | protocol | Chapter 9: The Dendron (Protocol 003) | Ch 9 · Dendron · P003 | Part 3 |
| 19 | interlude | Interlude IV: The Voice, Studio Two | Int IV · The Voice | Part 4 |
| 20 | chapter | Chapter 10: The Listener | Ch 10 · The Listener | Part 4 |
| 21 | chapter | Chapter 11: The Orphan | Ch 11 · The Orphan | Part 4 |
| 22 | interlude | Interlude V: Account Lead, Cohort Review | Int V · Cohort Review | Part 4 |
| 23 | protocol | Chapter 12: The Codex (Protocol 004) | Ch 12 · The Codex · P004 | Part 4 |
| 24 | chapter | Chapter 13: The Youngest | Ch 13 · The Youngest | Part 5 |
| 25 | chapter | Chapter 14: The Mouse | Ch 14 · The Mouse | Part 5 |
| 26 | interlude | Interlude VI: Wiktor Szeliga, Shelter 9 | Int VI · Szeliga, S9 | Part 5 |
| 27 | protocol | Chapter 15: The Aftermath (Protocol 005) | Ch 15 · Aftermath · P005 | Part 5 |
| 28 | chapter | Chapter 16: The Protocols | Ch 16 · The Protocols | Part 5 |
| 29 | back | Acknowledgments | Back · Acknowledgments | After |
| 30 | appendix | Appendix: The Brief | App · The Brief | After |

Rules: the full title is read from the manuscript heading and never retyped by hand. If a heading changes in the manuscript, the label is reviewed. The group names are proposals for David to overrule. Previous and next links follow the Order column.

## 9. Sidebar and right column behaviour

- Left sidebar: collapsible groups, one open at a time, the current page's group open by default. Entries are grouped by taxonomy mark: Locations (Survivor outposts, Russian positions, Escape routes), Characters (Primary, Secondary, Antagonists), Objects and Lore by their marks. No inner scrollbar; if one is unavoidable it is thin and shown only on hover.
- Previous and next links at the foot of every chapter and entry.
- Right column: each panel collapsible with a count in its heading. Evidence and Appears in start open, the others folded. Each relation is one line: a short mono prefix (the section short label, or the entry reference) then a title truncated with an ellipsis, with the full title on hover. Long explanatory text under "Appears in" sits inside a "Note" fold.
