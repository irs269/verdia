-- Phase 12 : modération de contenu (signaler un post/commentaire pour
-- spam/abus), distinct des `environmental_reports` (Phase 7, qui signalent
-- un problème environnemental réel, pas un contenu).

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('post', 'comment')),
  target_id uuid not null,
  reason text not null check (
    reason in ('spam', 'contenu_inapproprie', 'fausse_action', 'fraude', 'harcelement', 'autre')
  ),
  description text,
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'dismissed')),
  created_at timestamptz not null default now(),
  -- Empêche un même utilisateur de signaler dix fois le même contenu.
  unique (reporter_id, target_type, target_id)
);

create index reports_target_idx on public.reports (target_type, target_id);
create index reports_status_idx on public.reports (status);

-- Trace ce qu'un modérateur a fait suite à un signalement. Aucune interface
-- d'administration n'existe encore côté Flutter (hors périmètre de ce dépôt
-- mobile, cf. section 41 du cahier des charges) : cette table n'est préparée
-- que pour un futur backoffice qui écrira via service_role (qui contourne
-- RLS), d'où l'absence de toute policy pour `authenticated` ci-dessous.
create table public.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.reports (id) on delete cascade,
  moderator_id uuid references public.profiles (id) on delete set null,
  action text not null check (
    action in ('content_removed', 'warning_sent', 'account_suspended', 'no_action')
  ),
  notes text,
  created_at timestamptz not null default now()
);

alter table public.reports enable row level security;
alter table public.moderation_actions enable row level security;

create policy "Users can report content"
  on public.reports for insert with check (auth.uid() = reporter_id);
create policy "Users can view their own reports"
  on public.reports for select using (auth.uid() = reporter_id);

-- `moderation_actions` : RLS activé, aucune policy pour `authenticated` ->
-- accès refusé par défaut pour le client mobile (deny-all), conformément à
-- la section 31 ("les opérations sensibles doivent passer par des fonctions
-- sécurisées côté serveur").
