/// Neutralise les caractères qui ont un sens dans la syntaxe de filtre
/// PostgREST (`,` sépare les clauses d'un `.or()`, `(`/`)` délimitent les
/// embeds) pour qu'un terme de recherche saisi librement par l'utilisateur
/// ne puisse jamais casser la requête.
String sanitizeSearchTerm(String query) {
  return query.replaceAll(RegExp(r'[,()]'), ' ').trim();
}
