class CommunityStats {
  const CommunityStats({
    required this.membersCount,
    required this.verifiedActionsCount,
    required this.totalPoints,
    required this.eventsCount,
    required this.organizationsCount,
    required this.quantityTotals,
  });

  final int membersCount;
  final int verifiedActionsCount;
  final int totalPoints;
  final int eventsCount;
  final int organizationsCount;

  /// Quantité totale par unité ('arbres', 'kg', ...) toutes actions vérifiées
  /// confondues — même agrégation que `ActionRepository.fetchUserQuantityTotals`
  /// mais sans filtre d'auteur.
  final Map<String, double> quantityTotals;
}
