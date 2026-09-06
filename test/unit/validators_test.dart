import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/core/utils/validators.dart';
import 'package:verdia/l10n/app_localizations_fr.dart';

void main() {
  final l10n = AppLocalizationsFr();

  group('Validators.email', () {
    test('rejects empty value', () {
      expect(Validators.email(l10n)(''), isNotNull);
    });

    test('rejects malformed email', () {
      expect(Validators.email(l10n)('not-an-email'), isNotNull);
    });

    test('accepts a valid email', () {
      expect(Validators.email(l10n)('user@example.com'), isNull);
    });

    test('trims surrounding whitespace before validating', () {
      expect(Validators.email(l10n)('  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty password', () {
      expect(Validators.password(l10n)(''), isNotNull);
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.password(l10n)('short'), isNotNull);
    });

    test('accepts a password of exactly 8 characters', () {
      expect(Validators.password(l10n)('12345678'), isNull);
    });

    test('accepts a password of 8+ characters', () {
      expect(Validators.password(l10n)('password123'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects when confirmation differs from the original', () {
      expect(Validators.confirmPassword(l10n, 'xyz98765')('abc12345'), isNotNull);
    });

    test('accepts when confirmation matches the original', () {
      expect(Validators.confirmPassword(l10n, 'abc12345')('abc12345'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects null', () {
      expect(Validators.required(null), isNotNull);
    });

    test('rejects blank/whitespace-only value', () {
      expect(Validators.required('   '), isNotNull);
    });

    test('accepts non-empty value', () {
      expect(Validators.required('Plantation'), isNull);
    });

    test('uses the custom message when provided', () {
      expect(Validators.required(null, message: 'Titre requis'), 'Titre requis');
    });
  });

  group('Validators.username', () {
    test('rejects usernames with uppercase or spaces', () {
      expect(Validators.username(l10n)('Ahmed Green'), isNotNull);
    });

    test('rejects usernames shorter than 3 characters', () {
      expect(Validators.username(l10n)('ab'), isNotNull);
    });

    test('rejects usernames longer than 20 characters', () {
      expect(Validators.username(l10n)('a' * 21), isNotNull);
    });

    test('accepts a valid username', () {
      expect(Validators.username(l10n)('ahmed.green'), isNull);
    });

    test('accepts usernames with underscores and digits', () {
      expect(Validators.username(l10n)('ahmed_green_92'), isNull);
    });
  });
}
