-- Tuning, and private fields.
--
-- 1. Tuning: a key fact for characters, chosen from a list of options. The
--    options live in public.tunings so the admin can rename and reorder
--    them (Tuning options page). A character stores the option's code, so a
--    rename never loses a choice. The site shows the option's label.
--
-- 2. Private fields: facts that only the owner can read. They are kept in
--    their own tables, outside every table the public key can read, so
--    they can never reach the site, the release data or the public API.
--    The admin loads the field names from the database after sign-in, so
--    they are not in the admin's page code either.
--
-- 3. The character fact that was shown on the site as a theme becomes a
--    private field. Every stored value is copied over unchanged before the
--    old column is removed. The full database was backed up first, in the
--    private schema backup_20261110_tuning.

begin;

-- ---------------------------------------------------------------------------
-- 1. Tuning options
-- ---------------------------------------------------------------------------
create table public.tunings (
  code        text primary key,           -- never shown; stays the same when the label changes
  label       text not null unique,       -- shown on the site
  position    int not null,               -- order in the admin
  updated_at  timestamptz not null default now()
);
insert into public.tunings (code, label, position) values
  ('unison',             'Unison',              1),
  ('echo',               'Echo',                2),
  ('discord',            'Discord',             3),
  ('rest',               'Rest',                4),
  ('canon',              'Canon',               5),
  ('mute',               'Mute',                6),
  ('counterpoint',       'Counterpoint',        7),
  ('borrowed_chord',     'Borrowed chord',      8),
  ('false_note',         'False note',          9),
  ('sympathetic_string', 'Sympathetic string', 10);
alter table public.tunings enable row level security;
create policy "Public read" on public.tunings for select using (true);
create policy "Owner write" on public.tunings for all to authenticated
  using (public.is_owner()) with check (public.is_owner());

-- Empty = "Not recorded". An option in use cannot be deleted.
alter table public.character_facts
  add column tuning text references public.tunings (code) on update cascade on delete restrict;

-- The admin's Save button for the Tuning options page: the whole list, in
-- order, in one transaction. A row without a code is a new option. An
-- option left out of the list is deleted, unless a character still uses it.
create or replace function public.save_tunings(p jsonb)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  before  jsonb := (select coalesce(jsonb_object_agg(code, label), '{}') from tunings);
  x       jsonb;
  i       int := 0;
  c       text;
  l       text;
  keep    text[] := '{}';
begin
  if not public.is_owner() then
    raise exception 'This account cannot edit the archive.';
  end if;
  -- Park every label first, so two options can swap names.
  update tunings set label = '~' || code;
  for x in select * from jsonb_array_elements(p) loop
    i := i + 1;
    l := trim(coalesce(x->>'label', ''));
    if l = '' then raise exception 'Option % has no name.', i; end if;
    c := nullif(x->>'code', '');
    if c is null then
      c := trim(both '_' from regexp_replace(lower(l), '[^a-z0-9]+', '_', 'g'));
      if c = '' then c := 'option'; end if;
      while exists (select 1 from tunings where code = c) or c = any (keep) loop
        c := c || '_' || i;
      end loop;
      insert into tunings (code, label, position) values (c, l, i);
    else
      update tunings set label = l, position = i,
        updated_at = case when before->>c is distinct from l then now() else updated_at end
      where code = c;
      if not found then raise exception 'Option % no longer exists. Reload the page.', i; end if;
    end if;
    keep := keep || c;
  end loop;
  begin
    delete from tunings where code <> all (keep);
  exception when foreign_key_violation then
    raise exception 'An option you removed is still chosen for a character. Choose another option on that character first.';
  end;
end;
$$;
revoke execute on function public.save_tunings(jsonb) from public, anon;
grant execute on function public.save_tunings(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Private fields: owner only
-- ---------------------------------------------------------------------------
create table public.private_fields (
  code      text primary key,
  category  text not null references public.categories (code),
  label     text not null,
  help      text,
  position  int not null default 0
);
create table public.private_values (
  ref    text not null references public.entries (ref) on update cascade on delete cascade,
  field  text not null references public.private_fields (code) on update cascade on delete restrict,
  value  text not null,
  primary key (ref, field)
);
alter table public.private_fields enable row level security;
alter table public.private_values enable row level security;
create policy "Owner only" on public.private_fields for all to authenticated
  using (public.is_owner()) with check (public.is_owner());
create policy "Owner only" on public.private_values for all to authenticated
  using (public.is_owner()) with check (public.is_owner());
-- No public access at all, not even to the table definitions.
revoke all on public.private_fields, public.private_values from public, anon;

-- ---------------------------------------------------------------------------
-- 3. The old character theme becomes a private field
-- ---------------------------------------------------------------------------
insert into public.private_fields (code, category, label, help, position) values
  ('commandment', 'CHR', 'Commandment (private)', 'Never shown on the site.', 1);

insert into public.private_values (ref, field, value)
  select ref, 'commandment', commandment_theme from public.character_facts
  where commandment_theme is not null;

-- Stop if anything was not copied exactly.
do $$
begin
  if exists (
    select 1 from public.character_facts c
    left join public.private_values v on v.ref = c.ref and v.field = 'commandment'
    where c.commandment_theme is distinct from v.value
  ) then
    raise exception 'A stored value was not copied exactly. Nothing has been changed.';
  end if;
end;
$$;

alter table public.character_facts drop column commandment_theme;

-- ---------------------------------------------------------------------------
-- 4. Saving and history
-- ---------------------------------------------------------------------------
create or replace function public.save_entry(p jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  e   jsonb := p->'entry';
  f   jsonb := coalesce(p->'facts', '{}'::jsonb);
  r   text  := nullif(p->>'ref', '');
  t   text;
  cur timestamptz;
  x   jsonb;
  k   text;
  i   int;
begin
  if not public.is_owner() then
    raise exception 'This account cannot edit the archive.';
  end if;

  if r is null then
    t := p->>'type';
    insert into entries (type, name, summary, entry, status, published)
    values (t, coalesce(e->>'name', ''), coalesce(e->>'summary', ''), coalesce(e->>'entry', ''), 'Draft', false)
    returning ref into r;
  else
    select type, updated_at into t, cur from entries where ref = r for update;
    if t is null then raise exception 'Entry % does not exist.', r; end if;
    if p ? 'expected_updated_at' and cur is distinct from (p->>'expected_updated_at')::timestamptz then
      raise exception 'This entry was changed somewhere else since you opened it. Reload it to see the newer version.';
    end if;
  end if;

  update entries set
    name                  = e->>'name',
    aliases               = nullif(trim(e->>'aliases'), ''),
    mark                  = nullif(e->>'mark', ''),
    grade                 = nullif(e->>'grade', ''),
    source_count          = nullif(e->>'source_count', '')::int,
    summary               = coalesce(e->>'summary', ''),
    entry                 = coalesce(e->>'entry', ''),
    appears_in            = nullif(trim(e->>'appears_in'), ''),
    reliability           = nullif(trim(e->>'reliability'), ''),
    cross_references_note = nullif(trim(e->>'cross_references_note'), ''),
    archivist_note        = nullif(trim(e->>'archivist_note'), ''),
    status                = coalesce(nullif(e->>'status', ''), 'Draft'),
    published             = coalesce((e->>'published')::boolean, true),
    featured_order        = nullif(e->>'featured_order', '')::int,
    icon                  = nullif(e->>'icon', ''),
    lottie                = nullif(e->>'lottie', ''),
    updated_at            = now()
  where ref = r;

  -- Key facts: one row per entry, in the table for its category.
  case t
    when 'LOC' then
      update location_facts set
        control = nullif(f->>'control', ''), ground_class = nullif(f->>'ground_class', ''),
        function = nullif(trim(f->>'function'), ''),
        lon = nullif(f->>'lon', '')::float8, lat = nullif(f->>'lat', '')::float8,
        coords_approximate = coalesce((f->>'coords_approximate')::boolean, false),
        water_condition = nullif(trim(f->>'water_condition'), ''), events = nullif(trim(f->>'events'), '')
      where ref = r;
    when 'CHR' then
      update character_facts set
        age = nullif(trim(f->>'age'), ''), age_grade = nullif(f->>'age_grade', ''),
        role = nullif(trim(f->>'role'), ''), group_name = nullif(trim(f->>'group_name'), ''),
        -- Only when the admin sends it, so an older copy of the admin cannot clear it.
        tuning = case when f ? 'tuning' then nullif(f->>'tuning', '') else tuning end,
        first_appearance = nullif(f->>'first_appearance', ''), own_protocol = nullif(f->>'own_protocol', ''),
        distinguishing_trait = nullif(trim(f->>'distinguishing_trait'), ''), fate = nullif(trim(f->>'fate'), '')
      where ref = r;
    when 'OBJ' then
      update object_facts set
        object_type = nullif(f->>'object_type', ''), holder = nullif(trim(f->>'holder'), ''),
        origin = nullif(trim(f->>'origin'), ''), function = nullif(trim(f->>'function'), ''),
        last_seen = nullif(trim(f->>'last_seen'), '')
      where ref = r;
    when 'LOR' then
      update lore_facts set
        lore_type = nullif(f->>'lore_type', ''), period = nullif(trim(f->>'period'), ''),
        parties = nullif(trim(f->>'parties'), ''), consequences = nullif(trim(f->>'consequences'), '')
      where ref = r;
  end case;

  -- Lists are replaced whole, in the order given.
  if p ? 'appearances' then
    delete from entry_appearances where entry_ref = r;
    i := -1;
    for x in select * from jsonb_array_elements(p->'appearances') loop
      i := i + 1;
      insert into entry_appearances (entry_ref, section, position) values (r, x #>> '{}', i);
    end loop;
  end if;

  if p ? 'relations' then
    delete from relations where from_ref = r;
    i := -1;
    for x in select * from jsonb_array_elements(p->'relations') loop
      i := i + 1;
      if not exists (select 1 from entries where ref = x->>'to_ref') then
        raise exception 'Relation % points to %, which is not an entry.', i + 1, x->>'to_ref';
      end if;
      insert into relations (from_ref, to_ref, type, position, note)
      values (r, x->>'to_ref', x->>'type', i, nullif(trim(x->>'note'), ''));
    end loop;
  end if;

  if p ? 'images' then
    delete from entry_images where entry_ref = r;
    i := -1;
    for x in select * from jsonb_array_elements(p->'images') loop
      i := i + 1;
      insert into entry_images (entry_ref, file, alt, caption, credit, position)
      values (r, x->>'file', nullif(trim(x->>'alt'), ''), nullif(trim(x->>'caption'), ''), nullif(trim(x->>'credit'), ''), i);
    end loop;
  end if;

  if p ? 'audio' then
    delete from entry_audio where entry_ref = r;
    i := -1;
    for x in select * from jsonb_array_elements(p->'audio') loop
      i := i + 1;
      insert into entry_audio (entry_ref, file, label, meta, note, position)
      values (r, x->>'file', nullif(trim(x->>'label'), ''), nullif(trim(x->>'meta'), ''), nullif(trim(x->>'note'), ''), i);
    end loop;
  end if;

  if p ? 'video' then
    delete from entry_video where entry_ref = r;
    i := -1;
    for x in select * from jsonb_array_elements(p->'video') loop
      i := i + 1;
      insert into entry_video (entry_ref, file, caption, position)
      values (r, x->>'file', nullif(trim(x->>'caption'), ''), i);
    end loop;
  end if;

  if p ? 'files' then
    delete from entry_files where entry_ref = r;
    i := -1;
    for x in select * from jsonb_array_elements(p->'files') loop
      i := i + 1;
      insert into entry_files (entry_ref, file, label, page_count, position)
      values (r, x->>'file', nullif(trim(x->>'label'), ''), nullif(x->>'page_count', '')::int, i);
    end loop;
  end if;

  -- Private fields (migration 011): owner only, never exported. Only the
  -- fields sent are changed; an empty value removes the stored one.
  if jsonb_typeof(p->'private') = 'object' then
    for k in select jsonb_object_keys(p->'private') loop
      if not exists (select 1 from private_fields where code = k and category = t) then
        raise exception 'There is no private field % for this kind of entry.', k;
      end if;
      if coalesce(trim(p->'private'->>k), '') = '' then
        delete from private_values where ref = r and field = k;
      else
        insert into private_values (ref, field, value) values (r, k, p->'private'->>k)
        on conflict (ref, field) do update set value = excluded.value;
      end if;
    end loop;
  end if;

  if p ? 'editor_note' then
    if coalesce(trim(p->>'editor_note'), '') = '' then
      delete from editor_notes where ref = r;
    else
      insert into editor_notes (ref, note) values (r, p->>'editor_note')
      on conflict (ref) do update set note = excluded.note;
    end if;
  end if;

  -- Keep this version in the history (migration 010).
  perform public.record_entry_revision(r);

  return (select jsonb_build_object('ref', ref, 'slug', slug, 'updated_at', updated_at) from entries where ref = r);
end;
$$;


revoke execute on function public.save_entry(jsonb) from public, anon;
grant execute on function public.save_entry(jsonb) to authenticated;

-- Entry versions include the private fields. Versions are owner only.
create or replace function public.entry_snapshot(r text)
returns jsonb
language sql
stable
set search_path = public
as $$
  select jsonb_build_object(
    'ref', e.ref,
    'type', e.type,
    'entry', to_jsonb(e) - 'created_at' - 'updated_at',
    'facts', coalesce(
      (select to_jsonb(f) - 'ref' from location_facts f where f.ref = r),
      (select to_jsonb(f) - 'ref' from character_facts f where f.ref = r),
      (select to_jsonb(f) - 'ref' from object_facts f where f.ref = r),
      (select to_jsonb(f) - 'ref' from lore_facts f where f.ref = r), '{}'::jsonb),
    'appearances', coalesce((select jsonb_agg(section order by position) from entry_appearances where entry_ref = r), '[]'),
    'relations', coalesce((select jsonb_agg(jsonb_build_object('type', type, 'to_ref', to_ref, 'note', note) order by position) from relations where from_ref = r), '[]'),
    'images', coalesce((select jsonb_agg(jsonb_build_object('file', file, 'alt', alt, 'caption', caption, 'credit', credit) order by position, id) from entry_images where entry_ref = r), '[]'),
    'audio', coalesce((select jsonb_agg(jsonb_build_object('file', file, 'label', label, 'meta', meta, 'note', note) order by position, id) from entry_audio where entry_ref = r), '[]'),
    'video', coalesce((select jsonb_agg(jsonb_build_object('file', file, 'caption', caption) order by position, id) from entry_video where entry_ref = r), '[]'),
    'files', coalesce((select jsonb_agg(jsonb_build_object('file', file, 'label', label, 'page_count', page_count) order by position, id) from entry_files where entry_ref = r), '[]'),
    'editor_note', (select note from editor_notes where ref = r),
    'private', coalesce((select jsonb_object_agg(field, value) from private_values where ref = r), '{}'))
  from entries e where e.ref = r;
$$;
revoke execute on function public.entry_snapshot(text) from public, anon;
grant execute on function public.entry_snapshot(text) to authenticated;

commit;
