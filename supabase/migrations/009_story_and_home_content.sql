-- Stage 2 of the admin: the Story text and the home page copy move into the
-- database, so they can be edited at /admin and go live on Publish.
--
-- story_sections.body   the Markdown of each section, under its heading
--                       (the heading itself is story_sections.title)
-- site_content 'home'   the home page copy (formerly content/home.json)
-- site_content 'book'   the book title, tagline and back cover copy shown
--                       on the Story page (formerly story/back-cover.md)
--
-- The files in the repository stay as the fallback the build uses if a
-- release does not carry this content. Loaded by supabase/load_content.mjs.

begin;

alter table public.story_sections
  add column body text,
  add column updated_at timestamptz not null default now();
create trigger story_sections_touch before update on public.story_sections
  for each row execute function public.touch_updated_at();

create table public.site_content (
  key         text primary key check (key in ('home', 'book')),
  data        json not null,   -- json, not jsonb: keeps the order the copy is written in
  updated_at  timestamptz not null default now()
);
create trigger site_content_touch before update on public.site_content
  for each row execute function public.touch_updated_at();
alter table public.site_content enable row level security;
create policy "Public read" on public.site_content for select using (true);
create policy "Owner write" on public.site_content for all to authenticated
  using (public.is_owner()) with check (public.is_owner());

commit;

-- Releases keep the exact order of the data they hold (jsonb would sort the
-- keys of every object, including the home page copy).
alter table public.releases alter column data type json using data::json;
