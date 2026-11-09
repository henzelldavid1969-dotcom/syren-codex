-- The admin (CMS) at /admin.
--
-- Publishing: edits in the database do not reach the site on their own.
-- When the owner presses Publish, /api/publish exports the site data and
-- saves it here as a release; the site is then rebuilt from the newest
-- release. A release is exactly what the public site shows, so anyone may
-- read it, and only the owner may add one.

begin;

create table public.releases (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  created_by  uuid default auth.uid(),
  entries     int,
  note        text,
  data        jsonb not null
);
alter table public.releases enable row level security;
create policy "Public read" on public.releases for select using (true);
create policy "Owner publish" on public.releases for insert to authenticated
  with check (public.is_owner());

-- Editor notes stay private: the owner may read and write them, nobody else.
create policy "Owner only" on public.editor_notes for all to authenticated
  using (public.is_owner()) with check (public.is_owner());

-- The admin asks this once after sign-in to show or refuse the editor.
grant execute on function public.is_owner() to authenticated;

commit;
