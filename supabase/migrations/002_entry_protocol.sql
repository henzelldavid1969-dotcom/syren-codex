-- Syren Codex: Entry Protocol v0.1 (schema change 002)
-- Builds the database fields from reference/ENTRY_PROTOCOL.md.
-- Runs in one transaction: if any step fails, nothing changes.
-- Keeps every existing table and entry. Adds fields, tables and rules.

begin;

-- ===========================================================================
-- 1. Core fields on entries (protocol section 1)
-- ===========================================================================

alter table public.entries
  add column aliases         text,            -- other names, separated by semicolons
  add column source_count    int check (source_count >= 0),
  add column archivist_note  text;            -- shown to readers, optional

-- Status becomes Draft, Filed or Verified. Any longer working note in the old
-- status text is kept, word for word, in editor_notes (section 9 below).
create table public.editor_notes (
  ref   text primary key references public.entries (ref) on update cascade on delete cascade,
  note  text not null
);
insert into public.editor_notes (ref, note)
  select ref, status from public.entries
  where status is not null and status !~ '^(Draft|Filed|Verified)\.?$';
update public.entries set status = coalesce(substring(status from '^(Draft|Filed|Verified)'), 'Draft');
alter table public.entries
  alter column status set default 'Draft',
  alter column status set not null,
  add constraint entries_status_check check (status in ('Draft', 'Filed', 'Verified'));

-- Icon: one name from the site's icon set (or leave empty and use lottie).
alter table public.entries
  add constraint entries_icon_check check (icon is null or icon in
    ('pin', 'user', 'cube', 'waves', 'book', 'map', 'compass', 'route',
     'shield', 'image', 'audio', 'play', 'file'));

-- Taxonomy marks named in the protocol that were not yet listed.
insert into public.marks (code, category) values
  ('LINK_SYNC', 'OBJ'), ('REF_SYNC_400', 'LOR')
on conflict do nothing;

-- ===========================================================================
-- 2. References are assigned by the database, never typed, never reused
-- ===========================================================================

create table public.ref_counters (
  type         text primary key references public.categories (code),
  last_number  int not null
);
insert into public.ref_counters (type, last_number)
  select c.code, coalesce(max(right(e.ref, 3)::int), 0)
  from public.categories c left join public.entries e on e.type = c.code
  group by c.code;

alter table public.entries alter column ref set default '';

create function public.assign_ref() returns trigger
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if new.ref is null or new.ref = '' then
    update ref_counters set last_number = last_number + 1
      where type = new.type returning last_number into n;
    new.ref := 'SYNPTCL/' || new.type || '/' || lpad(n::text, 3, '0');
  else
    update ref_counters set last_number = greatest(last_number, right(new.ref, 3)::int)
      where type = new.type;
  end if;
  return new;
end;
$$;
create trigger entries_assign_ref before insert on public.entries
for each row execute function public.assign_ref();

-- ===========================================================================
-- 3. Filed and Verified need the required fields (protocol section 6)
-- ===========================================================================

create function public.check_filed() returns trigger
language plpgsql as $$
begin
  if new.status in ('Filed', 'Verified') and (
       new.mark is null or new.grade is null
    or coalesce(trim(new.summary), '') = '' or coalesce(trim(new.entry), '') = ''
    or coalesce(trim(new.appears_in), '') = '' or coalesce(trim(new.reliability), '') = '') then
    raise exception 'An entry can only be % when mark, grade, summary, entry, appears_in and reliability are all filled in.', new.status;
  end if;
  return new;
end;
$$;
create trigger entries_check_filed before insert or update on public.entries
for each row execute function public.check_filed();

-- ===========================================================================
-- 4. Key facts, one table per category (protocol section 2)
--    A row is created automatically for every entry. Empty = "Not recorded".
-- ===========================================================================

create table public.location_facts (
  ref                 text primary key references public.entries (ref) on update cascade on delete cascade
                      check (ref like 'SYNPTCL/LOC/%'),
  control             text check (control in ('survivor', 'occupier', 'contested', 'neutral')),
  ground_class        text check (ground_class in ('A', 'B', 'C', 'D')),
  function            text,
  lon                 double precision check (lon between -180 and 180),
  lat                 double precision check (lat between -90 and 90),
  coords_approximate  boolean not null default false,
  water_condition     text,
  events              text
  -- "Who is here" is shown from the relations, so it has no column.
);

create table public.character_facts (
  ref                   text primary key references public.entries (ref) on update cascade on delete cascade
                        check (ref like 'SYNPTCL/CHR/%'),
  age                   text,
  age_grade             text check (age_grade in ('C', 'E', 'U')),
  role                  text,
  group_name            text,
  commandment_theme     text,
  first_appearance      text,   -- a story section, see story_sections
  own_protocol          text,   -- a story section, see story_sections
  distinguishing_trait  text,
  fate                  text
);

create table public.object_facts (
  ref          text primary key references public.entries (ref) on update cascade on delete cascade
               check (ref like 'SYNPTCL/OBJ/%'),
  object_type  text check (object_type in ('document', 'artefact', 'organism', 'substance')),
  holder       text,
  origin       text,
  function     text,
  last_seen    text
);

create table public.lore_facts (
  ref           text primary key references public.entries (ref) on update cascade on delete cascade
                check (ref like 'SYNPTCL/LOR/%'),
  lore_type     text check (lore_type in ('programme', 'event', 'concept', 'history')),
  period        text,
  parties       text,
  consequences  text
);

create function public.create_facts_row() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  case new.type
    when 'LOC' then insert into location_facts (ref) values (new.ref) on conflict do nothing;
    when 'CHR' then insert into character_facts (ref) values (new.ref) on conflict do nothing;
    when 'OBJ' then insert into object_facts (ref) values (new.ref) on conflict do nothing;
    when 'LOR' then insert into lore_facts (ref) values (new.ref) on conflict do nothing;
  end case;
  return new;
end;
$$;
create trigger entries_create_facts after insert on public.entries
for each row execute function public.create_facts_row();

insert into public.location_facts  (ref) select ref from public.entries where type = 'LOC';
insert into public.character_facts (ref) select ref from public.entries where type = 'CHR';
insert into public.object_facts    (ref) select ref from public.entries where type = 'OBJ';
insert into public.lore_facts      (ref) select ref from public.entries where type = 'LOR';

-- ===========================================================================
-- 5. Story sections and structured appearances (protocol sections 1 and 5)
-- ===========================================================================

create table public.story_sections (
  slug      text primary key,
  title     text not null,
  position  int not null
);

alter table public.character_facts
  add foreign key (first_appearance) references public.story_sections (slug) on update cascade on delete set null,
  add foreign key (own_protocol)     references public.story_sections (slug) on update cascade on delete set null;

create table public.entry_appearances (
  entry_ref  text not null references public.entries (ref) on update cascade on delete cascade,
  section    text not null references public.story_sections (slug) on update cascade on delete cascade,
  position   int not null default 0,
  primary key (entry_ref, section)
);

-- ===========================================================================
-- 6. Typed, two-way relations (protocol section 3)
--    Replaces entry_links. Each row shows on both entries.
-- ===========================================================================

create table public.relation_types (
  code           text primary key,
  label          text not null,   -- as read from the first entry
  inverse_label  text not null,   -- as read from the second entry
  position       int not null
);
insert into public.relation_types (code, label, inverse_label, position) values
  ('located_at',   'Located at',   'Location of',  1),
  ('lives_at',     'Lives at',     'Home of',      2),
  ('appears_with', 'Appears with', 'Appears with', 3),
  ('member_of',    'Member of',    'Members',      4),
  ('holds',        'Holds',        'Held by',      5),
  ('created_by',   'Created by',   'Created',      6),
  ('part_of',      'Part of',      'Includes',     7),
  ('opposes',      'Opposes',      'Opposed by',   8),
  ('mentioned_in', 'Mentioned in', 'Mentions',     9),
  ('connected',    'Connected',    'Connected',   10);  -- untyped, until a type is chosen

alter table public.entry_links rename to relations;
alter table public.relations
  add column type text not null default 'connected' references public.relation_types (code),
  add column note text,
  drop constraint entry_links_pkey,
  add primary key (from_ref, to_ref, type);

-- ===========================================================================
-- 7. Media: four separate fields (protocol section 1a)
--    Each row names a file uploaded to storage, or a full https:// address.
-- ===========================================================================

drop table public.entry_media;   -- empty; replaced by the four tables below

create table public.entry_images (           -- bucket: images. Up to 10. First is the cover.
  id         bigint generated always as identity primary key,
  entry_ref  text not null references public.entries (ref) on update cascade on delete cascade,
  file       text not null,
  alt        text,
  caption    text,
  credit     text,
  position   int not null default 0
);

create table public.entry_audio (            -- bucket: audio. WAV or MP3.
  id         bigint generated always as identity primary key,
  entry_ref  text not null references public.entries (ref) on update cascade on delete cascade,
  file       text not null,
  label      text,          -- for example Dry, Wet
  meta       text,          -- source, place, date, duration, format
  note       text,
  position   int not null default 0
);

create table public.entry_video (            -- bucket: video. MP4.
  id         bigint generated always as identity primary key,
  entry_ref  text not null references public.entries (ref) on update cascade on delete cascade,
  file       text not null,
  caption    text,
  position   int not null default 0
);

create table public.entry_files (            -- bucket: files. PDF first, other documents allowed.
  id          bigint generated always as identity primary key,
  entry_ref   text not null references public.entries (ref) on update cascade on delete cascade,
  file        text not null,
  label       text,
  page_count  int check (page_count > 0),
  position    int not null default 0
  -- The size is read from storage automatically (entry_files_view).
);

create index on public.entry_images (entry_ref);
create index on public.entry_audio (entry_ref);
create index on public.entry_video (entry_ref);
create index on public.entry_files (entry_ref);
create index on public.entry_appearances (section);

create function public.limit_images() returns trigger
language plpgsql as $$
begin
  if (select count(*) from public.entry_images where entry_ref = new.entry_ref and id <> coalesce(new.id, -1)) >= 10 then
    raise exception 'An entry can have at most 10 images.';
  end if;
  return new;
end;
$$;
create trigger entry_images_limit before insert or update on public.entry_images
for each row execute function public.limit_images();

-- File sizes, read from storage so they are always right.
create view public.entry_files_view as
  select f.*, (o.metadata ->> 'size')::bigint as size_bytes
  from public.entry_files f
  left join storage.objects o on o.bucket_id = 'files' and o.name = f.file;

-- ===========================================================================
-- 8. Storage: a new "files" bucket, and owner-only uploads to all five
-- ===========================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('files', 'files', true, 52428800, array[
    'application/pdf', 'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.oasis.opendocument.text', 'application/rtf', 'text/plain',
    'application/epub+zip']);

drop policy "Owner upload" on storage.objects;
drop policy "Owner update" on storage.objects;
drop policy "Owner delete" on storage.objects;
create policy "Owner upload" on storage.objects for insert to authenticated
  with check (bucket_id in ('images', 'audio', 'video', 'files', 'lottie') and public.is_owner());
create policy "Owner update" on storage.objects for update to authenticated
  using (bucket_id in ('images', 'audio', 'video', 'files', 'lottie') and public.is_owner());
create policy "Owner delete" on storage.objects for delete to authenticated
  using (bucket_id in ('images', 'audio', 'video', 'files', 'lottie') and public.is_owner());

-- ===========================================================================
-- 9. Access rules for the new tables: public read, owner write.
--    editor_notes and ref_counters are private: no public access at all.
-- ===========================================================================

do $$
declare t text;
begin
  foreach t in array array['location_facts', 'character_facts', 'object_facts', 'lore_facts',
                           'story_sections', 'entry_appearances', 'relation_types',
                           'entry_images', 'entry_audio', 'entry_video', 'entry_files'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "Public read" on public.%I for select using (true)', t);
    execute format('create policy "Owner write" on public.%I for all to authenticated using (public.is_owner()) with check (public.is_owner())', t);
  end loop;
end;
$$;
alter table public.editor_notes enable row level security;
alter table public.ref_counters enable row level security;

commit;
