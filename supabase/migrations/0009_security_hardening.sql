-- Phase 8 : durcissement de la sécurité.
--
-- Ce fichier ne change aucune fonctionnalité ; il ferme des trous laissés
-- par les migrations précédentes. Rappel du problème général : la RLS
-- contrôle QUELLES LIGNES un rôle peut toucher, pas QUELLES COLONNES. Un
-- utilisateur authentifié peut donc appeler l'API REST Supabase directement
-- (en dehors de l'app Flutter) et modifier n'importe quelle colonne d'une
-- ligne qu'il a le droit de modifier — y compris des colonnes qui ne
-- devraient être écrites que par nos triggers `security definer`.

-- 1. profiles.total_points / profiles.level
--    Sans ceci, n'importe quel utilisateur pouvait s'attribuer des points
--    en appelant directement `PATCH /profiles?id=eq.<son_id>` avec
--    {"total_points": 999999} — la policy "Users can update their own
--    profile" l'autorisait puisque auth.uid() = id. Les triggers
--    `award_action_points` restent fonctionnels : ils s'exécutent en tant
--    que propriétaire de la fonction (security definer), qui n'est jamais
--    soumis à ce REVOKE (celui-ci ne vise que le rôle `authenticated`).
revoke update (total_points, level) on public.profiles from authenticated;

-- 2. actions.status
--    Sans ceci, un auteur pouvait repasser sa propre action de 'rejected'
--    (une fois la modération ajoutée) à 'verified' lui-même, ou faire
--    osciller le statut pour tenter de rejouer la logique de validation.
--    Le statut ne doit changer que via une future Edge Function/panel admin
--    utilisant la service role key (qui ignore RLS et ces GRANT/REVOKE).
revoke update (status) on public.actions from authenticated;

-- 3. challenge_participants.contribution
--    La policy d'insertion n'autorisait que `profile_id = auth.uid()`, sans
--    contraindre la valeur de `contribution` : un utilisateur aurait pu
--    rejoindre un défi avec une contribution initiale arbitraire. Cette
--    colonne ne doit être renseignée que par le trigger
--    `update_challenge_progress`, jamais à l'insertion cliente.
revoke insert (contribution) on public.challenge_participants from authenticated;

-- (La policy de suppression sur `posts` existe déjà depuis la migration
-- 0003 — vérifiée, pas de trou ici.)

-- Note volontaire : `actions` n'a pas de policy de suppression. Autoriser
-- un auteur à supprimer une action après coup permettrait de faire
-- disparaître la preuve d'une action frauduleuse tout en gardant les
-- points déjà crédités (ceux-ci ne sont jamais retirés rétroactivement).
-- C'est un choix délibéré, pas un oubli.

-- 4. Limites de taille et de type MIME au niveau du bucket Storage.
--    Jusqu'ici la validation des fichiers n'existait que côté client
--    (compression via image_picker) : rien n'empêchait un appel direct à
--    l'API Storage d'envoyer un fichier de type ou de taille arbitraire.
update storage.buckets
  set file_size_limit = 5 * 1024 * 1024, -- 5 Mo
      allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
  where id = 'avatars';

update storage.buckets
  set file_size_limit = 10 * 1024 * 1024, -- 10 Mo
      allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
  where id in ('post-media', 'event-media', 'report-media');
