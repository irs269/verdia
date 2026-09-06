-- Étend le Realtime (jusqu'ici limité aux notifications) aux likes et
-- commentaires : les compteurs du fil et le fil de commentaires d'un post se
-- mettent désormais à jour en direct pour tous les viewers, pas seulement
-- pour l'auteur de l'action.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'likes'
  ) then
    alter publication supabase_realtime add table public.likes;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'comments'
  ) then
    alter publication supabase_realtime add table public.comments;
  end if;
end $$;
