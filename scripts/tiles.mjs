// Home page category tiles: the map graphics for "The Ground" and
// "Ways Out", generated at build time from the map data (the same data as
// the map section) and inlined as SVG. Nothing is drawn in the browser.
//
// Projection, as in the tiles prototype: longitude scaled by cos 52.25
// degrees; the whole data set fitted so its larger side measures 400 units.
// Contour rings are the occupation perimeter scaled towards its mean point.

const COS = Math.cos((52.25 * Math.PI) / 180);
const f = (n) => n.toFixed(1);

function projection(MAP) {
  const all = MAP.pts.map((p) => [p.x, p.y]).concat(...MAP.lines.map((l) => l.c));
  const lons = all.map((p) => p[0]), lats = all.map((p) => p[1]);
  const minLon = Math.min(...lons), maxLat = Math.max(...lats);
  const scale = 400 / Math.max((Math.max(...lons) - minLon) * COS, maxLat - Math.min(...lats));
  return ([lon, lat]) => [scale * COS * (lon - minLon), scale * (maxLat - lat)];
}

const path = (pts) => pts.map((p, i) => (i ? 'L' : 'M') + f(p[0]) + ' ' + f(p[1])).join(' ');

function rings(occ, factors) {
  const cx = occ.reduce((s, p) => s + p[0], 0) / occ.length;
  const cy = occ.reduce((s, p) => s + p[1], 0) / occ.length;
  return factors.map((k) => occ.map(([x, y]) => [cx + (x - cx) * k, cy + (y - cy) * k]));
}

const ascii = (s) => s.replace(/[łŁ]/g, (c) => (c === 'ł' ? 'l' : 'L')).normalize('NFD').replace(/[̀-ͯ]/g, '');
const ROUTE_LABEL = (name) => (/far east/i.test(name) ? 'FE' : /north/i.test(name) ? 'N' : /east/i.test(name) ? 'E' : /south/i.test(name) ? 'S' : /west/i.test(name) ? 'W' : '');
const PIN_DELAYS = [0, 1.4, 0.35, 0, 1.4, 0.35, 0, 2.1, 1.05, 0.7, 0.35, 0, 2.1];

export function buildTiles(MAP) {
  const P = projection(MAP);
  const line = (k) => MAP.lines.filter((l) => l.k === k).map((l) => ({ ...l, p: l.c.map(P) }));
  const occ = line('occ')[0], rus = line('rus')[0], routes = line('esc');
  const pts = (k) => MAP.pts.filter((p) => p.k === k).map((p) => ({ ...p, q: P([p.x, p.y]) }));
  const outs = pts('out'), nodes = pts('node'), gates = pts('gate'), occupier = pts('rus'), other = pts('kos');

  // The Ground
  let g = '<svg class="gfx map" viewBox="-30 -30 460 440" aria-hidden="true">';
  if (rus) g += `<path d="${path(rus.p)}" class="rusline"/>`;
  if (occ) {
    g += `<path d="${path(occ.p)}" class="occ"/>`;
    rings(occ.p, [0.82, 0.64, 0.46, 0.28]).forEach((r, i) => { g += `<path d="${path(r)}" class="cont" style="--i:${i}"/>`; });
  }
  routes.forEach((r, i) => { g += `<path d="${path(r.p)}" class="route" style="--i:${i}"/>`; });
  outs.forEach((p, i) => {
    const [x, y] = p.q.map(f);
    g += `<g class="pin" style="--d:${PIN_DELAYS[i % PIN_DELAYS.length].toFixed(2)}s"><circle cx="${x}" cy="${y}" r="13" class="ring"/><circle cx="${x}" cy="${y}" r="4.6" class="tdot"/></g>`;
  });
  nodes.forEach((p) => { g += `<circle cx="${f(p.q[0])}" cy="${f(p.q[1])}" r="3.4" class="node"/>`; });
  gates.forEach((p) => { g += `<rect x="${f(p.q[0] - 4.5)}" y="${f(p.q[1] - 4.5)}" width="9" height="9" class="gate"/>`; });
  other.forEach((p) => { g += `<path d="M${f(p.q[0])} ${f(p.q[1] - 5)}l5 5-5 5-5-5z" class="kos"/>`; });
  occupier.forEach((p) => { g += `<path d="M${f(p.q[0] - 5)} ${f(p.q[1] - 5)}l10 10m0-10l-10 10" class="x"/>`; });
  g += '</svg>';

  // Ways Out: one dot travels each route; a still dot stands in when motion is reduced.
  let w = '<svg class="gfx esc" viewBox="-30 -30 460 440" aria-hidden="true">';
  if (occ) {
    w += `<path d="${path(occ.p)}" class="eocc"/>`;
    rings(occ.p, [0.55, 0.2]).forEach((r) => { w += `<path d="${path(r)}" class="econt"/>`; });
  }
  routes.forEach((r, i) => {
    const id = `tl-rt${i}`;
    const end = r.p[r.p.length - 1];
    const near = gates.length ? gates.reduce((a, b) => (Math.hypot(a.q[0] - end[0], a.q[1] - end[1]) <= Math.hypot(b.q[0] - end[0], b.q[1] - end[1]) ? a : b)).q : end;
    const mid = r.p[Math.floor(r.p.length / 2)];
    w += `<path id="${id}" d="${path(r.p)}" class="rline" style="--i:${i}"/>`;
    w += `<circle r="3.6" class="rdot"><animateMotion dur="${(7 + 1.3 * i).toFixed(1)}s" begin="${(0.9 * i).toFixed(1)}s" repeatCount="indefinite" rotate="auto"><mpath href="#${id}"/></animateMotion></circle>`;
    w += `<circle cx="${f(mid[0])}" cy="${f(mid[1])}" r="3.6" class="rdot still"/>`;
    w += `<text x="${Math.round(near[0])}" y="${Math.round(near[1])}" class="rl">${ROUTE_LABEL(r.n)}</text>`;
  });
  w += '</svg>';

  const first = outs[0];
  const coord = first ? `${first.y.toFixed(2)}°N ${first.x.toFixed(2)}°E · ${ascii(first.n.split(',')[0]).toUpperCase()}` : '';
  return { ground: g, ways: w, coord, routes: routes.length };
}

// "Four ways in": the Map card. A close crop of the corridor with a survey
// grid, and a reticle that moves between four outposts, pausing on each.
// The reticle's keyframes come from the real outpost positions, so they are
// written into the SVG here; the readout lines under it change in step.
export function buildScan(MAP) {
  const P = projection(MAP);
  const line = (k) => MAP.lines.filter((l) => l.k === k).map((l) => ({ ...l, p: l.c.map(P) }));
  const occ = line('occ')[0], routes = line('esc');
  const outs = MAP.pts.filter((p) => p.k === 'out').map((p) => ({ ...p, q: P([p.x, p.y]) }));
  const rus = MAP.pts.filter((p) => p.k === 'rus').map((p) => ({ ...p, q: P([p.x, p.y]) }));
  const pick = ['Z1', 'S1', 'G1', 'F1'].map((c) => outs.find((o) => o.c === c)).filter(Boolean);
  const stops = pick.length >= 2 ? pick : outs.slice(0, 4);
  const cx = stops.reduce((s, o) => s + o.q[0], 0) / stops.length, cy = stops.reduce((s, o) => s + o.q[1], 0) / stops.length;
  const W = 230, H = 170, x0 = cx - W / 2, y0 = cy - H / 2;
  let s = `<svg class="gfx scan" viewBox="${f(x0)} ${f(y0)} ${W} ${H}" preserveAspectRatio="xMidYMid slice" aria-hidden="true">`;
  const n = stops.length, dur = 3.2 * n;
  let kf = '@keyframes tl-scan{';
  stops.forEach((o, i) => {
    const a = (i / n) * 100, b = a + (100 / n) * 0.62, t = `translate(${f(o.q[0])}px,${f(o.q[1])}px)`;
    kf += `${a.toFixed(2)}%,${b.toFixed(2)}%{transform:${t}}`;
  });
  kf += `100%{transform:translate(${f(stops[0].q[0])}px,${f(stops[0].q[1])}px)}}`;
  let rd = '@keyframes tl-read{';
  stops.forEach((o, i) => {
    const a = (i / n) * 100 + (100 / n) * 0.0, b = ((i + 1) / n) * 100 - 0.01;
    rd += `${a.toFixed(2)}%,${b.toFixed(2)}%{transform:translateY(${-i * 100 / n}%)}`;
  });
  rd += '}';
  s += `<style>${kf}${rd}.tiles .scan .ret{animation:tl-scan ${dur}s cubic-bezier(.65,0,.35,1) infinite;transform:translate(${f(stops[0].q[0])}px,${f(stops[0].q[1])}px)}.tiles .rdo .rl2{animation:tl-read ${dur}s steps(1,end) infinite}</style>`;
  for (let gx = Math.floor(x0 / 20) * 20; gx < x0 + W + 20; gx += 20) s += `<path d="M${gx} ${f(y0 - 20)}V${f(y0 + H + 20)}" class="sgr"/>`;
  for (let gy = Math.floor(y0 / 20) * 20; gy < y0 + H + 20; gy += 20) s += `<path d="M${f(x0 - 20)} ${gy}H${f(x0 + W + 20)}" class="sgr"/>`;
  if (occ) {
    s += `<path d="${path(occ.p)}Z" class="socc"/>`;
    rings(occ.p, [0.8, 0.6, 0.4, 0.2]).forEach((r) => { s += `<path d="${path(r)}Z" class="scont"/>`; });
  }
  routes.forEach((r) => { s += `<path d="${path(r.p)}" class="srt"/>`; });
  rus.forEach((p) => { const [x, y] = p.q; s += `<path d="M${f(x - 3)} ${f(y - 3)}l6 6m0-6l-6 6" class="sx"/>`; });
  outs.forEach((p) => { const [x, y] = p.q.map(f); s += `<circle cx="${x}" cy="${y}" r="5" class="sring"/><circle cx="${x}" cy="${y}" r="2.2" class="sdot"/>`; });
  s += `<g class="ret"><path d="M-400 0H-9M9 0H400M0 -400V-9M0 9V400" class="rx"/><rect x="-8" y="-8" width="16" height="16" class="rb"/><circle r="11" class="rp"/></g>`;
  s += '</svg>';
  const ascii = (t) => t.replace(/[łŁ]/g, (c) => (c === 'ł' ? 'l' : 'L')).normalize('NFD').replace(/[̀-ͯ]/g, '');
  const read = stops.map((o) => `${o.y.toFixed(2)}°N ${o.x.toFixed(2)}°E · ${o.c} ${ascii(o.n.split(',')[0]).toUpperCase()}`);
  return { scan: s, scanRead: read };
}
