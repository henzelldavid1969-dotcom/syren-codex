// Turns the manuscript exports in story/ into the pages of the Story section.
// The words are never changed. The only adjustment is to spaces that the doc
// exporter leaves just inside an italic or bold marker (for example
// "**Location: **houseboat"), which Markdown would otherwise print as
// literal asterisks. Those spaces are moved to the outside of the marker.

import { marked } from 'marked';

// Move whitespace from inside emphasis markers to outside, one line at a time.
export function fixEmphasis(line) {
  const parts = [];
  const re = /\\.|\*+|[^*\\]+|\\/g;
  let m;
  while ((m = re.exec(line))) parts.push(m[0]);
  const stack = [];
  const out = [];
  for (let i = 0; i < parts.length; i++) {
    const p = parts[i];
    if (!/^\*+$/.test(p)) { out.push(p); continue; }
    let n = p.length;
    let close = '';
    while (n > 0 && stack.length) {
      const top = stack[stack.length - 1];
      if (top.length > n) break;
      close += top;
      n -= top.length;
      stack.pop();
    }
    let open = '';
    if (n === 3) { stack.push('*', '**'); open = '***'; }
    else if (n === 2) { stack.push('**'); open = '**'; }
    else if (n === 1) { stack.push('*'); open = '*'; }
    // A closer must not follow whitespace: move that whitespace after it.
    let before = '';
    if (close && out.length) {
      const prev = out[out.length - 1];
      const ws = prev.match(/\s+$/);
      if (ws && !/^\*+$/.test(prev)) { out[out.length - 1] = prev.slice(0, -ws[0].length); before = ws[0]; }
    }
    // An opener must not be followed by whitespace: move that whitespace before it.
    let after = '';
    if (open && i + 1 < parts.length) {
      const ws = parts[i + 1].match(/^\s+/);
      if (ws) { parts[i + 1] = parts[i + 1].slice(ws[0].length); after = ws[0]; }
    }
    const gap = before + after;
    out.push(close && open ? close + gap + open : close ? close + gap : gap + open);
  }
  return out.join('');
}

const slugify = (s) =>
  s.replace(/[łŁ]/g, 'l').normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

const render = (md) => {
  const html = marked.parse(md.split('\n').map(fixEmphasis).join('\n'), { gfm: true });
  return html
    .replace(/<p><strong>([A-ZĄĆĘŁŃÓŚŹŻ][A-ZĄĆĘŁŃÓŚŹŻ .'-]*)<\/strong> · /g, '<p class="spk"><strong>$1</strong> · ')
    .replace(/<p>\* \* \*<\/p>/g, '<p class="brk">* * *</p>');
};

// Split a doc export into its "## " sections.
export function sections(md) {
  const out = [];
  let cur = null;
  for (const line of md.split('\n')) {
    const h = line.match(/^## (.*)$/);
    if (h) { cur = { title: h[1].trim(), lines: [] }; out.push(cur); continue; }
    if (cur) cur.lines.push(line);
  }
  // A section break and speaker line just before a heading belong to the next
  // section, under its heading, as everywhere else in the manuscript.
  for (let i = 0; i < out.length - 1; i++) {
    const L = out[i].lines;
    while (L.length && !L[L.length - 1].trim()) L.pop();
    const last = L[L.length - 1] || '';
    if (/^\*\*[A-ZĄĆĘŁŃÓŚŹŻ][^*]*\*\* · /.test(last)) {
      L.pop();
      while (L.length && !L[L.length - 1].trim()) L.pop();
      if (/^\\\* \\\* \\\*$/.test(L[L.length - 1] || '')) L.pop();
      out[i + 1].lines.unshift('', last, '');
    }
  }
  return out.map((s) => ({ title: s.title, md: s.lines.join('\n').trim() }));
}

// The book's title line ("# Name: Subtitle") and back cover sections.
export function bookFromFiles({ manuscript, backCover }) {
  const title = (manuscript.match(/^# (.*)$/m) || [, 'The Syren Protocols'])[1];
  const cover = Object.fromEntries(sections(backCover).map((s) => [s.title, s.md]));
  return { title, tagline: cover['Tagline'] || '', back_cover: cover['Back cover'] || '' };
}

// Build the Story pages. parts: [{ slug, title, md, group }] in reading
// order, where group is front, story or back.
export function buildStoryFrom({ book, parts }) {
  const [name, subtitle = ''] = book.title.split(/:\s*/);
  return {
    name,
    subtitle,
    tagline: render(book.tagline || ''),
    blurb: render(book.back_cover || ''),
    pages: parts.map((s) => ({ slug: s.slug, title: s.title, group: s.group, html: render(s.md || '') })),
  };
}

// The manuscript file as the source: every "## " heading is a page, the
// appendix included (it follows Acknowledgments, in the back matter).
export function partsFromManuscript(manuscript) {
  const parts = sections(manuscript);
  const firstStory = parts.findIndex((s) => /^Prologue/i.test(s.title));
  const lastStory = parts.findIndex((s) => /^Acknowledg/i.test(s.title));
  const seen = new Set();
  return parts.map((s, i) => {
    let slug = slugify(s.title);
    while (seen.has(slug)) slug += '-2';
    seen.add(slug);
    const group = i < firstStory ? 'front' : lastStory > -1 && i >= lastStory ? 'back' : 'story';
    return { slug, title: s.title, group, md: s.md };
  });
}

export function buildStory({ manuscript, backCover }) {
  return buildStoryFrom({ book: bookFromFiles({ manuscript, backCover }), parts: partsFromManuscript(manuscript) });
}

// The page group for a section kind from the database.
export const groupOfKind = (kind) => (kind === 'front' ? 'front' : kind === 'back' || kind === 'appendix' ? 'back' : 'story');
