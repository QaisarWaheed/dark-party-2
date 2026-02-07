// models/base_response_model.dart
class BaseResponseModel {
  final bool success;
  final String message;
  final dynamic data;
  final String status;

  BaseResponseModel({
    required this.success,
    required this.message,
    this.data,
    required this.status,
  });

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    return BaseResponseModel(
      success: json['status'] == 'success',
      message: json['message'] ?? '',
      data: json['data'],
      status: json['status'] ?? 'error',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'status': status,
    };
  }
}


// models/chat_message_model.dart
class ChatMessage {
  final int id;
  final int chatroomId;
  final int senderId;
  final String senderName;
  final String message;
  final String messageType;
  final String filePath;
  final bool isDeleted;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatroomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.messageType = 'text',
    this.filePath = '',
    this.isDeleted = false,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      chatroomId: json['chatroom_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      filePath: json['file_path'] ?? '',
      isDeleted: json['is_deleted'] == 1,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatroom_id': chatroomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'message_type': messageType,
      'file_path': filePath,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}



// models/chat_room_model.dart
class ChatRoom {
  final int id;
  final int user1Id;
  final int user2Id;
  final String user1Name;
  final String user2Name;
  final DateTime lastActivity;
  final DateTime createdAt;
  final ChatMessage? lastMessage;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    required this.lastActivity,
    required this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? 0,
      user1Id: json['user1_id'] ?? 0,
      user2Id: json['user2_id'] ?? 0,
      
      // ✅ API RESPONSE ME YE FIELDS HAIN
      user1Name: json['other_user_name'] ?? '',  // ✅ Changed
      user2Name: json['other_user_name'] ?? '',  // ✅ Changed
      
      lastActivity: DateTime.parse(json['last_activity'] ?? DateTime.now().toString()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      
      // ✅ LAST MESSAGE NULL HO SAKTA HAI
      lastMessage: json['last_message'] != null 
          ? ChatMessage.fromJson(json['last_message']) 
          : null,
      
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  String getOtherUserName(int currentUserId) {
    // ✅ API already "other_user_name" return kar rahi hai
    return user1Name; // Ya user2Name (dono same hain)
  }

  int getOtherUserId(int currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'user1_name': user1Name,
      'user2_name': user2Name,
      'last_activity': lastActivity.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
    };
  }
}


// class ChatUserModel {
//   final int id;
//   final String name;
//   final String username;
//   final String profileUrl;
//   final String? countryFlag;
//   final int? views;
//   final bool isOnline;
//   bool isFollowing;
//   final int followersCount;
//   final int followingCount;

//   ChatUserModel({
//     required this.id,
//     required this.name,
//     required this.username,
//     required this.profileUrl,
//     this.countryFlag,
//     this.views,
//     this.isOnline = false,
//     this.isFollowing = false,
//     this.followersCount = 0,
//     this.followingCount = 0,
//   });

//   factory ChatUserModel.fromJson(Map<String, dynamic> json) {
//     return ChatUserModel(
//       id: json['id'] ?? json['user_id'] ?? 0,
//       name: json['name'] ?? '',
//       username: json['username'] ?? '',
//       profileUrl: json['profile_url'] ?? json['profileUrl'] ?? '',
//       countryFlag: json['country_flag'] ?? json['countryFlag'] ?? '🇵🇰',
//       views: json['views'] ?? json['viewCount'] ?? 0,
//       isOnline: json['is_online'] ?? json['isOnline'] ?? false,
//       isFollowing: json['is_following'] ?? json['isFollowing'] ?? false,
//       followersCount: json['followers_count'] ?? json['followersCount'] ?? 0,
//       followingCount: json['following_count'] ?? json['followingCount'] ?? 0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'username': username,
//       'profile_url': profileUrl,
//       'country_flag': countryFlag,
//       'views': views,
//       'is_online': isOnline,
//       'is_following': isFollowing,
//       'followers_count': followersCount,
//       'following_count': followingCount,
//     };
//   }
// }