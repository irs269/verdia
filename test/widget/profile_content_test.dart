import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/profile/domain/profile.dart';
import 'package:verdia/features/profile/presentation/widgets/profile_content.dart';

const _profile = Profile(
  id: 'user-1',
  username: 'fatima.verdia',
  firstName: 'Fatima',
  lastName: 'Ali',
  bio: 'Passionnée par la nature',
  city: 'Moroni',
  country: 'Comores',
  level: 2,
  totalPoints: 65,
);

Widget _wrap({int? friends, Widget? impactSummary}) {
  return MaterialApp(
    home: ProfileContent(
      profile: _profile,
      friends: friends,
      impactSummary: impactSummary,
      actionButton: const Text('Modifier le profil'),
      tabLabels: const ['Mes actions', 'Mes badges'],
      tabViews: const [Text('Contenu actions'), Text('Contenu badges')],
    ),
  );
}

void main() {
  testWidgets('renders identity, location, bio and stats', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Fatima Ali'), findsOneWidget);
    expect(find.text('@fatima.verdia'), findsOneWidget);
    expect(find.text('Moroni, Comores'), findsOneWidget);
    expect(find.text('Passionnée par la nature'), findsOneWidget);
    expect(find.text('⭐ 65'), findsOneWidget);
    expect(find.text('🏆 2'), findsOneWidget);
  });

  testWidgets('hides friend stat when count is not provided', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('amis'), findsNothing);
    expect(find.text('ami'), findsNothing);
  });

  testWidgets('shows friend stat once count is provided', (tester) async {
    await tester.pumpWidget(_wrap(friends: 34));
    expect(find.text('34'), findsOneWidget);
    expect(find.text('amis'), findsOneWidget);
  });

  testWidgets('renders the provided action button and tab labels', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Mes actions'), findsOneWidget);
    expect(find.text('Mes badges'), findsOneWidget);
  });

  testWidgets('renders the impact summary slot only when supplied', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('🌳 3'), findsNothing);

    await tester.pumpWidget(_wrap(impactSummary: const Text('🌳 3')));
    expect(find.text('🌳 3'), findsOneWidget);
  });
}
