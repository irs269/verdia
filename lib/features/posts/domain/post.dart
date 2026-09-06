import '../../actions/domain/eco_action.dart';

class PostAuthor {
  const PostAuthor({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  factory PostAuthor.fromMap(String id, Map<String, dynamic> map) {
    return PostAuthor(
      id: id,
      username: map['username'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName';
}

class PostMedia {
  const PostMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.position,
    this.label,
  });

  factory PostMedia.fromMap(Map<String, dynamic> map) {
    return PostMedia(
      id: map['id'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      position: map['position'] as int,
      label: map['label'] as String?,
    );
  }

  /// 'avant' | 'apres' | `null` (photo de galerie non taguée) — voir
  /// migration 0015.
  final String? label;

  final String id;
  final String url;
  final String type;
  final int position;
}

class Post {
  const Post({
    required this.id,
    required this.author,
    required this.content,
    this.city,
    this.country,
    required this.createdAt,
    required this.media,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByMe,
    required this.isSavedByMe,
    this.action,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    final mediaList = (map['post_media'] as List? ?? [])
        .map((e) => PostMedia.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    int extractCount(dynamic raw) {
      if (raw is List && raw.isNotEmpty) {
        return (raw.first as Map<String, dynamic>)['count'] as int? ?? 0;
      }
      return 0;
    }

    return Post(
      id: map['id'] as String,
      author: PostAuthor.fromMap(
        map['author_id'] as String,
        map['profiles'] as Map<String, dynamic>,
      ),
      content: map['content'] as String,
      city: map['city'] as String?,
      country: map['country'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      media: mediaList,
      likeCount: extractCount(map['likes']),
      commentCount: extractCount(map['comments']),
      isLikedByMe: false,
      isSavedByMe: false,
      action: map['actions'] != null
          ? EcoAction.fromMap(map['actions'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final PostAuthor author;
  final String content;
  final String? city;
  final String? country;
  final DateTime createdAt;
  final List<PostMedia> media;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final bool isSavedByMe;
  final EcoAction? action;

  String? get location {
    if (city == null && country == null) return null;
    return [city, country].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  Post copyWith({
    String? content,
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
    bool? isSavedByMe,
  }) {
    return Post(
      id: id,
      author: author,
      content: content ?? this.content,
      city: city,
      country: country,
      createdAt: createdAt,
      media: media,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      action: action,
    );
  }
}
