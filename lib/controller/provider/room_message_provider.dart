

// room_message_provider.dart
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/send_message_room_model.dart';
import 'package:shaheen_star_app/controller/provider/seat_provider.dart';

class RoomMessageProvider with ChangeNotifier {
  final List<SendMessageRoomModel> _messages = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSending = false;
  SeatProvider? _seatProvider; // ✅ WebSocket provider for message broadcasting

  List<SendMessageRoomModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isSending => _isSending;

  Future<void> fetchRoomMessages(String roomId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print("🔄 Fetching messages for room: $roomId");
      print("📊 Current local messages count before fetch: ${_messages.length}");
      
      final response = await ApiManager.getRoomMessages(roomId);
      
      if (response['status'] == 'success') {
        List<dynamic> messagesData = response['data']?['messages'] ?? [];
        final apiMessages = messagesData.map((msg) => SendMessageRoomModel.fromApiData(msg)).toList();
        
        print("📊 API returned ${apiMessages.length} messages");
        print("📊 Local messages before merge: ${_messages.length}");
        
        // ✅ MERGE API messages with local messages instead of replacing
        // Keep local messages (system messages, recent sends) and add API messages
        // Avoid duplicates by checking message content and timestamp
        final existingMessageKeys = _messages.map((m) => '${m.userId}_${m.message}_${m.timestamp}').toSet();
        
        for (var apiMsg in apiMessages) {
          final msgKey = '${apiMsg.userId}_${apiMsg.message}_${apiMsg.timestamp}';
          if (!existingMessageKeys.contains(msgKey)) {
            _messages.add(apiMsg);
            existingMessageKeys.add(msgKey);
          }
        }
        
        // ✅ Sort messages by timestamp (newest first for reverse ListView)
        _messages.sort((a, b) {
          final timeA = a.timestamp ?? '';
          final timeB = b.timestamp ?? '';
          return timeB.compareTo(timeA); // Reverse order (newest first)
        });
        
        print("✅ Total messages after merge: ${_messages.length} (${apiMessages.length} from API, ${_messages.length - apiMessages.length} local)");
        _errorMessage = '';
      } else {
        _errorMessage = response['message'] ?? 'Failed to load messages';
        print("❌ Load messages failed: $_errorMessage");
        print("📊 Preserving ${_messages.length} local messages despite API failure");
      }
    } catch (e) {
      _errorMessage = 'Load messages error: $e';
      print("❌ Fetch messages exception: $e");
      print("📊 Preserving ${_messages.length} local messages despite exception");
    } finally {
      _isLoading = false;
      notifyListeners();
      print("📊 Final messages count: ${_messages.length}");
      if (_messages.isNotEmpty) {
        print("📋 First message: ${_messages.first.message}");
        print("📋 Last message: ${_messages.last.message}");
      }
    }
  }

  // ✅ Set SeatProvider for WebSocket message sending
  void setSeatProvider(SeatProvider seatProvider) {
    _seatProvider = seatProvider;
    print("✅ RoomMessageProvider: SeatProvider set for WebSocket message sending");
  }

  Future<void> sendMessage({
    required String userId,
    required String roomId,
    required String message,
    required String userName,
    String? profileUrl,
  }) async {
    if (_isSending) return;
    
    _isSending = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // ✅ OPTIMISTIC UPDATE - Add message locally first
      final localMessage = SendMessageRoomModel.createLocal(
        userId: userId,
        roomId: roomId,
        message: message,
        userName: userName,
        profileUrl: profileUrl,
      );
      
      _messages.insert(0, localMessage);
      notifyListeners();

      // ✅ SEND VIA WEBSOCKET (broadcast to all users in room)
      if (_seatProvider != null && _seatProvider!.isConnected) {
        final wsSuccess = await _seatProvider!.sendMessage(
          roomId: roomId,
          userId: userId,
          message: message,
        );

        if (wsSuccess) {
          _isSending = false;
          notifyListeners();
          return;
        } else {
          print("⚠️ WebSocket send failed, falling back to HTTP API");
        }
      } else {
        print("⚠️ WebSocket not connected, using HTTP API fallback");
      }

      // ✅ FALLBACK: HTTP API call (if WebSocket fails)
      final apiMessage = await ApiManager.sendMessage(
        userId: userId,
        roomId: roomId,
        message: message,
      );

      // ✅ If API success, replace local message with server message
      if (!apiMessage.isLocalMessage) {
        _messages.remove(localMessage);
        _messages.insert(0, apiMessage);
      }

      // Message sent successfully
      
    } catch (e) {
      _errorMessage = 'Send message error: $e';
      print("❌ Send message exception: $e");
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ✅ Helper function to normalize user ID (remove leading zeros)
  String _normalizeUserId(String? userId) {
    if (userId == null || userId.isEmpty) return '';
    return userId.replaceFirst(RegExp(r'^0+'), '');
  }

  // ✅ Add received message from WebSocket (broadcast from other users)
  void addReceivedMessage(SendMessageRoomModel message) {
    // ✅ STRICT DEDUPLICATION: Check if message already exists
    // Compare userId + message content (timestamp may vary slightly, so don't rely on it)
    // For "joined the room" messages, also check if same user joined recently (within 10 seconds)
    // ✅ Normalize user IDs to prevent duplicates from different formats (00100623 vs 100623)
    final messageTime = message.timestamp != null ? DateTime.tryParse(message.timestamp!) : null;
    final normalizedMessageUserId = _normalizeUserId(message.userId);
    
    // ✅ Check for exact duplicate (normalized userId + message + timestamp)
    final exactDuplicate = _messages.any((m) {
      final normalizedMUserId = _normalizeUserId(m.userId);
      return normalizedMUserId == normalizedMessageUserId && 
      m.message == message.message && 
             m.timestamp == message.timestamp;
    });
    
    // ✅ Check for "joined the room" or "joined seat" duplicate (same user, same message type, within 10 seconds)
    final isJoinedMessage = message.message.toLowerCase().contains('joined the room') ||
                            message.message.toLowerCase().contains('joined seat');
    final recentDuplicate = isJoinedMessage && normalizedMessageUserId.isNotEmpty
        ? _messages.any((m) {
            final mIsJoined = m.message.toLowerCase().contains('joined the room') ||
                             m.message.toLowerCase().contains('joined seat');
            final normalizedMUserId = _normalizeUserId(m.userId);
            if (normalizedMUserId != normalizedMessageUserId || !mIsJoined) {
              return false;
            }
            // Check if this is a recent duplicate (within 10 seconds)
            final mTime = m.timestamp != null ? DateTime.tryParse(m.timestamp!) : null;
            if (mTime != null && messageTime != null) {
              final diff = mTime.difference(messageTime).abs();
              return diff.inSeconds < 10; // Same message within 10 seconds = duplicate
            }
            // If timestamps are close or same, and message is identical, it's a duplicate
            if (m.message == message.message) {
              return true;
            }
            return mTime == null && messageTime == null; // Both null = same timestamp
          })
        : false;
    
    if (exactDuplicate || recentDuplicate) {
      print("ℹ️ Message already exists (duplicate detected), skipping:");
      print("   - User: ${message.userName} (${message.userId}, normalized: $normalizedMessageUserId)");
      print("   - Message: ${message.message}");
      print("   - Exact duplicate: $exactDuplicate, Recent duplicate: $recentDuplicate");
      return;
    }
    
    _messages.insert(0, message);
    notifyListeners();
    print("✅ Received message added to chat: ${message.userName}: ${message.message}");
  }

  // ✅ NEW METHOD: Send seat join message
  Future<void> sendSeatJoinMessage({
    required String roomId,
    required String userName,
    required int seatNumber,
    String? userId,
    String? profileUrl,
  }) async {
    try {
      // ✅ If userId and profileUrl provided, create a user message (not system message)
      // This allows the message to show the user's profile image
      final message = userId != null && userId.isNotEmpty && userId != 'system'
          ? SendMessageRoomModel(
              userId: userId,
              roomId: roomId,
              message: "$userName joined seat $seatNumber",
              userName: userName,
              profileUrl: profileUrl,
              timestamp: DateTime.now().toIso8601String(),
              isLocalMessage: true,
              isSystemMessage: false, // ✅ Not a system message - it's from a real user
            )
          : SendMessageRoomModel.createSystemMessage(
              roomId: roomId,
              message: "$userName joined seat $seatNumber",
            );
      
      _messages.insert(0, message);
      notifyListeners();
      
      print("✅ Seat join message added: $userName joined seat $seatNumber");
      if (userId != null) {
        print("   - User ID: $userId, Profile URL: $profileUrl");
      }
    } catch (e) {
      print("❌ Error sending seat join message: $e");
    }
  }

  // ✅ NEW METHOD: Send seat leave message
  Future<void> sendSeatLeaveMessage({
    required String roomId,
    required String userName,
    required int seatNumber,
    String? userId,
    String? profileUrl,
  }) async {
    try {
      // ✅ If userId and profileUrl provided, create a user message (not system message)
      final message = userId != null && userId.isNotEmpty && userId != 'system'
          ? SendMessageRoomModel(
              userId: userId,
              roomId: roomId,
              message: " $userName left seat $seatNumber",
              userName: userName,
              profileUrl: profileUrl,
              timestamp: DateTime.now().toIso8601String(),
              isLocalMessage: true,
              isSystemMessage: false, // ✅ Not a system message - it's from a real user
            )
          : SendMessageRoomModel.createSystemMessage(
              roomId: roomId,
              message: " $userName left seat $seatNumber",
            );
      
      _messages.insert(0, message);
      notifyListeners();
      
      print("✅ Seat leave message added: $userName left seat $seatNumber");
    } catch (e) {
      print("❌ Error sending seat leave message: $e");
    }
  }

  // ✅ NEW METHOD: Send user joined room message
  Future<void> sendUserJoinedMessage({
    required String roomId,
    required String userName,
    String? userId,
    String? profileUrl,
  }) async {
    try {
      print("📤 [RoomMessageProvider] Sending 'joined the room' message via WebSocket");
      print("📤 [RoomMessageProvider] This message will be broadcast to ALL users in room $roomId");
      
      // ✅ DON'T add local message - wait for WebSocket broadcast to avoid duplicates
      // The backend will broadcast it back, and we'll receive it via WebSocket callback
      
      // This is a temporary workaround until backend is fixed
      if (_seatProvider != null && _seatProvider!.isConnected && userId != null && userId.isNotEmpty) {
        try {
          // Send as a regular message so other users see it
          // The backend will broadcast it back, and we'll receive it via WebSocket
          final sent = await _seatProvider!.sendMessage(
            roomId: roomId,
            userId: userId,
            message: "$userName joined the room",
          );
          if (sent) {
            print("✅ [RoomMessageProvider] 'Joined the room' message sent via WebSocket");
            print("✅ [RoomMessageProvider] Backend should now broadcast this to all users in room $roomId");
            print("✅ [RoomMessageProvider] Message will appear when backend broadcasts it back (no local duplicate)");
          } else {
            print("❌ [RoomMessageProvider] Failed to send 'joined the room' message via WebSocket");
          }
        } catch (e) {
          print("❌ [RoomMessageProvider] Error sending 'joined the room' message via WebSocket: $e");
          print("⚠️ [RoomMessageProvider] This is a workaround - backend should broadcast user:joined event");
        }
      } else {
        print("⚠️ [RoomMessageProvider] Cannot send 'joined the room' via WebSocket:");
        print("   - SeatProvider is null: ${_seatProvider == null}");
        print("   - WebSocket connected: ${_seatProvider?.isConnected ?? false}");
        print("   - User ID is null: ${userId == null || userId.isEmpty}");
        print("⚠️ [RoomMessageProvider] Backend should broadcast user:joined event when user connects");
      }
    } catch (e) {
      print("❌ Error sending user joined message: $e");
    }
  }

  // ✅ NEW METHOD: Send user left room message
  Future<void> sendUserLeftMessage({
    required String roomId,
    required String userName,
  }) async {
    try {
      final systemMessage = SendMessageRoomModel.createSystemMessage(
        roomId: roomId,
        message: "$userName Left Room",
      );
      
      _messages.insert(0, systemMessage);
      notifyListeners();
      
      print("✅ User left message added: $userName left room");
    } catch (e) {
      print("❌ Error sending user left message: $e");
    }
  }

  // ✅ NEW METHOD: Send mic on message
  Future<void> sendMicOnMessage({
    required String roomId,
    required String userName,
    int? seatNumber,
    String? userId,
    String? profileUrl,
  }) async {
    try {
      final seatText = seatNumber != null ? " on seat $seatNumber" : "";
      // ✅ If userId and profileUrl provided, create a user message (not system message)
      final message = userId != null && userId.isNotEmpty && userId != 'system'
          ? SendMessageRoomModel(
              userId: userId,
              roomId: roomId,
              message: " $userName turned mic on$seatText",
              userName: userName,
              profileUrl: profileUrl,
              timestamp: DateTime.now().toIso8601String(),
              isLocalMessage: true,
              isSystemMessage: false, // ✅ Not a system message - it's from a real user
            )
          : SendMessageRoomModel.createSystemMessage(
              roomId: roomId,
              message: " $userName turned mic on$seatText",
            );
      
      _messages.insert(0, message);
      notifyListeners();
      
      print("✅ Mic on message added: $userName turned mic on");
      if (userId != null) {
        print("   - User ID: $userId, Profile URL: $profileUrl");
      }
    } catch (e) {
      print("❌ Error sending mic on message: $e");
    }
  }

  // ✅ NEW METHOD: Send mic off message
  Future<void> sendMicOffMessage({
    required String roomId,
    required String userName,
    int? seatNumber,
    String? userId,
    String? profileUrl,
  }) async {
    try {
      final seatText = seatNumber != null ? " on seat $seatNumber" : "";
      // ✅ If userId and profileUrl provided, create a user message (not system message)
      final message = userId != null && userId.isNotEmpty && userId != 'system'
          ? SendMessageRoomModel(
              userId: userId,
              roomId: roomId,
              message: "🔇 $userName turned mic off$seatText",
              userName: userName,
              profileUrl: profileUrl,
              timestamp: DateTime.now().toIso8601String(),
              isLocalMessage: true,
              isSystemMessage: false, // ✅ Not a system message - it's from a real user
            )
          : SendMessageRoomModel.createSystemMessage(
              roomId: roomId,
              message: "🔇 $userName turned mic off$seatText",
            );
      
      _messages.insert(0, message);
      notifyListeners();
      
      print("✅ Mic off message added: $userName turned mic off");
      if (userId != null) {
        print("   - User ID: $userId, Profile URL: $profileUrl");
      }
    } catch (e) {
      print("❌ Error sending mic off message: $e");
    }
  }

  // ✅ NEW METHOD: Send user speaking message
  Future<void> sendUserSpeakingMessage({
    required String roomId,
    required String userName,
    int? seatNumber,
  }) async {
    try {
      final seatText = seatNumber != null ? " on seat $seatNumber" : "";
      final systemMessage = SendMessageRoomModel.createSystemMessage(
        roomId: roomId,
        message: "🗣️ $userName is speaking$seatText",
      );
      
      _messages.insert(0, systemMessage);
      notifyListeners();
      
      print("✅ User speaking message added: $userName is speaking");
    } catch (e) {
      print("❌ Error sending user speaking message: $e");
    }
  }

  void clearMessages({bool skipNotification = false}) {
    _messages.clear();
    _errorMessage = '';
    print("🗑️ All messages cleared");
    if (!skipNotification) {
      try {
        notifyListeners();
      } catch (e) {
        // Widget tree might be locked during disposal - ignore error
        print("⚠️ Could not notify listeners (widget tree locked): $e");
      }
    }
  }

  void addWelcomeMessage(SendMessageRoomModel welcomeMessage) {
    _messages.insert(0, welcomeMessage);
    notifyListeners();
    print("✅ Welcome message added to chat");
  }
}