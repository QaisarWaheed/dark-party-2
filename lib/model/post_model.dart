class PostModel {
  final int id;
  final int userId;
  final String username;
  final String userName;
  final String? profileUrl;
  final String caption;
  final String? mediaUrl;
  final String mediaType; // image | video | text
  int likesCount;
  final int commentsCount;
  final String visibility;
  bool isLiked;
  final List<String> hashtags;
  final DateTime createdAt;
  final String formattedDate;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userName,
    this.profileUrl,
    required this.caption,
    this.mediaUrl,
    required this.mediaType,
    required this.likesCount,
    required this.commentsCount,
    required this.visibility,
    required this.isLiked,
    required this.hashtags,
    required this.createdAt,
    required this.formattedDate,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Normalize profile URL
    String? profile;
    if (json['profile_url'] != null &&
        json['profile_url'].toString().isNotEmpty &&
        !json['profile_url'].toString().startsWith('http')) {
      profile = 'https://shaheenstar.online/${json['profile_url']}';
    } else {
      profile = json['profile_url']?.toString();
    }

    return PostModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      profileUrl: profile,
      caption: json['caption']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString() ?? 'text',
      likesCount: int.tryParse(json['likes_count'].toString()) ?? 0,
      commentsCount: int.tryParse(json['comments_count'].toString()) ?? 0,
      visibility: json['visibility']?.toString() ?? 'public',
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      hashtags: json['hashtags'] != null
          ? List<String>.from(json['hashtags'])
          : [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      formattedDate: json['formatted_date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_name': userName,
      'profile_url': profileUrl,
      'caption': caption,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'visibility': visibility,
      'is_liked': isLiked,
      'hashtags': hashtags,
      'created_at': createdAt.toIso8601String(),
      'formatted_date': formattedDate,
    };
  }

  // Helpers
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}


class FeedData {
  final List<PostModel> posts;
  final int page;
  final int limit;
  final int total;

  FeedData({
    required this.posts,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory FeedData.fromJson(Map<String, dynamic> json) {
    return FeedData(
      posts: json['posts'] != null
          ? (json['posts'] as List)
              .map((e) => PostModel.fromJson(e))
              .toList()
          : [],
      page: int.tryParse(json['page'].toString()) ?? 1,
      limit: int.tryParse(json['limit'].toString()) ?? 10,
      total: int.tryParse(json['total'].toString()) ?? 0,
    );
  }
}


class FeedResponse {
  final String status;
  final String? message;
  final FeedData? data;

  FeedResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString(),
      data: json['data'] != null
          ? FeedData.fromJson(json['data'])
          : null,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}
