-- Complète l'item "Création de campagnes par une organisation" de l'audit :
-- jusqu'ici `events.organizer_id`/`challenges.organizer_id` ne référençaient
-- que des profils, aucun lien avec `organizations` n'existait.
--
-- `organizer_id` reste le profil réellement authentifié qui a créé la
-- campagne (ancre de permission RLS, inchangée) ; `organizer_org_id` est un
-- champ optionnel indiquant qu'elle est publiée "au nom" d'une organisation
-- dont ce profil est membre — validé à l'insertion, pas seulement côté UI.
alter table public.events add column organizer_org_id uuid references public.organizations (id) on delete set null;
alter table public.challenges add column organizer_org_id uuid references public.organizations (id) on delete set null;

drop policy if exists "Users can create their own events" on public.events;
create policy "Users can create their own events"
  on public.events for insert
  with check (
    auth.uid() = organizer_id
    and (
      organizer_org_id is null
      or exists (
        select 1 from public.organization_members
        where organization_id = organizer_org_id and profile_id = auth.uid()
      )
    )
  );

-- La policy UPDATE existante ("using" seul) n'empêchait pas un organisateur
-- de réassigner son événement à une organisation dont il n'est pas membre en
-- passant par un simple .update() — même garde qu'à l'insertion, appliquée
-- ici via "with check" (évalué sur la ligne APRÈS modification).
drop policy if exists "Organizers can update their own events" on public.events;
create policy "Organizers can update their own events"
  on public.events for update
  using (auth.uid() = organizer_id)
  with check (
    auth.uid() = organizer_id
    and (
      organizer_org_id is null
      or exists (
        select 1 from public.organization_members
        where organization_id = organizer_org_id and profile_id = auth.uid()
      )
    )
  );

drop policy if exists "Users can create challenges" on public.challenges;
create policy "Users can create challenges"
  on public.challenges for insert
  with check (
    auth.uid() = organizer_id
    and (
      organizer_org_id is null
      or exists (
        select 1 from public.organization_members
        where organization_id = organizer_org_id and profile_id = auth.uid()
      )
    )
  );
