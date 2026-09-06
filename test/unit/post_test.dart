import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/posts/domain/post.dart';

Map<String, dynamic> _authorMap({String username = 'ahmed.verdia'}) => {
      'username': username,
      'first_name': 'Ahmed',
      'last_name': 'Said',
      'avatar_url': null,
    };

Map<String, dynamic> _basePostMap({
  String id = 'post-1',
  String? content,
  List<Map<String, dynamic>>? media,
  List<Map<String, dynamic>>? likes,
  List<Map<String, dynamic>>? comments,
  Map<String, dynamic>? action,
  String? city,
  String? country,
}) {
  return {
    'id': id,
    'author_id': 'author-1',
    'content': content ?? 'Belle action aujourd\'hui',
    'city': city,
    'country': country,
    'created_at': '2026-09-05T12:00:00.000Z',
    'profiles': _authorMap(),
    'post_media': media ?? [],
    'likes': likes ?? [],
    'comments': comments ?? [],
    'actions': action,
  };
}

void main() {
  group('Post.fromMap', () {
    test('parses author, content and dates', () {
      final post = Post.fromMap(_basePostMap());

      expect(post.id, 'post-1');
      expect(post.author.username, 'ahmed.verdia');
      expect(post.author.fullName, 'Ahmed Said');
      expect(post.content, "Belle action aujourd'hui");
      expect(post.createdAt, DateTime.parse('2026-09-05T12:00:00.000Z'));
    });

    test('extracts like and comment counts from the embedded aggregates', () {
      final post = Post.fromMap(_basePostMap(
        likes: [
          {'count': 5}
        ],
        comments: [
          {'count': 2}
        ],
      ));

      expect(post.likeCount, 5);
      expect(post.commentCount, 2);
    });

    test('defaults counts to zero when the aggregate is empty', () {
      final post = Post.fromMap(_basePostMap());

      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
    });

    test('sorts media by position regardless of input order', () {
      final post = Post.fromMap(_basePostMap(media: [
        {'id': 'm2', 'url': 'https://x/2.jpg', 'type': 'image', 'position': 1},
        {'id': 'm1', 'url': 'https://x/1.jpg', 'type': 'image', 'position': 0},
      ]));

      expect(post.media.map((m) => m.id), ['m1', 'm2']);
    });

    test('media label defaults to null for untagged gallery photos', () {
      final post = Post.fromMap(_basePostMap(media: [
        {'id': 'm1', 'url': 'https://x/1.jpg', 'type': 'image', 'position': 0},
      ]));

      expect(post.media.single.label, isNull);
    });

    test('media label is parsed when tagged avant/apres', () {
      final post = Post.fromMap(_basePostMap(media: [
        {'id': 'm1', 'url': 'https://x/1.jpg', 'type': 'image', 'position': 0, 'label': 'avant'},
        {'id': 'm2', 'url': 'https://x/2.jpg', 'type': 'image', 'position': 1, 'label': 'apres'},
      ]));

      expect(post.media.map((m) => m.label), ['avant', 'apres']);
    });

    test('action is null for a plain post with no linked action', () {
      final post = Post.fromMap(_basePostMap());
      expect(post.action, isNull);
    });

    test('isLikedByMe and isSavedByMe always start false from the server payload', () {
      // Ces valeurs sont volontairement absentes de la ligne SQL : elles sont
      // recalculées côté repository via une requête séparée, jamais lues
      // directement depuis la ligne `posts`.
      final post = Post.fromMap(_basePostMap());
      expect(post.isLikedByMe, isFalse);
      expect(post.isSavedByMe, isFalse);
    });
  });

  group('Post.location', () {
    test('is null when neither city nor country is set', () {
      final post = Post.fromMap(_basePostMap());
      expect(post.location, isNull);
    });

    test('joins city and country when both are present', () {
      final post = Post.fromMap(_basePostMap(city: 'Moroni', country: 'Comores'));
      expect(post.location, 'Moroni, Comores');
    });

    test('shows only city when country is absent', () {
      final post = Post.fromMap(_basePostMap(city: 'Moroni'));
      expect(post.location, 'Moroni');
    });
  });

  group('Post.copyWith', () {
    test('overrides only the requested viewer-state fields', () {
      final post = Post.fromMap(_basePostMap(likes: [
        {'count': 3}
      ]));

      final liked = post.copyWith(isLikedByMe: true, likeCount: post.likeCount + 1);

      expect(liked.isLikedByMe, isTrue);
      expect(liked.likeCount, 4);
      expect(liked.id, post.id);
      expect(liked.content, post.content);
    });
  });
}
