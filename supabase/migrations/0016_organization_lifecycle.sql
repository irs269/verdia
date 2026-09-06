-- Complète l'item "Organisation" de l'audit : création en libre-service
-- (toujours non vérifiée à la création — la vérification reste un acte de
-- modération, cf. le commentaire de la migration 0013) et gestion des
-- membres par le propriétaire. Le workflow de validation des ACTIONS, lui,
-- reste inchangé (verified instantané) — décision produit assumée.

-- N'importe quel utilisateur connecté peut créer une organisation ; elle
-- démarre toujours non vérifiée (colonne `verified default false`, jamais
-- transmise par le client).
create policy "Users can create an organization"
  on public.organizations for insert
  with check (auth.uid() is not null);

-- Un modérateur peut modifier n'importe quelle organisation (notamment la
-- vérifier) — les propriétaires gardent leur policy existante (0015) pour
-- éditer la leur.
create policy "Moderators can update any organization"
  on public.organizations for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'moderator'));

-- Empêche un propriétaire de s'auto-vérifier via son propre accès en
-- écriture : seul un modérateur peut faire évoluer `verified`. Symétrique de
-- `revoke update (role)` sur profiles (0015), mais implémenté en trigger ici
-- car la policy owner doit rester utilisable pour éditer les AUTRES champs
-- d'une organisation déjà vérifiée (un simple `with check (verified=false)`
-- bloquerait aussi ces éditions légitimes).
create or replace function public.prevent_owner_self_verification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.verified is distinct from old.verified then
    if not exists (select 1 from public.profiles where id = auth.uid() and role = 'moderator') then
      new.verified := old.verified;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_owner_self_verification on public.organizations;
create trigger prevent_owner_self_verification
  before update on public.organizations
  for each row
  execute function public.prevent_owner_self_verification();

-- Un utilisateur peut s'auto-déclarer `owner` d'une organisation qu'il
-- vient de créer (aucun membre existant) — empêche de s'approprier une
-- organisation déjà possédée (ex. Ulanga Comores).
create policy "Users can claim ownership of a fresh organization"
  on public.organization_members for insert
  with check (
    auth.uid() = profile_id and role = 'owner'
    and not exists (
      select 1 from public.organization_members m where m.organization_id = organization_members.organization_id
    )
  );

-- Le propriétaire peut ajouter des membres (toujours 'member', jamais
-- 'owner' par ce biais).
create policy "Owners can add members to their organization"
  on public.organization_members for insert
  with check (
    role = 'member'
    and exists (
      select 1 from public.organization_members m
      where m.organization_id = organization_members.organization_id and m.profile_id = auth.uid() and m.role = 'owner'
    )
  );

-- Le propriétaire peut retirer un membre (jamais lui-même, pour éviter une
-- organisation sans propriétaire).
create policy "Owners can remove members"
  on public.organization_members for delete
  using (
    profile_id <> auth.uid()
    and exists (
      select 1 from public.organization_members m
      where m.organization_id = organization_members.organization_id and m.profile_id = auth.uid() and m.role = 'owner'
    )
  );
