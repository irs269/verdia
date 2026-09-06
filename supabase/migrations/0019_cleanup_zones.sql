-- Complète l'item "Affichage des zones nettoyées" de l'audit : jusqu'ici
-- seuls des points ponctuels existaient pour les actions de nettoyage.
-- Rayon optionnel (mètres) autour du point choisi, dessiné comme un cercle
-- sur la carte — une vraie zone polygonale serait plus fidèle mais
-- demanderait une UI de dessin bien plus lourde pour un MVP.
alter table public.actions add column zone_radius_m double precision;
