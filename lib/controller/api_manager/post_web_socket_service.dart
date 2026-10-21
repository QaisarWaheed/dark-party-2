
// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PostsWebSocketService with ChangeNotifier {
  static PostsWebSocketService? _instance;

  static PostsWebSocketService get instance {
    _instance ??= PostsWebSocketService._();
    return _instance!;
  }

  PostsWebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUserId;
  Completer<bool>? _connectionCompleter;

  final Map<String, List<Function(Map<String, dynamic>)>> _eventCallbacks = {};

  String get wsUrl => ApiConstants.postWebSocketUrl;

  // Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  /// Connect to Posts WebSocket
  Future<bool> connect({required String userId,
    String? username,
    String? name,}) async {
      try{


  // ✅ If already connected and user is the same, return true
      if (_isConnected && _channel != null && _currentUserId == userId) {
        print("✅ [PostWebSocketService] Already connected with same user - reusing connection");
        return true;
      }
   // ✅ If connection is in progress, wait for it
      if (_isConnecting && _connectionCompleter != null) {
        print("⏳ [PostWebSocketService] Connection already in progress - waiting...");
        return await _connectionCompleter!.future;
      }

    _isConnecting = true;
    _connectionCompleter = Completer<bool>();

final baseUrl = wsUrl.trim();
print(baseUrl);
    print("🎁 [PostWebSocketService] Connecting to Posts WebSocket server: $baseUrl");
      
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
        print("📡 [PostWebSocketService] User ID formatted to 8 digits: ${formattedUserId ?? userId} (original: $userId)");
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

             print("📡 [PostWebSocketService] Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Port: ${uri.port}");
      print("📡 [PostWebSocketService] Query Parameters: ${uri.queryParameters}");
      
       if (uri.port == 0) {
        throw Exception('WebSocket URL must include a port number (e.g., :8084)');
      }

  // ✅ Disconnect existing connection if any (only if user changed)
      if (_channel != null && _currentUserId != userId) {
        print("🔄 [PostWebSocketService] Disconnecting existing connection (user changed)...");
        await disconnect();
        // Wait a bit after disconnecting
        await Future.delayed(Duration(milliseconds: 500));
      }
      else if (_channel != null && _isConnected) {
        // ✅ Same user, already connected - just return
        _isConnecting = false;
        if (!_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete(true);
        }
        return true;
      }
            // Connect - wrap in try-catch to handle immediate connection failures
      print("🔌 [PostWebSocketService] Creating new WebSocket connection...");
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
        print("❌ [PostWebSocketService] Socket Exception during channel creation: $e");
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
      catch (e, stackTrace) {
        print("❌ [PostWebSocketService] Exception during channel creation: $e");
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
        print("❌ [PostWebSocketService] Channel is null after creation attempt");
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
      print("👂 [PostWebSocketService] Setting up WebSocket message listener...");
     
     try {
        // Set up the stream listener immediately to catch any async errors
      _messageSubscription = _channel!.stream.listen(
        (message) {
          if (!connectionEstablished) {
            connectionEstablished = true;
            print("✅ [PostWebSocketService] First message received - connection confirmed");
            print("✅ [PostWebSocketService] First message content: $message");
          }
          print("📥 [PostWebSocketService] ===== RAW MESSAGE RECEIVED =====");
          print("📥 [PostWebSocketService] Message Type: ${message.runtimeType}");
          print("📥 [PostWebSocketService] Message Content: $message");
          print("📥 [PostWebSocketService] ==================================");
          _handleMessage(message);
        },
        onError: (error) {
            // This will catch async errors from the WebSocket connection
          print("❌ [PostWebSocketService] WebSocket stream error: $error");
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
          print("🔌 [PostWebSocketService] WebSocket connection closed");
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
        print("❌ [PostWebSocketService] Error setting up stream listener: $e");
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

       print("✅ [PostWebSocketService] WebSocket message listener set up successfully");

      // Wait a bit to allow connection to establish (shorter wait for faster fallback)
      print("⏳ [PostWebSocketService] Waiting for connection to establish...");
      
      // Check connection status multiple times during wait
      for (int i = 0; i < 4; i++) {
        await Future.delayed(Duration(milliseconds: 500));
        
        // Check if connection failed during wait
        if (connectionFailed) {
          print("❌ [PostWebSocketService] Connection failed during establishment (after ${(i + 1) * 500}ms)");
          _isConnected = false;
          notifyListeners();
          return false;
        }
        
        // Verify channel is still valid
        if (_channel == null) {
          print("❌ [PostWebSocketService] Channel is null after connection attempt");
          _isConnected = false;
          notifyListeners();
          return false;
        }
      }

       // Final check before marking as connected
      if (connectionFailed) {
        print("❌ [PostWebSocketService] Connection failed - final check");
        _isConnected = false;
        notifyListeners();
        return false;
      }

      _isConnected = true;
      _isConnecting = false;
      print("✅ [PostWebSocketService] ===== Post WEBSOCKET CONNECTION ESTABLISHED =====");
      print("✅ [PostWebSocketService] Connection Status: $_isConnected");
      print("✅ [PostWebSocketService] Channel Status: ${_channel != null}");
      print("✅ [PostWebSocketService] ============================================");
      
      // ✅ Complete the connection completer
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(true);
      }
      _connectionCompleter = null;
      
      notifyListeners();
      return true;
    } on TimeoutException catch (e) {
      print("⏱️ [PostWebSocketService] Connection Timeout: $e");
      _isConnected = false;
      _isConnecting = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }
      _connectionCompleter = null;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      print("🔌 [PostWebSocketService] Socket Exception: $e");
      _isConnected = false;
      _isConnecting = false;
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter!.complete(false);
      }
      _connectionCompleter = null;
      notifyListeners();
      return false;
    } catch (e) {
      print("❌ [PostWebSocketService] Connection Exception: $e");
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
    print("📝 [PostWebSocketService] Registered callback for event: $eventName");
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
    print("📤 [PostWebSocketService] Manually emitting event: $eventName");
    print("📤 [PostWebSocketService] Event data: $data");
    
    if (_eventCallbacks.containsKey(eventName)) {
      final callbacks = List<Function(Map<String, dynamic>)>.from(_eventCallbacks[eventName]!);
      print("✅ [PostWebSocketService] Triggering ${callbacks.length} callback(s) for event: $eventName");
      for (var callback in callbacks) {
        try {
          callback(data);
        } catch (e) {
          print("❌ [PostWebSocketService] Error in callback for $eventName: $e");
        }
      }
    } else {
      print("⚠️ [PostWebSocketService] No callbacks registered for event: $eventName");
      print("⚠️ [PostWebSocketService] Available callbacks: ${_eventCallbacks.keys.toList()}");
    }
  }

  /// Send an action to the WebSocket server
  bool sendAction(String action, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print("❌ [PostWebSocketService] Cannot send action: WebSocket not connected");
      print("   - isConnected: $_isConnected");
      print("   - channel: ${_channel != null}");
      return false;
    }

    try {
      // ✅ Verify channel is still open before sending
      if (_channel == null) {
        print("❌ [PostWebSocketService] Channel is null");
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
        print("📤 [PostWebSocketService] ===== SENDING WEBSOCKET ACTION =====");
        print("📤 [PostWebSocketService] Action Name: $action");
        print("📤 [PostWebSocketService] Action Data: $data");
        print("📤 [PostWebSocketService] Full JSON Message: $message");
        print("📤 [PostWebSocketService] Message Length: ${message.length} bytes");
        print("📤 [PostWebSocketService] ====================================");
        return true;
      } catch (sinkError) {
        print("❌ [PostWebSocketService] Error adding to sink: $sinkError");
        print("   - Channel may be closed or connection lost");
        _isConnected = false;
        _channel = null;
        _messageSubscription?.cancel();
        _messageSubscription = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("❌ [PostWebSocketService] Error sending action: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      print("📥 [PostWebSocketService] ===== PARSING WEBSOCKET MESSAGE =====");
      print("📥 [PostWebSocketService] Raw message: $message");
      print("📥 [PostWebSocketService] Message type: ${message.runtimeType}");
      print("📥 [PostWebSocketService] Message length: ${message.toString().length} characters");

      String messageStr;
      if (message is String) {
        messageStr = message;
        print("📥 [PostWebSocketService] Message is String, parsing JSON...");
      } else {
        messageStr = message.toString();
      }

      final data = json.decode(messageStr) as Map<String, dynamic>;
      print("✅ [PostWebSocketService] JSON parsed successfully");

      // Check for event-based response
      if (data.containsKey('event')) {
        // ✅ Safely get event (handle int types)
        String eventName = '';
        if (data['event'] != null) {
          eventName = data['event'].toString();
        }
        final eventData = data['data'] as Map<String, dynamic>? ?? {};
        
        print("📡 [PostWebSocketService] ===== EVENT DETAILS =====");
        print("📡 [PostWebSocketService] Event: $eventName");
        print("📡 [PostWebSocketService] Event Data Keys: ${eventData.keys.toList()}");
        print("📡 [PostWebSocketService] Full Event Data: $eventData");
        print("📡 [PostWebSocketService] ==========================");

        // Trigger callbacks for this event
        if (_eventCallbacks.containsKey(eventName)) {
          print("✅ [PostWebSocketService] Triggering ${_eventCallbacks[eventName]!.length} callback(s) for event: $eventName");
          for (var callback in _eventCallbacks[eventName]!) {
            try {
              callback(eventData);
            } catch (e) {
              print("❌ [PostWebSocketService] Error in callback for $eventName: $e");
            }
          }
        } else {
          print("⚠️ [PostWebSocketService] No callbacks registered for event: $eventName");
          print("⚠️ [PostWebSocketService] Available callbacks: ${_eventCallbacks.keys.toList()}");
        }
      }
      // Check for action-based response
      else if (data.containsKey('action')) {
        // ✅ Safely get action (handle int types)
        String actionName = '';
        if (data['action'] != null) {
          actionName = data['action'].toString();
        }
        print("📡 [PostWebSocketService] Action response: $actionName");
        print("📡 [PostWebSocketService] Action Data: $data");
        // Handle action responses if needed
      }
      // Check for error response
      else if (data.containsKey('status') && data['status'] == 'error') {
        final errorMessage = data['message'] as String? ?? 'Unknown error';
        print("❌ [PostWebSocketService] ===== SERVER ERROR RESPONSE =====");
        print("❌ [PostWebSocketService] Error Message: $errorMessage");
        print("❌ [PostWebSocketService] ==================================");
        
        // Trigger error callbacks
        if (_eventCallbacks.containsKey('error')) {
          final errorCallbacks = List<Function(Map<String, dynamic>)>.from(_eventCallbacks['error']!);
          for (var callback in errorCallbacks) {
            try {
              callback(data);
            } catch (e) {
              print("❌ [PostWebSocketService] Error in error callback: $e");
            }
          }
        }
      }
      // Check for success response
      else if (data.containsKey('status') && data['status'] == 'success') {
        final successMessage = data['message'] as String? ?? '';
        print("✅ [PostWebSocketService] ===== SERVER SUCCESS RESPONSE =====");
        print("✅ [PostWebSocketService] Success Message: $successMessage");
        print("✅ [PostWebSocketService] Response Data: $data");
        print("✅ [PostWebSocketService] Response Keys: ${data.keys.toList()}");
        print("✅ [PostWebSocketService] ====================================");
        
        // Trigger success callbacks
        if (_eventCallbacks.containsKey('success')) {
          final successCallbacks = List<Function(Map<String, dynamic>)>.from(_eventCallbacks['success']!);
          print("✅ [PostWebSocketService] Triggering ${successCallbacks.length} success callback(s)");
          for (var callback in successCallbacks) {
            try {
              callback(data);
            } catch (e) {
              print("❌ [PostWebSocketService] Error in success callback: $e");
            }
          }
        } else {
          print("⚠️ [PostWebSocketService] No success callbacks registered");
          print("⚠️ [PostWebSocketService] Available callbacks: ${_eventCallbacks.keys.toList()}");
        }
      }
      // ✅ Log any other response format for debugging
      else {
        print("⚠️ [PostWebSocketService] ===== UNKNOWN RESPONSE FORMAT =====");
        print("⚠️ [PostWebSocketService] Response Keys: ${data.keys.toList()}");
        print("⚠️ [PostWebSocketService] Full Response: $data");
        print("⚠️ [PostWebSocketService] ==================================");
      }
    } catch (e) {
      print("❌ [PostWebSocketService] Error handling message: $e");
      print("   - Message: $message");
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    print("🔌 [PostWebSocketService] Disconnecting from WebSocket");
    try {
      await _messageSubscription?.cancel();
      await _channel?.sink.close();
      _channel = null;
      _messageSubscription = null;
      _isConnected = false;
      _currentUserId = null;
      _eventCallbacks.clear();
      print("✅ [PostWebSocketService] Disconnected successfully");
      notifyListeners();
    } catch (e) {
      print("❌ [PostWebSocketService] Error disconnecting: $e");
    }
  }
}

