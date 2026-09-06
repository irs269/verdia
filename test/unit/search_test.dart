import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/core/utils/search.dart';

void main() {
  group('sanitizeSearchTerm', () {
    test('leaves a normal term untouched', () {
      expect(sanitizeSearchTerm('Ahmed'), 'Ahmed');
    });

    test('strips commas so they cannot break a .or() filter clause', () {
      expect(sanitizeSearchTerm('smith,or(admin'), 'smith or admin');
    });

    test('strips parentheses used to delimit PostgREST embeds', () {
      expect(sanitizeSearchTerm('test)eq.1,('), 'test eq.1');
    });

    test('trims surrounding whitespace', () {
      expect(sanitizeSearchTerm('  plage  '), 'plage');
    });
  });
}
