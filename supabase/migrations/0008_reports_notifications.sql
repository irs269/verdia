-- Phase 7 : signalements environnementaux + notifications.

create table public.environmental_reports (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in (
    'depot_sauvage', 'pollution', 'deforestation', 'eau_polluee',
    'dechets', 'destruction_espace', 'autre'
  )),
  description text not null,
  photo_url text,
  lat double precision not null,
  lng double precision not null,
  city text,
  country text,
  status text not null default 'signale' check (status in (
    'signale', 'en_verification', 'en_cours', 'resolu', 'rejete'
  )),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index environmental_reports_created_at_idx on public.environmental_reports (created_at desc);
create index environmental_reports_lat_lng_idx on public.environmental_reports (lat, lng);

-- Storage : photo du signalement. Public en lecture (les signalements sont
-- affichés sur la carte pour tous), écriture réservée à l'auteur.
insert into storage.buckets (id, name, public)
values ('report-media', 'report-media', true)
on conflict (id) do nothing;

create policy "Report media files are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'report-media');

create policy "Users can upload their own report media"
  on storage.objects for insert
  with check (
    bucket_id = 'report-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

alter table public.environmental_reports enable row level security;

create policy "Reports are viewable by everyone"
  on public.environmental_reports for select using (true);
create policy "Users can create their own reports"
  on public.environmental_reports for insert with check (auth.uid() = author_id);

-- Notifications
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in (
    'like', 'comment', 'follow', 'event_joined', 'challenge_joined',
    'badge', 'action_validated', 'report_resolved'
  )),
  payload jsonb not null default '{}'::jsonb,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_profile_id_created_at_idx
  on public.notifications (profile_id, created_at desc);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications"
  on public.notifications for select using (auth.uid() = profile_id);
create policy "Users can mark their own notifications as read"
  on public.notifications for update using (auth.uid() = profile_id);

-- Realtime : la table doit être ajoutée à la publication Supabase.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- Chaque trigger dénormalise les infos de l'acteur dans `payload` pour que
-- l'écran de notifications n'ait pas besoin de requêtes supplémentaires
-- (et fonctionne avec `.stream()`, qui ne supporte pas les embeds).

create or replace function public.notify_on_like()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  post_author uuid;
  actor record;
begin
  select author_id into post_author from public.posts where id = new.post_id;
  if post_author is null or post_author = new.profile_id then
    return new;
  end if;

  select username, first_name, last_name, avatar_url into actor
    from public.profiles where id = new.profile_id;

  insert into public.notifications (profile_id, type, payload)
  values (post_author, 'like', jsonb_build_object(
    'actor_id', new.profile_id,
    'actor_username', actor.username,
    'actor_name', actor.first_name || ' ' || actor.last_name,
    'actor_avatar_url', actor.avatar_url,
    'post_id', new.post_id
  ));
  return new;
end;
$$;

drop trigger if exists on_like_notify on public.likes;
create trigger on_like_notify
  after insert on public.likes
  for each row execute function public.notify_on_like();

create or replace function public.notify_on_comment()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  post_author uuid;
  actor record;
begin
  select author_id into post_author from public.posts where id = new.post_id;
  if post_author is null or post_author = new.author_id then
    return new;
  end if;

  select username, first_name, last_name, avatar_url into actor
    from public.profiles where id = new.author_id;

  insert into public.notifications (profile_id, type, payload)
  values (post_author, 'comment', jsonb_build_object(
    'actor_id', new.author_id,
    'actor_username', actor.username,
    'actor_name', actor.first_name || ' ' || actor.last_name,
    'actor_avatar_url', actor.avatar_url,
    'post_id', new.post_id,
    'comment_id', new.id,
    'preview', left(new.content, 140)
  ));
  return new;
end;
$$;

drop trigger if exists on_comment_notify on public.comments;
create trigger on_comment_notify
  after insert on public.comments
  for each row execute function public.notify_on_comment();

create or replace function public.notify_on_follow()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  actor record;
begin
  select username, first_name, last_name, avatar_url into actor
    from public.profiles where id = new.follower_id;

  insert into public.notifications (profile_id, type, payload)
  values (new.following_id, 'follow', jsonb_build_object(
    'actor_id', new.follower_id,
    'actor_username', actor.username,
    'actor_name', actor.first_name || ' ' || actor.last_name,
    'actor_avatar_url', actor.avatar_url
  ));
  return new;
end;
$$;

drop trigger if exists on_follow_notify on public.follows;
create trigger on_follow_notify
  after insert on public.follows
  for each row execute function public.notify_on_follow();

create or replace function public.notify_on_badge()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  b record;
begin
  select code, name, icon into b from public.badges where id = new.badge_id;

  insert into public.notifications (profile_id, type, payload)
  values (new.profile_id, 'badge', jsonb_build_object(
    'badge_id', new.badge_id,
    'badge_code', b.code,
    'badge_name', b.name,
    'badge_icon', b.icon
  ));
  return new;
end;
$$;

drop trigger if exists on_badge_notify on public.user_badges;
create trigger on_badge_notify
  after insert on public.user_badges
  for each row execute function public.notify_on_badge();

create or replace function public.notify_on_event_join()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  ev record;
  actor record;
begin
  select organizer_id, title into ev from public.events where id = new.event_id;
  if ev.organizer_id is null or ev.organizer_id = new.profile_id then
    return new;
  end if;

  select username, first_name, last_name, avatar_url into actor
    from public.profiles where id = new.profile_id;

  insert into public.notifications (profile_id, type, payload)
  values (ev.organizer_id, 'event_joined', jsonb_build_object(
    'actor_id', new.profile_id,
    'actor_username', actor.username,
    'actor_name', actor.first_name || ' ' || actor.last_name,
    'actor_avatar_url', actor.avatar_url,
    'event_id', new.event_id,
    'event_title', ev.title
  ));
  return new;
end;
$$;

drop trigger if exists on_event_join_notify on public.event_participants;
create trigger on_event_join_notify
  after insert on public.event_participants
  for each row execute function public.notify_on_event_join();

create or replace function public.notify_on_challenge_join()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  chal record;
  actor record;
begin
  select organizer_id, title into chal from public.challenges where id = new.challenge_id;
  if chal.organizer_id is null or chal.organizer_id = new.profile_id then
    return new;
  end if;

  select username, first_name, last_name, avatar_url into actor
    from public.profiles where id = new.profile_id;

  insert into public.notifications (profile_id, type, payload)
  values (chal.organizer_id, 'challenge_joined', jsonb_build_object(
    'actor_id', new.profile_id,
    'actor_username', actor.username,
    'actor_name', actor.first_name || ' ' || actor.last_name,
    'actor_avatar_url', actor.avatar_url,
    'challenge_id', new.challenge_id,
    'challenge_title', chal.title
  ));
  return new;
end;
$$;

drop trigger if exists on_challenge_join_notify on public.challenge_participants;
create trigger on_challenge_join_notify
  after insert on public.challenge_participants
  for each row execute function public.notify_on_challenge_join();
