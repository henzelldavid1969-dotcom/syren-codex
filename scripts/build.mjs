// Build the site: put data/codex.json into the approved template and write
// dist/index.html. The template is not changed. Vercel runs this on every
// deployment. It needs no network access and no keys.

import { readFile, writeFile, mkdir } from 'node:fs/promises';

const { META, DATA, MAP } = JSON.parse(await readFile(new URL('../data/codex.json', import.meta.url), 'utf8'));

// JSON that is safe inside a <script> element.
const LS = String.fromCharCode(0x2028), PS = String.fromCharCode(0x2029);
const js = (v) => JSON.stringify(v).replace(/</g, '\\u003c').split(LS).join('\\u2028').split(PS).join('\\u2029');

// The prototype was viewed inside a standard page shell; add the same shell.
const head =
  '<!doctype html>\n<html lang="en-GB">\n<meta charset="utf-8">\n' +
  '<meta name="viewport" content="width=device-width, initial-scale=1">\n' +
  '<meta name="description" content="The archive behind The Syren Protocols: places, people, objects and lore, with a map.">\n';

const template = await readFile(new URL('../template.html', import.meta.url), 'utf8');
const html =
  head +
  template
    .replace('/*DATA*/', () => js(DATA))
    .replace('/*META*/', () => js(META))
    .replace('/*MAP*/', () => js(MAP));

await mkdir(new URL('../dist/', import.meta.url), { recursive: true });
await writeFile(new URL('../dist/index.html', import.meta.url), html);
console.log(`Built dist/index.html: ${DATA.length} entries, ${MAP.pts.length} map points, ${html.length} bytes.`);
