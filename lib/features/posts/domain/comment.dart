import 'post.dart';

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      author: PostAuthor.fromMap(
        map['author_id'] as String,
        map['profiles'] as Map<String, dynamic>,
      ),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String postId;
  final PostAuthor author;
  final String content;
  final DateTime createdAt;
}
