abstract final class Validators {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9_.]{3,20}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email requis';
    if (!_emailRegex.hasMatch(value.trim())) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 8) return '8 caractères minimum';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? required(String? value, {String message = 'Champ requis'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? username(String? value) {
    final error = required(value, message: "Nom d'utilisateur requis");
    if (error != null) return error;
    if (!_usernameRegex.hasMatch(value!.trim())) {
      return '3-20 caractères : lettres, chiffres, . ou _';
    }
    return null;
  }
}
