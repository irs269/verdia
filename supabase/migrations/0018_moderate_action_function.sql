-- Corrige un bug découvert en vérification live : la migration 0009 a
-- volontairement `revoke update (status) on public.actions from
-- authenticated` (Phase 8, durcissement de sécurité) — son propre
-- commentaire anticipait exactement ce cas : "Le statut ne doit changer que
-- via une future Edge Function/panel admin utilisant la service role key".
-- Le tableau de bord de modération (migration 0015/0017) tentait de changer
-- `status` via un simple `.update()` authentifié, qui échoue TOUJOURS avec
-- "permission denied for table actions" (42501) — y compris pour un
-- modérateur, puisque ce revoke s'applique au rôle Postgres `authenticated`
-- dans son ensemble, pas à un rôle applicatif "modérateur" qui n'existe pas
-- au niveau Postgres. Solution cohérente avec le reste du projet (déjà
-- documentée par l'audit, item "Edge Functions" : remplacées par des
-- triggers/fonctions `security definer`) : une fonction RPC dédiée,
-- exécutée avec les privilèges de son propriétaire, qui vérifie elle-même
-- le rôle modérateur avant d'écrire.
create or replace function public.moderate_action(p_action_id uuid, p_new_status text)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'moderator') then
    raise exception 'Seul un modérateur peut modifier le statut d''une action.'
      using errcode = '42501';
  end if;

  if p_new_status not in ('pending', 'verified', 'rejected') then
    raise exception 'Statut invalide : %', p_new_status;
  end if;

  update public.actions set status = p_new_status where id = p_action_id;
end;
$$;

grant execute on function public.moderate_action(uuid, text) to authenticated;
