import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/actions/domain/eco_action.dart';

Map<String, dynamic> _categoryMap() => {
      'id': 'cat-1',
      'code': 'plantation',
      'label': 'Plantation',
      'icon': '🌳',
      'color': '#2E7D32',
    };

Map<String, dynamic> _actionMap({
  double? quantity,
  String? quantityUnit,
  List<Map<String, dynamic>>? impactPoints,
}) {
  return {
    'id': 'action-1',
    'title': 'Plantation au jardin public',
    'description': "Nous avons planté 15 arbres avec l'école primaire",
    'quantity': quantity,
    'quantity_unit': quantityUnit,
    'participants_count': 12,
    'city': 'Moroni',
    'country': null,
    'lat': null,
    'lng': null,
    'occurred_at': '2026-09-05',
    'status': 'verified',
    'created_at': '2026-09-05T10:00:00Z',
    'action_categories': _categoryMap(),
    'impact_points': impactPoints ?? [],
  };
}

void main() {
  group('EcoAction.fromMap', () {
    test('parses the embedded category', () {
      final action = EcoAction.fromMap(_actionMap());
      expect(action.category.code, 'plantation');
      expect(action.category.label, 'Plantation');
    });

    test('reads the real awarded points from impact_points, not an estimate', () {
      final action = EcoAction.fromMap(_actionMap(impactPoints: [
        {'points': 35}
      ]));
      expect(action.impactPoints, 35);
    });

    test('impactPoints is null when the action has not been credited yet', () {
      final action = EcoAction.fromMap(_actionMap());
      expect(action.impactPoints, isNull);
    });
  });

  group('EcoAction.quantityLabel', () {
    test('is null when no quantity was recorded', () {
      final action = EcoAction.fromMap(_actionMap());
      expect(action.quantityLabel, isNull);
    });

    test('formats a whole-number quantity without decimals', () {
      final action = EcoAction.fromMap(_actionMap(quantity: 15, quantityUnit: 'arbres'));
      expect(action.quantityLabel, '15 arbres');
    });

    test('keeps decimals for a fractional quantity', () {
      final action = EcoAction.fromMap(_actionMap(quantity: 12.5, quantityUnit: 'kg'));
      expect(action.quantityLabel, '12.5 kg');
    });

    test('falls back to the bare number when no unit is set', () {
      final action = EcoAction.fromMap(_actionMap(quantity: 4));
      expect(action.quantityLabel, '4');
    });
  });
}
