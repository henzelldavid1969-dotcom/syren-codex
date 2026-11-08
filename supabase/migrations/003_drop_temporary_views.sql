-- The new entry layout is published, so the code on main reads the new
-- tables directly. The temporary views from 002b are no longer needed.
drop view if exists public.entry_links;
drop view if exists public.entry_media;
