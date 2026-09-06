-- Phase 8 (correctif) : le test en direct a montré que la migration 0009
-- ne bloquait rien. Cause : `REVOKE UPDATE (colonne) ... FROM authenticated`
-- ne retire qu'un éventuel droit accordé AU NIVEAU COLONNE. Or Supabase
-- accorde par défaut `GRANT ALL ON ALL TABLES IN SCHEMA public TO
-- authenticated`, un droit AU NIVEAU TABLE — et un droit table-level reste
-- pleinement valide même après un REVOKE column-level ciblé (Postgres ne
-- les combine pas par intersection). Preuve en direct : un appel
-- `PATCH /profiles?id=eq.<moi>` avec `{"total_points": 999999}` réussissait
-- toujours après la 0009 + un `NOTIFY pgrst, 'reload schema'`.
--
-- Le seul moyen fiable de restreindre certaines colonnes est de révoquer le
-- droit au niveau table, puis de le regranter explicitement colonne par
-- colonne pour celles qui doivent rester modifiables par le client.

revoke update on public.profiles from authenticated;
grant update (first_name, last_name, username, avatar_url, bio, city, country)
  on public.profiles to authenticated;

revoke update on public.actions from authenticated;
grant update (title, description, quantity, quantity_unit, participants_count,
              city, country, lat, lng, occurred_at)
  on public.actions to authenticated;

revoke insert on public.challenge_participants from authenticated;
grant insert (challenge_id, profile_id) on public.challenge_participants to authenticated;

notify pgrst, 'reload schema';
