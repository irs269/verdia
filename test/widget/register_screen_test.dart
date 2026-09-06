import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/auth/presentation/screens/register_screen.dart';

import 'test_helpers.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: wrapLocalized(child),
  );
}

void main() {
  testWidgets('shows every validation error on an empty submit', (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Créer mon compte" est remplacé par un spinner.
    await tester.pump();

    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();

    expect(find.text('Champ requis'), findsNWidgets(2)); // Prénom, Nom
    expect(find.text("Nom d'utilisateur requis"), findsOneWidget);
    expect(find.text('Email requis'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
  });

  testWidgets('rejects a username with uppercase letters or spaces', (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Créer mon compte" est remplacé par un spinner.
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'Ahmed Green');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();

    expect(find.text('3-20 caractères : lettres, chiffres, . ou _'), findsOneWidget);
  });

  testWidgets('flags mismatched password confirmation', (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Créer mon compte" est remplacé par un spinner.
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'somethingElse');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();

    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
  });

  testWidgets('clears the mismatch error once the confirmation is fixed',
      (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Créer mon compte" est remplacé par un spinner.
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'somethingElse');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();
    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);

    // Les autres champs (prénom, email...) restent vides, donc
    // `validate()` échoue toujours globalement et `_submit` ne progresse
    // jamais jusqu'à l'appel réseau `signUp` — seule l'erreur de
    // correspondance des mots de passe doit disparaître ci-dessous.
    await tester.enterText(fields.at(5), 'password123');
    await tester.tap(find.text('Créer mon compte'));
    await tester.pump();

    expect(find.text('Les mots de passe ne correspondent pas'), findsNothing);
  });
}
