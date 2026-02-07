// // lib/model/user_chat_model.dart

// class UserChatRoom {
//   final int id;
//   final int userId;
//   final int otherUserId;
//   final String otherUserName;
//   final String otherUserUsername;
//   final String? otherUserProfileUrl;
//   final String? lastMessage;
//   final DateTime? lastMessageTime;
//   final int unreadCount;
//   final bool isOnline;
//   final String? status; // online, away, busy, offline

//   UserChatRoom({
//     required this.id,
//     required this.userId,
//     required this.otherUserId,
//     required this.otherUserName,
//     required this.otherUserUsername,
//     this.otherUserProfileUrl,
//     this.lastMessage,
//     this.lastMessageTime,
//     this.unreadCount = 0,
//     this.isOnline = false,
//     this.status,
//   });

//   factory UserChatRoom.fromJson(Map<String, dynamic> json) {
//     return UserChatRoom(
//       id: json['chatroom_id'] ?? json['id'] ?? 0,
//       userId: json['user_id'] ?? 0,
//       otherUserId: json['other_user_id'] ?? 0,
//       otherUserName: json['other_user_name'] ?? json['name'] ?? '',
//       otherUserUsername: json['other_user_username'] ?? json['username'] ?? '',
//       otherUserProfileUrl: json['other_user_profile_url'] ?? json['profile_url'],
//       lastMessage: json['last_message'],
//       lastMessageTime: json['last_message_time'] != null
//           ? DateTime.parse(json['last_message_time'])
//           : null,
//       unreadCount: json['unread_count'] ?? 0,
//       isOnline: json['is_online'] ?? false,
//       status: json['status'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'user_id': userId,
//       'other_user_id': otherUserId,
//       'other_user_name': otherUserName,
//       'other_user_username': otherUserUsername,
//       'other_user_profile_url': otherUserProfileUrl,
//       'last_message': lastMessage,
//       'last_message_time': lastMessageTime?.toIso8601String(),
//       'unread_count': unreadCount,
//       'is_online': isOnline,
//       'status': status,
//     };
//   }

//   UserChatRoom copyWith({
//     int? id,
//     int? userId,
//     int? otherUserId,
//     String? otherUserName,
//     String? otherUserUsername,
//     String? otherUserProfileUrl,
//     String? lastMessage,
//     DateTime? lastMessageTime,
//     int? unreadCount,
//     bool? isOnline,
//     String? status,
//   }) {
//     return UserChatRoom(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       otherUserId: otherUserId ?? this.otherUserId,
//       otherUserName: otherUserName ?? this.otherUserName,
//       otherUserUsername: otherUserUsername ?? this.otherUserUsername,
//       otherUserProfileUrl: otherUserProfileUrl ?? this.otherUserProfileUrl,
//       lastMessage: lastMessage ?? this.lastMessage,
//       lastMessageTime: lastMessageTime ?? this.lastMessageTime,
//       unreadCount: unreadCount ?? this.unreadCount,
//       isOnline: isOnline ?? this.isOnline,
//       status: status ?? this.status,
//     );
//   }
// }

// class UserChatMessage {
//   final int id;
//   final int chatroomId;
//   final int senderId;
//   final String senderName;
//   final String senderUsername;
//   final String? senderProfileUrl;
//   final String message;
//   final DateTime createdAt;
//   final bool isRead;

//   UserChatMessage({
//     required this.id,
//     required this.chatroomId,
//     required this.senderId,
//     required this.senderName,
//     required this.senderUsername,
//     this.senderProfileUrl,
//     required this.message,
//     required this.createdAt,
//     this.isRead = false,
//   });

//   factory UserChatMessage.fromJson(Map<String, dynamic> json) {
//     return UserChatMessage(
//       id: json['id'] ?? 0,
//       chatroomId: json['chatroom_id'] ?? 0,
//       senderId: json['sender_id'] ?? 0,
//       senderName: json['sender_name'] ?? '',
//       senderUsername: json['sender_username'] ?? '',
//       senderProfileUrl: json['sender_profile_url'],
//       message: json['message'] ?? '',
//       createdAt: DateTime.parse(json['created_at']),
//       isRead: json['is_read'] ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'chatroom_id': chatroomId,
//       'sender_id': senderId,
//       'sender_name': senderName,
//       'sender_username': senderUsername,
//       'sender_profile_url': senderProfileUrl,
//       'message': message,
//       'created_at': createdAt.toIso8601String(),
//       'is_read': isRead,
//     };
//   }
// }

// class SearchedUser {
//   final int id;
//   final String username;
//   final String name;
//   final String? profileUrl;
//   final bool isOnline;
//   final String? status;
//   final bool isFollowing;
//   final bool isFollower;

//   SearchedUser({
//     required this.id,
//     required this.username,
//     required this.name,
//     this.profileUrl,
//     this.isOnline = false,
//     this.status,
//     this.isFollowing = false,
//     this.isFollower = false,
//   });

//   factory SearchedUser.fromJson(Map<String, dynamic> json) {
//     return SearchedUser(
//       id: json['id'] ?? 0,
//       username: json['username'] ?? '',
//       name: json['name'] ?? '',
//       profileUrl: json['profile_url'],
//       isOnline: json['is_online'] ?? false,
//       status: json['status'],
//       isFollowing: json['is_following'] ?? false,
//       isFollower: json['is_follower'] ?? false,
//     );
//   }
// }


// lib/model/user_chat_model.dart

class UserChatRoom {
  final int id;
  final int userId;
  final int otherUserId;
  final String otherUserName;
  final String otherUserUsername;
  final String? otherUserProfileUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String? status; // online, away, busy, offline

  UserChatRoom({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserUsername,
    this.otherUserProfileUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.status,
  });

  factory UserChatRoom.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      try {
        return v.toString();
      } catch (_) {
        return '';
      }
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        final s = parseString(v);
        if (s.isEmpty) return null;
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    String? profileUrl;
    if (json['other_user_profile_url'] != null) {
      final v = json['other_user_profile_url'];
      profileUrl = v is String ? v : v is Map ? (v['url']?.toString() ?? v.toString()) : v.toString();
    } else if (json['profile_url'] != null) {
      final v = json['profile_url'];
      profileUrl = v is String ? v : v is Map ? (v['url']?.toString() ?? v.toString()) : v.toString();
    } else {
      profileUrl = null;
    }

    // Try nested user objects for name/profile if top-level keys missing
    if ((json['other_user_name'] == null || json['other_user_name'].toString().isEmpty) && (json['name'] == null || json['name'].toString().isEmpty)) {
      final candidates = ['other_user', 'user', 'user_info', 'other', 'participant'];
      for (var key in candidates) {
        if (json[key] is Map) {
          final m = json[key] as Map<String, dynamic>;
          if (m['name'] != null && m['name'].toString().isNotEmpty) {
            // prefer this
            json['other_user_name'] = m['name'];
          }
          if (m['username'] != null && (json['other_user_username'] == null || json['other_user_username'].toString().isEmpty)) {
            json['other_user_username'] = m['username'];
          }
          if ((profileUrl == null || profileUrl.isEmpty) && (m['profile_url'] != null || m['avatar'] != null || m['picture'] != null)) {
            profileUrl = (m['profile_url'] ?? m['avatar'] ?? m['picture']) is String
                ? (m['profile_url'] ?? m['avatar'] ?? m['picture']) as String
                : ((m['profile_url'] ?? m['avatar'] ?? m['picture'])?.toString());
          }
          break;
        }
      }
    }

    return UserChatRoom(
      id: (json['chatroom_id'] ?? json['id'] ?? 0) is int
          ? (json['chatroom_id'] ?? json['id'] ?? 0)
          : int.tryParse((json['chatroom_id'] ?? json['id'] ?? '0').toString()) ?? 0,
      userId: (json['user_id'] ?? 0) is int
          ? (json['user_id'] ?? 0)
          : int.tryParse((json['user_id'] ?? '0').toString()) ?? 0,
      otherUserId: (json['other_user_id'] ?? 0) is int
          ? (json['other_user_id'] ?? 0)
          : int.tryParse((json['other_user_id'] ?? '0').toString()) ?? 0,
      otherUserName: json['other_user_name'] != null
          ? parseString(json['other_user_name'])
          : (json['name'] != null ? parseString(json['name']) : ''),
      otherUserUsername: json['other_user_username'] != null
          ? parseString(json['other_user_username'])
          : (json['username'] != null ? parseString(json['username']) : ''),
      otherUserProfileUrl: profileUrl,
      lastMessage: (() {
        final lm = json['last_message'];
        if (lm == null) return null;
        if (lm is String) return lm;
        if (lm is Map) {
          // common message text keys
          final keys = ['message', 'text', 'body', 'message_text', 'msg'];
          for (var k in keys) {
            if (lm.containsKey(k) && lm[k] != null) return lm[k].toString();
          }
          // if not found, try nested sender/message structure
          if (lm['data'] is Map && lm['data']['message'] != null) return lm['data']['message'].toString();
          // fallback to a concise map summary
          final preview = lm.entries.map((e) => '${e.key}: ${e.value}').take(3).join(', ');
          return preview;
        }
        return lm.toString();
      })(),
      lastMessageTime: parseDate(json['last_message_time']),
      unreadCount: (json['unread_count'] ?? 0) is int
          ? (json['unread_count'] ?? 0)
          : int.tryParse((json['unread_count'] ?? '0').toString()) ?? 0,
      isOnline: json['is_online'] is bool
          ? json['is_online']
          : (json['is_online'] != null ? (json['is_online'].toString() == '1' || json['is_online'].toString().toLowerCase() == 'true') : false),
      status: json['status'] is String ? json['status'] : (json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_username': otherUserUsername,
      'other_user_profile_url': otherUserProfileUrl,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'is_online': isOnline,
      'status': status,
    };
  }

  UserChatRoom copyWith({
    int? id,
    int? userId,
    int? otherUserId,
    String? otherUserName,
    String? otherUserUsername,
    String? otherUserProfileUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    String? status,
  }) {
    return UserChatRoom(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserUsername: otherUserUsername ?? this.otherUserUsername,
      otherUserProfileUrl: otherUserProfileUrl ?? this.otherUserProfileUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
    );
  }
}

class UserChatMessage {
  final int id;
  final int chatroomId;
  final int senderId;
  final String senderName;
  final String senderUsername;
  final String? senderProfileUrl;
  final String message;
  final String? attachmentUrl; // local path or remote URL for image/voice
  final String? attachmentType; // 'image'|'voice'|null
  final DateTime createdAt;
  final bool isRead;

  UserChatMessage({
    required this.id,
    required this.chatroomId,
    required this.senderId,
    required this.senderName,
    required this.senderUsername,
    this.senderProfileUrl,
    required this.message,
    this.attachmentUrl,
    this.attachmentType,
    required this.createdAt,
    this.isRead = false,
  });

  factory UserChatMessage.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      try {
        return v.toString();
      } catch (_) {
        return '';
      }
    }

    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      try {
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        final s = parseString(v);
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final senderProfile = json['sender_profile_url'];
    final senderProfileUrl = senderProfile is String
        ? senderProfile
        : senderProfile is Map
            ? (senderProfile['url']?.toString() ?? senderProfile.toString())
            : (senderProfile?.toString());

    // Inspect message text for a direct image URL fallback
    final parsedMessage = json['message'] != null ? parseString(json['message']) : '';
    String? fallbackAttachmentUrl;
    String? fallbackAttachmentType;
    if (parsedMessage.isNotEmpty) {
      final lower = parsedMessage.toLowerCase();
      if (lower.startsWith('http') && (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp') || lower.contains('/uploads/') || lower.contains('/storage/'))) {
        fallbackAttachmentUrl = parsedMessage;
        fallbackAttachmentType = 'image';
      }
    }

    return UserChatMessage(
      id: (json['id'] ?? 0) is int ? (json['id'] ?? 0) : int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      chatroomId: (json['chatroom_id'] ?? 0) is int
          ? (json['chatroom_id'] ?? 0)
          : int.tryParse((json['chatroom_id'] ?? '0').toString()) ?? 0,
      senderId: (json['sender_id'] ?? 0) is int
          ? (json['sender_id'] ?? 0)
          : int.tryParse((json['sender_id'] ?? '0').toString()) ?? 0,
      senderName: json['sender_name'] != null ? parseString(json['sender_name']) : '',
      senderUsername: json['sender_username'] != null ? parseString(json['sender_username']) : '',
      senderProfileUrl: senderProfileUrl,
      message: parsedMessage,
      attachmentUrl: (() {
        if (json['image_url'] != null) return parseString(json['image_url']);
        if (json['voice_url'] != null) return parseString(json['voice_url']);
        if (json['attachment_url'] != null) return parseString(json['attachment_url']);
        // Sometimes the server returns file info in 'data' or 'file'
        if (json['data'] is Map && json['data']['file'] != null) return parseString(json['data']['file']);
        if (json['data'] is Map && json['data']['media_url'] != null) return parseString(json['data']['media_url']);
        if (json['data'] is Map && json['data']['mediaUrl'] != null) return parseString(json['data']['mediaUrl']);
        // Also accept top-level media_url or mediaUrl
        if (json['media_url'] != null) return parseString(json['media_url']);
        if (json['mediaUrl'] != null) return parseString(json['mediaUrl']);
        return fallbackAttachmentUrl;
      })(),
      attachmentType: (() {
        if (json['image_url'] != null) return 'image';
        if (json['voice_url'] != null) return 'voice';
        if (json['attachment_type'] != null) return parseString(json['attachment_type']);
        if (json['data'] is Map && json['data']['media_url'] != null) return 'image';
        if (json['data'] is Map && json['data']['mediaUrl'] != null) return 'image';
        // Top-level message_type or type fields
        if (json['message_type'] != null) {
          final mt = parseString(json['message_type']).toLowerCase();
          if (mt == 'image') return 'image';
          if (mt == 'voice' || mt == 'audio') return 'voice';
        }
        if (json['messageType'] != null) {
          final mt = parseString(json['messageType']).toLowerCase();
          if (mt == 'image') return 'image';
          if (mt == 'voice' || mt == 'audio') return 'voice';
        }
        if (json['type'] != null) {
          final mt = parseString(json['type']).toLowerCase();
          if (mt == 'image') return 'image';
          if (mt == 'voice' || mt == 'audio') return 'voice';
        }
        return fallbackAttachmentType;
      })(),
      createdAt: parseDate(json['created_at']),
      isRead: json['is_read'] is bool
          ? json['is_read']
          : (json['is_read'] != null ? (json['is_read'].toString() == '1' || json['is_read'].toString().toLowerCase() == 'true') : false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatroom_id': chatroomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_username': senderUsername,
      'sender_profile_url': senderProfileUrl,
      'message': message,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class SearchedUser {
  final int id;
  final String username;
  final String name;
  final String? profileUrl;
  final bool isOnline;
  final String? status;
  final bool isFollowing;
  final bool isFollower;

  SearchedUser({
    required this.id,
    required this.username,
    required this.name,
    this.profileUrl,
    this.isOnline = false,
    this.status,
    this.isFollowing = false,
    this.isFollower = false,
  });

  factory SearchedUser.fromJson(Map<String, dynamic> json) {
    return SearchedUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      profileUrl: json['profile_url'],
      isOnline: json['is_online'] ?? false,
      status: json['status'],
      isFollowing: json['is_following'] ?? false,
      isFollower: json['is_follower'] ?? false,
    );
  }
}