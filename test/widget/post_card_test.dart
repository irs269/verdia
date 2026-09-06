import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verdia/features/actions/domain/action_category.dart';
import 'package:verdia/features/actions/domain/eco_action.dart';
import 'package:verdia/features/auth/presentation/providers/auth_provider.dart';
import 'package:verdia/features/posts/domain/post.dart';
import 'package:verdia/features/posts/presentation/widgets/post_card.dart';

Post _fixturePost({
  bool isLikedByMe = false,
  bool isSavedByMe = false,
  int likeCount = 3,
  EcoAction? action,
}) {
  return Post(
    id: 'post-1',
    author: const PostAuthor(
      id: 'author-1',
      username: 'fatima.verdia',
      firstName: 'Fatima',
      lastName: 'Ali',
    ),
    content: "Aujourd'hui nous avons nettoyé la plage",
    createdAt: DateTime.now(), // évite tout formatage dépendant d'une locale
    media: const [],
    likeCount: likeCount,
    commentCount: 2,
    isLikedByMe: isLikedByMe,
    isSavedByMe: isSavedByMe,
    action: action,
  );
}

EcoAction _fixtureAction() {
  return EcoAction(
    id: 'action-1',
    category: const ActionCategory(
      id: 'cat-1',
      code: 'nettoyage',
      label: 'Nettoyage',
      icon: '🧹',
      color: Colors.teal,
    ),
    title: 'Nettoyage de la plage',
    description: 'Grand nettoyage communautaire',
    participantsCount: 8,
    occurredAt: DateTime.now(),
    status: 'verified',
    impactPoints: 30,
    createdAt: DateTime.now(),
  );
}

/// `PostCard` utilise des `InkWell` (icônes like/commentaire/partage), qui
/// exigent un ancêtre `Material` — un simple `MaterialApp(home: ...)` n'en
/// fournit pas à lui seul, il faut passer par un `Scaffold`. `currentUserProvider`
/// est surchargé à `null` pour éviter tout appel à Supabase (non initialisé en
/// test) — ces tests ne couvrent pas la logique "propriétaire du post".
Widget _wrap(Widget child, {String? currentUserId}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(
        currentUserId == null
            ? null
            : User(
                id: currentUserId,
                appMetadata: const {},
                userMetadata: const {},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
              ),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('renders author, content and like count', (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(post: _fixturePost(), onToggleLike: () {}, onToggleSave: () {}),
    ));

    expect(find.text('Fatima Ali'), findsOneWidget);
    expect(find.text("Aujourd'hui nous avons nettoyé la plage"), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows the category badge and impact points when linked to an action',
      (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(
        post: _fixturePost(action: _fixtureAction()),
        onToggleLike: () {},
        onToggleSave: () {},
      ),
    ));

    expect(find.textContaining('Nettoyage'), findsWidgets);
    expect(find.textContaining('+30 points'), findsOneWidget);
  });

  testWidgets('shows a filled heart when already liked, outline otherwise',
      (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(post: _fixturePost(isLikedByMe: false), onToggleLike: () {}, onToggleSave: () {}),
    ));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);

    await tester.pumpWidget(_wrap(
      PostCard(post: _fixturePost(isLikedByMe: true), onToggleLike: () {}, onToggleSave: () {}),
    ));
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('invokes onToggleLike when the heart icon is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PostCard(
        post: _fixturePost(),
        onToggleLike: () => tapped = true,
        onToggleSave: () {},
      ),
    ));

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('invokes onToggleSave when the bookmark icon is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PostCard(
        post: _fixturePost(),
        onToggleLike: () {},
        onToggleSave: () => tapped = true,
      ),
    ));

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('offers "Signaler" (not "Supprimer") on someone else\'s post', (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(post: _fixturePost(), onToggleLike: () {}, onToggleSave: () {}),
      currentUserId: 'someone-else',
    ));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Signaler'), findsOneWidget);
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets('offers "Supprimer" (not "Signaler") on your own post', (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(post: _fixturePost(), onToggleLike: () {}, onToggleSave: () {}),
      currentUserId: 'author-1',
    ));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer'), findsOneWidget);
    expect(find.text('Signaler'), findsNothing);
  });

  testWidgets('offers "Modifier" on your own text-only post', (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(post: _fixturePost(), onToggleLike: () {}, onToggleSave: () {}),
      currentUserId: 'author-1',
    ));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsOneWidget);
  });

  testWidgets('does not offer "Modifier" on your own action-linked post',
      (tester) async {
    await tester.pumpWidget(_wrap(
      PostCard(
        post: _fixturePost(action: _fixtureAction()),
        onToggleLike: () {},
        onToggleSave: () {},
      ),
      currentUserId: 'author-1',
    ));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsOneWidget);
  });
}
