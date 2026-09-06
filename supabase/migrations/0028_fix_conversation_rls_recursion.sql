-- Corrige un bug réel trouvé en vérification live : la policy "Participants
-- can view conversation membership" (migration 0027) référence
-- `conversation_participants` dans sa PROPRE clause USING (pour vérifier que
-- l'appelant est bien participant de la même conversation) — Postgres lève
-- "infinite recursion detected in policy for relation
-- conversation_participants" (42P17) dès qu'une requête sur `messages` ou
-- `conversations` doit évaluer cette policy en cascade, bloquant purement et
-- simplement l'envoi/la lecture de messages.
--
-- Fix standard pour ce piège RLS bien connu : une fonction `security
-- definer` (donc qui contourne RLS en interne) casse la boucle, puisque la
-- policy n'interroge plus directement la table sur laquelle elle s'applique.
create or replace function public.is_conversation_participant(
  p_conversation_id uuid,
  p_profile_id uuid default auth.uid()
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants
    where conversation_id = p_conversation_id and profile_id = p_profile_id
  );
$$;

drop policy if exists "Participants can view conversation membership" on public.conversation_participants;
create policy "Participants can view conversation membership"
  on public.conversation_participants for select
  using (public.is_conversation_participant(conversation_id));

drop policy if exists "Participants can view their conversations" on public.conversations;
create policy "Participants can view their conversations"
  on public.conversations for select
  using (public.is_conversation_participant(id));

drop policy if exists "Participants can view messages" on public.messages;
create policy "Participants can view messages"
  on public.messages for select
  using (public.is_conversation_participant(conversation_id));

drop policy if exists "Participants can send messages as themselves" on public.messages;
create policy "Participants can send messages as themselves"
  on public.messages for insert
  with check (sender_id = auth.uid() and public.is_conversation_participant(conversation_id));
