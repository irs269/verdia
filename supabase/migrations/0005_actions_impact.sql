-- Phase 4 : actions écologiques + système de points d'impact.
-- Les points ne sont jamais calculés côté client : le trigger
-- `award_action_points` ci-dessous est la seule source d'attribution.

create table public.action_categories (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  label text not null,
  icon text not null,
  color text not null
);

insert into public.action_categories (code, label, icon, color) values
  ('plantation', 'Plantation', '🌳', '#2E7D32'),
  ('nettoyage', 'Nettoyage', '🧹', '#00897B'),
  ('recyclage', 'Recyclage', '♻️', '#7CB342'),
  ('eau', 'Protection de l''eau', '🌊', '#0288D1'),
  ('pollution', 'Pollution', '🚯', '#EF6C00'),
  ('communaute', 'Action communautaire', '🤝', '#8E24AA');

create table public.actions (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid not null references public.action_categories (id),
  title text not null,
  description text not null,
  quantity numeric,
  quantity_unit text,
  participants_count int not null default 1,
  city text,
  country text,
  occurred_at date not null default current_date,
  status text not null default 'verified' check (status in ('pending', 'verified', 'rejected')),
  created_at timestamptz not null default now()
);

create index actions_author_id_idx on public.actions (author_id, created_at desc);
create index actions_category_id_idx on public.actions (category_id);

-- Une publication peut désormais être rattachée à une action.
alter table public.posts add column action_id uuid references public.actions (id) on delete set null;

create table public.action_participants (
  action_id uuid not null references public.actions (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (action_id, profile_id)
);

-- Règles de points pilotables (jamais hardcodées côté Flutter).
create table public.impact_rules (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.action_categories (id),
  points int not null default 0,
  quantity_multiplier numeric not null default 0,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

insert into public.impact_rules (category_id, points, quantity_multiplier)
select id,
  case code
    when 'plantation' then 20
    when 'nettoyage' then 30
    when 'recyclage' then 10
    when 'eau' then 15
    when 'pollution' then 15
    when 'communaute' then 50
  end,
  case code when 'plantation' then 1 else 0 end
from public.action_categories;

create table public.impact_points (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  action_id uuid not null references public.actions (id) on delete cascade,
  points int not null,
  awarded_at timestamptz not null default now(),
  unique (action_id, profile_id)
);

-- Attribution des points : exécutée côté serveur (security definer),
-- déclenchée uniquement quand une action passe (ou est créée) au statut
-- 'verified'. La contrainte unique sur impact_points empêche tout double
-- crédit même si le statut est modifié plusieurs fois.
create or replace function public.award_action_points()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  rule record;
  pts int;
begin
  if new.status = 'verified' and (tg_op = 'INSERT' or old.status is distinct from 'verified') then
    select * into rule from public.impact_rules
      where category_id = new.category_id and active
      limit 1;

    if rule is not null then
      pts := rule.points + floor(coalesce(new.quantity, 0) * rule.quantity_multiplier)::int;

      insert into public.impact_points (profile_id, action_id, points)
      values (new.author_id, new.id, pts)
      on conflict (action_id, profile_id) do nothing;

      -- `found` n'est vrai que si l'insert a réellement créé une ligne
      -- (donc jamais deux fois pour la même action, même si le statut
      -- oscille ou que le trigger se redéclenche).
      if found then
        update public.profiles
          set total_points = total_points + pts,
              level = greatest(1, floor((total_points + pts) / 100.0)::int + 1)
          where id = new.author_id;
      end if;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_action_verified on public.actions;
create trigger on_action_verified
  after insert or update on public.actions
  for each row
  execute function public.award_action_points();

-- RLS
alter table public.action_categories enable row level security;
alter table public.actions enable row level security;
alter table public.action_participants enable row level security;
alter table public.impact_rules enable row level security;
alter table public.impact_points enable row level security;

create policy "Categories are viewable by everyone"
  on public.action_categories for select using (true);

create policy "Actions are viewable by everyone"
  on public.actions for select using (true);
create policy "Users can create their own actions"
  on public.actions for insert with check (auth.uid() = author_id);
create policy "Users can update their own actions"
  on public.actions for update using (auth.uid() = author_id);

create policy "Action participants are viewable by everyone"
  on public.action_participants for select using (true);
create policy "Users can join actions as themselves"
  on public.action_participants for insert with check (auth.uid() = profile_id);
create policy "Users can leave actions they joined"
  on public.action_participants for delete using (auth.uid() = profile_id);

create policy "Impact rules are viewable by everyone"
  on public.impact_rules for select using (true);

create policy "Impact points are viewable by everyone"
  on public.impact_points for select using (true);
