-- Complète l'item "Catégories d'action manquantes" de l'audit : le cahier des
-- charges prévoyait 10 catégories, seules 6 avaient été seedées en migration
-- 0005. Ajoute les 4 restantes avec les mêmes points de base que 'eau'/
-- 'pollution' (15 pts, pas de multiplicateur par quantité — ce ne sont pas
-- des actions mesurables en unités comme la plantation ou le nettoyage).
insert into public.action_categories (code, label, icon, color) values
  ('sensibilisation', 'Sensibilisation', '📣', '#F9A825'),
  ('agriculture', 'Agriculture durable', '🌾', '#9E9D24'),
  ('education', 'Éducation', '📚', '#5E35B1'),
  ('autre', 'Autre', '🌿', '#546E7A');

insert into public.impact_rules (category_id, points, quantity_multiplier)
select id, 15, 0
from public.action_categories
where code in ('sensibilisation', 'agriculture', 'education', 'autre');
