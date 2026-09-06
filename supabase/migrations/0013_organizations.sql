-- Phase 14 : organisations (section 28 du cahier des charges).
-- Le cahier des charges classe lui-même la fonctionnalité complète en
-- "Phase 2" ("même si la fonctionnalité complète peut être phase 2, prévoir
-- la base de données") — ce MVP minimal ne construit que le schéma et un
-- écran de consultation en lecture seule. Créer une organisation suppose une
-- vérification/modération dédiée qui n'existe pas encore : aucune policy
-- d'écriture pour `authenticated` ci-dessous, deny-all côté client.

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  logo_url text,
  description text not null,
  category text not null check (
    category in ('association', 'ong', 'entreprise', 'ecole', 'collectivite', 'groupe_communautaire')
  ),
  city text,
  country text,
  website text,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create index organizations_category_idx on public.organizations (category);

create table public.organization_members (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (organization_id, profile_id)
);

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;

create policy "Organizations are viewable by everyone"
  on public.organizations for select using (true);
create policy "Organization members are viewable by everyone"
  on public.organization_members for select using (true);

-- Deux organisations de démonstration pour que l'écran de consultation ait
-- réellement quelque chose à afficher.
insert into public.organizations (name, description, category, city, country, website, verified) values
  (
    'Ulanga Comores',
    'Association de protection de l''environnement et de sensibilisation communautaire aux Comores.',
    'association',
    'Moroni',
    'Comores',
    'https://ulanga-comores.example.org',
    true
  ),
  (
    'École Primaire de Chindini',
    'Établissement scolaire participant aux programmes de plantation et de sensibilisation environnementale avec ses élèves.',
    'ecole',
    'Chindini',
    'Comores',
    null,
    false
  );
