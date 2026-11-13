-- A Polish version of the Story, section by section.
--
-- Each Story section may carry a Polish title and Polish text alongside the
-- English. Two times are kept so the admin can say when the Polish needs a
-- look: body_en_at, when the English text last changed, and body_pl_at, when
-- the Polish last changed. The site offers Polish only for sections that
-- have it. Polish edits are kept in the version history like English ones.

begin;

alter table public.story_sections
  add column title_pl   text,
  add column body_pl    text,
  add column body_en_at timestamptz,
  add column body_pl_at timestamptz;

update public.story_sections set body_en_at = updated_at;

create or replace function public.story_lang_stamps()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' or new.body is distinct from old.body then
    new.body_en_at := now();
  end if;
  if (tg_op = 'INSERT' and (new.body_pl is not null or new.title_pl is not null))
     or (tg_op = 'UPDATE' and (new.body_pl, new.title_pl) is distinct from (old.body_pl, old.title_pl)) then
    new.body_pl_at := now();
  end if;
  return new;
end;
$$;
create trigger story_sections_lang_stamps before insert or update on public.story_sections
  for each row execute function public.story_lang_stamps();

-- Versions of a section include the Polish.
create or replace function public.record_row_revision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_table_name = 'story_sections' then
    if tg_op = 'UPDATE' and (old.title, old.label, old.kind, old.group_code, old.body, old.title_pl, old.body_pl)
       is not distinct from (new.title, new.label, new.kind, new.group_code, new.body, new.title_pl, new.body_pl) then
      return new;
    end if;
    insert into revisions (kind, key, data) values ('section', new.slug,
      json_build_object('title', new.title, 'label', new.label, 'kind', new.kind, 'group_code', new.group_code, 'body', new.body,
                        'title_pl', new.title_pl, 'body_pl', new.body_pl));
  else
    if tg_op = 'UPDATE' and old.data::text = new.data::text then return new; end if;
    insert into revisions (kind, key, data) values ('content', new.key, json_build_object('data', new.data));
  end if;
  return new;
end;
$$;

commit;
