import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/auth/presentation/screens/login_screen.dart';

import 'test_helpers.dart';

/// Ces tests ne couvrent que la validation du formulaire, qui s'exécute
/// entièrement côté client avant tout appel à Supabase — `LoginScreen` ne
/// touche donc jamais le réseau tant que `_formKey.currentState!.validate()`
/// échoue, ce qui permet de la tester sans initialiser Supabase.
Widget _wrap(Widget child) {
  return ProviderScope(
    child: wrapLocalized(child),
  );
}

void main() {
  testWidgets('shows validation errors when submitting an empty form',
      (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Se connecter" est remplacé par un spinner.
    await tester.pump();

    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Email requis'), findsOneWidget);
    expect(find.text('Mot de passe requis'), findsOneWidget);
  });

  testWidgets('shows an email format error for a malformed address',
      (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Se connecter" est remplacé par un spinner.
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Email invalide'), findsOneWidget);
  });

  testWidgets('clears the email error once a valid address is entered',
      (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Se connecter" est remplacé par un spinner.
    await tester.pump();

    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.text('Email requis'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Email requis'), findsNothing);
    expect(find.text('Email invalide'), findsNothing);
  });

  testWidgets('renders the core call-to-actions', (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Se connecter" est remplacé par un spinner.
    await tester.pump();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.textContaining("S'inscrire"), findsOneWidget);
  });

  testWidgets('toggles password visibility when tapping the eye icon',
      (tester) async {
    useTallTestViewport(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    // Laisse `AuthController.build()` (un Future trivial) se résoudre avant
    // toute assertion : sur la toute première frame, `authState.isLoading`
    // vaut encore `true` et "Se connecter" est remplacé par un spinner.
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
  });
}
