-- Phase 6 : défis écologiques + badges + classement.
-- Comme pour les points d'impact, la progression des défis et le
-- déblocage des badges sont calculés uniquement côté serveur (triggers).

create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid references public.action_categories (id),
  title text not null,
  description text not null,
  scope text not null default 'community' check (scope in ('individual', 'community')),
  target_value numeric not null,
  current_value numeric not null default 0,
  unit text not null,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index challenges_ends_at_idx on public.challenges (ends_at);

create table public.challenge_participants (
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  contribution numeric not null default 0,
  joined_at timestamptz not null default now(),
  primary key (challenge_id, profile_id)
);

-- Empêche de créditer deux fois la même action sur un même défi (idempotence),
-- symétrique à `impact_points` pour les actions.
create table public.challenge_action_credits (
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  action_id uuid not null references public.actions (id) on delete cascade,
  amount numeric not null,
  primary key (challenge_id, action_id)
);

-- Quand une action est vérifiée, incrémente la progression de tout défi actif
-- (même catégorie, dans sa fenêtre de dates) auquel l'auteur a déjà adhéré.
create or replace function public.update_challenge_progress()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  chal record;
  amount numeric;
begin
  if new.status = 'verified' and (tg_op = 'INSERT' or old.status is distinct from 'verified') then
    for chal in
      select c.* from public.challenges c
      join public.challenge_participants cp
        on cp.challenge_id = c.id and cp.profile_id = new.author_id
      where c.category_id = new.category_id
        and new.occurred_at::timestamptz >= c.starts_at
        and new.occurred_at::timestamptz <= c.ends_at
    loop
      amount := coalesce(new.quantity, 1);

      insert into public.challenge_action_credits (challenge_id, action_id, amount)
      values (chal.id, new.id, amount)
      on conflict (challenge_id, action_id) do nothing;

      if found then
        update public.challenge_participants
          set contribution = contribution + amount
          where challenge_id = chal.id and profile_id = new.author_id;

        update public.challenges
          set current_value = current_value + amount
          where id = chal.id;
      end if;
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists on_action_verified_challenge_progress on public.actions;
create trigger on_action_verified_challenge_progress
  after insert or update on public.actions
  for each row
  execute function public.update_challenge_progress();

-- Badges : ensemble fixe pour ce MVP, avec des conditions simples et
-- pilotables (points totaux, ou nombre d'actions vérifiées, par catégorie
-- ou toutes catégories confondues) sans avoir besoin de redéployer Flutter.
create table public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null,
  icon text not null,
  condition jsonb not null
);

insert into public.badges (code, name, description, icon, condition) values
  ('premiere_action', 'Première action', 'Publie ta première action vérifiée.', '🌱',
    '{"metric": "actions_count", "threshold": 1}'),
  ('gardien_des_arbres', 'Gardien des arbres', 'Plante lors de 5 actions de plantation.', '🌳',
    '{"metric": "actions_count", "category": "plantation", "threshold": 5}'),
  ('protecteur_oceans', 'Protecteur des océans', 'Participe à 3 actions de protection de l''eau.', '🌊',
    '{"metric": "actions_count", "category": "eau", "threshold": 3}'),
  ('champion_recyclage', 'Champion du recyclage', 'Réalise 5 actions de recyclage.', '♻️',
    '{"metric": "actions_count", "category": "recyclage", "threshold": 5}'),
  ('heros_nettoyage', 'Héros du nettoyage', 'Réalise 5 actions de nettoyage.', '🧹',
    '{"metric": "actions_count", "category": "nettoyage", "threshold": 5}'),
  ('green_warrior', 'Green Warrior', 'Atteins 200 points d''impact.', '🔥',
    '{"metric": "points", "threshold": 200}'),
  ('ambassadeur_verdia', 'Ambassadeur VERDIA', 'Atteins 500 points d''impact.', '🏆',
    '{"metric": "points", "threshold": 500}');

create table public.user_badges (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  badge_id uuid not null references public.badges (id) on delete cascade,
  earned_at timestamptz not null default now(),
  primary key (profile_id, badge_id)
);

create or replace function public.check_and_award_badges(p_profile_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  b record;
  total_actions int;
  total_pts int;
  cat_count int;
begin
  select total_points into total_pts from public.profiles where id = p_profile_id;
  select count(*) into total_actions from public.actions
    where author_id = p_profile_id and status = 'verified';

  for b in select * from public.badges loop
    if exists (
      select 1 from public.user_badges
      where profile_id = p_profile_id and badge_id = b.id
    ) then
      continue;
    end if;

    if b.condition ->> 'metric' = 'points' then
      if total_pts >= (b.condition ->> 'threshold')::int then
        insert into public.user_badges (profile_id, badge_id) values (p_profile_id, b.id);
      end if;
    elsif b.condition ->> 'metric' = 'actions_count' then
      if b.condition ? 'category' then
        select count(*) into cat_count
          from public.actions a
          join public.action_categories c on c.id = a.category_id
          where a.author_id = p_profile_id and a.status = 'verified'
            and c.code = b.condition ->> 'category';
        if cat_count >= (b.condition ->> 'threshold')::int then
          insert into public.user_badges (profile_id, badge_id) values (p_profile_id, b.id);
        end if;
      else
        if total_actions >= (b.condition ->> 'threshold')::int then
          insert into public.user_badges (profile_id, badge_id) values (p_profile_id, b.id);
        end if;
      end if;
    end if;
  end loop;
end;
$$;

create or replace function public.trigger_check_badges()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.status = 'verified' and (tg_op = 'INSERT' or old.status is distinct from 'verified') then
    perform public.check_and_award_badges(new.author_id);
  end if;
  return new;
end;
$$;

drop trigger if exists on_action_verified_check_badges on public.actions;
create trigger on_action_verified_check_badges
  after insert or update on public.actions
  for each row
  execute function public.trigger_check_badges();

-- RLS
alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;
alter table public.challenge_action_credits enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

create policy "Challenges are viewable by everyone"
  on public.challenges for select using (true);
create policy "Users can create challenges"
  on public.challenges for insert with check (auth.uid() = organizer_id);

create policy "Challenge participants are viewable by everyone"
  on public.challenge_participants for select using (true);
create policy "Users can join challenges as themselves"
  on public.challenge_participants for insert with check (auth.uid() = profile_id);
create policy "Users can leave challenges they joined"
  on public.challenge_participants for delete using (auth.uid() = profile_id);

create policy "Challenge action credits are viewable by everyone"
  on public.challenge_action_credits for select using (true);

create policy "Badges are viewable by everyone"
  on public.badges for select using (true);

create policy "User badges are viewable by everyone"
  on public.user_badges for select using (true);
