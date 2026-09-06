-- Système de messagerie : conversations directes (uniquement entre amis,
-- voir migration 0026), groupes créés par un utilisateur, et un groupe
-- automatique par organisation dont les membres sont synchronisés avec
-- `organization_members`.

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  is_group boolean not null default false,
  name text,
  organization_id uuid references public.organizations (id) on delete cascade,
  -- Clé canonique "min_id:max_id" pour les conversations directes (1:1),
  -- garantit via l'index unique ci-dessous qu'il n'existe jamais deux
  -- conversations directes entre les deux mêmes personnes, y compris en cas
  -- d'appels concurrents (voir get_or_create_direct_conversation).
  direct_key text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create unique index conversations_direct_key_idx on public.conversations (direct_key) where direct_key is not null;
create unique index conversations_organization_id_idx on public.conversations (organization_id) where organization_id is not null;

create table public.conversation_participants (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, profile_id)
);

create index conversation_participants_profile_id_idx on public.conversation_participants (profile_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  content text not null check (length(trim(content)) > 0),
  created_at timestamptz not null default now()
);

create index messages_conversation_id_created_at_idx on public.messages (conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

create policy "Participants can view their conversations"
  on public.conversations for select
  using (exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = id and cp.profile_id = auth.uid()
  ));

create policy "Participants can view conversation membership"
  on public.conversation_participants for select
  using (exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = conversation_participants.conversation_id
      and cp.profile_id = auth.uid()
  ));

-- Quitter un groupe classique reste permis en libre-service ; quitter le
-- groupe automatique d'une organisation ne l'est pas (on en part en
-- quittant l'organisation elle-même, cf. trigger plus bas qui gère déjà ce
-- retrait).
create policy "Users can leave a non-organization conversation"
  on public.conversation_participants for delete
  using (
    profile_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_participants.conversation_id
        and c.organization_id is null
    )
  );

-- Aucune policy insert pour conversation_participants : l'ajout d'un
-- participant passe toujours par une fonction `security definer`
-- (get_or_create_direct_conversation / create_group_conversation /
-- add_group_member) ou par le trigger d'organisation ci-dessous, jamais par
-- un insert direct du client — évite qu'un utilisateur s'ajoute lui-même à
-- une conversation à laquelle il n'a pas été invité.

create policy "Participants can view messages"
  on public.messages for select
  using (exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id and cp.profile_id = auth.uid()
  ));

create policy "Participants can send messages as themselves"
  on public.messages for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = messages.conversation_id and cp.profile_id = auth.uid()
    )
  );

-- Fonctions serveur -----------------------------------------------------

-- Réutilise ou crée la conversation directe entre l'appelant et [p_other_id].
-- Refuse si les deux ne sont pas "amis" (migration 0026 : les abonnements
-- sont désormais toujours réciproques, une seule direction suffit à vérifier
-- la relation). `on conflict (direct_key) do nothing` + relecture gère
-- proprement la course entre deux appels concurrents.
create or replace function public.get_or_create_direct_conversation(p_other_id uuid)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_key text;
  v_id uuid;
begin
  if v_me is null or p_other_id is null or v_me = p_other_id then
    raise exception 'Destinataire invalide.' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.follows
    where follower_id = v_me and following_id = p_other_id
  ) then
    raise exception 'Vous ne pouvez discuter qu''avec vos amis.' using errcode = '42501';
  end if;

  v_key := least(v_me::text, p_other_id::text) || ':' || greatest(v_me::text, p_other_id::text);

  insert into public.conversations (is_group, direct_key, created_by)
  values (false, v_key, v_me)
  on conflict (direct_key) where direct_key is not null do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id from public.conversations where direct_key = v_key;
  else
    insert into public.conversation_participants (conversation_id, profile_id)
    values (v_id, v_me), (v_id, p_other_id);
  end if;

  return v_id;
end;
$$;

grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;

-- Crée un groupe avec l'appelant comme premier membre, plus [p_member_ids]
-- (chacun doit être un ami de l'appelant).
create or replace function public.create_group_conversation(p_name text, p_member_ids uuid[])
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_id uuid;
  v_member uuid;
begin
  if v_me is null or trim(coalesce(p_name, '')) = '' then
    raise exception 'Nom de groupe requis.' using errcode = '22023';
  end if;

  foreach v_member in array coalesce(p_member_ids, array[]::uuid[]) loop
    if v_member <> v_me and not exists (
      select 1 from public.follows where follower_id = v_me and following_id = v_member
    ) then
      raise exception 'Tous les membres doivent être des amis.' using errcode = '42501';
    end if;
  end loop;

  insert into public.conversations (is_group, name, created_by)
  values (true, trim(p_name), v_me)
  returning id into v_id;

  insert into public.conversation_participants (conversation_id, profile_id)
  values (v_id, v_me)
  on conflict do nothing;

  foreach v_member in array coalesce(p_member_ids, array[]::uuid[]) loop
    if v_member <> v_me then
      insert into public.conversation_participants (conversation_id, profile_id)
      values (v_id, v_member)
      on conflict do nothing;
    end if;
  end loop;

  return v_id;
end;
$$;

grant execute on function public.create_group_conversation(text, uuid[]) to authenticated;

-- Ajoute [p_member_id] à un groupe classique existant — réservé aux membres
-- déjà présents dans la conversation, et uniquement pour un de leurs amis.
create or replace function public.add_group_member(p_conversation_id uuid, p_member_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_me uuid := auth.uid();
begin
  if not exists (
    select 1 from public.conversation_participants
    where conversation_id = p_conversation_id and profile_id = v_me
  ) then
    raise exception 'Vous ne faites pas partie de ce groupe.' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.conversations
    where id = p_conversation_id and is_group and organization_id is null
  ) then
    raise exception 'Ce groupe ne peut pas recevoir de nouveaux membres directement.' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.follows where follower_id = v_me and following_id = p_member_id
  ) then
    raise exception 'Vous ne pouvez ajouter que des amis.' using errcode = '42501';
  end if;

  insert into public.conversation_participants (conversation_id, profile_id)
  values (p_conversation_id, p_member_id)
  on conflict do nothing;
end;
$$;

grant execute on function public.add_group_member(uuid, uuid) to authenticated;

-- Marque la conversation comme lue par l'appelant jusqu'à maintenant — sert
-- au badge "non lu" de la liste des conversations.
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.conversation_participants
  set last_read_at = now()
  where conversation_id = p_conversation_id and profile_id = auth.uid();
end;
$$;

grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- Groupe automatique par organisation -------------------------------------

create or replace function public.create_organization_conversation()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.conversations (is_group, name, organization_id, created_by)
  values (true, new.name, new.id, null)
  on conflict (organization_id) where organization_id is not null do nothing;
  return new;
end;
$$;

drop trigger if exists on_organization_created_conversation on public.organizations;
create trigger on_organization_created_conversation
  after insert on public.organizations
  for each row
  execute function public.create_organization_conversation();

-- Garde le nom du groupe synchronisé avec celui de l'organisation.
create or replace function public.sync_organization_conversation_name()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.name is distinct from old.name then
    update public.conversations set name = new.name where organization_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists on_organization_updated_conversation on public.organizations;
create trigger on_organization_updated_conversation
  after update of name on public.organizations
  for each row
  execute function public.sync_organization_conversation_name();

-- Ajoute/retire automatiquement un membre du groupe de l'organisation quand
-- il rejoint/quitte l'organisation elle-même.
create or replace function public.sync_organization_conversation_membership()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_conversation_id uuid;
begin
  if tg_op = 'INSERT' then
    select id into v_conversation_id from public.conversations where organization_id = new.organization_id;
    if v_conversation_id is not null then
      insert into public.conversation_participants (conversation_id, profile_id)
      values (v_conversation_id, new.profile_id)
      on conflict do nothing;
    end if;
    return new;
  else
    select id into v_conversation_id from public.conversations where organization_id = old.organization_id;
    if v_conversation_id is not null then
      delete from public.conversation_participants
      where conversation_id = v_conversation_id and profile_id = old.profile_id;
    end if;
    return old;
  end if;
end;
$$;

drop trigger if exists on_organization_member_insert_conversation on public.organization_members;
create trigger on_organization_member_insert_conversation
  after insert on public.organization_members
  for each row
  execute function public.sync_organization_conversation_membership();

drop trigger if exists on_organization_member_delete_conversation on public.organization_members;
create trigger on_organization_member_delete_conversation
  after delete on public.organization_members
  for each row
  execute function public.sync_organization_conversation_membership();

-- Rattrapage pour les organisations déjà existantes : crée leur groupe.
insert into public.conversations (is_group, name, organization_id, created_by)
select true, o.name, o.id, null
from public.organizations o
where not exists (
  select 1 from public.conversations c where c.organization_id = o.id
);

-- ... puis y ajoute leurs membres actuels.
insert into public.conversation_participants (conversation_id, profile_id)
select c.id, om.profile_id
from public.organization_members om
join public.conversations c on c.organization_id = om.organization_id
on conflict do nothing;

-- Liste des conversations de l'appelant, avec aperçu du dernier message et
-- indicateur "non lu" — évite le N+1 (une requête par conversation pour son
-- dernier message) que PostgREST seul ne peut pas exprimer.
create or replace function public.list_my_conversations()
returns table (
  conversation_id uuid,
  is_group boolean,
  name text,
  organization_id uuid,
  other_profile_id uuid,
  other_username text,
  other_first_name text,
  other_last_name text,
  other_avatar_url text,
  last_message_content text,
  last_message_sender_id uuid,
  last_message_created_at timestamptz,
  unread boolean
)
language sql
security definer
stable
set search_path = public
as $$
  select
    c.id,
    c.is_group,
    c.name,
    c.organization_id,
    other.id,
    other.username,
    other.first_name,
    other.last_name,
    other.avatar_url,
    lm.content,
    lm.sender_id,
    lm.created_at,
    coalesce(lm.created_at > cp.last_read_at, false)
  from public.conversation_participants cp
  join public.conversations c on c.id = cp.conversation_id
  left join lateral (
    select p2.profile_id as id, pr.username, pr.first_name, pr.last_name, pr.avatar_url
    from public.conversation_participants p2
    join public.profiles pr on pr.id = p2.profile_id
    where p2.conversation_id = c.id and p2.profile_id <> auth.uid() and not c.is_group
    limit 1
  ) other on true
  left join lateral (
    select m.content, m.sender_id, m.created_at
    from public.messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) lm on true
  where cp.profile_id = auth.uid()
  order by coalesce(lm.created_at, c.created_at) desc;
$$;

grant execute on function public.list_my_conversations() to authenticated;

-- Realtime : les messages arrivent en direct dans une conversation ouverte,
-- même pattern que likes/commentaires (migration 0014).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
