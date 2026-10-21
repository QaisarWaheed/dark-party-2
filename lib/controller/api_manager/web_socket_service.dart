// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

 
 class WebSocketService with ChangeNotifier {
   static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  bool _isReconnecting = false; // ✅ Track reconnection state
  Timer? _reconnectTimer; // ✅ Timer for reconnection attempts

  final Map<String, List<Function(Map<String, dynamic>)>> _eventCallbacks = {};

  // Getters
  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  String get wsUrl => ApiConstants.webSocketUrl;

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_isReconnecting) {
      print("⚠️ [WebSocketService] Reconnection already in progress, skipping...");
      return;
    }
    
    _reconnectTimer?.cancel();
    _isReconnecting = true;
    
    _reconnectTimer = Timer(Duration(seconds: 2), () async {
      if (_currentRoomId != null && _currentUserId != null) {
        print("🔄 [WebSocketService] Attempting to reconnect...");
        print("🔄 [WebSocketService] Room ID: $_currentRoomId, User ID: $_currentUserId");
        
        // Get username and profileUrl from SharedPreferences if needed
        try {
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username');
          final profileUrl = prefs.getString('profile_url');
          
          final success = await connect(
            roomId: _currentRoomId,
            userId: _currentUserId,
            username: username,
            profileUrl: profileUrl,
          );
          
          if (success) {
            print("✅ [WebSocketService] Reconnection successful");
            _isReconnecting = false;
          } else {
            print("❌ [WebSocketService] Reconnection failed, will retry...");
            _isReconnecting = false;
            _scheduleReconnect(); // Retry after another delay
          }
        } catch (e) {
          print("❌ [WebSocketService] Error during reconnection: $e");
          _isReconnecting = false;
          _scheduleReconnect(); // Retry after another delay
        }
      } else {
        print("⚠️ [WebSocketService] Cannot reconnect: Room ID or User ID is null");
        _isReconnecting = false;
      }
    });
  }

  /// Connect to WebSocket server with optional room_id, user_id, username, and profile_url in URL
  Future<bool> connect({
    String? roomId,
    String? userId,
    String? username,
    String? profileUrl,
  }) async {
    try {
      final baseUrl = wsUrl.trim();
      print("🚀 [WebSocketService] Connecting to WebSocket server: $baseUrl");
      
      // Validate URL format
      if (!baseUrl.startsWith('ws://') && !baseUrl.startsWith('wss://')) {
        throw Exception('Invalid WebSocket URL format. Must start with ws:// or wss://');
      }
      
      // Build URI with query parameters if room_id and user_id are provided
      Map<String, String> queryParams = {};
      if (roomId != null && userId != null) {
        queryParams['room_id'] = roomId;
        queryParams['user_id'] = userId;
        
        // Add username if provided
        if (username != null && username.isNotEmpty) {
          queryParams['username'] = username;
        }
        
        // Add profile_url if provided
        if (profileUrl != null && profileUrl.isNotEmpty) {
          queryParams['profile_url'] = profileUrl;
        }
      }
      
      final uri = queryParams.isNotEmpty
          ? Uri.parse(baseUrl).replace(queryParameters: queryParams)
          : Uri.parse(baseUrl);
      
      print("📡 [WebSocketService] Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Port: ${uri.port}");
      print("📡 [WebSocketService] Query Parameters: ${uri.queryParameters}");
      print("📡 [WebSocketService] Full WebSocket URL: $uri");
      if (queryParams.isNotEmpty) {
        print("✅ [WebSocketService] Connection includes URL parameters for backend user tracking:");
        print("   - room_id: ${queryParams['room_id']}");
        print("   - user_id: ${queryParams['user_id']}");
        print("   - username: ${queryParams['username'] ?? 'not provided'}");
        print("   - profile_url: ${queryParams['profile_url'] ?? 'not provided'}");
        print("✅ [WebSocketService] Backend should auto-register user from these parameters");
      } else {
        print("⚠️ [WebSocketService] No URL parameters - backend won't auto-register user");
        print("⚠️ [WebSocketService] Frontend will send join_room action as fallback");
      }
      
      if (uri.port == 0) {
        throw Exception('WebSocket URL must include a port number (e.g., :8083)');
      }

      // Disconnect existing connection if any
      // ⚠️ NOTE: disconnect() clears all callbacks, so providers must re-register them after connect()
      if (_channel != null) {
        print("⚠️ [WebSocketService] Existing connection found, disconnecting (this will clear all callbacks)");
        await disconnect();
        print("⚠️ [WebSocketService] Disconnected - all callbacks cleared. Providers must re-register listeners.");
      }

      // Connect
      _channel = WebSocketChannel.connect(uri);

      // Store room/user info
      _currentRoomId = roomId;
      _currentUserId = userId;

      // Listen to incoming messages
      print("👂 [WebSocketService] Setting up WebSocket message listener...");
      _messageSubscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print("❌ [WebSocketService] ===== WEBSOCKET STREAM ERROR =====");
          print("❌ [WebSocketService] Error: $error");
          print("❌ [WebSocketService] Error Type: ${error.runtimeType}");
          print("❌ [WebSocketService] Connection Status Before: $_isConnected");
          _isConnected = false;
          print("❌ [WebSocketService] Connection Status After: $_isConnected");
          print("❌ [WebSocketService] ====================================");
          notifyListeners();
        },
        onDone: () {
          print("🔌 [WebSocketService] ===== WEBSOCKET CONNECTION CLOSED =====");
          print("🔌 [WebSocketService] Connection closed by server or network issue");
          print("🔌 [WebSocketService] Current Room ID: $_currentRoomId");
          print("🔌 [WebSocketService] Current User ID: $_currentUserId");
          print("🔌 [WebSocketService] Connection Status Before: $_isConnected");
          _isConnected = false;
          print("🔌 [WebSocketService] Connection Status After: $_isConnected");
          print("🔌 [WebSocketService] ======================================");
          
          // ✅ Auto-reconnect if we have room and user info
          if (_currentRoomId != null && _currentUserId != null && !_isReconnecting) {
            print("🔄 [WebSocketService] Attempting to reconnect in 2 seconds...");
            _scheduleReconnect();
          }
          
          notifyListeners();
        },
        cancelOnError: false,
      );
      
      print("✅ [WebSocketService] WebSocket message listener set up successfully");

      // Wait a bit to allow connection to establish
      print("⏳ [WebSocketService] Waiting for connection to establish...");
      await Future.delayed(Duration(seconds: 2));

      _isConnected = true;
      print("✅ [WebSocketService] ===== WEBSOCKET CONNECTION ESTABLISHED =====");
      print("✅ [WebSocketService] Connection Status: $_isConnected");
      print("✅ [WebSocketService] Channel Status: ${_channel != null}");
      print("✅ [WebSocketService] Stream Status: ${_channel?.stream != null}");
      print("✅ [WebSocketService] ============================================");
      
      notifyListeners();
      return true;
    } on TimeoutException catch (e) {
      print("⏱️ [WebSocketService] Connection Timeout: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      print("🔌 [WebSocketService] Socket Exception: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    } catch (e) {
      print("❌ [WebSocketService] Connection Exception: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a callback for a specific event
  void on(String eventName, Function(Map<String, dynamic>) callback) {
    _eventCallbacks.putIfAbsent(eventName, () => []).add(callback);
    print("📝 [WebSocketService] Registered callback for event: $eventName");
    print("📝 [WebSocketService] Total registered events: ${_eventCallbacks.keys.length}");
    print("📝 [WebSocketService] Registered events: ${_eventCallbacks.keys.toList()}");
  }

  /// Unregister a callback for a specific event
  void off(String eventName, Function(Map<String, dynamic>) callback) {
    _eventCallbacks[eventName]?.remove(callback);
    if (_eventCallbacks[eventName]?.isEmpty ?? false) {
      _eventCallbacks.remove(eventName);
    }
    print("🗑️ [WebSocketService] Unregistered callback for event: $eventName");
  }

  /// Remove all callbacks for an event
  void offAll(String eventName) {
    _eventCallbacks.remove(eventName);
    print("🗑️ [WebSocketService] Removed all callbacks for event: $eventName");
  }

  /// Send action to server (server expects action format)
  /// Format: {"action": "get_seats", "room_id": 181}
  bool sendAction(String action, Map<String, dynamic> data) {
    try {
      if (_channel == null || !_isConnected) {
        print("❌ [WebSocketService] Cannot send action: WebSocket not connected");
        print("❌ [WebSocketService] Channel: ${_channel != null}, Connected: $_isConnected");
        return false;
      }

      // ✅ Check if channel is still valid before sending
      // Note: We can't easily check if sink is closed, so we'll rely on try-catch

      // Server expects: {"action": "get_seats", "room_id": 181}
      Map<String, dynamic> messageData = {
        'action': action,
        ...data, // Spread data fields at root level
      };
      
      final message = json.encode(messageData);

      try {
        _channel!.sink.add(message);
        print("✅ [WebSocketService] Sent action: $action");
        
        // ✅ Wait a moment and check if connection is still alive
        Future.delayed(Duration(milliseconds: 100), () {
          if (!_isConnected) {
            print("⚠️ [WebSocketService] Connection lost after sending message");
          }
        });
        
        return true;
      } catch (e) {
        print("❌ [WebSocketService] Error adding message to sink: $e");
        print("❌ [WebSocketService] Error type: ${e.runtimeType}");
        _isConnected = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      print("❌ [WebSocketService] ===== ERROR SENDING ACTION =====");
      print("❌ [WebSocketService] Error: $e");
      print("❌ [WebSocketService] Stack Trace: $stackTrace");
      print("❌ [WebSocketService] ==================================");
      return false;
    }
  }

  /// Send event to server (server expects event/data format for some operations)
  /// Format: {"event": "event_name", "data": {...}}
  bool sendEvent(String event, Map<String, dynamic> data) {
    try {
      if (_channel == null || !_isConnected) {
        print("❌ [WebSocketService] Cannot send event: WebSocket not connected");
        return false;
      }

      Map<String, dynamic> messageData = {
        'event': event,
        'data': data,
      };
      
      final message = json.encode(messageData);

      print("📤 [WebSocketService] ===== SENDING WEBSOCKET EVENT =====");
      print("📤 [WebSocketService] Event Name: $event");
      print("📤 [WebSocketService] Event Data: $data");
      print("📤 [WebSocketService] Full JSON Message: $message");
      print("📤 [WebSocketService] Message Length: ${message.length} bytes");
      print("📤 [WebSocketService] ====================================");
      
      _channel!.sink.add(message);
      return true;
    } catch (e) {
      print("❌ [WebSocketService] Error sending event: $e");
      return false;
    }
  }

  /// Extract room ID from message data (handles multiple possible field names)
  String? _extractRoomId(Map<String, dynamic> data) {
    // Check data field first
    if (data.containsKey('data') && data['data'] is Map) {
      final eventData = data['data'] as Map<String, dynamic>;
      
      // Try multiple possible field names for room ID
      final roomId = eventData['room_id']?.toString() ?? 
                    eventData['roomId']?.toString() ?? 
                    eventData['room']?.toString();
      
      if (roomId != null) {
        return roomId;
      }
    }
    
    // Check root level
    final rootRoomId = data['room_id']?.toString() ?? 
                      data['roomId']?.toString() ?? 
                      data['room']?.toString();
    
    return rootRoomId;
  }

  /// Log room filtering details for debugging
  void _logRoomFilteringDetails(Map<String, dynamic> data, String? eventRoomId) {
    print("🏠 [WebSocketService] ===== ROOM FILTERING DEBUG =====");
    print("🏠 [WebSocketService] Current Room: $_currentRoomId");
    print("🏠 [WebSocketService] Extracted Event Room: $eventRoomId");
    print("🏠 [WebSocketService] Event Type: ${data['event'] ?? data['action']}");
    print("🏠 [WebSocketService] All Data Keys: ${data.keys.toList()}");
    
    if (data.containsKey('data') && data['data'] is Map) {
      final eventData = data['data'] as Map;
      print("🏠 [WebSocketService] Event Data Keys: ${eventData.keys.toList()}");
      print("🏠 [WebSocketService] Event Data Room Fields:");
      print("   - room_id: ${eventData['room_id']}");
      print("   - roomId: ${eventData['roomId']}");
      print("   - room: ${eventData['room']}");
    }
    
    final shouldProcess = eventRoomId == null || eventRoomId == _currentRoomId;
    print("🏠 [WebSocketService] Should Process: $shouldProcess");
    print("🏠 [WebSocketService] ================================");
  }


  

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      print("📥 [WebSocketService] ===== PARSING WEBSOCKET MESSAGE =====");
      print("📥 [WebSocketService] Raw message: $message");
      print("📥 [WebSocketService] Message type: ${message.runtimeType}");
      print("📥 [WebSocketService] Connection status: $_isConnected");

      // Parse JSON message
      final Map<String, dynamic> data;
      if (message is String) {
        print("📥 [WebSocketService] Message is String, parsing JSON...");
        
        // ✅ Check if message is an error or close notification
        if (message.toLowerCase().contains('error') || 
            message.toLowerCase().contains('close') ||
            message.toLowerCase().contains('disconnect')) {
          print("⚠️ [WebSocketService] Received potential error/close message: $message");
        }
        
        try {
          data = json.decode(message);
          print("✅ [WebSocketService] JSON parsed successfully");
        } catch (e) {
          print("❌ [WebSocketService] JSON Parse Error: $e");
          print("❌ [WebSocketService] Raw string: $message");
          
          // ✅ If it's not JSON, it might be a plain text error from server
          if (message.trim().isNotEmpty) {
            print("⚠️ [WebSocketService] Non-JSON message received (might be server error): $message");
          }
          return;
        }
      } else if (message is Map) {
        print("📥 [WebSocketService] Message is already a Map");
        data = Map<String, dynamic>.from(message);
      } else {
        print("❌ [WebSocketService] Unknown message type: ${message.runtimeType}");
        return;
      }

      print("📥 [WebSocketService] Parsed data keys: ${data.keys.toList()}");
      
      // ✅ Check for error status in response
      if (data.containsKey('status') && data['status'] == 'error') {
        print("❌ [WebSocketService] ===== SERVER ERROR IN MESSAGE =====");
        print("❌ [WebSocketService] Error Status: ${data['status']}");
        print("❌ [WebSocketService] Error Message: ${data['message'] ?? 'No message'}");
        print("❌ [WebSocketService] Full Error Data: $data");
        print("❌ [WebSocketService] ====================================");
      }

      // ✅ CRITICAL: FILTER BY ROOM ID FIRST
      final eventRoomId = _extractRoomId(data);
      final currentRoomId = _currentRoomId;
      
      print("🏠 [WebSocketService] Room Filtering - Event Room: $eventRoomId, Current Room: $currentRoomId");
      
      // ✅ DEBUG: Log room filtering details
      _logRoomFilteringDetails(data, eventRoomId);
      
      // ✅ If we have a current room and event has a room ID, filter by room
      if (currentRoomId != null && eventRoomId != null && eventRoomId != currentRoomId) {
        print("🔕 [WebSocketService] IGNORING EVENT - Room mismatch: Event for room $eventRoomId, but we're in room $currentRoomId");
        print("🔕 [WebSocketService] Event data: ${data['event'] ?? data['action']}");
        return; // Skip processing events from other rooms
      }
      
      // ✅ If no room ID in event, assume it's for current room (backward compatibility)
      if (currentRoomId != null && eventRoomId == null) {
        print("ℹ️ [WebSocketService] Event has no room ID, assuming it's for current room: $currentRoomId");
      }

      // Continue with existing message processing...
      _processMessageData(data);

    } catch (e, stackTrace) {
      print("❌ [WebSocketService] ===== ERROR PARSING WEBSOCKET MESSAGE =====");
      print("❌ [WebSocketService] Error: $e");
      print("❌ [WebSocketService] Stack Trace: $stackTrace");
      print("❌ [WebSocketService] Message that caused error: $message");
      print("❌ [WebSocketService] ============================================");
    }
  }

  /// Process message data after room filtering
  void _processMessageData(Map<String, dynamic> data) {
    // Extract event/action name
    // ✅ Safely get action and event (handle int types)
    String? action;
    if (data['action'] != null) {
      action = data['action'].toString();
    }
    String? event;
    if (data['event'] != null) {
      event = data['event'].toString();
    }
    final eventName = action ?? event;

    // Extract event data
    Map<String, dynamic> eventData;
    if (data.containsKey('data') && data['data'] is Map) {
      eventData = Map<String, dynamic>.from(data['data'] as Map);
    } else {
      eventData = Map<String, dynamic>.from(data);
      eventData.remove('action');
      eventData.remove('event');
    }

    print("📡 [WebSocketService] ===== EVENT DETAILS =====");
    print("📡 [WebSocketService] Action: $action");
    print("📡 [WebSocketService] Event: $event");
    print("📡 [WebSocketService] Event Name (using): $eventName");
    print("📡 [WebSocketService] Event Data Keys: ${eventData.keys.toList()}");
    print("📡 [WebSocketService] ==========================");

    // ✅ HANDLE STATUS-BASED RESPONSES FIRST (error/success)
    // This must be checked BEFORE returning if eventName is null
    if (data.containsKey('status')) {
      if (data['status'] == 'error') {
        // ✅ Safely get message (handle int types)
        String errorMessage = 'Unknown error';
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        }
        print("❌ [WebSocketService] ===== SERVER ERROR RESPONSE =====");
        print("❌ [WebSocketService] Error Message: $errorMessage");
        print("❌ [WebSocketService] Full Error Data: $data");
        print("❌ [WebSocketService] ==================================");
        _triggerEvent('error', {
          'message': errorMessage,
          'data': data,
        });
        // ✅ Error event triggered, no need to process further
        return;
      } else if (data['status'] == 'success') {
        // ✅ Safely get message (handle int types)
        String successMessage = 'Operation successful';
        if (data['message'] != null) {
          successMessage = data['message'].toString();
        }
        print("✅ [WebSocketService] ===== SERVER SUCCESS RESPONSE =====");
        print("✅ [WebSocketService] Success Message: $successMessage");
        print("✅ [WebSocketService] Success Data: ${data['data'] ?? {}}");
        print("✅ [WebSocketService] ====================================");
        
        // ✅ Prepare success data
        final successDataRaw = data['data'] ?? {};
        final successData = successDataRaw is Map 
            ? Map<String, dynamic>.from(successDataRaw) 
            : <String, dynamic>{};
        
        // ✅ SPECIAL HANDLING: If success message contains chat history, trigger chat_history event
        if (successMessage.toLowerCase().contains('chat history') && 
            successData.containsKey('messages')) {
          print("📜 [WebSocketService] ===== CHAT HISTORY IN SUCCESS RESPONSE =====");
          print("📜 [WebSocketService] Detected chat history in success response");
          print("📜 [WebSocketService] Triggering chat_history event with messages");
          print("📜 [WebSocketService] ============================================");
          // ✅ Trigger chat_history event with the messages data
          _triggerEvent('chat_history', successData);
        }
        
        // ✅ SPECIAL HANDLING: If success message contains seats information, trigger all_seats_info event
        if ((successMessage.toLowerCase().contains('seats information') || 
             successMessage.toLowerCase().contains('seats info')) && 
            successData.containsKey('seats')) {
          print("🪑 [WebSocketService] ===== SEATS INFO IN SUCCESS RESPONSE =====");
          print("🪑 [WebSocketService] Detected seats information in success response");
          print("🪑 [WebSocketService] Success Message: $successMessage");
          print("🪑 [WebSocketService] Success Data Keys: ${successData.keys.toList()}");
          print("🪑 [WebSocketService] Triggering all_seats_info event with seats data");
          print("🪑 [WebSocketService] ============================================");
          // ✅ Trigger all_seats_info event with the seats data
          _triggerEvent('all_seats_info', successData);
        }
        
        _triggerEvent('success', {
          'message': successMessage,
          'data': successData,
        });
        // ✅ Success event triggered, continue to process event if present
      }
    }

    // ✅ Now check if we have an event/action name
    if (eventName == null) {
      print("⚠️ [WebSocketService] Both action and event are null! Message structure might be different");
      print("⚠️ [WebSocketService] Available keys: ${data.keys.toList()}");
      // ✅ If we already handled status (error/success), we can return
      // Otherwise, this might be an unknown message format
      if (!data.containsKey('status')) {
        print("⚠️ [WebSocketService] No status field either - unknown message format");
      }
      return;
    }

    // ✅ DIAGNOSTIC: Log filtered events
    print("🔔 [WebSocketService] ===== ROOM-FILTERED EVENT RECEIVED =====");
    print("🔔 [WebSocketService] Event Name: $eventName");
    print("🔔 [WebSocketService] Current Room: $_currentRoomId");
    print("🔔 [WebSocketService] =====================================");
    
    // Trigger callbacks for this event
    final callbacks = _eventCallbacks[eventName] ?? [];
    print("🔍 [WebSocketService] Checking callbacks for event: $eventName");
    print("🔍 [WebSocketService] Callbacks found: ${callbacks.length}");
    print("🔍 [WebSocketService] All registered events: ${_eventCallbacks.keys.toList()}");
    print("🔍 [WebSocketService] Total registered events: ${_eventCallbacks.length}");
    
    if (callbacks.isNotEmpty) {
      print("✅ [WebSocketService] Triggering ${callbacks.length} callback(s) for event: $eventName");
      for (final callback in callbacks) {
        try {
          callback(eventData);
          print("✅ [WebSocketService] Callback executed successfully for: $eventName");
        } catch (e, stackTrace) {
          print("❌ [WebSocketService] Error in callback for $eventName: $e");
          print("❌ [WebSocketService] Stack trace: $stackTrace");
        }
      }
    } else {
      print("⚠️ [WebSocketService] ⚠️⚠️⚠️ NO CALLBACKS REGISTERED FOR EVENT: $eventName ⚠️⚠️⚠️");
      print("⚠️ [WebSocketService] This event was received from server but no handler is set up!");
      print("⚠️ [WebSocketService] Available registered events: ${_eventCallbacks.keys.toList()}");
      print("⚠️ [WebSocketService] Total registered events: ${_eventCallbacks.length}");
      print("⚠️ [WebSocketService] This might mean:");
      print("⚠️   1. Event listener not set up in SeatProvider");
      print("⚠️   2. Event name mismatch (server sends '$eventName' but client expects different name)");
      print("⚠️   3. Backend is broadcasting but Flutter isn't handling it");
      print("⚠️   4. Callbacks were cleared (e.g., by disconnect() or offAll())");
    }

    // Also trigger callbacks for wildcard events
    final wildcardCallbacks = _eventCallbacks['*'] ?? [];
    for (final callback in wildcardCallbacks) {
      try {
        callback({
          'event': eventName,
          'data': eventData,
        });
      } catch (e) {
        print("❌ [WebSocketService] Error in wildcard callback: $e");
      }
    }
  }

  /// Trigger event callbacks manually (for internal use)
  void _triggerEvent(String eventName, Map<String, dynamic> data) {
    final callbacks = _eventCallbacks[eventName] ?? [];
    for (final callback in callbacks) {
      try {
        callback(data);
      } catch (e) {
        print("❌ [WebSocketService] Error in callback for $eventName: $e");
      }
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    try {
      print("🔌 [WebSocketService] Disconnecting from WebSocket");

      await _messageSubscription?.cancel();
      await _channel?.sink.close();

      _channel = null;
      _messageSubscription = null;
      _isConnected = false;
      _currentRoomId = null;
      _currentUserId = null;

      // Clear all callbacks
      _eventCallbacks.clear();

      notifyListeners();
      print("✅ [WebSocketService] Disconnected successfully");
    } catch (e) {
      print("❌ [WebSocketService] Error disconnecting: $e");
    }
  }

  /// Update current room and user ID
  void updateRoomInfo(String? roomId, String? userId) {
    _currentRoomId = roomId;
    _currentUserId = userId;
    print("📝 [WebSocketService] Updated room info - Room: $roomId, User: $userId");
  }

  @override
  void dispose() {
    print("🗑️ [WebSocketService] Disposing WebSocketService");
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    disconnect();
    super.dispose();
  }


  
}

