// The scheduled check (.github/workflows/publish.yml). If the admin has
// published a release that data/release.json does not record yet, save that
// release as data/codex.json and data/release.json. The commit that follows
// makes Vercel rebuild the live site. This is the fallback for when the
// Publish button's own rebuild (the Vercel deploy hook) is not set up.
// Prints "changed" when it wrote anything.

import { readFile, writeFile } from 'node:fs/promises';
import { SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from './codex-lib.mjs';

const at = (p) => new URL('../' + p, import.meta.url);
const res = await fetch(`${SUPABASE_URL}/rest/v1/releases?select=id,created_at,data&order=id.desc&limit=1`, {
  headers: { apikey: SUPABASE_PUBLISHABLE_KEY },
});
if (!res.ok) throw new Error(`releases: ${res.status} ${await res.text()}`);
const [release] = await res.json();
const known = await readFile(at('data/release.json'), 'utf8').then(JSON.parse).catch(() => ({ id: null }));
if (!release || release.id === known.id) {
  console.log(release ? `Release ${release.id} is already saved.` : 'No release yet.');
} else {
  await writeFile(at('data/codex.json'), JSON.stringify(release.data, null, 1) + '\n');
  await writeFile(at('data/release.json'), JSON.stringify({ id: release.id, created_at: release.created_at }) + '\n');
  console.log(`changed: release ${release.id} of ${release.created_at}`);
}
