-- Complète l'item "Vidéos" de l'audit : jusqu'ici le bucket 'post-media'
-- n'acceptait que des images (migration 0009). On élargit les types MIME
-- acceptés et on relève la limite de taille pour accueillir de courtes
-- vidéos (les autres buckets média restent images-only, non concernés).
update storage.buckets
  set file_size_limit = 50 * 1024 * 1024, -- 50 Mo
      allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']
  where id = 'post-media';
