-- Phase 11 : recherche (utilisateurs, publications, événements, défis).
-- `pg_trgm` permet à `ilike '%terme%'` (recherche "contient", pas juste
-- "commence par") de rester indexé — un index B-tree classique ne sert à
-- rien pour ce type de motif.

create extension if not exists pg_trgm;

create index if not exists profiles_username_trgm_idx
  on public.profiles using gin (username gin_trgm_ops);
create index if not exists profiles_first_name_trgm_idx
  on public.profiles using gin (first_name gin_trgm_ops);
create index if not exists profiles_last_name_trgm_idx
  on public.profiles using gin (last_name gin_trgm_ops);

create index if not exists posts_content_trgm_idx
  on public.posts using gin (content gin_trgm_ops);

create index if not exists events_title_trgm_idx
  on public.events using gin (title gin_trgm_ops);

create index if not exists challenges_title_trgm_idx
  on public.challenges using gin (title gin_trgm_ops);
