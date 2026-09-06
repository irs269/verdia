-- Phase 1 : identité utilisateur.
-- À exécuter dans l'éditeur SQL Supabase (ou via `supabase db push`).

create extension if not exists "uuid-ossp";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  first_name text not null,
  last_name text not null,
  avatar_url text,
  bio text,
  city text,
  country text,
  level integer not null default 1,
  total_points integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_.]{3,20}$')
);

create index if not exists profiles_username_idx on public.profiles (username);

-- updated_at automatique sur toute modification.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

-- Crée automatiquement la ligne `profiles` à l'inscription, à partir des
-- métadonnées passées par AuthRepository.signUp (first_name, last_name, username).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, first_name, last_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- RLS : profils publics en lecture, modifiables uniquement par leur propriétaire.
alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Aucune policy insert/delete cliente : la création passe par le trigger
-- `handle_new_user` (security definer), la suppression par cascade sur auth.users.
