class SearchedUser {
  final int id;
  final String username;
  final String name;
  final String? profileUrl;
  final bool isFollowing;
  final bool isOnline;

  SearchedUser({
    required this.id,
    required this.username,
    required this.name,
    this.profileUrl,
    this.isFollowing = false,
    this.isOnline = false,
  });

  factory SearchedUser.fromJson(Map<String, dynamic> json) {
    return SearchedUser(
      id: json['id'] ?? json['user_id'],
      username: json['username'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      profileUrl: json['profile_url'],
      isFollowing: json['is_following'] ?? false,
      isOnline: json['is_online'] ?? false,
    );
  }

  SearchedUser copyWith({
    int? id,
    String? username,
    String? name,
    String? profileUrl,
    bool? isFollowing,
    bool? isOnline,
  }) {
    return SearchedUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      profileUrl: profileUrl ?? this.profileUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class UserProfile {
  final int id;
  final String username;
  final String name;
  final String? email;
  final String? profileUrl;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool followsYou;
  final bool isOnline;
  final String? status;

  UserProfile({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.profileUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.followsYou = false,
    this.isOnline = false,
    this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? json['user_id'],
      username: json['username'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      email: json['email'],
      profileUrl: json['profile_url'],
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
      followsYou: json['follows_you'] ?? false,
      isOnline: json['is_online'] ?? false,
      status: json['status'],
    );
  }
}