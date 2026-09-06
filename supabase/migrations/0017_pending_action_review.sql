-- Décision produit explicite de l'utilisateur (revient sur le choix inverse
-- fait lors de la finalisation précédente) : une action nouvellement créée
-- attend désormais la validation d'un modérateur avant que les points ne
-- soient crédités, au lieu d'être "verified" instantanément.
--
-- Les triggers `on_action_verified_challenge_progress` (0007),
-- `on_action_verified_check_badges` (0007) et `award_action_points` (0005)
-- ne se déclenchent déjà QUE sur `new.status = 'verified'` — ils n'ont besoin
-- d'aucune modification : ils attendront naturellement la validation.
alter table public.actions alter column status set default 'pending';

-- Empêche l'auteur (ou n'importe qui d'autre non-modérateur) de faire
-- évoluer lui-même le statut de sa propre action. La policy "Users can
-- update their own actions" (0005) n'a jamais eu d'appelant légitime pour ce
-- champ précis (aucun écran ne modifiait le statut) ; ce trigger la
-- neutralise spécifiquement pour `status`, sans toucher aux autres colonnes
-- si un futur écran d'édition d'action venait à exister. Même logique que
-- `prevent_owner_self_verification` (organisations, 0016) et
-- `revoke update (role)` (profils, 0015).
create or replace function public.prevent_author_self_verification()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    if not exists (select 1 from public.profiles where id = auth.uid() and role = 'moderator') then
      new.status := old.status;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_author_self_verification on public.actions;
create trigger prevent_author_self_verification
  before update on public.actions
  for each row
  execute function public.prevent_author_self_verification();
