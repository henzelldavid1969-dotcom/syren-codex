-- The admin's Save button for one entry: every field, key facts, appearances,
-- relations, media and the private editor note, in one transaction, so an
-- entry is never left half saved. Runs with the caller's rights, so the
-- database's own rules (owner only) still apply.
--
-- p.ref is null for a new entry; the database assigns the reference.
-- p.expected_updated_at guards against saving over a newer edit (for
-- example the same entry open in two tabs).

begin;

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
        commandment_theme = nullif(trim(f->>'commandment_theme'), ''),
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

commit;
