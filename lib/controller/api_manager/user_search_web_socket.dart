import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class UserSearchWebSocket {
  static final UserSearchWebSocket _instance = UserSearchWebSocket._internal();
  factory UserSearchWebSocket() => _instance;
  UserSearchWebSocket._internal();

  WebSocketChannel? _channel;
  final List<Function(dynamic)> _messageListeners = [];
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ✅ User Search WebSocket Server - Port 8087 (for user search, follow/unfollow operations)
  static const String baseUrl = "ws://shaheenstar.online:8087";

  /// Add a message listener
  void addMessageListener(Function(dynamic) listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
      print('✅ [UserSearchWebSocket] Added message listener (total: ${_messageListeners.length})');
    }
  }

  /// Remove a message listener
  void removeMessageListener(Function(dynamic) listener) {
    _messageListeners.remove(listener);
    print('✅ [UserSearchWebSocket] Removed message listener (remaining: ${_messageListeners.length})');
  }

  // Connect to WebSocket
  void connect({
    required int userId,
    required String username,
    required String name,
    String? profileUrl,
  }) {
    try {
      print('🔌 [UserSearchWebSocket] Connecting to User Search WebSocket...');
      print('📍 [UserSearchWebSocket] UserID: $userId, Username: $username, Name: $name');
      
      final uri = Uri.parse(
        '$baseUrl?user_id=$userId&username=${Uri.encodeComponent(username)}&name=${Uri.encodeComponent(name)}&profile_url=${Uri.encodeComponent(profileUrl ?? "")}',
      );

      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      print('✅ [UserSearchWebSocket] User Search WebSocket connected!');
      
      _channel!.stream.listen(
        (message) {
          print('📨 [UserSearchWebSocket] Received: $message');
          try {
            // Notify all listeners
            for (var listener in _messageListeners) {
              listener(message);
            }
            onMessage?.call(message);
          } catch (e) {
            print('❌ [UserSearchWebSocket] Error in message handler: $e');
          }
        },
        onError: (error) {
          print('❌ [UserSearchWebSocket] WebSocket error: $error');
          _isConnected = false;
          onError?.call(error);
          
          // Auto-reconnect
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isConnected) {
              print('🔄 [UserSearchWebSocket] Attempting to reconnect...');
              connect(
                userId: userId,
                username: username,
                name: name,
                profileUrl: profileUrl,
              );
            }
          });
        },
        onDone: () {
          print('🔌 [UserSearchWebSocket] User Search WebSocket disconnected');
          _isConnected = false;
          onDisconnected?.call();
        },
        cancelOnError: false,
      );
      
      onConnected?.call();
      
    } catch (e) {
      print('❌ [UserSearchWebSocket] Connection failed: $e');
      _isConnected = false;
      onError?.call(e);
    }
  }

  // Send message
  bool send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      try {
        final jsonData = json.encode(data);
        print('📤 [UserSearchWebSocket] Sending: $jsonData');
        _channel!.sink.add(jsonData);
        return true;
      } catch (e) {
        print('❌ [UserSearchWebSocket] Error encoding message: $e');
        return false;
      }
    } else {
      print('❌ [UserSearchWebSocket] Cannot send - not connected');
      return false;
    }
  }

  // Disconnect
  void disconnect() {
    print('🔌 [UserSearchWebSocket] Disconnecting User Search WebSocket...');
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  // ==================== ACTION METHODS ====================

  // Search users
  void searchUsers(String searchTerm, int userId, {int limit = 20, int offset = 0}) {
    send({
      'action': 'search_users',
      'user_id': userId,
      'search_term': searchTerm,
      'limit': limit,
      'offset': offset,
    });
  }

  // Get user profile
  void getUserProfile(int targetUserId, int currentUserId) {
    send({
      'action': 'get_user_profile',
      'user_id': currentUserId,
      'target_user_id': targetUserId,
    });
  }

  // Follow user
  bool followUser(int followerId, int followingId) {
    print('👤 [UserSearchWebSocket] followUser called: followerId=$followerId, followingId=$followingId');
    final success = send({
      'action': 'follow_user',
      'user_id': followerId,
      'target_user_id': followingId,
    });
    if (!success) {
      print('❌ [UserSearchWebSocket] Failed to send follow_user request');
    }
    return success;
  }

  // Unfollow user
  bool unfollowUser(int followerId, int followingId) {
    print('👤 [UserSearchWebSocket] unfollowUser called: followerId=$followerId, followingId=$followingId');
    final success = send({
      'action': 'unfollow_user',
      'user_id': followerId,
      'target_user_id': followingId,
    });
    if (!success) {
      print('❌ [UserSearchWebSocket] Failed to send unfollow_user request');
    }
    return success;
  }

  // Get followers
  void getFollowers(int userId, {int limit = 50, int offset = 0}) {
    send({
      'action': 'get_followers',
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
  }

  // Get following
  void getFollowing(int userId, {int limit = 50, int offset = 0}) {
    send({
      'action': 'get_following',
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
  }

  // Check follow status
  void checkFollowStatus(int followerId, int followingId) {
    send({
      'action': 'check_follow_status',
      'user_id': followerId,
      'target_user_id': followingId,
    });
  }

  // Get suggested users
  void getSuggestedUsers(int userId, {int limit = 10}) {
    send({
      'action': 'get_suggested_users',
      'user_id': userId,
      'limit': limit,
    });
  }

  // Get online users
  void getOnlineUsers(int userId, {int limit = 50}) {
    send({
      'action': 'get_online_users',
      'user_id': userId,
      'limit': limit,
    });
  }

  // Update user status
  void updateUserStatus(int userId, String status) {
    send({
      'action': 'update_user_status',
      'user_id': userId,
      'status': status, // online, away, busy, offline
    });
  }

  // Callback for messages (for backward compatibility)
  Function(dynamic)? onMessage;
}
