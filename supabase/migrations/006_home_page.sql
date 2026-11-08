-- Syren Codex: home page data (schema change 006). Additive only.

begin;

-- "Popular searches": a curated list until there is real usage data.
-- 1 shows first. Empty means the entry is not featured.
alter table public.entries
  add column featured_order int check (featured_order > 0);
update public.entries e set featured_order = v.n
from (values ('SYNPTCL/CHR/001', 1), ('SYNPTCL/OBJ/001', 2), ('SYNPTCL/OBJ/002', 3),
             ('SYNPTCL/LOR/001', 4), ('SYNPTCL/LOC/001', 5), ('SYNPTCL/OBJ/003', 6)) as v(ref, n)
where e.ref = v.ref;

-- The factions strip. mark_file is an SVG in the images bucket (drawn with
-- currentColor so it follows light and dark mode). Without a mark, the
-- site shows the name instead.
create table public.factions (
  id         bigint generated always as identity primary key,
  position   int  not null,
  name       text not null,
  slug       text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  mark_file  text,
  entry_ref  text references public.entries (ref) on update cascade on delete set null
);
insert into public.factions (position, name, slug, entry_ref) values
  ( 1, 'Survivor community', 'survivor-community', null),
  ( 2, 'The Runners',        'the-runners',        'SYNPTCL/CHR/017'),
  ( 3, 'Kościuszko group',   'kosciuszko-group',   null),
  ( 4, 'The Occupation',     'the-occupation',     null),
  ( 5, 'Faction 05', 'faction-05', null), ( 6, 'Faction 06', 'faction-06', null),
  ( 7, 'Faction 07', 'faction-07', null), ( 8, 'Faction 08', 'faction-08', null),
  ( 9, 'Faction 09', 'faction-09', null), (10, 'Faction 10', 'faction-10', null),
  (11, 'Faction 11', 'faction-11', null), (12, 'Faction 12', 'faction-12', null);

alter table public.factions enable row level security;
create policy "Public read" on public.factions for select using (true);
create policy "Owner write" on public.factions for all to authenticated
  using (public.is_owner()) with check (public.is_owner());

commit;
