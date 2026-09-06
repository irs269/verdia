import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty value', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects malformed email', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('trims surrounding whitespace before validating', () {
      expect(Validators.email('  user@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty password', () {
      expect(Validators.password(''), isNotNull);
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(Validators.password('short'), isNotNull);
    });

    test('accepts a password of exactly 8 characters', () {
      expect(Validators.password('12345678'), isNull);
    });

    test('accepts a password of 8+ characters', () {
      expect(Validators.password('password123'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects when confirmation differs from the original', () {
      expect(Validators.confirmPassword('abc12345', 'xyz98765'), isNotNull);
    });

    test('accepts when confirmation matches the original', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
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
      expect(Validators.username('Ahmed Green'), isNotNull);
    });

    test('rejects usernames shorter than 3 characters', () {
      expect(Validators.username('ab'), isNotNull);
    });

    test('rejects usernames longer than 20 characters', () {
      expect(Validators.username('a' * 21), isNotNull);
    });

    test('accepts a valid username', () {
      expect(Validators.username('ahmed.green'), isNull);
    });

    test('accepts usernames with underscores and digits', () {
      expect(Validators.username('ahmed_green_92'), isNull);
    });
  });
}
