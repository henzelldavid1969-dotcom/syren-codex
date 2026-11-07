-- Syren Codex: database schema for Supabase (free plan).
-- Run once, in order. Safe to read top to bottom: every table is explained.
--
-- Access rule for every table and bucket: anyone may read; only the site
-- owner may write. Edits made in the Supabase dashboard (Table Editor and
-- Storage) always work, because the dashboard acts as the project owner.

begin;

-- ---------------------------------------------------------------------------
-- Owners. A list of user accounts allowed to write through the public API.
-- It starts empty, so for now only the dashboard can change anything.
-- ---------------------------------------------------------------------------
create table public.site_owners (
  user_id uuid primary key references auth.users (id) on delete cascade
);

create function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.site_owners where user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- Categories. The four sections of the archive and their taxonomy marks.
-- ---------------------------------------------------------------------------
create table public.categories (
  code        text primary key check (code in ('LOC', 'CHR', 'OBJ', 'LOR')),
  label       text not null,
  mark        text not null,
  sort_order  int  not null
);

-- ---------------------------------------------------------------------------
-- Marks. The sub-tags an entry can carry, each tied to one category.
-- Adding a new mark here makes it available in the entries table.
-- ---------------------------------------------------------------------------
create table public.marks (
  code      text primary key check (code ~ '^[A-Z0-9_.]+$'),
  category  text not null references public.categories (code),
  unique (code, category)
);

-- ---------------------------------------------------------------------------
-- Entries. One row per filed entry.
-- ref is the archive reference, for example SYNPTCL/CHR/001.
-- slug is worked out from ref automatically (chr-001) and is used in links.
-- ---------------------------------------------------------------------------
create table public.entries (
  ref                     text primary key
                          check (ref ~ '^SYNPTCL/(LOC|CHR|OBJ|LOR)/[0-9]{3}$'),
  type                    text not null references public.categories (code),
  slug                    text generated always as
                          (lower(type) || '-' || right(ref, 3)) stored unique,
  name                    text not null,
  mark                    text,
  grade                   text check (grade in ('C', 'E', 'U')),
  summary                 text not null,
  entry                   text not null,
  appears_in              text,
  reliability             text,
  cross_references_note   text,
  status                  text,
  icon                    text,   -- file name in the images bucket
  lottie                  text,   -- file name in the lottie bucket
  published               boolean not null default true,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  check (split_part(ref, '/', 2) = type),
  foreign key (mark, type) references public.marks (code, category)
);

-- ---------------------------------------------------------------------------
-- Cross-references. One row per link from one entry to another, in order.
-- ---------------------------------------------------------------------------
create table public.entry_links (
  from_ref  text not null references public.entries (ref)
            on update cascade on delete cascade,
  to_ref    text not null references public.entries (ref)
            on update cascade on delete cascade,
  position  int  not null default 0,
  primary key (from_ref, to_ref),
  check (from_ref <> to_ref)
);

-- ---------------------------------------------------------------------------
-- Media. Images, sound and video attached to an entry, with captions.
-- file is the file name in the matching bucket (images, audio or video),
-- or a full https:// address for a file kept elsewhere.
-- ---------------------------------------------------------------------------
create table public.entry_media (
  id         bigint generated always as identity primary key,
  entry_ref  text not null references public.entries (ref)
             on update cascade on delete cascade,
  kind       text not null check (kind in ('image', 'audio', 'video')),
  file       text not null,
  caption    text,
  position   int  not null default 0
);

-- ---------------------------------------------------------------------------
-- Map points. Codes may repeat (several route nodes share EN), so each
-- point has its own number as well.
-- ---------------------------------------------------------------------------
create table public.map_points (
  id         bigint generated always as identity primary key,
  code       text not null,
  name       text not null,
  kind       text not null
             check (kind in ('outpost', 'node', 'gate', 'occupier', 'other')),
  lon        double precision not null check (lon between -180 and 180),
  lat        double precision not null check (lat between -90 and 90),
  entry_ref  text references public.entries (ref)
             on update cascade on delete set null,
  note       text,
  position   int not null default 0
);

-- ---------------------------------------------------------------------------
-- Map lines. The two perimeters and four escape routes, as lists of
-- [longitude, latitude] pairs. Not edited by hand in normal use.
-- ---------------------------------------------------------------------------
create table public.map_lines (
  id           bigint generated always as identity primary key,
  kind         text not null
               check (kind in ('occupation_perimeter', 'russian_perimeter', 'escape_route')),
  name         text not null,
  coordinates  jsonb not null check (jsonb_typeof(coordinates) = 'array'),
  position     int not null default 0
);

create index on public.entries (type);
create index on public.entry_links (to_ref);
create index on public.entry_media (entry_ref);
create index on public.map_points (entry_ref);

-- Keep updated_at current on every edit to an entry.
create function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger entries_touch before update on public.entries
for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row-level security: public read, owner write.
-- Unpublished entries (published = false) are hidden from the public.
-- ---------------------------------------------------------------------------
alter table public.site_owners  enable row level security;
alter table public.categories   enable row level security;
alter table public.marks        enable row level security;
alter table public.entries      enable row level security;
alter table public.entry_links  enable row level security;
alter table public.entry_media  enable row level security;
alter table public.map_points   enable row level security;
alter table public.map_lines    enable row level security;

create policy "Public read" on public.categories  for select using (true);
create policy "Public read" on public.marks       for select using (true);
create policy "Public read" on public.entries     for select using (published or public.is_owner());
create policy "Public read" on public.entry_links for select using (true);
create policy "Public read" on public.entry_media for select using (true);
create policy "Public read" on public.map_points  for select using (true);
create policy "Public read" on public.map_lines   for select using (true);

create policy "Owner write" on public.categories  for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "Owner write" on public.marks       for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "Owner write" on public.entries     for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "Owner write" on public.entry_links for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "Owner write" on public.entry_media for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "Owner write" on public.map_points  for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "Owner write" on public.map_lines   for all to authenticated using (public.is_owner()) with check (public.is_owner());
-- site_owners has no public policies at all: it is managed from the dashboard.

-- ---------------------------------------------------------------------------
-- Storage buckets. All public to read. 50 MB per file, the free-plan ceiling.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('images', 'images', true, 52428800, array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml', 'image/avif']),
  ('audio',  'audio',  true, 52428800, array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/ogg', 'audio/wav', 'audio/x-wav', 'audio/webm', 'audio/flac']),
  ('video',  'video',  true, 52428800, array['video/mp4', 'video/webm', 'video/quicktime']),
  ('lottie', 'lottie', true, 52428800, array['application/json', 'application/zip']);

create policy "Owner upload" on storage.objects for insert to authenticated
  with check (bucket_id in ('images', 'audio', 'video', 'lottie') and public.is_owner());
create policy "Owner update" on storage.objects for update to authenticated
  using (bucket_id in ('images', 'audio', 'video', 'lottie') and public.is_owner());
create policy "Owner delete" on storage.objects for delete to authenticated
  using (bucket_id in ('images', 'audio', 'video', 'lottie') and public.is_owner());

-- ---------------------------------------------------------------------------
-- Fixed reference data: the four categories and the marks in use.
-- ---------------------------------------------------------------------------
insert into public.categories (code, label, mark, sort_order) values
  ('LOC', 'Locations',  'SYNC_PATH',    1),
  ('CHR', 'Characters', 'PROB_VAL_0.9', 2),
  ('OBJ', 'Objects',    'FLUX_LOCK_09', 3),
  ('LOR', 'Lore',       'ION_PATH',     4);

insert into public.marks (code, category) values
  ('PROX_SCAN', 'LOC'), ('TRIGGER_V1', 'LOC'), ('ACT_SYNC', 'LOC'),
  ('CHROMA_VAL', 'CHR'), ('TORUS_VAL', 'CHR'), ('GRID_FAIL', 'CHR'),
  ('MAG_REF_400', 'OBJ'), ('SHIFT_REF_04', 'OBJ'), ('FLUX_SYNC', 'OBJ'),
  ('LOAD_STRESS', 'LOR'), ('DIFF_REF_89', 'LOR'), ('PORE_SEQ', 'LOR');

commit;
