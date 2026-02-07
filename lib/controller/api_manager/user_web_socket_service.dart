// import 'dart:convert';
// import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class UserChatWebSocket {
//   static final UserChatWebSocket _instance = UserChatWebSocket._internal();
//   factory UserChatWebSocket() => _instance;
//   UserChatWebSocket._internal();

//   WebSocketChannel? _channel;
//   Function(dynamic)? onMessage;
//   Function()? onConnected;
//   Function()? onDisconnected;
//   Function(dynamic)? onError;

//   bool _isConnected = false;
//   bool get isConnected => _isConnected;

//   // WebSocket URL
//   static const String baseUrl = ApiConstants.userChatWebSocketUrl;

//   // Connect to WebSocket
//   void connect({
//     required int userId,
//     required String username,
//     required String name,
//     String? profileUrl,
//   }) {
//     try {
//       print('🔌 Connecting to WebSocket...');
//       print('📍 UserID: $userId, Username: $username, Name: $name');
      
//       final uri = Uri.parse(
//         '$baseUrl?user_id=$userId&username=${Uri.encodeComponent(username)}&name=${Uri.encodeComponent(name)}&profile_url=${Uri.encodeComponent(profileUrl ?? "")}',
//       );

//       _channel = WebSocketChannel.connect(uri);
//       _isConnected = true;

//       print('✅ WebSocket connected!');
      
//       // Listen to messages with better error handling
//       _channel!.stream.listen(
//         (message) {
//           print('📨 Received: $message');
//           try {
//             onMessage?.call(message);
//           } catch (e) {
//             print('❌ Error in message handler: $e');
//           }
//         },
//         onError: (error) {
//           print('❌ WebSocket error: $error');
//           _isConnected = false;
//           onError?.call(error);
//           // Attempt reconnect after delay
//           Future.delayed(Duration(seconds: 5), () {
//             if (!_isConnected) {
//               print('🔄 Attempting to reconnect...');
//               connect(
//                 userId: userId,
//                 username: username,
//                 name: name,
//                 profileUrl: profileUrl,
//               );
//             }
//           });
//         },
//         onDone: () {
//           print('🔌 WebSocket disconnected');
//           _isConnected = false;
//           onDisconnected?.call();
//         },
//         cancelOnError: false,
//       );
      
//       onConnected?.call();
      
//     } catch (e) {
//       print('❌ Connection failed: $e');
//       _isConnected = false;
//       onError?.call(e);
//     }
//   }

//   // Send message
//   void send(Map<String, dynamic> data) {
//     if (_channel != null && _isConnected) {
//       final jsonData = json.encode(data);
//       print('📤 Sending: $jsonData');
//       _channel!.sink.add(jsonData);
//     } else {
//       print('❌ Cannot send - not connected');
//     }
//   }

//   // Disconnect
//   void disconnect() {
//     print('🔌 Disconnecting WebSocket...');
//     _channel?.sink.close();
//     _channel = null;
//     _isConnected = false;
//   }

//   // Action helpers
//   void getChatRooms(int userId) {
//     send({
//       'action': 'get_chat_rooms',  // Changed from get_chatrooms
//       'user_id': userId,
//     });
//   }

//   void createChatroom(int userId, int otherUserId) {
//     send({
//       'action': 'create_chat_room',  // Changed from create_chatroom
//       'user_id': userId,
//       'other_user_id': otherUserId,
//     });
//   }

//   void getMessages(int userId, int chatroomId, {int limit = 100}) {
//     send({
//       'action': 'get_chat_messages',  // Changed from get_messages
//       'user_id': userId,
//       'chatroom_id': chatroomId,
//       'limit': limit,
//       'offset': 0,
//     });
//   }

//   void sendMessage(int userId, int chatroomId, String message) {
//     send({
//       'action': 'send_chat_message',  // Changed from send_message
//       'user_id': userId,
//       'chatroom_id': chatroomId,
//       'message': message,
//     });
//   }

//   void searchUsers(int userId, String searchTerm, {int limit = 50}) {
//     send({
//       'action': 'search_users',  // This one should be correct based on doc
//       'user_id': userId,
//       'search_term': searchTerm,
//       'limit': limit,
//       'offset': 0,
//     });
//   }

//   void markAsRead(int userId, int chatroomId) {
//     send({
//       'action': 'mark_chat_as_read',  // Changed from mark_as_read
//       'user_id': userId,
//       'chatroom_id': chatroomId,
//     });
//   }
// }


// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:async';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UserChatWebSocket {
  WebSocketChannel? _channel;
  Function(dynamic)? onMessage;
  final List<Function(dynamic)> _messageListeners = []; // Support multiple listeners
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ========== STREAM CONTROLLERS FOR EVENTS ==========
  final _chatRoomsController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesController = StreamController<Map<String, dynamic>>.broadcast();
  final _userSearchController = StreamController<Map<String, dynamic>>.broadcast();
  final _followStatusController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Voice chat controllers
  final _voiceSignalController = StreamController<Map<String, dynamic>>.broadcast();
  final _voiceAudioController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatRoomsStream => _chatRoomsController.stream;
  Stream<Map<String, dynamic>> get messagesStream => _messagesController.stream;
  Stream<Map<String, dynamic>> get userSearchStream => _userSearchController.stream;
  Stream<Map<String, dynamic>> get followStatusStream => _followStatusController.stream;
  // Public voice streams
  Stream<Map<String, dynamic>> get voiceSignalStream => _voiceSignalController.stream;
  Stream<Map<String, dynamic>> get voiceAudioStream => _voiceAudioController.stream;

  /// Add a message listener (for multiple providers to listen)
  void addMessageListener(Function(dynamic) listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
    }
  }

  /// Remove a message listener
  void removeMessageListener(Function(dynamic) listener) {
    _messageListeners.remove(listener);
  }

  // Track last sent payload to support retry when server rejects JSON format
  Map<String, dynamic>? _lastSentNormalized;
  bool _lastSentWasJson = false;
  bool _lastSentRetried = false;
  String? _lastSentAction;
  final Map<String, int> _formatErrorCounts = {}; // track repeated invalid format errors per action

  // WebSocket URL - CHANGE THIS TO YOUR URL
  static const String baseUrl = ApiConstants.userChatWebSocketUrl;

  // Connect to WebSocket
  void connect({
    required int userId,
    required String username,
    required String name,
    String? profileUrl,
  }) {
    try {
      print('🔌 Connecting to WebSocket...');
      print('📍 UserID: $userId, Username: $username, Name: $name');
      
      // Build URL with parameters
      final uri = Uri.parse(
        '$baseUrl?user_id=$userId&username=${Uri.encodeComponent(username)}&name=${Uri.encodeComponent(name)}${profileUrl != null ? '&profile_url=${Uri.encodeComponent(profileUrl)}' : ''}',
      );

      print('🌐 Connecting to: $uri');
      print('🌐 WebSocket URL: $baseUrl');
      
      // Create WebSocket connection
      _channel = WebSocketChannel.connect(uri);
      
      // Don't set _isConnected to true immediately - wait for actual connection
      print('⏳ WebSocket channel created, waiting for connection...');
      
      // Setup listener for incoming messages BEFORE connection is fully established
      _channel!.stream.listen(
        (message) {
          // Mark as connected when we receive first message
          if (!_isConnected) {
            _isConnected = true;
            print('✅ WebSocket connected successfully! (First message received)');
            if (onConnected != null) {
              onConnected!();
            }
          }
          
          print('📨 Received raw message: $message');
          
          // Parse the message to check structure
          try {
            final parsed = json.decode(message);
            print('📊 Parsed message: $parsed');
            
            // Handle different event types
            _handleMessage(parsed);
            
          } catch (e) {
            print('⚠️ Could not parse as JSON: $message');
            print('⚠️ Parse error: $e');
          }
          
          // Forward message to provider (legacy support)
          if (onMessage != null) {
            onMessage!(message);
          }

          // Forward to all listeners
          for (var listener in _messageListeners) {
            listener(message);
          }
        },
        onError: (error) {
          print('❌ WebSocket stream error: $error');
          _isConnected = false;
          if (onError != null) {
            onError!(error);
          }
          if (onDisconnected != null) {
            onDisconnected!();
          }
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _isConnected = false;
          if (onDisconnected != null) {
            onDisconnected!();
          }
        },
        cancelOnError: false, // Changed to false to keep connection alive on errors
      );

      // Set a timeout to mark as connected if no error occurs
      Future.delayed(Duration(seconds: 2), () {
        if (!_isConnected && _channel != null) {
          // If we haven't received a message but channel exists, assume connected
          _isConnected = true;
          print('✅ WebSocket connection assumed successful (timeout)');
          if (onConnected != null) {
            onConnected!();
          }
        }
      });
      
    } catch (e, stackTrace) {
      print('❌ [UserChatWebSocket] Connection failed: $e');
      print('❌ [UserChatWebSocket] Stack trace: $stackTrace');
      print('❌ [UserChatWebSocket] Port 8088 might not be running or server is down');
      print('❌ [UserChatWebSocket] Check if WebSocket server is running on $baseUrl');
      _isConnected = false;
      if (onError != null) {
        onError!(e);
      }
    }
  }

  // ========== HANDLE INCOMING MESSAGES ==========
  // ========== HANDLE INCOMING MESSAGES ==========
void _handleMessage(Map<String, dynamic> message) {
  // ✅ Safely get event (handle int types)
  String? event;
  if (message['event'] != null) {
    event = message['event'].toString();
  }
  final data = message['data'];
  
  print('📊 Event: $event, Data: $data');

  switch (event) {
    case 'error':
      try {
        final errMsg = message['message']?.toString() ?? '';
        print('❗ Server error event: $errMsg');
        // If server complains about message format, retry the last sent payload as urlencoded once
        if (errMsg.toLowerCase().contains('invalid message format')) {
          final actionKey = _lastSentAction ?? _lastSentNormalized?['action']?.toString() ?? 'unknown';
          _formatErrorCounts[actionKey] = (_formatErrorCounts[actionKey] ?? 0) + 1;

          // If we haven't retried yet for this payload and we originally sent JSON, retry once as urlencoded
          if (_lastSentNormalized != null && _lastSentWasJson == true && !_lastSentRetried && (_formatErrorCounts[actionKey] ?? 0) <= 2) {
            print('🔁 Retrying last action as urlencoded due to server format error (action=$actionKey)');
            _lastSentRetried = true;
            final encoded = _lastSentNormalized!.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}').join('&');
            print('📤 [UserChatWebSocket] Retrying (urlencoded): $encoded');
            try {
              _channel?.sink.add(encoded);
              _lastSentWasJson = false;
            } catch (e) {
              print('❌ Retry send failed: $e');
            }
          } else {
            // Too many retries or nothing to retry — suppress repeated noisy logging after a few occurrences
            if ((_formatErrorCounts[actionKey] ?? 0) > 2) {
              if ((_formatErrorCounts[actionKey] ?? 0) == 3) {
                print('⚠️ Repeated Invalid message format for action=$actionKey — further retries suppressed');
              }
            }
          }
        }
      } catch (e) {
        print('❌ Error handling server error event: $e');
      }
      break;
    case 'chatrooms:list':  // ⭐ YEH ALREADY CORRECT HAI
      print('✅ Chatrooms list received');
      _chatRoomsController.add(data ?? {});
      break;
      
    case 'chatroom:created':
      print('✅ Chatroom created');
      _chatRoomsController.add(data ?? {});
      break;
    
    case 'messages:history':
    case 'message:new':
    case 'message:sent':
    case 'user:messages':   // server may send this for get_messages response
      print('✅ Messages received (event: $event)');
      _messagesController.add(data ?? {});
      break;
    
    case 'users:search':
    case 'users:search_results':  // ⭐ YEH ADD KARO
      print('✅ User search results received');
      _userSearchController.add(data ?? {});
      break;
    
    case 'follow:status':
    case 'follow:success':
    case 'unfollow:success':
      print('✅ Follow status received');
      _followStatusController.add(data ?? {});
      break;
    // Voice chat events
    case 'voice:signal':
    case 'voice:offer':
    case 'voice:answer':
    case 'voice:ice':
      print('🎙️ Voice signaling event received: $event');
      _voiceSignalController.add({'event': event, 'data': data ?? {}});
      break;
    case 'voice:audio':
      // Expected: data = { user_id, chatroom_id, audio_b64, sequence, is_last }
      print('🔊 Voice audio chunk received');
      _voiceAudioController.add(data ?? {});
      break;
    case 'voice:started':
    case 'voice:stopped':
    case 'voice:muted':
    case 'voice:unmuted':
      print('🎛 Voice control event: $event');
      _voiceSignalController.add({'event': event, 'data': data ?? {}});
      break;
    
    default:
      print('! Unknown event: $event');
  }
}
  // Send message
  bool send(Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) {
      print('❌ Cannot send - WebSocket not connected');
      if (onError != null) {
        onError!('WebSocket not connected');
      }
      return false;
    }

    // Normalize payload: many backend PHP WS implementations expect string values
    final normalized = <String, dynamic>{};
    data.forEach((k, v) {
      if (v == null) return;
      if (v is int || v is double || v is bool) {
        normalized[k] = v.toString();
      } else {
        normalized[k] = v;
      }
    });

    // Track action for retry/error counting
    _lastSentAction = normalized['action']?.toString();

    // Prefer JSON; only create_chatroom forced to urlencoded (server may expect form-style for that)
    final Set<String> forceUrlEncodedActions = {
      'create_chatroom',
    };

    final shouldForceUrlEncoded = _lastSentAction != null && forceUrlEncodedActions.contains(_lastSentAction);

    // Decide format: force urlencoded for certain chat actions, otherwise prefer JSON
    _lastSentNormalized = normalized;
    _lastSentRetried = false;
    try {
      if (shouldForceUrlEncoded) {
        final encoded = normalized.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}').join('&');
        print('📤 [UserChatWebSocket] Sending (urlencoded forced for $_lastSentAction): $encoded');
        _channel!.sink.add(encoded);
        _lastSentWasJson = false;
      } else {
        final jsonData = json.encode(normalized);
        print('📤 [UserChatWebSocket] Sending (json): $jsonData');
        _channel!.sink.add(jsonData);
        _lastSentWasJson = true;
      }
    } catch (e) {
      // Last-resort: send urlencoded if JSON encoding/sending fails
      final encoded = normalized.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}').join('&');
      print('📤 [UserChatWebSocket] JSON send failed, falling back to urlencoded: $encoded');
      try {
        _channel!.sink.add(encoded);
        _lastSentWasJson = false;
      } catch (e) {
        print('❌ Final send failed: $e');
        return false;
      }
    }
    return true;
  }

  // Disconnect
  void disconnect() {
    print('🔌 Disconnecting WebSocket...');
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    
    // DON'T close stream controllers - they might be reused
    // Only close them if you're sure they won't be used again
    // _chatRoomsController.close();
    // _messagesController.close();
    // _userSearchController.close();
    // _followStatusController.close();
  }

  // Send both user_id and user1_id so server accepts either; use JSON (WebSocket often expects JSON)
  void getChatRooms(int userId) {
    send({
      'action': 'get_chatrooms',
      'user_id': userId,
      'user1_id': userId,
    });
  }

  void createChatroom(int userId, int otherUserId) {
    send({
      'action': 'create_chatroom',
      'user1_id': userId,
      'user2_id': otherUserId,
    });
  }

  void getMessages(int userId, int chatroomId, {int limit = 100}) {
    send({
      'action': 'get_messages',  // Changed from 'get_chat_messages'
      'user_id': userId,
      'chatroom_id': chatroomId,
      'limit': limit,
      'offset': 0,
    });
  }

  void sendMessage(int userId, int chatroomId, String message) {
    // Use same flat JSON format as get_chatrooms so server gets consistent action-based messages.
    send({
      'action': 'send_message',
      'user_id': userId,
      'chatroom_id': chatroomId,
      'message': message,
    });
  }

  void searchUsers(int userId, String searchTerm, {int limit = 50}) {
    send({
      'action': 'search_users',  // This one should be correct
      'user_id': userId,
      'search_term': searchTerm,
      'limit': limit,
      'offset': 0,
    });
  }

  void markAsRead(int userId, int chatroomId) {
    send({
      'action': 'mark_as_read',  // Changed from 'mark_chat_as_read'
      'user_id': userId,
      'chatroom_id': chatroomId,
    });
  }

  // ========== FOLLOW/UNFOLLOW METHODS ==========

  /// Follow a user
  bool followUser(int followerId, int followingId) {
    print('👤 [UserChatWebSocket] followUser called: followerId=$followerId, followingId=$followingId');
    final success = send({
      'action': 'follow_user',
      'user_id': followerId,
      'target_user_id': followingId,
    });
    if (!success) {
      print('❌ [UserChatWebSocket] Failed to send follow_user request');
    }
    return success;
  }

  /// Unfollow a user
  bool unfollowUser(int followerId, int followingId) {
    print('👤 [UserChatWebSocket] unfollowUser called: followerId=$followerId, followingId=$followingId');
    final success = send({
      'action': 'unfollow_user',
      'user_id': followerId,
      'target_user_id': followingId,
    });
    if (!success) {
      print('❌ [UserChatWebSocket] Failed to send unfollow_user request');
    }
    return success;
  }

  /// Check if current user is following target user
  void checkFollowStatus(int followerId, int followingId) {
    send({
      'action': 'check_follow_status',
      'user_id': followerId,
      'target_user_id': followingId,
    });
  }

  /// Get list of followers for a user
  void getFollowers(int userId, {int limit = 50, int offset = 0}) {
    send({
      'action': 'get_followers',
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
  }

  /// Get list of users that a user is following
  void getFollowing(int userId, {int limit = 50, int offset = 0}) {
    send({
      'action': 'get_following',
      'user_id': userId,
      'limit': limit,
      'offset': offset,
    });
  }

  /// Get suggested users to follow
  void getSuggestedUsers(int userId, {int limit = 10}) {
    send({
      'action': 'get_suggested_users',
      'user_id': userId,
      'limit': limit,
    });
  }

  /// Get online users
  void getOnlineUsers(int userId, {int limit = 50}) {
    send({
      'action': 'get_online_users',
      'user_id': userId,
      'limit': limit,
    });
  }

  /// Update user status (online, away, busy, offline)
  void updateUserStatus(int userId, String status) {
    send({
      'action': 'update_user_status',
      'user_id': userId,
      'status': status,
    });
  }

  // ========== VOICE CHAT API (SKELETON) ==========
  /// Start a voice chat session for a chatroom. This sends a signaling event
  /// to the server which should coordinate peer connections or enable server-side mixing.
  bool startVoiceChat(int userId, int chatroomId) {
    final payload = {
      'event': 'voice:start',
      'data': {
        'user_id': userId.toString(),
        'chatroom_id': chatroomId.toString(),
      }
    };
    _lastSentAction = 'voice:start';
    _lastSentNormalized = payload.map((k, v) => MapEntry(k, v));
    return send(payload);
  }

  /// Stop an ongoing voice chat session.
  bool stopVoiceChat(int userId, int chatroomId) {
    final payload = {
      'event': 'voice:stop',
      'data': {
        'user_id': userId.toString(),
        'chatroom_id': chatroomId.toString(),
      }
    };
    _lastSentAction = 'voice:stop';
    _lastSentNormalized = payload.map((k, v) => MapEntry(k, v));
    return send(payload);
  }

  /// Send signaling message (offer/answer/ice) for WebRTC-style voice negotiation.
  bool sendVoiceSignal(int userId, int chatroomId, Map<String, dynamic> signal) {
    final payload = {
      'event': 'voice:signal',
      'data': {
        'user_id': userId.toString(),
        'chatroom_id': chatroomId.toString(),
        'signal': signal,
      }
    };
    _lastSentAction = 'voice:signal';
    _lastSentNormalized = payload.map((k, v) => MapEntry(k, v));
    return send(payload);
  }

  /// Send an audio chunk encoded as base64. `bytes` should be raw PCM/Opus/etc.
  /// The server must know how to decode and route these chunks.
  bool sendAudioChunk(int userId, int chatroomId, List<int> bytes, {int? sequence, bool isLast = false}) {
    try {
      final b64 = base64.encode(bytes);
      final data = {
        'user_id': userId.toString(),
        'chatroom_id': chatroomId.toString(),
        'audio_b64': b64,
        if (sequence != null) 'sequence': sequence.toString(),
        'is_last': isLast.toString(),
      };
      final payload = {'event': 'voice:audio', 'data': data};
      _lastSentAction = 'voice:audio';
      _lastSentNormalized = payload.map((k, v) => MapEntry(k, v));
      return send(payload);
    } catch (e) {
      print('❌ Failed to encode/send audio chunk: $e');
      return false;
    }
  }

  /// Mute/unmute controls (local intent to mute, forwarded to server)
  bool setVoiceMute(int userId, int chatroomId, bool muted) {
    final payload = {
      'event': muted ? 'voice:mute' : 'voice:unmute',
      'data': {
        'user_id': userId.toString(),
        'chatroom_id': chatroomId.toString(),
      }
    };
    _lastSentAction = muted ? 'voice:mute' : 'voice:unmute';
    _lastSentNormalized = payload.map((k, v) => MapEntry(k, v));
    return send(payload);
  }
}