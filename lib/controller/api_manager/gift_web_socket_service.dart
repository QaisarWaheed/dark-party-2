import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Separate WebSocket service for gift operations on port 8085
class GiftWebSocketService with ChangeNotifier {
  static GiftWebSocketService? _instance;
  static GiftWebSocketService get instance {
    _instance ??= GiftWebSocketService._();
    return _instance!;
  }

  GiftWebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  bool _isConnected = false;
  String? _currentUserId;
  bool _isConnecting = false; // ✅ Prevent simultaneous connection attempts
  Completer<bool>? _connectionCompleter; // ✅ Track ongoing connection

  final Map<String, List<Function(Map<String, dynamic>)>> _eventCallbacks = {};

  // Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String get wsUrl => ApiConstants.giftsWebSocketUrl;

  /// Connect to Gifts WebSocket server (port 8085)
  Future<bool> connect({
    String? userId,
    String? username,
    String? name,
  }) async {
    try {
      // ✅ If already connected and user is the same, return true
      if (_isConnected && _channel != null && _currentUserId == userId) {
        print("✅ [GiftWebSocketService] Already connected with same user - reusing connection");
        return true;
      }
      
      // ✅ If connection is in progress, wait for it
      if (_isConnecting && _connectionCompleter != null) {
        print("⏳ [GiftWebSocketService] Connection already in progress - waiting...");
        return await _connectionCompleter!.future;
      }
      
      // ✅ Start new connection
      _isConnecting = true;
      _connectionCompleter = Completer<bool>();
      
      final baseUrl = wsUrl.trim();
      print("🎁 [GiftWebSocketService] Connecting to Gifts WebSocket server: $baseUrl");
      
      // Validate URL format
      if (!baseUrl.startsWith('ws://') && !baseUrl.startsWith('wss://')) {
        throw Exception('Invalid WebSocket URL format. Must start with ws:// or wss://');
      }
      
      // Build URI with query parameters
      Map<String, String> queryParams = {};
      if (userId != null && userId.isNotEmpty) {
        // ✅ Format user_id to 8 digits before sending to backend
        final formattedUserId = UserIdUtils.formatTo8Digits(userId);
        queryParams['user_id'] = formattedUserId ?? userId;
        print("📡 [GiftWebSocketService] User ID formatted to 8 digits: ${formattedUserId ?? userId} (original: $userId)");
      }
      if (username != null && username.isNotEmpty) {
        queryParams['username'] = username;
      }
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }
      
      final uri = queryParams.isNotEmpty
          ? Uri.parse(baseUrl).replace(queryParameters: queryParams)
          : Uri.parse(baseUrl);
      
      print("📡 [GiftWebSocketService] Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Port: ${uri.port}");
      print("📡 [GiftWebSocketService] Query Parameters: ${uri.queryParameters}");
      
      if (uri.port == 0) {
        throw Exception('WebSocket URL must include a port number (e.g., :8085)');
      }

      // ✅ Disconnect existing connection if any (only if user changed)
      if (_channel != null && _currentUserId != userId) {
        print("🔄 [GiftWebSocketService] Disconnecting existing connection (user changed)...");
        await disconnect();
        // Wait a bit after disconnecting
        await Future.delayed(Duration(milliseconds: 500));
      } else if (_channel != null && _isConnected) {
        // ✅ Same user, already connected - just return
        _isConnecting = false;
        if (!_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(true);
        }
        return true;
      }

      // Connect - wrap in try-catch to handle immediate connection failures
      print("🔌 [GiftWebSocketService] Creating new WebSocket connection...");
      
      bool connectionEstablished = false;
      bool connectionFailed = false;
      
      // Store user info before connection attempt
      _currentUserId = userId;

      // Attempt to create WebSocket channel with comprehensive error handling
      // Note: WebSocketChannel.connect() is synchronous but connection happens asynchronously
      // Errors will come through the stream's onError callback, but we also catch sync errors
      try {
        _channel = WebSocketChannel.connect(uri);
      } on SocketException catch (e) {
        print("❌ [GiftWebSocketService] Socket Exception during channel creation: $e");
        connectionFailed = true;
        _isConnected = false;
        _isConnecting = false;
        _channel = null;
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _connectionCompleter = null;
        notifyListeners();
        return false;
      } catch (e, stackTrace) {
        print("❌ [GiftWebSocketService] Exception during channel creation: $e");
        print("   - Error type: ${e.runtimeType}");
        print("   - Stack trace: $stackTrace");
        connectionFailed = true;
        _isConnected = false;
        _isConnecting = false;
        _channel = null;
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _connectionCompleter = null;
        notifyListeners();
        return false;
      }

      // Verify channel was created
      if (_channel == null) {
        print("❌ [GiftWebSocketService] Channel is null after creation attempt");
        connectionFailed = true;
        _isConnected = false;
        _isConnecting = false;
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _connectionCompleter = null;
        notifyListeners();
        return false;
      }

      // Listen to incoming messages - set up error handler IMMEDIATELY
      // This ensures we catch any async errors that occur during connection
      print("👂 [GiftWebSocketService] Setting up WebSocket message listener...");
      
      try {
        // Set up the stream listener immediately to catch any async errors
      _messageSubscription = _channel!.stream.listen(
        (message) {
          if (!connectionEstablished) {
            connectionEstablished = true;
            print("✅ [GiftWebSocketService] First message received - connection confirmed");
            print("✅ [GiftWebSocketService] First message content: $message");
          }
          print("📥 [GiftWebSocketService] ===== RAW MESSAGE RECEIVED =====");
          print("📥 [GiftWebSocketService] Message Type: ${message.runtimeType}");
          print("📥 [GiftWebSocketService] Message Content: $message");
          print("📥 [GiftWebSocketService] ==================================");
          _handleMessage(message);
        },
        onError: (error) {
            // This will catch async errors from the WebSocket connection
          print("❌ [GiftWebSocketService] WebSocket stream error: $error");
            print("   - Error type: ${error.runtimeType}");
            // Check if it's a WebSocketChannelException and extract the underlying error
            if (error is WebSocketChannelException) {
              print("   - WebSocketChannelException detected");
              print("   - Inner error: ${error.message}");
            }
          connectionFailed = true;
          _isConnected = false;
          _isConnecting = false;
          if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete(false);
          }
          _connectionCompleter = null;
          notifyListeners();
        },
        onDone: () {
          print("🔌 [GiftWebSocketService] WebSocket connection closed");
          connectionFailed = true;
          _isConnected = false;
          _isConnecting = false;
          if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete(false);
          }
          _connectionCompleter = null;
          notifyListeners();
        },
          cancelOnError: false, // Don't cancel on error, let onError handle it
      );
      } catch (e, stackTrace) {
        print("❌ [GiftWebSocketService] Error setting up stream listener: $e");
        print("   - Error type: ${e.runtimeType}");
        print("   - Stack trace: $stackTrace");
        connectionFailed = true;
        _isConnected = false;
        _isConnecting = false;
        _channel = null;
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(false);
        }
        _connectionCompleter = null;
        notifyListeners();
        return false;
      }
      
      print("✅ [GiftWebSocketService] WebSocket message listener set up successfully");

      // Wait a bit to allow connection to establish (shorter wait for faster fallback)
      print("⏳ [GiftWebSocketService] Waiting for connection to establish...");
      
      // Check connection status multiple times during wait
      for (int i = 0; i < 4; i++) {
        await Future.delayed(Duration(milliseconds: 500));
        
        // Check if connection failed during wait
        if (connectionFailed) {
          print("❌ [GiftWebSocketService] Connection failed during establishment (after ${(i + 1) * 500}ms)");
          _isConnected = false;
          notifyListeners();
          return false;
        }
        
        // Verify channel is still valid
        if (_channel == null) {
          print("❌ [GiftWebSocketService] Channel is null after connection attempt");
          _isConnected = false;
          notifyListeners();
          return false;
        }
      }

      // Final check before marking as connected
      if (connectionFailed) {
        print("❌ [GiftWebSocketService] Connection failed - final check");
        _isConnected = false;
        notifyListeners();
        return false;
      }

      _isConnected = true;
      _isConnecting = false;
      print("✅ [GiftWebSocketService] ===== GIFTS WEBSOCKET CONNECTION ESTABLISHED =====");
      print("✅ [GiftWebSocketService] Connection Status: $_isConnected");
      print("✅ [GiftWebSocketService] Channel Status: ${_channel != null}");
      print("✅ [GiftWebSocketService] ============================================");
      
      // ✅ Complete the connection completer
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(true);
      }
      _connectionCompleter = null;
      
      notifyListeners();
      return true;
    } on TimeoutException catch (e) {
      print("⏱️ [GiftWebSocketService] Connection Timeout: $e");
      _isConnected = false;
      _isConnecting = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }
      _connectionCompleter = null;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      print("🔌 [GiftWebSocketService] Socket Exception: $e");
      _isConnected = false;
      _isConnecting = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }
      _connectionCompleter = null;
      notifyListeners();
      return false;
    } catch (e) {
      print("❌ [GiftWebSocketService] Connection Exception: $e");
      _isConnected = false;
      _isConnecting = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }
      _connectionCompleter = null;
      notifyListeners();
      return false;
    }
  }

  /// Register a callback for a specific event
  void on(String eventName, Function(Map<String, dynamic>) callback) {
    if (!_eventCallbacks.containsKey(eventName)) {
      _eventCallbacks[eventName] = [];
    }
    _eventCallbacks[eventName]!.add(callback);
    print("📝 [GiftWebSocketService] Registered callback for event: $eventName");
  }

  /// Unregister a callback for a specific event
  void off(String eventName, Function(Map<String, dynamic>)? callback) {
    if (_eventCallbacks.containsKey(eventName)) {
      if (callback != null) {
        _eventCallbacks[eventName]!.remove(callback);
      } else {
        _eventCallbacks[eventName]!.clear();
      }
      if (_eventCallbacks[eventName]!.isEmpty) {
        _eventCallbacks.remove(eventName);
      }
    }
  }

  /// Unregister all callbacks for a specific event
  void offAll(String eventName) {
    _eventCallbacks.remove(eventName);
  }

  /// Manually trigger an event (useful for local events)
  void emit(String eventName, Map<String, dynamic> data) {
    print("📤 [GiftWebSocketService] Manually emitting event: $eventName");
    print("📤 [GiftWebSocketService] Event data: $data");
    
    if (_eventCallbacks.containsKey(eventName)) {
      print("✅ [GiftWebSocketService] Triggering ${_eventCallbacks[eventName]!.length} callback(s) for event: $eventName");
      for (var callback in _eventCallbacks[eventName]!) {
        try {
          callback(data);
        } catch (e) {
          print("❌ [GiftWebSocketService] Error in callback for $eventName: $e");
        }
      }
    } else {
      print("⚠️ [GiftWebSocketService] No callbacks registered for event: $eventName");
      print("⚠️ [GiftWebSocketService] Available callbacks: ${_eventCallbacks.keys.toList()}");
    }
  }

  /// Send an action to the WebSocket server
  bool sendAction(String action, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print("❌ [GiftWebSocketService] Cannot send action: WebSocket not connected");
      print("   - isConnected: $_isConnected");
      print("   - channel: ${_channel != null}");
      return false;
    }

    try {
      // ✅ Verify channel is still open before sending
      if (_channel == null) {
        print("❌ [GiftWebSocketService] Channel is null");
        _isConnected = false;
        notifyListeners();
        return false;
      }
      
      final message = json.encode({
        'action': action,
        ...data,
      });

      // ✅ Check if sink is still available
      try {
        _channel!.sink.add(message);
        print("📤 [GiftWebSocketService] ===== SENDING WEBSOCKET ACTION =====");
        print("📤 [GiftWebSocketService] Action Name: $action");
        print("📤 [GiftWebSocketService] Action Data: $data");
        print("📤 [GiftWebSocketService] Full JSON Message: $message");
        print("📤 [GiftWebSocketService] Message Length: ${message.length} bytes");
        print("📤 [GiftWebSocketService] ====================================");
        return true;
      } catch (sinkError) {
        print("❌ [GiftWebSocketService] Error adding to sink: $sinkError");
        print("   - Channel may be closed or connection lost");
        _isConnected = false;
        _channel = null;
        _messageSubscription?.cancel();
        _messageSubscription = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("❌ [GiftWebSocketService] Error sending action: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Convenience helper to trigger lucky spinner via WebSocket
  /// Emits action 'lucky_gift:spin' with provided data
  bool triggerLuckySpin({
    required int senderId,
    required int receiverId,
    required int giftId,
    int quantity = 1,
    int? roomId,
  }) {
    final data = <String, dynamic>{
      'sender_id': senderId,
      'receiver_id': receiverId,
      'gift_id': giftId,
      'quantity': quantity,
    };
    if (roomId != null) data['room_id'] = roomId;

    print('🍀 [GiftWebSocketService] triggerLuckySpin called');
    final success = sendAction('lucky_gift:spin', data);
    if (!success) {
      print('❌ [GiftWebSocketService] Failed to send lucky_gift:spin via WebSocket');
    } else {
      print('✅ [GiftWebSocketService] lucky_gift:spin sent via WebSocket');
    }
    return success;
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      print("📥 [GiftWebSocketService] ===== PARSING WEBSOCKET MESSAGE =====");
      print("📥 [GiftWebSocketService] Raw message: $message");
      print("📥 [GiftWebSocketService] Message type: ${message.runtimeType}");
      print("📥 [GiftWebSocketService] Message length: ${message.toString().length} characters");

      String messageStr;
      if (message is String) {
        messageStr = message;
        print("📥 [GiftWebSocketService] Message is String, parsing JSON...");
      } else {
        messageStr = message.toString();
      }

      final data = json.decode(messageStr) as Map<String, dynamic>;
      print("✅ [GiftWebSocketService] JSON parsed successfully");

      // Check for event-based response
      if (data.containsKey('event')) {
        // ✅ Safely get event (handle int types)
        String eventName = '';
        if (data['event'] != null) {
          eventName = data['event'].toString();
        }
        final eventData = data['data'] as Map<String, dynamic>? ?? {};
        
        print("📡 [GiftWebSocketService] ===== EVENT DETAILS =====");
        print("📡 [GiftWebSocketService] Event: $eventName");
        print("📡 [GiftWebSocketService] Event Data Keys: ${eventData.keys.toList()}");
        print("📡 [GiftWebSocketService] Full Event Data: $eventData");
        print("📡 [GiftWebSocketService] ==========================");

        // Trigger callbacks for this event
        if (_eventCallbacks.containsKey(eventName)) {
          print("✅ [GiftWebSocketService] Triggering ${_eventCallbacks[eventName]!.length} callback(s) for event: $eventName");
          for (var callback in _eventCallbacks[eventName]!) {
            try {
              callback(eventData);
            } catch (e) {
              print("❌ [GiftWebSocketService] Error in callback for $eventName: $e");
            }
          }
        } else {
          print("⚠️ [GiftWebSocketService] No callbacks registered for event: $eventName");
          print("⚠️ [GiftWebSocketService] Available callbacks: ${_eventCallbacks.keys.toList()}");
        }
      }
      // Check for action-based response
      else if (data.containsKey('action')) {
        // ✅ Safely get action (handle int types)
        String actionName = '';
        if (data['action'] != null) {
          actionName = data['action'].toString();
        }
        print("📡 [GiftWebSocketService] Action response: $actionName");
        print("📡 [GiftWebSocketService] Action Data: $data");
        // Handle action responses if needed
      }
      // Check for error response
      else if (data.containsKey('status') && data['status'] == 'error') {
        final errorMessage = data['message'] as String? ?? 'Unknown error';
        print("❌ [GiftWebSocketService] ===== SERVER ERROR RESPONSE =====");
        print("❌ [GiftWebSocketService] Error Message: $errorMessage");
        print("❌ [GiftWebSocketService] ==================================");
        
        // Trigger error callbacks
        if (_eventCallbacks.containsKey('error')) {
          for (var callback in _eventCallbacks['error']!) {
            try {
              callback(data);
            } catch (e) {
              print("❌ [GiftWebSocketService] Error in error callback: $e");
            }
          }
        }
      }
      // Check for success response
      else if (data.containsKey('status') && data['status'] == 'success') {
        final successMessage = data['message'] as String? ?? '';
        print("✅ [GiftWebSocketService] ===== SERVER SUCCESS RESPONSE =====");
        print("✅ [GiftWebSocketService] Success Message: $successMessage");
        print("✅ [GiftWebSocketService] Response Data: $data");
        print("✅ [GiftWebSocketService] Response Keys: ${data.keys.toList()}");
        print("✅ [GiftWebSocketService] ====================================");
        
        // Trigger success callbacks
        if (_eventCallbacks.containsKey('success')) {
          print("✅ [GiftWebSocketService] Triggering ${_eventCallbacks['success']!.length} success callback(s)");
          for (var callback in _eventCallbacks['success']!) {
            try {
              callback(data);
            } catch (e) {
              print("❌ [GiftWebSocketService] Error in success callback: $e");
            }
          }
        } else {
          print("⚠️ [GiftWebSocketService] No success callbacks registered");
          print("⚠️ [GiftWebSocketService] Available callbacks: ${_eventCallbacks.keys.toList()}");
        }
      }
      // ✅ Log any other response format for debugging
      else {
        print("⚠️ [GiftWebSocketService] ===== UNKNOWN RESPONSE FORMAT =====");
        print("⚠️ [GiftWebSocketService] Response Keys: ${data.keys.toList()}");
        print("⚠️ [GiftWebSocketService] Full Response: $data");
        print("⚠️ [GiftWebSocketService] ==================================");
      }
    } catch (e) {
      print("❌ [GiftWebSocketService] Error handling message: $e");
      print("   - Message: $message");
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    print("🔌 [GiftWebSocketService] Disconnecting from WebSocket");
    try {
      await _messageSubscription?.cancel();
      await _channel?.sink.close();
      _channel = null;
      _messageSubscription = null;
      _isConnected = false;
      _currentUserId = null;
      _eventCallbacks.clear();
      print("✅ [GiftWebSocketService] Disconnected successfully");
      notifyListeners();
    } catch (e) {
      print("❌ [GiftWebSocketService] Error disconnecting: $e");
    }
  }
}

