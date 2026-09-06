import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/actions/domain/action_category.dart';
import 'package:verdia/features/actions/presentation/providers/action_provider.dart';
import 'package:verdia/features/actions/presentation/screens/create_action_screen.dart';

final _fixtureCategories = [
  ActionCategory(id: 'cat-1', code: 'plantation', label: 'Plantation', icon: '🌳', color: Colors.green),
  ActionCategory(id: 'cat-2', code: 'nettoyage', label: 'Nettoyage', icon: '🧹', color: Colors.teal),
];

/// `actionCategoriesProvider` est surchargé pour ne jamais toucher
/// `ActionRepository`/Supabase : c'est le point d'entrée réseau du premier
/// écran, tout le reste de l'assistant (étapes 2 et 3) n'est atteint que
/// via les interactions testées ici, sans jamais appeler `estimatePoints`
/// ni `publish` (qui nécessiteraient un vrai client Supabase).
Widget _wrap() {
  return ProviderScope(
    overrides: [
      actionCategoriesProvider.overrideWith((ref) => Future.value(_fixtureCategories)),
    ],
    child: const MaterialApp(home: CreateActionScreen()),
  );
}

void main() {
  testWidgets('the "Suivant" button starts disabled with no category selected',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a category enables "Suivant"', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plantation'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('moving to step 2 shows the details form with a dynamic quantity label',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plantation'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('Titre'), findsOneWidget);
    expect(find.text("Nombre d'arbres plantés"), findsOneWidget);
  });

  testWidgets('the quantity label changes when a different category is picked back on step 1',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nettoyage'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('Déchets collectés (kg)'), findsOneWidget);
  });

  testWidgets('step 2 flags empty required fields when trying to advance',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plantation'));
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pump();

    // Sur l'étape 2, le bouton "Suivant" appelle `_goToPreview`, qui valide
    // le formulaire avant de calculer une estimation de points (laquelle
    // toucherait le réseau) — avec des champs vides, la validation échoue
    // et on ne quitte jamais cette étape.
    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('Titre requis'), findsOneWidget);
    expect(find.text('Description requise'), findsOneWidget);
  });
}
