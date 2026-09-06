-- Rend les abonnements automatiquement réciproques ("Amis"), à la demande
-- explicite de l'utilisateur : si X suit Y, Y suit automatiquement X.
-- Décision confirmée par l'utilisateur : rétroactif (les abonnements
-- asymétriques déjà en base reçoivent leur inverse) et fusion en un seul
-- concept "Amis" côté UI (voir modifications Dart associées).

-- `auto_generated` distingue une ligne créée par une vraie action utilisateur
-- d'une ligne créée mécaniquement par le trigger de réciprocité — sert à ne
-- pas doubler la notification "X vous suit" (Y n'a rien fait de son côté).
alter table public.follows add column auto_generated boolean not null default false;

-- Backfill rétroactif : ajoute l'abonnement inverse partout où il manque.
insert into public.follows (follower_id, following_id, auto_generated)
select f.following_id, f.follower_id, true
from public.follows f
where not exists (
  select 1 from public.follows r
  where r.follower_id = f.following_id and r.following_id = f.follower_id
);

create or replace function public.mirror_follow_on_insert()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.follows (follower_id, following_id, auto_generated)
  values (new.following_id, new.follower_id, true)
  on conflict (follower_id, following_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_follow_mirror_insert on public.follows;
create trigger on_follow_mirror_insert
  after insert on public.follows
  for each row
  execute function public.mirror_follow_on_insert();

-- Symétrique pour le "unfollow" : rompre la relation d'un côté la rompt des
-- deux côtés (comme "unfriend"), cohérent avec la fusion en un seul concept
-- "Amis". Termine naturellement (pas de boucle infinie) : une fois la ligne
-- inverse supprimée, la ligne originale n'existe déjà plus, donc le second
-- DELETE n'affecte aucune ligne et ne redéclenche rien.
create or replace function public.mirror_follow_on_delete()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  delete from public.follows
  where follower_id = old.following_id and following_id = old.follower_id;
  return old;
end;
$$;

drop trigger if exists on_follow_mirror_delete on public.follows;
create trigger on_follow_mirror_delete
  after delete on public.follows
  for each row
  execute function public.mirror_follow_on_delete();

-- La notification "X vous suit" ne doit se déclencher que pour la ligne
-- créée par une vraie action de l'utilisateur, pas pour son miroir
-- automatique (sinon Y recevrait une notification pour une action qu'il n'a
-- pas faite).
create or replace function public.notify_on_follow()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor record;
begin
  if new.auto_generated then
    return new;
  end if;

  select username, first_name, last_name, avatar_url into actor
    from public.profiles where id = new.follower_id;

  insert into public.notifications (profile_id, type, payload)
  values (new.following_id, 'follow', jsonb_build_object(
    'actor_id', new.follower_id,
    'actor_username', actor.username,
    'actor_name', actor.first_name || ' ' || actor.last_name,
    'actor_avatar_url', actor.avatar_url
  ));
  return new;
end;
$$;
