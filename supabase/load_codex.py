"""Build supabase/load_codex.sql: the full Codex records for all 67 entries.

Sources, in order of authority for story facts:
  - dist/story.json (the manuscript, built from story/) for chapter speakers
    and story sections
  - codex/*.md (the Codex Doc, exported unchanged) for every entry field
  - map.json (the project map data) for coordinates not given in the text

Text fields are copied exactly. The only change is removing the Markdown
escape before underscores (SYNC\\_PATH becomes SYNC_PATH).
A key fact is filled only where a source states it. Otherwise it stays empty
and the site shows "Not recorded".

Run from the repository root after `node scripts/build.mjs`:
    python3 supabase/load_codex.py
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REF_RE = r'SYNPTCL/(?:LOC|CHR|OBJ|LOR)/\d{3}'

# Known cross-reference faults (reference/ENTRY_PROTOCOL.md, section 7).
FIX = {
    ('SYNPTCL/CHR/022', 'Wiktor Szeliga'): 'SYNPTCL/CHR/019',
    ('SYNPTCL/LOR/004', 'The Warsaw Uprising of 1944'): 'SYNPTCL/LOR/003',
}
DROP = {
    ('SYNPTCL/LOR/008', 'Screening citizens'),   # no such entry
    ('SYNPTCL/CHR/024', 'Mrs Kaczmarek'),         # CHR/024 is Mrs Lewandowska
}

# Object and lore types, set only where the record itself names the kind.
OBJECT_TYPE = {
    'SYNPTCL/OBJ/001': 'organism',   # summary: "An ancient organism"
    'SYNPTCL/OBJ/002': 'substance',  # summary: "A psychedelic scraped from the surface"
    'SYNPTCL/OBJ/003': 'document',   # summary: "The collected papers and recordings"
    'SYNPTCL/OBJ/004': 'document',   # summary: "The document that names the programme"
    'SYNPTCL/OBJ/005': 'artefact',   # summary: "Taped prayer book"
    'SYNPTCL/OBJ/006': 'artefact',   # summary: "Forty-one family photographs"
}
LORE_TYPE = {
    'SYNPTCL/LOR/001': 'programme',  # summary: "The programme behind the Dendron"
    'SYNPTCL/LOR/002': 'concept',    # summary: "The occupiers' scale"
    'SYNPTCL/LOR/003': 'history',    # summary: "The historical parallel"
}
LORE_PERIOD = {'SYNPTCL/LOR/003': '1944'}   # name: "The Warsaw Uprising of 1944"

WORDS = {'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5}


def unesc(s):
    return re.sub(r'\\([\\`*_{}\[\]()#+\-.!|])', r'\1', s)


def records():
    out = []
    for f in ['locations', 'characters', 'objects', 'lore']:
        text = (ROOT / 'codex' / f'{f}.md').read_text(encoding='utf8')
        for sec in re.split(r'\n## ', text)[1:]:
            rows = re.findall(r'^\| ([^|]+?) \| (.*) \|$', sec, re.M)
            d = {k.strip(): unesc(v) for k, v in rows if k.strip() not in ('Field', '---')}
            if 'Reference' in d:
                out.append(d)
    return out


def q(v):
    if v is None or v == '':
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return repr(v)
    return "'" + str(v).replace("'", "''") + "'"


def grade_of(rel):
    m = re.match(r'^([CEU])(?:\s*\((\d+)\)|,\s*(one|two|three|four|five|several) sources?\b|\.|,|$)', rel)
    if not m:
        return None, None
    n = int(m.group(2)) if m.group(2) else WORDS.get(m.group(3))
    return m.group(1), n


def age_of(summary, entry, reliability):
    for text in (summary, entry):
        m = re.search(r'\b[Aa]ged ([^.]*)', text)
        if m:
            age = m.group(1)
            parts = age.split(',')
            if len(parts) > 1 and not re.search(r'\d', parts[1]):
                age = parts[0]
            g = re.search(r'\s*\(([CEU])\)\s*$', age)
            return (age[:g.start()] if g else age).strip(), (g.group(1) if g else None)
    m = re.search(r'\bof (about \d+)\b', summary)
    if m:
        return m.group(1), None
    m = re.search(r'age of (\d+) is in the project brief only \(([CEU])\)', reliability)
    if m:
        return m.group(1), m.group(2)
    return None, None


def links(rec):
    """Cross-references in order, with ranges expanded and known faults fixed."""
    out, notes = [], []
    x = rec['Cross-references']
    for m in re.finditer(r'(SYNPTCL/(LOC|CHR|OBJ|LOR)/(\d{3}))(?: to (?:\2/)?(\d{3}))?(?:,? ([^.;]*?))?(?=\.|;| SYNPTCL|$)', x):
        ref, typ, a, b, label = m.group(1), m.group(2), int(m.group(3)), m.group(4), (m.group(5) or '').strip()
        targets = [f'SYNPTCL/{typ}/{n:03d}' for n in range(a, int(b) + 1)] if b else [ref]
        for t in targets:
            if (t, label) in DROP:
                notes.append(f'dropped {t} "{label}"')
                continue
            if (t, label) in FIX:
                notes.append(f'fixed {t} "{label}" to {FIX[(t, label)]}')
                t = FIX[(t, label)]
            if t != rec['Reference'] and t not in out:
                out.append(t)
    note = None if 'SYNPTCL' in x or re.fullmatch(r'None yet\.?', x.strip()) else x.strip()
    return out, note, notes


def main():
    recs = records()
    assert len(recs) == 67
    refs = {r['Reference'] for r in recs}
    story = json.loads((ROOT / 'dist' / 'story.json').read_text(encoding='utf8'))
    pages = story['pages']
    slugs = {p['slug'] for p in pages}
    mp = json.loads((ROOT / 'map.json').read_text(encoding='utf8'))

    # Own Protocol: the chapter in which the character speaks in their own voice.
    speaker = {}
    for p in pages:
        if p['group'] != 'story' or not p['slug'].startswith('chapter-'):
            continue
        for name, kind in re.findall(r'<p class="spk"><strong>([^<]+)</strong> · (recording|written)', p['html']):
            speaker.setdefault(name.strip().lower(), p['slug'])

    def section_for(phrase, rec):
        s = phrase.strip().lower()
        if 'prologue' in s:
            return ['prologue-the-barn']
        found = []
        for m in re.finditer(r'protocol (\d{3})', s):
            found += [p['slug'] for p in pages if f'(protocol {m.group(1)})' in p['title'].lower()]
        for m in re.finditer(r'chapter (\d+)\b', s):
            found += [p['slug'] for p in pages if p['slug'].startswith(f'chapter-{m.group(1)}-')]
        for m in re.finditer(r'interlude (vi|v|iv|iii|ii|i)\b', s):
            found += [p['slug'] for p in pages if p['slug'].startswith(f'interlude-{m.group(1)}-')]
        for m in re.finditer(r'diary (\d{3})', s):
            found += [p['slug'] for p in pages if p['slug'].startswith(f'diary-{m.group(1)}-')]
        if 'appendix: the brief' in s:
            found.append('appendix-the-brief')
        own = re.search(r"\b(his|her) own protocol\b", s)
        if own:
            first = rec['Name'].replace('"', '').split()[0].lower()
            nick = re.search(r'"([^"]+)"', rec['Name'])
            for key in ([nick.group(1).lower()] if nick else []) + [first]:
                if key in speaker:
                    found.append(speaker[key])
                    break
        for m in re.finditer(r"\b([a-zł]+)'s (?:protocol|testimony)\b|testimony of ([a-zł]+)\b", s):
            key = (m.group(1) or m.group(2)).lower()
            if key in speaker:
                found.append(speaker[key])
        return found

    sql = ['-- Generated by supabase/load_codex.py from codex/, story/ and map.json. Do not edit by hand.', 'begin;', '']
    sql.append('insert into public.story_sections (slug, title, position) values')
    sql.append(',\n'.join(f"  ({q(p['slug'])}, {q(p['title'])}, {i + 1})" for i, p in enumerate(pages)))
    sql.append('on conflict (slug) do update set title = excluded.title;\n')

    sql += ['delete from public.editor_notes;', 'delete from public.relations;', 'delete from public.entry_appearances;', '']
    report = {'fixes': [], 'unresolved': [], 'grades': 0, 'facts': 0}
    rel_rows, note_rows, app_rows, upd, facts = [], [], [], [], []
    for r in recs:
        ref = r['Reference']
        typ = ref.split('/')[1]
        mark = r['Category'].split('/')[-1].strip() if '/' in r['Category'] else None
        status_text = r['Status'].strip()
        status = (re.match(r'(Draft|Filed|Verified)\b', status_text) or [None, 'Draft'])[1]
        grade, n = grade_of(r['Reliability'])
        report['grades'] += bool(grade)
        targets, xnote, fixnotes = links(r)
        report['fixes'] += [f'{ref}: {x}' for x in fixnotes]
        rel_rows += [(ref, t, i) for i, t in enumerate(targets)]
        note = status_text if not re.fullmatch(r'(Draft|Filed|Verified)\.?', status_text) else ''
        if r.get('Media'):
            note = (note + '\n\n' if note else '') + 'Media: ' + r['Media']
        if note:
            note_rows.append((ref, note))
        seen = []
        for phrase in re.split(r'[.;]\s+|\.$', r['Appears in']):
            if not phrase.strip():
                continue
            got = section_for(phrase, r)
            if not got and re.search(r'protocol|interlude|chapter|diary 0|prologue|appendix|testimony', phrase, re.I):
                report['unresolved'].append(f'{ref}: {phrase.strip()}')
            for g in got:
                if g not in seen:
                    seen.append(g)
        app_rows += [(ref, s, i) for i, s in enumerate(seen)]
        upd.append(
            f"update public.entries set name = {q(r['Name'])}, mark = {q(mark)}, grade = {q(grade)}, "
            f"source_count = {q(n)}, summary = {q(r['Summary'])}, entry = {q(r['Entry'])}, "
            f"appears_in = {q(r['Appears in'])}, reliability = {q(r['Reliability'])}, "
            f"cross_references_note = {q(xnote)}, status = {q(status)} where ref = {q(ref)};")

        if typ == 'LOC':
            control = {'PROX_SCAN': 'survivor', 'TRIGGER_V1': 'occupier'}.get(mark)
            gc = re.search(r'Class ([A-D]) ground', r['Entry'])
            grid = re.search(r'Grid reference (\d+\.\d+) N, (\d+\.\d+) E', r['Entry'])
            lon = lat = None
            approx = False
            if grid:
                lat, lon = float(grid.group(1)), float(grid.group(2))
            else:
                slug = 'loc-' + ref[-3:]
                pts = [p for p in mp['pts'] if p['e'] == slug]
                if len(pts) == 1:
                    lon, lat, approx = pts[0]['x'], pts[0]['y'], True
            facts.append(f"update public.location_facts set control = {q(control)}, ground_class = {q(gc and gc.group(1))}, "
                         f"lon = {q(lon)}, lat = {q(lat)}, coords_approximate = {q(approx)} where ref = {q(ref)};")
        elif typ == 'CHR':
            age, ag = age_of(r['Summary'], r['Entry'], r['Reliability'])
            own = None
            first = r['Name'].replace('"', '').split()[0].lower()
            nick = re.search(r'"([^"]+)"', r['Name'])
            for key in ([nick.group(1).lower()] if nick else []) + [first]:
                if key in speaker:
                    own = speaker[key]
                    break
            facts.append(f"update public.character_facts set age = {q(age)}, age_grade = {q(ag)}, "
                         f"own_protocol = {q(own)} where ref = {q(ref)};")
        elif typ == 'OBJ':
            facts.append(f"update public.object_facts set object_type = {q(OBJECT_TYPE.get(ref))} where ref = {q(ref)};")
        else:
            facts.append(f"update public.lore_facts set lore_type = {q(LORE_TYPE.get(ref))}, "
                         f"period = {q(LORE_PERIOD.get(ref))} where ref = {q(ref)};")

    assert all(a in refs and b in refs for a, b, _ in rel_rows)
    assert all(s in slugs for _, s, _ in app_rows)
    sql += upd + ['']
    sql.append('insert into public.relations (from_ref, to_ref, position, type) values')
    sql.append(',\n'.join(f"  ({q(a)}, {q(b)}, {i}, 'connected')" for a, b, i in rel_rows) + ';\n')
    sql.append('insert into public.editor_notes (ref, note) values')
    sql.append(',\n'.join(f'  ({q(a)}, {q(b)})' for a, b in note_rows) + ';\n')
    sql.append('insert into public.entry_appearances (entry_ref, section, position) values')
    sql.append(',\n'.join(f'  ({q(a)}, {q(b)}, {i})' for a, b, i in app_rows) + ';\n')
    sql += facts + ['', 'commit;']
    (ROOT / 'supabase' / 'load_codex.sql').write_text('\n'.join(sql) + '\n', encoding='utf8')

    print(f'{len(recs)} entries, {len(rel_rows)} relations, {len(note_rows)} editor notes, '
          f'{len(app_rows)} appearances, {report["grades"]} grades, {len(speaker)} own Protocols found')
    print('Cross-reference fixes:')
    for x in report['fixes']:
        print('  ', x)
    print('Appearance phrases not linked to a chapter (kept in the text):')
    for x in report['unresolved']:
        print('  ', x)


if __name__ == '__main__':
    main()
