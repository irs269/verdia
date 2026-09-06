-- Finalise plusieurs fonctionnalités partielles identifiées par l'audit :
-- date/heure précise d'une action, vérification GPS, avant/après photo,
-- rôle modérateur + workflow de validation des actions, gestion d'une
-- organisation par son propriétaire.

-- A. `occurred_at` n'avait qu'une date, jamais d'heure précise.
alter table public.actions alter column occurred_at type timestamptz using occurred_at::timestamptz;
alter table public.actions alter column occurred_at set default now();

-- E. Vérification GPS : position réelle de l'appareil au moment de l'action,
-- comparée côté client à la position choisie sur la carte (voir
-- ActionRepository.createAction). `location_verified` reflète le résultat de
-- cette comparaison ; les deux colonnes lat/lng restent nullables (la
-- géolocalisation peut échouer/être refusée sans bloquer la publication).
alter table public.actions add column device_lat double precision;
alter table public.actions add column device_lng double precision;
alter table public.actions add column location_verified boolean not null default false;

-- D. Avant/après : deux emplacements photo dédiés, en plus de la galerie
-- générale (post_media.label reste null pour les photos non taguées).
alter table public.post_media add column label text check (label is null or label in ('avant', 'apres'));

-- F. Rôle modérateur. La policy "Users can update their own profile" (0001)
-- autorise déjà la modification de n'importe quelle colonne de sa propre
-- ligne — sans le revoke ci-dessous, un utilisateur pourrait s'auto-promouvoir
-- modérateur via un simple appel REST. Seul un accès direct (SQL editor,
-- connecté en tant que postgres) peut donc accorder ce rôle, ce qui est
-- volontaire : il n'existe pas encore de flux applicatif pour élire un
-- modérateur.
alter table public.profiles add column role text not null default 'member' check (role in ('member', 'moderator'));
revoke update (role) on public.profiles from authenticated, anon;

-- Un modérateur peut désormais consulter tous les signalements (pas
-- seulement les siens) et les faire évoluer.
create policy "Moderators can view all reports"
  on public.reports for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'moderator'));
create policy "Moderators can update report status"
  on public.reports for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'moderator'));

-- `moderation_actions` était deny-all pour `authenticated` (0012) faute
-- d'interface : elle existe désormais.
create policy "Moderators can log moderation actions"
  on public.moderation_actions for insert
  with check (
    auth.uid() = moderator_id
    and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'moderator')
  );
create policy "Moderators can view moderation actions"
  on public.moderation_actions for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'moderator'));

-- Un modérateur peut faire évoluer le statut de N'IMPORTE QUELLE action
-- (contrairement à la policy existante "Users can update their own actions",
-- limitée à l'auteur) — c'est le workflow de validation qui manquait.
create policy "Moderators can moderate any action"
  on public.actions for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'moderator'));

-- Symétrique du trigger `award_action_points` (0005) : si un modérateur fait
-- passer une action déjà vérifiée à 'rejected', les points crédités pour
-- cette action précise sont retirés (jamais plus que ce qui a été crédité
-- pour CETTE action, pas un solde global).
create or replace function public.revoke_action_points()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  pts_row record;
begin
  if old.status = 'verified' and new.status = 'rejected' then
    select * into pts_row from public.impact_points
      where action_id = new.id and profile_id = new.author_id;

    if found then
      delete from public.impact_points where action_id = new.id and profile_id = new.author_id;
      update public.profiles
        set total_points = greatest(0, total_points - pts_row.points),
            level = greatest(1, floor(greatest(0, total_points - pts_row.points) / 100.0)::int + 1)
        where id = new.author_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_action_rejected on public.actions;
create trigger on_action_rejected
  after update on public.actions
  for each row
  execute function public.revoke_action_points();

-- H. Le propriétaire (`organization_members.role = 'owner'`) peut désormais
-- modifier les informations de son organisation — la création reste hors
-- périmètre (voir le commentaire de 0013 : nécessite une vérification/
-- modération dédiée qui n'existe pas encore).
create policy "Owners can update their organization"
  on public.organizations for update
  using (exists (
    select 1 from public.organization_members m
    where m.organization_id = organizations.id and m.profile_id = auth.uid() and m.role = 'owner'
  ));

-- Bucket dédié au logo d'organisation (jusqu'ici jamais créé, faute
-- d'upload possible). Chemin attendu : organization-media/{organization_id}/{uuid}.jpg
insert into storage.buckets (id, name, public)
values ('organization-media', 'organization-media', true)
on conflict (id) do nothing;

create policy "Organization media is publicly accessible"
  on storage.objects for select
  using (bucket_id = 'organization-media');

create policy "Owners can upload their organization media"
  on storage.objects for insert
  with check (
    bucket_id = 'organization-media'
    and exists (
      select 1 from public.organization_members m
      where m.profile_id = auth.uid() and m.role = 'owner'
        and m.organization_id::text = (storage.foldername(name))[1]
    )
  );

create policy "Owners can replace their organization media"
  on storage.objects for update
  using (
    bucket_id = 'organization-media'
    and exists (
      select 1 from public.organization_members m
      where m.profile_id = auth.uid() and m.role = 'owner'
        and m.organization_id::text = (storage.foldername(name))[1]
    )
  );
