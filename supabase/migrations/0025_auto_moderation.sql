-- Validation automatique par analyse de mots-clés, à la demande explicite de
-- l'utilisateur : une action dont le titre/description correspond au
-- périmètre écologique de VERDIA est vérifiée immédiatement (points crédités
-- tout de suite) ; sinon elle reste 'pending' et seul un modérateur peut la
-- valider via le tableau de bord existant (migration 0017/0018, inchangé).
--
-- Approche mots-clés côté SQL (pas d'IA externe) — choix explicite de
-- l'utilisateur : cohérent avec l'architecture du projet qui évite déjà les
-- Edge Functions (pas d'accès Supabase CLI/Deno dans cet environnement) et
-- garde toute la logique de confiance côté Postgres, sans clé API externe ni
-- coût par appel. Moins précis qu'une vraie analyse sémantique, mais rapide,
-- gratuit et entièrement auditable.

create or replace function public.is_content_in_scope(p_text text)
returns boolean
language plpgsql
immutable
as $$
declare
  v_text text := lower(coalesce(p_text, ''));
  -- Vocabulaire couvrant les 10 catégories d'action (migrations 0005/0021)
  -- plus des termes écologiques génériques. Volontairement large : le but
  -- est de repérer un vrai hors-sujet, pas de juger la qualité de l'action.
  v_in_scope_keywords text[] := array[
    'plant', 'arbre', 'reboisement', 'foret', 'forêt', 'graine', 'semis',
    'nettoy', 'dechet', 'déchet', 'ordure', 'plage', 'poubelle', 'proprete', 'propreté', 'ramass',
    'recycl', 'tri selectif', 'tri sélectif', 'compost',
    'eau', 'riviere', 'rivière', 'ocean', 'océan', 'lagon', 'potable', 'mangrove',
    'pollution', 'emission', 'émission', 'carbone', 'co2', 'air pur', 'plastique',
    'sensibilis', 'atelier', 'conference', 'conférence', 'campagne', 'formation ecolog', 'formation écolog',
    'agricultur', 'permacultur', 'agroecolog', 'agroécolog', 'jardin', 'potager',
    'education environ', 'éducation environ', 'ecole verte', 'école verte', 'scolaire',
    'communaut', 'benevol', 'bénévol', 'volontair', 'mobilisation', 'solidair',
    'environnement', 'ecolog', 'écolog', 'durable', 'biodiversite', 'biodiversité',
    'nature', 'climat', 'vert', 'planete', 'planète', 'faune', 'flore', 'corail', 'coraux'
  ];
  -- Signaux de spam/hors-sujet évident : si présents, hors périmètre même en
  -- cas de mot-clé écologique par ailleurs (ex. lien promotionnel glissé dans
  -- un texte par ailleurs plausible).
  v_red_flags text[] := array[
    'gratuit', 'argent facile', 'cliquez ici', 'whatsapp', 'telegram',
    'http://', 'https://', 'www.', 'promo', 'a vendre', 'à vendre', 'prix casse', 'prix cassé',
    'gagner', 'loterie', 'casino', 'crypto', 'bitcoin', 'investissement'
  ];
  kw text;
begin
  if length(trim(v_text)) < 10 then
    return false;
  end if;

  foreach kw in array v_red_flags loop
    if v_text like '%' || kw || '%' then
      return false;
    end if;
  end loop;

  foreach kw in array v_in_scope_keywords loop
    if v_text like '%' || kw || '%' then
      return true;
    end if;
  end loop;

  return false;
end;
$$;

create or replace function public.auto_moderate_action()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if public.is_content_in_scope(coalesce(new.title, '') || ' ' || coalesce(new.description, '')) then
    new.status := 'verified';
  else
    new.status := 'pending';
  end if;
  return new;
end;
$$;

drop trigger if exists auto_moderate_action on public.actions;
create trigger auto_moderate_action
  before insert on public.actions
  for each row
  execute function public.auto_moderate_action();
