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

Widget _wrap({int? followers, int? following, Widget? impactSummary}) {
  return MaterialApp(
    home: ProfileContent(
      profile: _profile,
      followers: followers,
      following: following,
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

  testWidgets('hides follow stats when counts are not provided', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('abonnements'), findsNothing);
    expect(find.text('abonnés'), findsNothing);
  });

  testWidgets('shows follow stats once counts are provided', (tester) async {
    await tester.pumpWidget(_wrap(followers: 12, following: 34));
    expect(find.text('34'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('abonnements'), findsOneWidget);
    expect(find.text('abonnés'), findsOneWidget);
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
