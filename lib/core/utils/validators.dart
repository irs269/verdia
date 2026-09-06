import '../../l10n/app_localizations.dart';

/// Les validateurs les plus utilisés (email/mot de passe/username) retournent
/// une fonction plutôt qu'une chaîne codée en dur, pour pouvoir puiser le
/// message d'erreur dans [AppLocalizations] sans que cette classe elle-même
/// ait besoin d'un `BuildContext`. `required` reste une fonction directe :
/// tous ses appelants passent déjà leur propre message explicite, donc rien
/// à localiser ici pour l'instant (son message par défaut sert de filet de
/// sécurité, pas de texte affiché en pratique).
abstract final class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9_.]{3,20}$');

  static String? Function(String?) email(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.trim().isEmpty) return l10n.emailRequired;
      if (!_emailRegex.hasMatch(value.trim())) return l10n.emailInvalid;
      return null;
    };
  }

  static String? Function(String?) password(AppLocalizations l10n) {
    return (value) {
      if (value == null || value.isEmpty) return l10n.passwordRequired;
      if (value.length < 8) return l10n.passwordTooShort;
      return null;
    };
  }

  static String? Function(String?) confirmPassword(AppLocalizations l10n, String original) {
    return (value) => value != original ? l10n.passwordsDontMatch : null;
  }

  static String? required(String? value, {String message = 'Champ requis'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? Function(String?) username(AppLocalizations l10n) {
    return (value) {
      final error = required(value, message: l10n.usernameRequired);
      if (error != null) return error;
      if (!_usernameRegex.hasMatch(value!.trim())) return l10n.usernameInvalid;
      return null;
    };
  }
}
