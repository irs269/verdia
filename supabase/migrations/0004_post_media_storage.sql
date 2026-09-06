-- Phase 3 : stockage des photos/vidéos de publication.

insert into storage.buckets (id, name, public)
values ('post-media', 'post-media', true)
on conflict (id) do nothing;

-- Chemin attendu : post-media/{user_id}/{uuid}.jpg
create policy "Post media files are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'post-media');

create policy "Users can upload their own post media"
  on storage.objects for insert
  with check (
    bucket_id = 'post-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their own post media"
  on storage.objects for delete
  using (
    bucket_id = 'post-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
