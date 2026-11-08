-- Temporary: lets the code currently on main keep exporting while the new
-- entry layout is in preview. Removed once the new layout is published.
create view public.entry_links as
  select from_ref, to_ref, position from public.relations;
create view public.entry_media as
  select null::text as entry_ref, null::text as kind, null::text as file,
         null::text as caption, null::int as position
  where false;
