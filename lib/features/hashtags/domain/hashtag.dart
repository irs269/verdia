class Hashtag {
  const Hashtag({required this.tag, required this.postCount});

  factory Hashtag.fromMap(Map<String, dynamic> map) {
    final counts = map['post_hashtags'] as List?;
    return Hashtag(
      tag: map['tag'] as String,
      postCount: (counts != null && counts.isNotEmpty)
          ? (counts.first as Map<String, dynamic>)['count'] as int? ?? 0
          : 0,
    );
  }

  /// Sans le `#` — voir migration 0024.
  final String tag;
  final int postCount;
}
