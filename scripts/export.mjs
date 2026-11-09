// Export the Codex from the Supabase database to data/codex.json.
//
// The export itself is in codex-lib.mjs. scripts/build.mjs then puts this
// file into the template. Normally the site is published from the admin
// (/admin, Publish), and this script is only for checking an export by hand.
//
// Optional settings (the public values are used when they are not set):
//   SUPABASE_URL              for example https://xxxx.supabase.co
//   SUPABASE_PUBLISHABLE_KEY  the public key (safe to expose; read only)

import { writeFile, mkdir } from 'node:fs/promises';
import { exportCodex } from './codex-lib.mjs';

const codex = await exportCodex({
  url: process.env.SUPABASE_URL || undefined,
  key: process.env.SUPABASE_PUBLISHABLE_KEY || undefined,
});
const out = JSON.stringify(codex, null, 1) + '\n';
await mkdir(new URL('../data/', import.meta.url), { recursive: true });
await writeFile(new URL('../data/codex.json', import.meta.url), out);
console.log(`Exported data/codex.json: ${codex.DATA.length} entries, ${codex.MAP.pts.length} map points.`);
