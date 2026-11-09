// POST /api/publish: the admin's Publish button.
//
// 1. Checks that the request comes from the site owner (a signed-in
//    Supabase session whose user is in site_owners).
// 2. Exports the site data from the database, exactly as scripts/export.mjs
//    does, and saves it as a new release (public.releases).
// 3. Starts a rebuild of the live site through the Vercel deploy hook kept
//    in the DEPLOY_HOOK_URL setting. If that setting is missing, the
//    GitHub Action picks the release up at its next check instead.
//
// No key is kept in this file. The owner's own session does the writing,
// and the database's rules refuse anyone else.

import { exportCodex, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY } from '../scripts/codex-lib.mjs';

const json = (res, status, body) => {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'no-store');
  res.end(JSON.stringify(body));
};

export default async function handler(req, res) {
  if (req.method !== 'POST') return json(res, 405, { error: 'Use POST.' });
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!token) return json(res, 401, { error: 'Not signed in.' });
  const as = { apikey: SUPABASE_PUBLISHABLE_KEY, Authorization: `Bearer ${token}` };

  // Who is asking?
  const user = await fetch(`${SUPABASE_URL}/auth/v1/user`, { headers: as });
  if (!user.ok) return json(res, 401, { error: 'Your session has expired. Sign in again.' });
  const owner = await fetch(`${SUPABASE_URL}/rest/v1/rpc/is_owner`, {
    method: 'POST', headers: { ...as, 'Content-Type': 'application/json' }, body: '{}',
  });
  if (!owner.ok || (await owner.json()) !== true) return json(res, 403, { error: 'This account cannot publish.' });

  let note = '';
  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
    note = String(body.note || '').slice(0, 500);
  } catch {}

  // Export and save the release.
  let codex;
  try {
    codex = await exportCodex();
  } catch (e) {
    return json(res, 502, { error: 'Could not read the database: ' + e.message });
  }
  const saved = await fetch(`${SUPABASE_URL}/rest/v1/releases?select=id,created_at`, {
    method: 'POST',
    headers: { ...as, 'Content-Type': 'application/json', Prefer: 'return=representation' },
    body: JSON.stringify({ entries: codex.DATA.length, note: note || null, data: codex }),
  });
  if (!saved.ok) return json(res, 502, { error: 'Could not save the release: ' + (await saved.text()) });
  const [release] = await saved.json();

  // Rebuild the live site.
  let rebuild = 'queued';
  const hook = process.env.DEPLOY_HOOK_URL;
  if (hook) {
    const r = await fetch(hook, { method: 'POST' }).catch(() => null);
    rebuild = r && r.ok ? 'started' : 'queued';
  }
  return json(res, 200, { release: release.id, created_at: release.created_at, entries: codex.DATA.length, rebuild });
}
