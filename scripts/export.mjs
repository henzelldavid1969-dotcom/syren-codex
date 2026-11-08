// Export the Codex from the Supabase database to data/codex.json.
//
// Reads every table with the public (read-only) key and rebuilds the data in
// the shape the template expects (reference/ENTRY_PROTOCOL.md). scripts/build.mjs then puts this
// file into the template. The GitHub Action in .github/workflows runs this
// every 15 minutes and saves the file when anything has changed.
//
// Needs two settings:
//   SUPABASE_URL              for example https://xxxx.supabase.co
//   SUPABASE_PUBLISHABLE_KEY  the public key (safe to expose; read only)

import { writeFile, mkdir } from 'node:fs/promises';

const URL_BASE = process.env.SUPABASE_URL?.replace(/\/$/, '');
const KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
if (!URL_BASE || !KEY) {
  console.error('SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be set.');
  process.exit(1);
}

async function table(name, select, order) {
  const res = await fetch(`${URL_BASE}/rest/v1/${name}?select=${select}&order=${order}`, {
    headers: { apikey: KEY },
  });
  if (!res.ok) throw new Error(`${name}: ${res.status} ${await res.text()}`);
  return res.json();
}

const fileUrl = (bucket, file) =>
  /^https?:\/\//.test(file)
    ? file
    : `${URL_BASE}/storage/v1/object/public/${bucket}/${file.split('/').map(encodeURIComponent).join('/')}`;

const LINE_KIND = { occupation_perimeter: 'occ', russian_perimeter: 'rus', escape_route: 'esc' };
const POINT_KIND = { outpost: 'out', node: 'node', gate: 'gate', occupier: 'rus', other: 'kos' };

const [categories, entries, relations, relTypes, sections, appearances, locF, chrF, objF, lorF,
  images, audio, video, files, points, lines] = await Promise.all([
  table('categories', 'code,label,mark,sort_order', 'sort_order'),
  table('entries', '*', 'ref'),
  table('relations', 'from_ref,to_ref,type,position', 'from_ref,position,to_ref'),
  table('relation_types', 'code,label,inverse_label,position', 'position'),
  table('story_sections', 'slug,title,position', 'position'),
  table('entry_appearances', 'entry_ref,section,position', 'entry_ref,position'),
  table('location_facts', '*', 'ref'),
  table('character_facts', '*', 'ref'),
  table('object_facts', '*', 'ref'),
  table('lore_facts', '*', 'ref'),
  table('entry_images', '*', 'entry_ref,position,id'),
  table('entry_audio', '*', 'entry_ref,position,id'),
  table('entry_video', '*', 'entry_ref,position,id'),
  table('entry_files_view', '*', 'entry_ref,position,id'),
  table('map_points', '*', 'position,id'),
  table('map_lines', 'kind,name,coordinates,position', 'position,id'),
]);

const typeOrder = categories.map((c) => c.code);
const slugOf = Object.fromEntries(entries.map((e) => [e.ref, e.slug]));
const RT = Object.fromEntries(relTypes.map((t) => [t.code, t]));
const SECTION = Object.fromEntries(sections.map((s) => [s.slug, s.title]));
const FACTS = Object.fromEntries([...locF, ...chrF, ...objF, ...lorF].map((f) => [f.ref, f]));
const by = (rows, ref) => rows.filter((r) => r.entry_ref === ref);
const clean = (o) => Object.fromEntries(Object.entries(o).filter(([, v]) => v !== null && v !== '' && v !== undefined));

const DATA = entries
  .slice()
  .sort((a, b) => typeOrder.indexOf(a.type) - typeOrder.indexOf(b.type) || a.ref.localeCompare(b.ref))
  .map((e) => {
    // Two-way relations: each row shows on both entries, with the right label.
    const rel = [];
    const add = (ref, label) => {
      if (slugOf[ref] && !rel.some((r) => r.id === slugOf[ref] && r.label === label)) rel.push({ id: slugOf[ref], label });
    };
    relations.filter((r) => r.from_ref === e.ref).forEach((r) => add(r.to_ref, RT[r.type].label));
    relations.filter((r) => r.to_ref === e.ref).forEach((r) => add(r.from_ref, RT[r.type].inverse_label));
    const { ref: _r, ...facts } = FACTS[e.ref] || {};
    for (const k of ['own_protocol', 'first_appearance']) if (facts[k]) facts[k + '_t'] = SECTION[facts[k]] || facts[k];
    const d = {
      id: e.slug,
      ref: e.ref,
      type: e.type,
      name: e.name,
      mark: e.mark || '',
      grade: e.grade || '',
      summary: e.summary,
      entry: e.entry,
      appears: e.appears_in || '',
      reliability: e.reliability || '',
      status: e.status || 'Draft',
      sources: e.source_count ?? null,
      note: e.archivist_note || '',
      xnote: e.cross_references_note || '',
      aliases: e.aliases || '',
      updated: (e.updated_at || '').slice(0, 10),
      facts: clean(facts),
      rel,
      apps: by(appearances, e.ref).filter((a) => SECTION[a.section]).map((a) => ({ s: a.section, t: SECTION[a.section] })),
      images: by(images, e.ref).slice(0, 10).map((x) => clean({ src: fileUrl('images', x.file), alt: x.alt, caption: x.caption, credit: x.credit })),
      audio: by(audio, e.ref).map((x) => clean({ src: fileUrl('audio', x.file), label: x.label, meta: x.meta, note: x.note })),
      video: by(video, e.ref).map((x) => clean({ src: fileUrl('video', x.file), caption: x.caption })),
      files: by(files, e.ref).map((x) => clean({ src: fileUrl('files', x.file), label: x.label || x.file, pages: x.page_count, size: x.size_bytes })),
    };
    if (e.icon) d.icon = e.icon;
    if (e.lottie) d.lottie = fileUrl('lottie', e.lottie);
    return d;
  });

const META = Object.fromEntries(categories.map((c) => [c.code, { label: c.label, mark: c.mark }]));

const MAP = {
  lines: lines.map((l) => ({ k: LINE_KIND[l.kind], n: l.name, c: l.coordinates })),
  pts: points.map((p) => ({
    k: POINT_KIND[p.kind],
    c: p.code,
    n: p.name,
    x: p.lon,
    y: p.lat,
    e: (p.entry_ref && slugOf[p.entry_ref]) || '',
    t: p.note || '',
  })),
};

const out = JSON.stringify({ META, DATA, MAP }, null, 1) + '\n';
await mkdir(new URL('../data/', import.meta.url), { recursive: true });
await writeFile(new URL('../data/codex.json', import.meta.url), out);
console.log(`Exported data/codex.json: ${DATA.length} entries, ${MAP.pts.length} map points.`);
