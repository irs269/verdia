-- Complète l'item "Hashtags" de l'audit (section 29 du cahier des charges,
-- jamais construit). Extraction 100% côté serveur — un trigger sur
-- `posts.content`, jamais le client — pour que ça fonctionne quel que soit
-- le chemin d'insertion (action liée ou post libre) sans dupliquer la
-- logique de parsing en Dart.

create table public.hashtags (
  id uuid primary key default gen_random_uuid(),
  tag text not null unique,
  created_at timestamptz not null default now()
);

create index hashtags_tag_trgm_idx on public.hashtags using gin (tag gin_trgm_ops);

create table public.post_hashtags (
  post_id uuid not null references public.posts (id) on delete cascade,
  hashtag_id uuid not null references public.hashtags (id) on delete cascade,
  primary key (post_id, hashtag_id)
);

create index post_hashtags_hashtag_id_idx on public.post_hashtags (hashtag_id);

alter table public.hashtags enable row level security;
alter table public.post_hashtags enable row level security;

create policy "Hashtags are viewable by everyone"
  on public.hashtags for select using (true);
create policy "Post hashtags are viewable by everyone"
  on public.post_hashtags for select using (true);
-- Aucune policy insert/update/delete pour `authenticated` : seul le trigger
-- `security definer` ci-dessous écrit ces deux tables.

create or replace function public.extract_hashtags()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_tag text;
  v_hashtag_id uuid;
begin
  delete from public.post_hashtags where post_id = new.id;

  for v_tag in
    select distinct lower(m[1])
    from regexp_matches(new.content, '#([[:alnum:]_]+)', 'g') as m
  loop
    insert into public.hashtags (tag) values (v_tag)
      on conflict (tag) do update set tag = excluded.tag
      returning id into v_hashtag_id;

    insert into public.post_hashtags (post_id, hashtag_id)
    values (new.id, v_hashtag_id)
    on conflict do nothing;
  end loop;

  return new;
end;
$$;

drop trigger if exists extract_hashtags_on_insert on public.posts;
create trigger extract_hashtags_on_insert
  after insert on public.posts
  for each row
  execute function public.extract_hashtags();

drop trigger if exists extract_hashtags_on_update on public.posts;
create trigger extract_hashtags_on_update
  after update of content on public.posts
  for each row
  when (old.content is distinct from new.content)
  execute function public.extract_hashtags();
