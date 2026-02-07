class CommentModel {
  final int id;
  final int postId;
  final int userId;
  final String username;
  final String? profileUrl;
  final String comment;
  final int? parentCommentId;
  final DateTime createdAt;
  final String formattedDate;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.profileUrl,
    required this.comment,
    this.parentCommentId,
    required this.createdAt,
    required this.formattedDate,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? 0,
      postId: json['post_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      profileUrl: json['profile_url'],
      comment: json['comment'] ?? '',
      parentCommentId: json['parent_comment_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      formattedDate: json['formatted_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'profile_url': profileUrl,
      'comment': comment,
      'parent_comment_id': parentCommentId,
      'created_at': createdAt.toIso8601String(),
      'formatted_date': formattedDate,
    };
  }
}
