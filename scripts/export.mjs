// Export the Codex from the Supabase database to data/codex.json.
//
// Reads every table with the public (read-only) key and rebuilds the data in
// the shape the approved template expects. scripts/build.mjs then puts this
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

const BUCKET = { image: 'images', audio: 'audio', video: 'video' };
const fileUrl = (bucket, file) =>
  /^https?:\/\//.test(file)
    ? file
    : `${URL_BASE}/storage/v1/object/public/${bucket}/${file.split('/').map(encodeURIComponent).join('/')}`;

const LINE_KIND = { occupation_perimeter: 'occ', russian_perimeter: 'rus', escape_route: 'esc' };
const POINT_KIND = { outpost: 'out', node: 'node', gate: 'gate', occupier: 'rus', other: 'kos' };

const [categories, entries, links, media, points, lines] = await Promise.all([
  table('categories', 'code,label,mark,sort_order', 'sort_order'),
  table('entries', '*', 'ref'),
  table('entry_links', 'from_ref,to_ref,position', 'from_ref,position'),
  table('entry_media', 'entry_ref,kind,file,caption,position', 'entry_ref,position,id'),
  table('map_points', '*', 'position,id'),
  table('map_lines', 'kind,name,coordinates,position', 'position,id'),
]);

const typeOrder = categories.map((c) => c.code);
const slugOf = Object.fromEntries(entries.map((e) => [e.ref, e.slug]));

const DATA = entries
  .slice()
  .sort((a, b) => typeOrder.indexOf(a.type) - typeOrder.indexOf(b.type) || a.ref.localeCompare(b.ref))
  .map((e) => {
    const refs = links.filter((l) => l.from_ref === e.ref && slugOf[l.to_ref]).map((l) => l.to_ref);
    const xrefs = [refs.join('; '), e.cross_references_note || ''].filter(Boolean).join(' ');
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
      xrefs,
      status: e.status || '',
      full: Boolean(e.appears_in || e.reliability || e.status),
    };
    const m = media.filter((x) => x.entry_ref === e.ref);
    if (m.length) d.media = m.map((x) => ({ type: x.kind, src: fileUrl(BUCKET[x.kind], x.file), caption: x.caption || '' }));
    if (e.icon) d.icon = fileUrl('images', e.icon);
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
