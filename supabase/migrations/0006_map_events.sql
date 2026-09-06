-- Phase 5 : carte interactive + événements.

-- Les actions existantes n'avaient qu'une ville en texte libre ; la carte a
-- besoin de coordonnées réelles pour placer un marqueur.
alter table public.actions add column lat double precision;
alter table public.actions add column lng double precision;

create index actions_lat_lng_idx on public.actions (lat, lng) where lat is not null;

create table public.events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text not null,
  cover_url text,
  lat double precision not null,
  lng double precision not null,
  city text,
  country text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  target_participants int,
  status text not null default 'upcoming' check (status in ('upcoming', 'ongoing', 'completed', 'cancelled')),
  created_at timestamptz not null default now()
);

create index events_starts_at_idx on public.events (starts_at);
create index events_organizer_id_idx on public.events (organizer_id);
create index events_lat_lng_idx on public.events (lat, lng);

create table public.event_participants (
  event_id uuid not null references public.events (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (event_id, profile_id)
);

create index event_participants_event_id_idx on public.event_participants (event_id);

-- Storage : photo de couverture des événements.
insert into storage.buckets (id, name, public)
values ('event-media', 'event-media', true)
on conflict (id) do nothing;

create policy "Event media files are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'event-media');

create policy "Users can upload their own event media"
  on storage.objects for insert
  with check (
    bucket_id = 'event-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their own event media"
  on storage.objects for delete
  using (
    bucket_id = 'event-media'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- RLS
alter table public.events enable row level security;
alter table public.event_participants enable row level security;

create policy "Events are viewable by everyone"
  on public.events for select using (true);
create policy "Users can create their own events"
  on public.events for insert with check (auth.uid() = organizer_id);
create policy "Organizers can update their own events"
  on public.events for update using (auth.uid() = organizer_id);

create policy "Event participants are viewable by everyone"
  on public.event_participants for select using (true);
create policy "Users can join events as themselves"
  on public.event_participants for insert with check (auth.uid() = profile_id);
create policy "Users can leave events they joined"
  on public.event_participants for delete using (auth.uid() = profile_id);
