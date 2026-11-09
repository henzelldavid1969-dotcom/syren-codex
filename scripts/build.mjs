// Build the site: put data/codex.json into the template and write
// dist/index.html, and turn the manuscript exports in story/ into
// dist/story.json for the Story pages. Vercel runs this on every deployment.
// It needs no network access and no keys.

import { readFile, writeFile, mkdir, copyFile, readdir } from 'node:fs/promises';
import { buildStory } from './story-lib.mjs';
import { buildTiles, buildScan } from './tiles.mjs';

const { META, DATA, MAP, STORY, FACTIONS = [] } = JSON.parse(await readFile(new URL('../data/codex.json', import.meta.url), 'utf8'));

// The River Vistula: geography, not story data, so it lives in content/
// rather than the database. Drawn under everything else on every map.
const VISTULA = JSON.parse(await readFile(new URL('../content/vistula.json', import.meta.url), 'utf8'));
MAP.lines.unshift({ k: 'riv', n: VISTULA.name, c: VISTULA.coordinates });

// JSON that is safe inside a <script> element.
const LS = String.fromCharCode(0x2028), PS = String.fromCharCode(0x2029);
const js = (v) => JSON.stringify(v).replace(/</g, '\\u003c').split(LS).join('\\u2028').split(PS).join('\\u2029');

// Home page copy, editable without touching layout code.
const HOME = JSON.parse(await readFile(new URL('../content/home.json', import.meta.url), 'utf8'));
const attr = (v) => String(v).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');

// A standard page shell, with the site name in the title and sharing tags.
const head =
  '<!doctype html>\n<html lang="en-GB">\n<meta charset="utf-8">\n' +
  '<meta name="viewport" content="width=device-width, initial-scale=1">\n' +
  `<meta name="description" content="${attr(HOME.site.description)}">\n` +
  `<meta name="application-name" content="${attr(HOME.site.title)}">\n` +
  `<meta property="og:type" content="website">\n` +
  `<meta property="og:site_name" content="${attr(HOME.site.title)}">\n` +
  `<meta property="og:title" content="${attr(HOME.site.title)}">\n` +
  `<meta property="og:description" content="${attr(HOME.site.description)}">\n` +
  `<meta name="twitter:card" content="summary">\n` +
  `<meta name="twitter:title" content="${attr(HOME.site.title)}">\n` +
  `<meta name="twitter:description" content="${attr(HOME.site.description)}">\n`;

// Home page tile graphics: maps generated from the map data; the Dendron and
// the Waterline are fixed drawings kept in assets/tiles.
const TILES = {
  ...buildTiles(MAP),
  ...buildScan(MAP),
  dendron: await readFile(new URL('../assets/tiles/dendron.svg', import.meta.url), 'utf8'),
  waterline: await readFile(new URL('../assets/tiles/waterline.svg', import.meta.url), 'utf8'),
};

const template = await readFile(new URL('../template.html', import.meta.url), 'utf8');
const html =
  head +
  template
    .replace('/*DATA*/', () => js(DATA))
    .replace('/*META*/', () => js(META))
    .replace('/*MAP*/', () => js(MAP))
    .replace('/*STORY*/', () => js(STORY))
    .replace('/*FACTIONS*/', () => js(FACTIONS))
    .replace('/*TILES*/', () => js(TILES))
    .replace('/*HOME*/', () => js(HOME))
    .replace(/<title>[^<]*<\/title>/, () => `<title>${attr(HOME.site.title)}</title>`);

await mkdir(new URL('../dist/', import.meta.url), { recursive: true });
// Portrait images for the home page (the Key Characters placeholder).
await mkdir(new URL('../dist/portraits/', import.meta.url), { recursive: true });
for (const f of await readdir(new URL('../assets/portraits/', import.meta.url)))
  await copyFile(new URL('../assets/portraits/' + f, import.meta.url), new URL('../dist/portraits/' + f, import.meta.url));
// The street map's software (MapLibre GL), served from the site itself and
// loaded only when a map is on screen. Its worker file must sit beside it.
await mkdir(new URL('../dist/vendor/maplibre/', import.meta.url), { recursive: true });
for (const f of ['maplibre-gl.mjs', 'maplibre-gl-worker.mjs', 'maplibre-gl.css'])
  await copyFile(new URL('../node_modules/maplibre-gl/dist/' + f, import.meta.url), new URL('../dist/vendor/maplibre/' + f, import.meta.url));
await writeFile(new URL('../dist/index.html', import.meta.url), html);
console.log(`Built dist/index.html: ${DATA.length} entries, ${MAP.pts.length} map points, ${html.length} bytes.`);

// The Story view's source: one file. To refresh the manuscript, replace
// story/manuscript.md (Markdown, one "## " heading per section) and rebuild.
const MANUSCRIPT = 'story/manuscript.md';
const read = (path) => readFile(new URL('../' + path, import.meta.url), 'utf8');
const story = buildStory({
  manuscript: await read(MANUSCRIPT),
  backCover: await read('story/back-cover.md'), // introduction on the Story page
});
await writeFile(new URL('../dist/story.json', import.meta.url), JSON.stringify(story));
console.log(`Built dist/story.json: ${story.pages.length} pages.`);
