import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/actions/domain/action_category.dart';

void main() {
  group('ActionCategory.fromMap', () {
    test('parses a category row correctly', () {
      final category = ActionCategory.fromMap({
        'id': 'cat-1',
        'code': 'plantation',
        'label': 'Plantation',
        'icon': '🌳',
        'color': '#2E7D32',
      });

      expect(category.id, 'cat-1');
      expect(category.code, 'plantation');
      expect(category.label, 'Plantation');
      expect(category.icon, '🌳');
    });

    test('parses the hex color into an opaque Color', () {
      final category = ActionCategory.fromMap({
        'id': 'cat-1',
        'code': 'plantation',
        'label': 'Plantation',
        'icon': '🌳',
        'color': '#2E7D32',
      });

      expect(category.color.a, 1.0);
      expect(category.color.toARGB32() & 0x00FFFFFF, 0x2E7D32);
    });
  });
}
