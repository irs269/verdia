/// Erreur applicative normalisée, affichable telle quelle dans l'UI.
///
/// Chaque repository doit attraper les exceptions bas niveau (Supabase,
/// réseau...) et les convertir en [AppException] pour que les écrans n'aient
/// jamais à connaître l'origine technique de l'erreur.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
