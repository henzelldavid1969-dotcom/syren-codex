-- Stage 3 of the admin: version history and the media library.
--
-- revisions: every saved version of an entry, a Story section and the site
-- copy. The admin lists them and can load an earlier version back into the
-- editor, where saving it restores it. Entry versions include the private
-- editor note, so only the owner can read them.
--
-- An entry version has the same shape as the admin's Save (save_entry), so
-- restoring is simply saving it again.

begin;

create table public.revisions (
  id          bigint generated always as identity primary key,
  kind        text not null check (kind in ('entry', 'section', 'content')),
  key         text not null,
  data        json not null,   -- json keeps the order of the copy
  created_at  timestamptz not null default now(),
  created_by  uuid default auth.uid(),
  note        text
);
create index revisions_by_key on public.revisions (kind, key, id desc);
alter table public.revisions enable row level security;
create policy "Owner read" on public.revisions for select to authenticated using (public.is_owner());
create policy "Owner insert" on public.revisions for insert to authenticated with check (public.is_owner());

-- One entry as a whole: its fields, key facts, lists, media and note.
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
    'editor_note', (select note from editor_notes where ref = r))
  from entries e where e.ref = r;
$$;
revoke execute on function public.entry_snapshot(text) from public, anon;
grant execute on function public.entry_snapshot(text) to authenticated;

-- Record an entry version, unless it is the same as the last one.
create or replace function public.record_entry_revision(r text)
returns void
language plpgsql
set search_path = public
as $$
declare snap jsonb := public.entry_snapshot(r);
begin
  if snap is null then return; end if;
  if (select data::jsonb from revisions where kind = 'entry' and key = r order by id desc limit 1) is distinct from snap then
    insert into revisions (kind, key, data) values ('entry', r, snap::json);
  end if;
end;
$$;

-- Story sections and site copy: a trigger records each saved version.
create or replace function public.record_row_revision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_table_name = 'story_sections' then
    if tg_op = 'UPDATE' and (old.title, old.label, old.kind, old.group_code, old.body)
       is not distinct from (new.title, new.label, new.kind, new.group_code, new.body) then
      return new;
    end if;
    insert into revisions (kind, key, data) values ('section', new.slug,
      json_build_object('title', new.title, 'label', new.label, 'kind', new.kind, 'group_code', new.group_code, 'body', new.body));
  else
    if tg_op = 'UPDATE' and old.data::text = new.data::text then return new; end if;
    insert into revisions (kind, key, data) values ('content', new.key, json_build_object('data', new.data));
  end if;
  return new;
end;
$$;
create trigger story_sections_revision after insert or update on public.story_sections
  for each row execute function public.record_row_revision();
create trigger site_content_revision after insert or update on public.site_content
  for each row execute function public.record_row_revision();

-- The starting version of everything, so there is something to go back to.
insert into revisions (kind, key, data, note)
  select 'entry', ref, public.entry_snapshot(ref)::json, 'Starting version' from entries order by ref;
insert into revisions (kind, key, data, note)
  select 'section', slug, json_build_object('title', title, 'label', label, 'kind', kind, 'group_code', group_code, 'body', body), 'Starting version'
  from story_sections order by position;
insert into revisions (kind, key, data, note)
  select 'content', key, json_build_object('data', data), 'Starting version' from site_content order by key;

-- Media library: every file in the five buckets, for the owner only.
create or replace function public.media_files()
returns table (bucket text, name text, size bigint, mimetype text, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = public, storage
as $$
begin
  if not public.is_owner() then raise exception 'This account cannot see the media library.'; end if;
  return query
    select o.bucket_id::text, o.name::text, (o.metadata->>'size')::bigint, (o.metadata->>'mimetype')::text, o.created_at
    from storage.objects o
    where o.bucket_id in ('images', 'audio', 'video', 'files', 'lottie') and o.name not like '%.emptyFolderPlaceholder'
    order by o.created_at desc;
end;
$$;
revoke execute on function public.media_files() from public, anon;
grant execute on function public.media_files() to authenticated;

-- Deleting a file through the storage service needs read access as well.
create policy "Owner read" on storage.objects for select to authenticated
  using (bucket_id in ('images', 'audio', 'video', 'files', 'lottie') and public.is_owner());

commit;
