-- Syren Codex: story structure and sidebar groups (schema change 004)
-- From reference/ENTRY_PROTOCOL.md, sections 8 and 9. Adds to existing
-- tables; changes no entry text.

begin;

-- The seven collapsible groups of the Story sidebar (section 8).
create table public.story_groups (
  code      text primary key,
  name      text not null,
  position  int  not null
);
insert into public.story_groups (code, name, position) values
  ('before', 'Before the story',          1),
  ('part-1', 'Part 1 · The Zone',         2),
  ('part-2', 'Part 2 · The Occupation',   3),
  ('part-3', 'Part 3 · The Dendron',      4),
  ('part-4', 'Part 4 · The Codex',        5),
  ('part-5', 'Part 5 · The Aftermath',    6),
  ('after',  'After the story',           7);

-- The chapter table: order (position), kind, full title (from the
-- manuscript heading), short label and group, one row per section.
alter table public.story_sections
  add column kind        text check (kind in ('front', 'prologue', 'diary', 'chapter',
                                              'interlude', 'protocol', 'back', 'appendix')),
  add column label       text,
  add column group_code  text references public.story_groups (code) on update cascade;

-- Sidebar names for the taxonomy marks (sections 4 and 9).
alter table public.marks
  add column label     text,
  add column position  int;
update public.marks m set label = v.label, position = v.position
from (values
  ('PROX_SCAN',    'Survivor outposts',      1),
  ('TRIGGER_V1',   'Russian positions',      2),
  ('ACT_SYNC',     'Escape routes',          3),
  ('CHROMA_VAL',   'Primary',                1),
  ('TORUS_VAL',    'Secondary',              2),
  ('GRID_FAIL',    'Antagonists',            3),
  ('SHIFT_REF_04', 'Dust',                   1),
  ('MAG_REF_400',  'Dendron and Entity',     2),
  ('LINK_SYNC',    'Communications',         3),
  ('FLUX_SYNC',    'Diaries and documents',  4),
  ('LOAD_STRESS',  null,                     1),
  ('DIFF_REF_89',  'Historical parallels',   2),
  ('REF_SYNC_400', 'Cross-references',       3),
  ('PORE_SEQ',     'Zone vocabulary',        4)
) as v(code, label, position)
where m.code = v.code;

alter table public.story_groups enable row level security;
create policy "Public read" on public.story_groups for select using (true);
create policy "Owner write" on public.story_groups for all to authenticated
  using (public.is_owner()) with check (public.is_owner());

commit;
