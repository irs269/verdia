-- Complète l'item "Paramètres" de l'audit : préférence de notifications et
-- suppression de compte en libre-service.

-- Préférence de notifications --------------------------------------------
-- Un seul interrupteur global (pas de granularité par type) pour rester
-- simple côté MVP. Appliquée au niveau le plus central possible : un trigger
-- BEFORE INSERT sur `notifications` elle-même plutôt que de modifier les 6
-- fonctions `notify_on_*` existantes (migration 0008) une par une — moins de
-- surface de régression, un seul endroit à lire pour comprendre la règle.
alter table public.profiles add column notifications_enabled boolean not null default true;
grant update (notifications_enabled) on public.profiles to authenticated;

create or replace function public.enforce_notification_preference()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if not coalesce(
    (select notifications_enabled from public.profiles where id = new.profile_id),
    true
  ) then
    return null;
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_notification_preference on public.notifications;
create trigger enforce_notification_preference
  before insert on public.notifications
  for each row
  execute function public.enforce_notification_preference();

-- Suppression de compte en libre-service ----------------------------------
-- `security definer` : le propriétaire de la fonction (postgres, plein
-- accès à `auth.users`) exécute la suppression pour le compte de
-- l'utilisateur connecté. `profiles.id references auth.users(id) on delete
-- cascade` (migration 0001) supprime ensuite en cascade tout le contenu de
-- l'utilisateur (actions, posts, commentaires, etc.) sans code
-- supplémentaire. Irréversible — le client doit exiger une confirmation
-- explicite avant d'appeler cette fonction.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.delete_own_account() to authenticated;
