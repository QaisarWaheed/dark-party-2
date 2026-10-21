import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/model/seat_model.dart';
import 'package:shaheen_star_app/controller/api_manager/web_socket_service.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

class SeatProvider with ChangeNotifier {
  // ✅ Use global WebSocket service
  final WebSocketService _wsService = WebSocketService.instance;

  // Seat data
  List<Seat> _seats = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _totalSeats = 0;
  int _occupiedSeats = 0;
  int _availableSeats = 0;
  bool _isInitialSeatsLoad = true; // ✅ Track if this is the first seats load
  bool _hasAutoOccupiedSeat =
      false; // ✅ Track if we've auto-sent occupy_seat for current session
  bool _isCurrentUserRegisteredAsSeated =
      false; // ✅ Track if current user is registered as seated with backend

  // ✅ User data cache to store user profile info fetched from API
  // Key: user_id (String), Value: Map with username, userName, profileUrl
  final Map<String, Map<String, String?>> _userDataCache = {};

  // ✅ Helper: Check if username is a "User X" pattern (fallback from backend)
  bool _isUserXPattern(String? username) {
    if (username == null || username.isEmpty) return false;
    final trimmed = username.trim();
    // Match patterns like "User 3", "User 8", "user 3", etc.
    return RegExp(r'^[Uu]ser\s+\d+$').hasMatch(trimmed);
  }

  // ✅ Helper: Filter out "User X" patterns - return null if it's a pattern
  String? _filterUserXPattern(String? username) {
    if (username == null || username.isEmpty) return null;
    if (_isUserXPattern(username)) {
      print("🚫 Filtered out 'User X' pattern: '$username'");
      return null; // Don't use "User X" patterns
    }
    return username;
  }

  // ✅ Helper: Check if a path is a local file path (not a network URL or server path)
  bool _isLocalFilePath(String? path) {
    if (path == null || path.isEmpty) return false;
    
    // Check for local file system paths
    if (path.startsWith('/data/') ||
        path.startsWith('/storage/') ||
        path.startsWith('/private/') ||
        path.startsWith('/var/') ||
        path.startsWith('/tmp/') ||
        path.contains('/cache/') ||
        path.contains('cache/') ||
        path.contains('/com.example.') ||
        path.contains('/com.') ||
        path.startsWith('file://') ||
        path.contains('/data/user/')) {
      return true;
    }
    
    return false;
  }

  // ✅ Helper: Normalize profile URL - converts relative server paths to full URLs, but preserves local file paths
  String? _normalizeProfileUrl(String? profileUrl) {
    if (profileUrl == null || profileUrl.isEmpty) return null;
    
    // ✅ If it's already a network URL, return as is
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return profileUrl;
    }
    
    // ✅ If it's a local file path, return null (don't try to load as network URL)
    if (_isLocalFilePath(profileUrl)) {
      print(
        "⚠️ [SeatProvider] Detected local file path, returning null: $profileUrl",
      );
      return null; // Don't use local file paths as network URLs
    }
    
    // ✅ If it's a relative server path (uploads/, profiles/, etc.), normalize to full URL
    if (profileUrl.startsWith('uploads/') ||
        profileUrl.startsWith('images/') ||
        profileUrl.startsWith('profiles/') ||
        profileUrl.startsWith('room_profiles/') ||
        profileUrl.startsWith('gifts/')) {
      return 'https://shaheenstar.online/$profileUrl';
    }
    
    // ✅ If it starts with /, it might be a server path (but not local file system)
    // Only normalize if it doesn't look like a local path
    if (profileUrl.startsWith('/') && !_isLocalFilePath(profileUrl)) {
      String cleanPath = profileUrl.substring(1); // Remove leading slash
      return 'https://shaheenstar.online/$cleanPath';
    }
    
    // ✅ Unknown format - return null to avoid invalid URLs
    print(
      "⚠️ [SeatProvider] Unknown profile URL format, returning null: $profileUrl",
    );
    return null;
  }

  // ✅ Callbacks for room events
  Function(Map<String, dynamic>)? onUserJoined;
  Function(Map<String, dynamic>)? onUserLeft;
  Function(Map<String, dynamic>)? onSeatOccupied; // ✅ Seat occupied callback (for seat join messages)
  Function(Map<String, dynamic>)? onMicStatusChanged;
  Function(Map<String, dynamic>)? onUserSpeaking;
  Function(Map<String, dynamic>)? onGiftSent; // ✅ Gift event callback
  Function(Map<String, dynamic>)? onMessageReceived; // ✅ Room message callback
  Function(List<Map<String, dynamic>>)?
  onChatHistoryReceived; // ✅ Chat history callback
  Function(Map<String, dynamic>)? onGiftsReceived; // ✅ Gifts list callback

  // Getters
  List<Seat> get seats => _seats;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get totalSeats => _totalSeats;
  int get occupiedSeats => _occupiedSeats;
  int get availableSeats => _availableSeats;
  bool get isConnected => _wsService.isConnected;
  bool get hasSeats => _seats.isNotEmpty;
  String? get currentRoomId => _wsService.currentRoomId;
  String? get currentUserId => _wsService.currentUserId;
  bool get isCurrentUserRegisteredAsSeated => _isCurrentUserRegisteredAsSeated;

  // ✅ Connect to WebSocket server (uses global WebSocketService)
  // ✅ Accepts optional username and profileUrl to avoid SharedPreferences fallbacks
  Future<bool> connect({
    String? roomId, 
    String? userId,
    String? username,
    String? profileUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // ✅ Use provided username/profileUrl (from ProfileUpdateProvider) - NO SharedPreferences fallback
      print("📡 [SeatProvider] WebSocket connection params:");
      print("   - Room ID: $roomId");
      print("   - User ID: $userId");
      print("   - Username: $username (from ProfileUpdateProvider, no SharedPreferences fallback)");
      print("   - Profile URL: $profileUrl (from ProfileUpdateProvider, no SharedPreferences fallback)");

      // ✅ Use global WebSocket service with username and profile_url
      final connected = await _wsService.connect(
        roomId: roomId,
        userId: userId,
        username: username,
        profileUrl: profileUrl,
      );
      
      if (connected) {
        // ✅ Set up event listeners for seat-related events
        _setupEventListeners();

        // ✅ CRITICAL FIX: Listen for connection status changes to re-register listeners after reconnection
        // WebSocketService clears all callbacks on disconnect, so we must re-register on reconnect
        _setupConnectionListener();
        
        // ✅ CRITICAL: Send   action immediately after connection
        if (roomId != null &&
            userId != null &&
            roomId.isNotEmpty &&
            userId.isNotEmpty) {
          print(
            "📤 [SeatProvider] Connection established - sending join_room action immediately",
          );
          print(
            "📤 [SeatProvider] This is CRITICAL for backend to track users for message broadcasting",
          );
          
          // Convert user_id to integer for backend (backend expects integer for database queries)
          final userIdInt =
              int.tryParse(userId.replaceAll(RegExp(r'^0+'), '')) ??
              int.tryParse(userId) ??
              0;
          final roomIdInt = int.tryParse(roomId) ?? 0;
          
          if (userIdInt > 0 && roomIdInt > 0) {
            // Wait a small delay to ensure connection is fully established
            Future.delayed(Duration(milliseconds: 300), () {
              final joinSent = _wsService.sendAction('join_room', {
                'room_id': roomIdInt,
                'user_id':
                    userIdInt, // ✅ Integer format (backend expects this for database queries)
              });
              
              if (joinSent) {
                print(
                  "✅ [SeatProvider] join_room action sent immediately after connection",
                );
                print(
                  "✅ [SeatProvider] Backend should now track this user in room $roomId",
                );
                print(
                  "✅ [SeatProvider] Messages should now broadcast to all users in room",
                );
              } else {
                print(
                  "⚠️ [SeatProvider] Failed to send join_room action immediately",
                );
                print("⚠️ [SeatProvider] Will retry in joinRoom() method");
              }
            });
          } else {
            print(
              "⚠️ [SeatProvider] Could not parse IDs for immediate join_room",
            );
            print(
              "⚠️ [SeatProvider] User ID: $userId -> $userIdInt, Room ID: $roomId -> $roomIdInt",
            );
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to connect to WebSocket';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print("❌ [SeatProvider] Connect Error: $e");
      _isLoading = false;
      _errorMessage = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Set up WebSocket event listeners
  // ✅ CLEAR EXISTING LISTENERS FIRST to prevent duplicates
  void _setupEventListeners() {
    print("🔧 [SeatProvider] ===== SETTING UP WEBSOCKET EVENT LISTENERS =====");
    print(
      "🔧 [SeatProvider] WebSocket Service Instance: ${_wsService.hashCode}",
    );
    print("🔧 [SeatProvider] WebSocket Connected: ${_wsService.isConnected}");
    
    // ✅ CRITICAL: Clear existing listeners to prevent duplicate registrations
    // This prevents the same event from triggering multiple times
    print("🧹 [SeatProvider] Clearing existing event listeners to prevent duplicates...");
    _wsService.offAll('seat_update');
    _wsService.offAll('seats:update');
    _wsService.offAll('get_seats');
    _wsService.offAll('seat_occupied');
    _wsService.offAll('seat:occupied');
    _wsService.offAll('seat_vacated');
    _wsService.offAll('seat:vacated');
    _wsService.offAll('user:joined');
    _wsService.offAll('user:left');
    _wsService.offAll('mic:on');
    _wsService.offAll('mic:off');
    _wsService.offAll('mic_status');
    _wsService.offAll('user:speaking');
    _wsService.offAll('speaking');
    _wsService.offAll('gift_sent');
    _wsService.offAll('gift:sent');
    _wsService.offAll('gifts:list');
    _wsService.offAll('gifts:update');
    _wsService.offAll('gifts:response');
    _wsService.offAll('gifts_list');
    _wsService.offAll('message');
    _wsService.offAll('room_message');
    _wsService.offAll('message:received');
    _wsService.offAll('message_received');
    _wsService.offAll('chat_history');
    _wsService.offAll('all_room_messages');
    _wsService.offAll('all_seats_info');
    _wsService.offAll('error');
    _wsService.offAll('success');
    _wsService.offAll('get_gifts');
    print("✅ [SeatProvider] Existing listeners cleared");
    
    // ✅ SEAT EVENTS
    _wsService.on('seat_update', _handleSeatsUpdate);
    _wsService.on('seats:update', _handleSeatsUpdate);
    // ✅ CRITICAL: Backend might respond with same action name as request
    // OR backend might send seats:update event after processing get_seats
    _wsService.on('get_seats', (data) {
      print("📊 [SeatProvider] ===== get_seats ACTION RESPONSE RECEIVED =====");
      print(
        "📊 [SeatProvider] Backend responded with 'get_seats' event (action response)",
      );
      print("📊 [SeatProvider] Data keys: ${data.keys.toList()}");
      print("📊 [SeatProvider] Full data: $data");

      // ✅ Check if response contains seats data directly
      if (data.containsKey('seats') || data.containsKey('data')) {
        print(
          "✅ [SeatProvider] Response contains seats data - processing directly",
        );
        _handleSeatsUpdate(data);
      } else {
        print(
          "ℹ️ [SeatProvider] Response is acknowledgment - backend should send seats:update event",
        );
        print("ℹ️ [SeatProvider] Waiting for seats:update event...");
      }
    });
    _wsService.on('seat_occupied', _handleSeatOccupied);
    _wsService.on('seat:occupied', (data) {
      _handleSeatOccupied(data);
      // ✅ Also trigger onSeatOccupied callback if set (for seat join messages)
      // Extract data from nested structure if present
      Map<String, dynamic> eventData = data;
      if (data['data'] != null && data['data'] is Map) {
        eventData = Map<String, dynamic>.from(data['data'] as Map);
      }
      if (onSeatOccupied != null) {
        onSeatOccupied!(eventData);
        print("✅ onSeatOccupied callback triggered from seat:occupied event");
      }
    });
    _wsService.on('seat_vacated', _handleSeatVacated);
    _wsService.on('seat:vacated', _handleSeatVacated);
    print("✅ [SeatProvider] Registered seat:vacated event listener");
    
    // ✅ ROOM EVENTS
    _wsService.on('user:joined', (data) {
      print("👤 [SeatProvider] User joined room: ${data['user_id']}");
      onUserJoined?.call(data);
    });
    
    _wsService.on('user:left', (data) {
      print("👋 [SeatProvider] User left room: ${data['user_id']}");
      onUserLeft?.call(data);
    });
    
    // ✅ MIC EVENTS
    _wsService.on('mic:on', (data) {
      print("🎤 [SeatProvider] Mic on: ${data['user_id']}");
      onMicStatusChanged?.call(data);
    });
    
    _wsService.on('mic:off', (data) {
      print("🔇 [SeatProvider] Mic off: ${data['user_id']}");
      onMicStatusChanged?.call(data);
    });
    
    _wsService.on('mic_status', (data) {
      print("🎤 [SeatProvider] Mic status: ${data['user_id']}");
      onMicStatusChanged?.call(data);
    });
    
    // ✅ SPEAKING EVENTS
    _wsService.on('user:speaking', (data) {
      print("🗣️ [SeatProvider] User speaking: ${data['user_id']}");
      onUserSpeaking?.call(data);
    });
    
    _wsService.on('speaking', (data) {
      print("🗣️ [SeatProvider] Speaking: ${data['user_id']}");
      onUserSpeaking?.call(data);
    });
    
    // ✅ GIFT EVENTS
    _wsService.on('gift_sent', (data) {
      print("🎁 [SeatProvider] Gift sent event received");
      onGiftSent?.call(data);
    });
    
    _wsService.on('gift:sent', (data) {
      print("🎁 [SeatProvider] Gift sent event received");
      onGiftSent?.call(data);
    });
    
    // ✅ GIFTS LIST EVENTS (for fetching gifts)
    _wsService.on('gifts:list', (data) {
      print("🎁 [SeatProvider] ===== GIFTS LIST EVENT RECEIVED =====");
      print("🎁 [SeatProvider] Event: gifts:list");
      print("🎁 [SeatProvider] Data keys: ${data.keys.toList()}");
      print("🎁 [SeatProvider] Callback set: ${onGiftsReceived != null}");
      if (onGiftsReceived != null) {
        onGiftsReceived!(data);
        print("✅ [SeatProvider] onGiftsReceived callback executed");
      } else {
        print(
          "⚠️ [SeatProvider] onGiftsReceived callback is NULL - gifts won't be processed",
        );
      }
      print("🎁 [SeatProvider] =====================================");
    });
    
    _wsService.on('gifts:update', (data) {
      print("🎁 [SeatProvider] ===== GIFTS UPDATE EVENT RECEIVED =====");
      print("🎁 [SeatProvider] Event: gifts:update");
      print("🎁 [SeatProvider] Data keys: ${data.keys.toList()}");
      print("🎁 [SeatProvider] Callback set: ${onGiftsReceived != null}");
      if (onGiftsReceived != null) {
        onGiftsReceived!(data);
        print("✅ [SeatProvider] onGiftsReceived callback executed");
      } else {
        print(
          "⚠️ [SeatProvider] onGiftsReceived callback is NULL - gifts won't be processed",
        );
      }
      print("🎁 [SeatProvider] =======================================");
    });
    
    _wsService.on('gifts:response', (data) {
      print("🎁 [SeatProvider] ===== GIFTS RESPONSE EVENT RECEIVED =====");
      print("🎁 [SeatProvider] Event: gifts:response");
      print("🎁 [SeatProvider] Data keys: ${data.keys.toList()}");
      print("🎁 [SeatProvider] Callback set: ${onGiftsReceived != null}");
      if (onGiftsReceived != null) {
        onGiftsReceived!(data);
        print("✅ [SeatProvider] onGiftsReceived callback executed");
      } else {
        print(
          "⚠️ [SeatProvider] onGiftsReceived callback is NULL - gifts won't be processed",
        );
      }
      print("🎁 [SeatProvider] =========================================");
    });
    
    _wsService.on('gifts_list', (data) {
      print("🎁 [SeatProvider] ===== GIFTS LIST EVENT RECEIVED =====");
      print("🎁 [SeatProvider] Event: gifts_list");
      print("🎁 [SeatProvider] Data keys: ${data.keys.toList()}");
      print("🎁 [SeatProvider] Callback set: ${onGiftsReceived != null}");
      if (onGiftsReceived != null) {
        onGiftsReceived!(data);
        print("✅ [SeatProvider] onGiftsReceived callback executed");
      } else {
        print(
          "⚠️ [SeatProvider] onGiftsReceived callback is NULL - gifts won't be processed",
        );
      }
      print("🎁 [SeatProvider] =====================================");
    });
    
    // ✅ MESSAGE EVENTS - SINGLE LISTENER TO PREVENT DUPLICATES
    // ✅ Backend sends messages via 'message' event - only listen to this one
    // ✅ REMOVED: Duplicate listeners for 'room_message', 'message:received', 'message_received'
    // ✅ This prevents the same message from being processed multiple times
    _wsService.on('message', (data) {
      print("💬 [SeatProvider] ===== ROOM MESSAGE EVENT RECEIVED =====");
      print("💬 [SeatProvider] Event: message");
      print("💬 [SeatProvider] Data keys: ${data.keys.toList()}");
      
      // ✅ CRITICAL: Backend sends nested structure: {event: 'message', data: {...}}
      // Extract data from nested structure if present
      Map<String, dynamic> messageData = data;
      if (data['data'] != null && data['data'] is Map) {
        messageData = Map<String, dynamic>.from(data['data'] as Map);
        print("💬 [SeatProvider] Extracted message data from nested 'data' field");
      }
      
      print(
        "💬 [SeatProvider] Message: ${messageData['message'] ?? messageData['message_text']}",
      );
      print("💬 [SeatProvider] User ID: ${messageData['user_id']}");
      print(
        "💬 [SeatProvider] Username: ${messageData['username'] ?? messageData['user_name']}",
      );
      print("💬 [SeatProvider] Profile URL: ${messageData['profile_url']}");
      print("💬 [SeatProvider] Callback set: ${onMessageReceived != null}");
      if (onMessageReceived != null) {
        onMessageReceived!(messageData); // ✅ Pass extracted data
        print("✅ [SeatProvider] onMessageReceived callback executed");
      } else {
        print(
          "⚠️ [SeatProvider] onMessageReceived callback is NULL - message won't be processed",
        );
      }
      print("💬 [SeatProvider] ========================================");
    });
    
    // ✅ CHAT HISTORY EVENT
    _wsService.on('chat_history', (data) {
      print("📜 [SeatProvider] ===== CHAT HISTORY RECEIVED =====");
      print("📜 [SeatProvider] Chat history data: $data");
      
      // ✅ Extract messages array from data
      List<Map<String, dynamic>> messages = [];
      // data is already Map<String, dynamic> from callback signature
      if (data.containsKey('messages') && data['messages'] is List) {
        messages = (data['messages'] as List).map((msg) {
          if (msg is Map) {
            return Map<String, dynamic>.from(msg);
          } else {
            return Map<String, dynamic>.from(msg as Map);
          }
        }).toList();
      } else if (data.containsKey('data') && data['data'] is Map) {
        final eventData = data['data'] as Map<String, dynamic>;
        if (eventData.containsKey('messages') &&
            eventData['messages'] is List) {
          messages = (eventData['messages'] as List).map((msg) {
            if (msg is Map) {
              return Map<String, dynamic>.from(msg);
            } else {
              return Map<String, dynamic>.from(msg as Map);
            }
          }).toList();
        }
      }
      
      print(
        "📜 [SeatProvider] Extracted ${messages.length} messages from chat history",
      );
      if (messages.isNotEmpty) {
        print("📜 [SeatProvider] First message: ${messages.first}");
        print("📜 [SeatProvider] Last message: ${messages.last}");
      }
      
      // ✅ Call callback with messages
      if (onChatHistoryReceived != null) {
        onChatHistoryReceived!(messages);
        print(
          "✅ [SeatProvider] Chat history callback triggered with ${messages.length} messages",
        );
      } else {
        print(
          "⚠️ [SeatProvider] onChatHistoryReceived callback is NULL - chat history won't be processed",
        );
      }
      print("📜 [SeatProvider] =====================================");
    });

    // ✅ ALL ROOM MESSAGES EVENT (from get_all_room_messages action)
    _wsService.on('all_room_messages', (data) {
      print("📜 [SeatProvider] ===== ALL ROOM MESSAGES RECEIVED =====");
      print("📜 [SeatProvider] All room messages data: $data");
      
      // ✅ Extract messages array from data
      List<Map<String, dynamic>> messages = [];
      if (data.containsKey('messages') && data['messages'] is List) {
        messages = (data['messages'] as List).map((msg) {
          if (msg is Map) {
            return Map<String, dynamic>.from(msg);
          } else {
            return Map<String, dynamic>.from(msg as Map);
          }
        }).toList();
      } else if (data.containsKey('data') && data['data'] is Map) {
        final eventData = data['data'] as Map<String, dynamic>;
        if (eventData.containsKey('messages') &&
            eventData['messages'] is List) {
          messages = (eventData['messages'] as List).map((msg) {
            if (msg is Map) {
              return Map<String, dynamic>.from(msg);
            } else {
              return Map<String, dynamic>.from(msg as Map);
            }
          }).toList();
        }
      }
      
      print(
        "📜 [SeatProvider] Extracted ${messages.length} messages from all room messages",
      );
      if (messages.isNotEmpty) {
        print("📜 [SeatProvider] First message: ${messages.first}");
        print("📜 [SeatProvider] Last message: ${messages.last}");
      }
      
      // ✅ Call callback with messages (reuse same callback as chat_history)
      if (onChatHistoryReceived != null) {
        onChatHistoryReceived!(messages);
        print(
          "✅ [SeatProvider] All room messages callback triggered with ${messages.length} messages",
        );
      } else {
        print(
          "⚠️ [SeatProvider] onChatHistoryReceived callback is NULL - all room messages won't be processed",
        );
      }
      print("📜 [SeatProvider] =====================================");
    });

    // ✅ ALL SEATS INFO EVENT (from get_all_seats_info action)
    // ✅ This is the response from get_all_seats_info action - queries database directly
    _wsService.on('all_seats_info', (data) {
      print("🪑 [SeatProvider] ===== ALL SEATS INFO RECEIVED (DATABASE QUERY RESPONSE) =====");
      print("🪑 [SeatProvider] This is a direct database query response from backend");
      print("🪑 [SeatProvider] Event: all_seats_info");
      print("🪑 [SeatProvider] Data type: ${data.runtimeType}");
      
      // ✅ Mark that we received the response - set flag that response detection checks
      _allSeatsInfoReceived = true; // ✅ Set flag to indicate event was actually received
      print("✅ [SeatProvider] Marked _allSeatsInfoReceived = true (event received)");
      print("✅ [SeatProvider] Marked _waitingForSeats = false (response received)");
      
      // ✅ Extract seats array from data
      List<Map<String, dynamic>> seatsList = [];
      
      // ✅ Try multiple data structures
      final dataMap = data;
      final dataKeys = dataMap.keys.toList();
      print("🪑 [SeatProvider] Data keys: $dataKeys");
      print("🪑 [SeatProvider] Full data: $data");
      
      if (dataMap.containsKey('seats') && dataMap['seats'] is List) {
        print("🪑 [SeatProvider] Found 'seats' array at top level");
        seatsList = (dataMap['seats'] as List).whereType<Map>().map((seat) {
          return Map<String, dynamic>.from(seat);
      }).toList();
      } else if (dataMap.containsKey('data')) {
        final dataField = dataMap['data'];
        if (dataField is Map) {
          if (dataField.containsKey('seats') && dataField['seats'] is List) {
            print("🪑 [SeatProvider] Found 'seats' array in nested 'data' field");
            seatsList = (dataField['seats'] as List).whereType<Map>().map((seat) {
            return Map<String, dynamic>.from(seat);
            }).toList();
          }
        } else if (dataField is List) {
          print("🪑 [SeatProvider] Found 'data' as direct List");
          seatsList = dataField.whereType<Map>().map((seat) {
            return Map<String, dynamic>.from(seat);
        }).toList();
      }
    }
          
      print("🪑 [SeatProvider] Extracted ${seatsList.length} seats from all_seats_info response");
      
      // ✅ Process seats using existing handler
      if (seatsList.isNotEmpty) {
        print("🪑 [SeatProvider] Processing ${seatsList.length} seats from database query");
        print("🪑 [SeatProvider] This is ACTUAL DATA from database - NO FALLBACK");
        
        // Create a data structure that matches what _handleSeatsUpdate expects
        final seatsData = {
          'seats': seatsList,
          'data': {'seats': seatsList},
        };
        
        final seatsBefore = _seats.length;
        _handleSeatsUpdate(seatsData);
        final seatsAfter = _seats.length;
        
        print("✅ [SeatProvider] All seats info processed and seats updated");
        print("✅ [SeatProvider] Seats before: $seatsBefore, Seats after: $seatsAfter");
        print("✅ [SeatProvider] Occupied seats: ${_seats.where((s) => s.isOccupied).length}");
        print("✅ [SeatProvider] Empty seats: ${_seats.where((s) => !s.isOccupied).length}");
      } else {
        print("⚠️ [SeatProvider] No seats found in all_seats_info response");
        print("⚠️ [SeatProvider] This might indicate:");
        print("   - Room has no seats initialized");
        print("   - Backend returned empty array");
        print("   - Data structure mismatch");
      }
      print("🪑 [SeatProvider] =====================================");
    });
    
    // ✅ ERROR EVENTS
    _wsService.on('error', (data) {
      // ✅ Safely get message and action (handle int types)
      String errorMessage = 'Unknown error';
      if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }
      String? action;
      if (data['action'] != null) {
        action = data['action'].toString();
      }
      
      print("❌ [SeatProvider] ===== WEBSOCKET ERROR EVENT RECEIVED =====");
      print("❌ [SeatProvider] Error Message: $errorMessage");
      print("❌ [SeatProvider] Error Action: $action");
      print("❌ [SeatProvider] Error Data: $data");
      
      // ✅ Check if error is for get_gifts action
      if (action == 'get_gifts' ||
          errorMessage.toLowerCase().contains('get_gifts') ||
          errorMessage.toLowerCase().contains('gift')) {
        print("❌ [SeatProvider] Error is related to get_gifts action");
        print(
          "❌ [SeatProvider] Server may not support get_gifts via WebSocket",
        );
        if (onGiftsReceived != null) {
          // Trigger callback with error so GiftProvider can handle it
          onGiftsReceived!({
            'error': true,
            'message': errorMessage,
            'gifts': [],
          });
          print(
            "✅ [SeatProvider] onGiftsReceived callback executed with error",
          );
        }
      }
      
      print("❌ [SeatProvider] Setting _errorMessage to: $errorMessage");
      _errorMessage = errorMessage;
      _isLoading = false;
      print("❌ [SeatProvider] _errorMessage after setting: $_errorMessage");
      notifyListeners();
      print("❌ [SeatProvider] ==========================================");
    });
    
    // ✅ SUCCESS EVENTS (for seat operations and gifts)
    // ✅ SUCCESS EVENTS (including chat history in success responses)
    _wsService.on('success', (data) {
        // ✅ Safely get message (handle int types)
        String message = '';
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      final successData = data['data'] as Map<String, dynamic>? ?? {};
      
      // ✅ Mark user as registered when seat occupation is confirmed
      if (message.toLowerCase().contains('seat occupied') || 
          message.toLowerCase().contains('seat occupied successfully')) {
        final userId =
            successData['user_id']?.toString() ?? data['user_id']?.toString();
        final currentUserId = _wsService.currentUserId;
        
        if (userId != null && userId == currentUserId) {
          _isCurrentUserRegisteredAsSeated = true;
          print(
            "✅ [SeatProvider] Current user (ID: $userId) confirmed as registered/seated by backend",
          );
        }
      }
      
      // ✅ Handle chat history in success event (backend sends it as success response)
      if (message.toLowerCase().contains('chat history') && 
          successData.containsKey('messages') && 
          successData['messages'] is List) {
        print("📜 [SeatProvider] ===== CHAT HISTORY IN SUCCESS EVENT =====");
        print("📜 [SeatProvider] Found chat history in success response");
        print("📜 [SeatProvider] Message: $message");
        print(
          "📜 [SeatProvider] Messages count: ${(successData['messages'] as List).length}",
        );
        
        // ✅ Extract messages and call chat history callback
        final messages = (successData['messages'] as List).map((msg) {
          if (msg is Map) {
            return Map<String, dynamic>.from(msg);
          } else {
            return Map<String, dynamic>.from(msg as Map);
          }
        }).toList();
        
        if (onChatHistoryReceived != null) {
          onChatHistoryReceived!(messages);
          print(
            "✅ [SeatProvider] Chat history callback triggered with ${messages.length} messages from success event",
          );
        } else {
          print(
            "⚠️ [SeatProvider] onChatHistoryReceived callback is NULL - chat history won't be processed",
          );
        }
        print("📜 [SeatProvider] ==========================================");
      }
      
      // ✅ Handle gifts response in success event
      if (successData.containsKey('gifts') || 
          successData.containsKey('data') && 
          (successData['data'] is List || 
                  (successData['data'] is Map &&
                      (successData['data'] as Map).containsKey('gifts')))) {
        print("🎁 [SeatProvider] ===== GIFTS IN SUCCESS EVENT =====");
        print("🎁 [SeatProvider] Found gifts in success event");
        if (onGiftsReceived != null) {
          onGiftsReceived!(successData);
          print(
            "✅ [SeatProvider] onGiftsReceived callback executed from success event",
          );
        }
        print("🎁 [SeatProvider] ==================================");
      }
      
      // ✅ Handle seat operation success
      if (message.toLowerCase().contains('seat')) {
        final seatNumber = successData['seat_number'] as int?;
        
        if (seatNumber != null && _wsService.currentRoomId != null) {
          print(
            "🔄 [SeatProvider] Seat operation successful, requesting updated seats...",
          );
          Future.delayed(Duration(milliseconds: 500), () {
            if (_wsService.currentRoomId != null) {
              getSeats(_wsService.currentRoomId!);
            }
          });
        }
      }
      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
    });
    
    // ✅ Listen for get_gifts action response (server might respond with same action name)
    _wsService.on('get_gifts', (data) {
      print("🎁 [SeatProvider] ===== GET_GIFTS ACTION RESPONSE =====");
      print("🎁 [SeatProvider] Event: get_gifts (action response)");
      print("🎁 [SeatProvider] Data keys: ${data.keys.toList()}");
      print("🎁 [SeatProvider] Callback set: ${onGiftsReceived != null}");
      if (onGiftsReceived != null) {
        onGiftsReceived!(data);
        print("✅ [SeatProvider] onGiftsReceived callback executed");
      } else {
        print(
          "⚠️ [SeatProvider] onGiftsReceived callback is NULL - gifts won't be processed",
        );
      }
      print("🎁 [SeatProvider] =====================================");
    });
    
    print("✅ [SeatProvider] WebSocket event listeners set up successfully");
  }

  // ✅ CRITICAL FIX: Set up connection listener to re-register listeners after reconnection
  // WebSocketService clears all callbacks on disconnect, so we must re-register on reconnect
  bool _connectionListenerSet = false;
  void _setupConnectionListener() {
    if (_connectionListenerSet) {
      print("ℹ️ [SeatProvider] Connection listener already set up");
      return;
    }

    print(
      "🔧 [SeatProvider] ===== SETTING UP CONNECTION STATUS LISTENER =====",
    );
    print(
      "🔧 [SeatProvider] This will re-register event listeners after reconnection",
    );

    // Listen for connection status changes using a periodic check
    // Note: WebSocketService uses ChangeNotifier, so we can listen to it
    _wsService.addListener(_onConnectionStatusChanged);
    _connectionListenerSet = true;

    print("✅ [SeatProvider] Connection status listener set up");
  }

  // ✅ Handle connection status changes
  void _onConnectionStatusChanged() {
    final isConnected = _wsService.isConnected;
    final currentRoomId = _wsService.currentRoomId;

    print("🔄 [SeatProvider] ===== CONNECTION STATUS CHANGED =====");
    print("🔄 [SeatProvider] Connected: $isConnected");
    print("🔄 [SeatProvider] Current Room: $currentRoomId");

    // If reconnected and we have a room, re-register listeners and re-request seats
    if (isConnected && currentRoomId != null) {
      print(
        "✅ [SeatProvider] Connection re-established - re-registering listeners",
      );

      // Re-register all event listeners (they were cleared on disconnect)
      _setupEventListeners();

      // Re-request seats after a short delay to ensure connection is stable
      Future.delayed(Duration(milliseconds: 500), () {
        if (_wsService.isConnected &&
            _wsService.currentRoomId == currentRoomId) {
          print("🔄 [SeatProvider] Re-requesting seats after reconnection");
          getSeats(currentRoomId);
        }
      });
    }
  }

  // ✅ Join room
  Future<bool> joinRoom(String roomId, String userId) async {
    try {
      print("🎯 [SeatProvider] ===== JOINING ROOM =====");
      print("🎯 [SeatProvider] Room ID: $roomId (Type: ${roomId.runtimeType})");
      print("🎯 [SeatProvider] User ID: $userId (Type: ${userId.runtimeType})");
      print("🎯 [SeatProvider] Connection Status: ${_wsService.isConnected}");

      if (!_wsService.isConnected) {
        print(
          "⚠️ [SeatProvider] Not connected. Connecting first with room_id and user_id...",
        );
        final connected = await connect(roomId: roomId, userId: userId);
        if (!connected) {
          print("❌ [SeatProvider] Failed to connect");
          return false;
        }
      }

      // ✅ Update room info in WebSocket service
      _wsService.updateRoomInfo(roomId, userId);

      // ✅ Reset flags when joining a new room
      _hasAutoOccupiedSeat = false;
      _isInitialSeatsLoad = true;
      _isCurrentUserRegisteredAsSeated = false;

      // ✅ Try to send explicit join_room action to ensure backend tracks the user
      // Backend logs show "Broadcasted message to 0 users" - this suggests user tracking is broken
      // Sending join_room action might help the backend properly register the user in the room
      print(
        "📤 [SeatProvider] Attempting to send join_room action to backend...",
      );
      print(
        "📤 [SeatProvider] This ensures backend properly tracks user in room for message broadcasting",
      );
      
      // Convert user_id to integer for backend (backend expects integer user_id)
      final userIdInt =
          int.tryParse(userId.replaceAll(RegExp(r'^0+'), '')) ??
          int.tryParse(userId) ??
          0;
      final roomIdInt = int.tryParse(roomId) ?? 0;
      
      if (userIdInt > 0 && roomIdInt > 0) {
        final joinSent = _wsService.sendAction('join_room', {
          'room_id': roomIdInt,
          'user_id': userIdInt,
        });
        
        if (joinSent) {
          print("✅ [SeatProvider] join_room action sent successfully");
          print(
            "✅ [SeatProvider] Backend should now track this user in room $roomId",
          );
        } else {
          print(
            "⚠️ [SeatProvider] Failed to send join_room action (connection might not be ready)",
          );
          print(
            "⚠️ [SeatProvider] Backend should still track user from connection URL parameters",
          );
        }
      } else {
        print(
          "⚠️ [SeatProvider] Could not parse user_id or room_id to integer",
        );
        print(
          "⚠️ [SeatProvider] User ID: $userId -> $userIdInt, Room ID: $roomId -> $roomIdInt",
        );
      }
      
      print(
        "✅ [SeatProvider] Room join info stored (room_id=$roomId, user_id=$userId)",
      );
      print(
        "✅ [SeatProvider] Current user ID stored: ${_wsService.currentUserId}",
      );
      print(
        "✅ [SeatProvider] Current room ID stored: ${_wsService.currentRoomId}",
      );
      print("✅ [SeatProvider] ==========================");
      print(
        "⚠️ [SeatProvider] IMPORTANT: If messages aren't broadcasting to other users,",
      );
      print(
        "⚠️ [SeatProvider] check backend logs - backend shows 'Broadcasted to 0 users'",
      );
      print("⚠️ [SeatProvider] This indicates backend user tracking is broken");
      return true;
    } catch (e) {
      print("❌ Join Room Error: $e");
      print("❌ Stack Trace: ${StackTrace.current}");
      _errorMessage = 'Failed to join room: $e';
      notifyListeners();
      return false;
    }
  }

  bool _allSeatsInfoReceived = false; // ✅ Flag set only when all_seats_info event is actually received
  DateTime? _lastGetSeatsRequest;
  static const Duration _getSeatsDebounceDuration = Duration(seconds: 2);
  /// When backend doesn't send all_seats_info, show this many empty seats so the layout is visible
  static const int kDefaultFallbackSeatCount = 20;

  void _applyEmptySeatsFallback() {
    _seats = List.generate(
      kDefaultFallbackSeatCount,
      (i) => Seat(seatNumber: i + 1, isOccupied: false, isReserved: false),
    );
    _totalSeats = _seats.length;
    _occupiedSeats = 0;
    _availableSeats = _seats.length;
    _errorMessage = ''; // Clear so "No Seats Available" doesn't show
    print("✅ [SeatProvider] Fallback applied: ${_seats.length} empty seats (backend did not send all_seats_info)");
  }
  
 
  Future<bool> getSeats(String roomId, {int maxRetries = 3}) async {
    final now = DateTime.now();
    if (_lastGetSeatsRequest != null && 
        now.difference(_lastGetSeatsRequest!) < _getSeatsDebounceDuration) {
      print("⏭️ [SeatProvider] Skipping get_all_seats_info request - too soon after last request (debounced)");
      return true; // Return true to avoid showing errors
    }
    _lastGetSeatsRequest = now;
    
    try {
      print("🚀 [SeatProvider] ===== REQUESTING ALL SEATS INFO (with retry logic) =====");
      print("🚀 [SeatProvider] Action: get_all_seats_info");
      print("🚀 [SeatProvider] Room ID: $roomId");
      print("🚀 [SeatProvider] Max Retries: $maxRetries");
      print("🚀 [SeatProvider] Connection Status: ${_wsService.isConnected}");
      print("🚀 [SeatProvider] This action queries database directly for all seats data");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      final roomIdInt = int.tryParse(roomId) ?? 0;
      
      if (roomIdInt == 0) {
        print(
          "❌ [SeatProvider] ERROR: Invalid room_id - cannot convert to integer: $roomId",
        );
        _errorMessage = 'Invalid room ID';
        notifyListeners();
        return false;
      }
      
      print(
        "✅ [SeatProvider] Converted room_id to integer: $roomId -> $roomIdInt",
      );
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        print("🔄 [SeatProvider] Attempt $attempt of $maxRetries");
      
      if (!_wsService.isConnected) {
        print("⚠️ [SeatProvider] Connection lost, waiting for reconnection...");
        await Future.delayed(Duration(milliseconds: 500));
        if (!_wsService.isConnected) {
          print("❌ [SeatProvider] Still not connected after wait");
            if (attempt < maxRetries) {
              await Future.delayed(Duration(milliseconds: 1000 * attempt));
              continue;
            }
          _errorMessage = 'WebSocket not connected. Please wait...';
          notifyListeners();
          return false;
        }
      }
      
         final payload = {
        'room_id': roomIdInt,
        };

        print("📤 [SeatProvider] ===== SENDING get_all_seats_info REQUEST (Attempt $attempt) =====");
        print("📤 [SeatProvider] Action: get_all_seats_info");
        print("📤 [SeatProvider] Payload: $payload");
        print("📤 [SeatProvider] This queries database directly for all seats in room $roomIdInt");

         _allSeatsInfoReceived = false; 
        final seatsCountBefore = _seats.length;
        print("📊 [SeatProvider] Current seats count before request: $seatsCountBefore");

        // ✅ Send request
        final sent = _wsService.sendAction('get_all_seats_info', payload);

        if (!sent) {
          print("❌ [SeatProvider] Failed to send get_all_seats_info request (Attempt $attempt)");
          _allSeatsInfoReceived = false;
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 1000 * attempt));
            continue;
          }
          _errorMessage = 'Failed to send request to backend';
          notifyListeners();
          return false;
        }

        print("✅ [SeatProvider] get_all_seats_info action sent via WebSocket (Attempt $attempt)");
        print("✅ [SeatProvider] Expected server response event: all_seats_info");
        print("✅ [SeatProvider] Backend will query database and respond with all seats data");
        print("✅ [SeatProvider] Response will include user info for occupied seats");
        
        bool responseReceived = false;
        for (int i = 0; i < 10; i++) {
          await Future.delayed(Duration(milliseconds: 500));
          
           if (_allSeatsInfoReceived) {
            responseReceived = true;
            print("✅ [SeatProvider] all_seats_info event received! Seats updated.");
            print("✅ [SeatProvider] New seats count: ${_seats.length}");
            break;
          }
          
          if (!_wsService.isConnected) {
            print("⚠️ [SeatProvider] Connection lost while waiting for response");
            break;
          }
        }
        
        if (responseReceived) {
          _allSeatsInfoReceived = false; 
          print("✅ [SeatProvider] Successfully received seats from database (Attempt $attempt)");
          print("✅ [SeatProvider] Total seats loaded: ${_seats.length}");
          print("✅ [SeatProvider] Occupied seats: ${_seats.where((s) => s.isOccupied).length}");
        return true;
        }

        print("⏳ [SeatProvider] No response received (Attempt $attempt)");
        print("⏳ [SeatProvider] Backend did not send all_seats_info event");
        _allSeatsInfoReceived = false;

        if (attempt == maxRetries) {
          print("❌ [SeatProvider] All retries exhausted - backend did not respond");
          print("✅ [SeatProvider] Using fallback: showing $kDefaultFallbackSeatCount empty seats so layout is visible");
          _applyEmptySeatsFallback();
          notifyListeners();
          return true;
        }

        if (attempt < maxRetries) {
          final delayMs = 1000 * attempt;
          print("⏳ [SeatProvider] Waiting ${delayMs}ms before retry...");
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      return false;
    } catch (e) {
      print("❌ Get Seats Error: $e");
      print("❌ Stack Trace: ${StackTrace.current}");
      _errorMessage = 'Failed to get seats: $e';
      notifyListeners();
      return false;
    }
  }
  Future<bool> getGifts({
    String? coinType,
    bool isActive = true,
    int? limit,
  }) async {
    try {
      print("🎁 [SeatProvider] ===== REQUESTING GIFTS =====");
      print("🎁 [SeatProvider] Connection Status: ${_wsService.isConnected}");
      print("🎁 [SeatProvider] Coin Type: $coinType");
      print("🎁 [SeatProvider] Is Active: $isActive");
      print("🎁 [SeatProvider] Limit: $limit");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "get_gifts", "coin_type": "gold", "is_active": 1, "limit": 200}
      final giftData = <String, dynamic>{'is_active': isActive ? 1 : 0};
      
      if (coinType != null && coinType.isNotEmpty) {
        giftData['coin_type'] = coinType.toLowerCase();
      }
      
      if (limit != null && limit > 0) {
        giftData['limit'] = limit;
      } else {
        giftData['limit'] = 200; // Default limit
      }
      
      print("📤 [SeatProvider] Sending get_gifts request in action format");
      final sent = _wsService.sendAction('get_gifts', giftData);

      if (sent) {
        print("✅ [SeatProvider] Get gifts event sent via WebSocket");
        print(
          "✅ [SeatProvider] Expected server response: gifts:list or gifts:update event with gifts array",
        );
        print("✅ [SeatProvider] ================================");
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send get_gifts request");
        return false;
      }
    } catch (e) {
      print("❌ Get Gifts Error: $e");
      print("❌ Stack Trace: ${StackTrace.current}");
      _errorMessage = 'Failed to get gifts: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> initializeSeats(String roomId) async {
    print("🚀 Initializing seats for room: $roomId");
    return true;
  }

  Future<bool> occupySeat({
    required String roomId,
    required String userId,
    required int seatNumber,
    String? username,
    String? profileUrl,
  }) async {
    try {
      print("🎯 Occupying seat $seatNumber for user $userId in room $roomId");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      final normalizedUserId = userId.replaceFirst(RegExp(r'^0+'), '');
      
      Seat? existingSeat;
      try {
        existingSeat = _seats.firstWhere(
          (s) {
            if (!s.isOccupied || s.userId == null) return false;
            final normalizedSeatUserId = s.userId!.replaceFirst(RegExp(r'^0+'), '');
            return normalizedSeatUserId == normalizedUserId;
          },
        );
      } catch (e) {
         existingSeat = null;
      }
      
        if (existingSeat == null) {
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          existingSeat = _seats.firstWhere(
            (s) {
              if (!s.isOccupied || s.userId == null) return false;
              final normalizedSeatUserId = s.userId!.replaceFirst(RegExp(r'^0+'), '');
              return normalizedSeatUserId == normalizedUserId;
            },
          );
        } catch (e) {
          existingSeat = null;
        }
      }
      
      if (existingSeat != null && existingSeat.seatNumber != seatNumber) {
        _errorMessage = 'You are already on seat ${existingSeat.seatNumber}. Please leave your current seat first.';
        print("❌ [SeatProvider] User is already on seat ${existingSeat.seatNumber}, cannot occupy seat $seatNumber");
        notifyListeners();
        return false;
      }
      
      if (existingSeat != null && existingSeat.seatNumber == seatNumber) {
        print("ℹ️ [SeatProvider] User is already on seat $seatNumber - no action needed");
        return true;
      }

      final roomIdInt = int.tryParse(roomId) ?? 0;
      final userIdInt = int.tryParse(userId) ?? 0;
      
      if (roomIdInt == 0 || userIdInt == 0) {
        print("❌ [SeatProvider] ERROR: Invalid IDs for occupy_seat");
        return false;
      }
      
      final sent = _wsService.sendAction('occupy_seat', {
        'room_id': roomIdInt,
        'user_id': userIdInt,
        'seat_number': seatNumber,
      });

      if (sent) {
        print("✅ [SeatProvider] Occupy seat action sent via WebSocket");
        print(
          "✅ [SeatProvider] Sent data: room_id=$roomIdInt, user_id=$userIdInt, seat_number=$seatNumber",
        );
        print(
          "✅ [SeatProvider] Expected server response: seat_occupied action or seat_update action",
        );
        print("✅ [SeatProvider] Waiting for backend response...");
        print(
          "✅ [SeatProvider] Will listen for: seat_occupied, seat:occupied, seat_update, seats:update",
        );
        print("✅ [SeatProvider] NO LOCAL FALLBACK - waiting for backend WebSocket response only");
        
      return true;
      } else {
        print("❌ [SeatProvider] Failed to send occupy_seat request");
        return false;
      }
    } catch (e) {
      print("❌ Occupy Seat Error: $e");
      _errorMessage = 'Failed to occupy seat: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ REMOVED: _updateSeatLocally method
  // ✅ All seat updates now come from WebSocket API responses only
  // ✅ No local fallbacks - backend handles all seat state management

  // ✅ Vacate seat
  Future<bool> vacateSeat({
    required String roomId,
    required String userId,
  }) async {
    try {
      print("🎯 Vacating seat for user $userId in room $roomId");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "vacate_seat", "room_id": 180, "user_id": 718}
      final roomIdInt = int.tryParse(roomId) ?? 0;
      final userIdInt = int.tryParse(userId) ?? 0;
      
      if (roomIdInt == 0 || userIdInt == 0) {
        print("❌ [SeatProvider] ERROR: Invalid IDs for vacate_seat");
        return false;
      }
      
      final sent = _wsService.sendAction('vacate_seat', {
        'room_id': roomIdInt,
        'user_id': userIdInt,
      });

      if (sent) {
        print("✅ [SeatProvider] Vacate seat action sent via WebSocket");
        print(
          "✅ [SeatProvider] Expected server response: seat_vacated action or seat_update action",
        );
      return true;
      } else {
        print("❌ [SeatProvider] Failed to send vacate_seat request");
        return false;
      }
    } catch (e) {
      print("❌ Vacate Seat Error: $e");
      _errorMessage = 'Failed to vacate seat: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Get chat history from backend
  Future<bool> getChatHistory({required String roomId, int limit = 50}) async {
    try {
      print("📜 [SeatProvider] ===== REQUESTING CHAT HISTORY =====");
      print("📜 [SeatProvider] Room ID: $roomId");
      print("📜 [SeatProvider] Limit: $limit");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "get_chat_history", "room_id": 64, "limit": 50}
      final roomIdInt = int.tryParse(roomId) ?? 0;
      
      if (roomIdInt == 0) {
        print("❌ [SeatProvider] ERROR: Invalid room ID for get_chat_history");
        return false;
      }
      
      print("📤 [SeatProvider] Sending get_chat_history request:");
      print("📤   - Action: get_chat_history");
      print("📤   - Room ID: $roomIdInt");
      print("📤   - Limit: $limit");
      
      final sent = _wsService.sendAction('get_chat_history', {
        'room_id': roomIdInt,
        'limit': limit,
      });

      if (sent) {
        print("✅ [SeatProvider] Chat history request sent via WebSocket");
        print(
          "✅ [SeatProvider] Expected server response: chat_history event with messages array",
        );
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send get_chat_history request");
        return false;
      }
    } catch (e) {
      print("❌ [SeatProvider] Get Chat History Error: $e");
      _errorMessage = 'Failed to get chat history: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Get all room messages from database (direct query, not from memory)
  Future<bool> getAllRoomMessages({required String roomId, int limit = 100}) async {
    try {
      print("📜 [SeatProvider] ===== REQUESTING ALL ROOM MESSAGES =====");
      print("📜 [SeatProvider] Room ID: $roomId");
      print("📜 [SeatProvider] Limit: $limit");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "get_all_room_messages", "room_id": 53, "limit": 100}
      final roomIdInt = int.tryParse(roomId) ?? 0;
      
      if (roomIdInt == 0) {
        print("❌ [SeatProvider] ERROR: Invalid room ID for get_all_room_messages");
        return false;
      }
      
      print("📤 [SeatProvider] Sending get_all_room_messages request:");
      print("📤   - Action: get_all_room_messages");
      print("📤   - Room ID: $roomIdInt");
      print("📤   - Limit: $limit");
      
      final sent = _wsService.sendAction('get_all_room_messages', {
        'room_id': roomIdInt,
        'limit': limit,
      });

      if (sent) {
        print("✅ [SeatProvider] Get all room messages request sent via WebSocket");
        print(
          "✅ [SeatProvider] Expected server response: all_room_messages event with messages array",
        );
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send get_all_room_messages request");
        return false;
      }
    } catch (e) {
      print("❌ [SeatProvider] Get All Room Messages Error: $e");
      _errorMessage = 'Failed to get all room messages: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Get all seats info from database (direct query, not from memory)
  Future<bool> getAllSeatsInfo({required String roomId}) async {
    try {
      print("🪑 [SeatProvider] ===== REQUESTING ALL SEATS INFO =====");
      print("🪑 [SeatProvider] Room ID: $roomId");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "get_all_seats_info", "room_id": 53}
      final roomIdInt = int.tryParse(roomId) ?? 0;
      
      if (roomIdInt == 0) {
        print("❌ [SeatProvider] ERROR: Invalid room ID for get_all_seats_info");
        return false;
      }
      
      print("📤 [SeatProvider] Sending get_all_seats_info request:");
      print("📤   - Action: get_all_seats_info");
      print("📤   - Room ID: $roomIdInt");
      
      final sent = _wsService.sendAction('get_all_seats_info', {
        'room_id': roomIdInt,
      });

      if (sent) {
        print("✅ [SeatProvider] Get all seats info request sent via WebSocket");
        print(
          "✅ [SeatProvider] Expected server response: all_seats_info event with seats array",
        );
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send get_all_seats_info request");
        return false;
      }
    } catch (e) {
      print("❌ [SeatProvider] Get All Seats Info Error: $e");
      _errorMessage = 'Failed to get all seats info: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Send room message via WebSocket (broadcast to all users in room)
  Future<bool> sendMessage({
    required String roomId,
    required String userId,
    required String message,
  }) async {
    try {
      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "send_message", "room_id": 173, "user_id": 718, "message": "hello"}
      final roomIdInt = int.tryParse(roomId) ?? 0;
      final userIdInt = int.tryParse(userId) ?? 0;
      
      if (roomIdInt == 0 || userIdInt == 0) {
        print("❌ [SeatProvider] Invalid IDs for send_message");
        return false;
      }
      
      final sent = _wsService.sendAction('send_message', {
        'room_id': roomIdInt,
        'user_id': userIdInt,
        'message': message,
      });

      if (sent) {
        print("✅ [SeatProvider] Message sent via WebSocket");
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send message");
        return false;
      }
    } catch (e) {
      print("❌ Send Message Error: $e");
      _errorMessage = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Send mic status change via WebSocket (broadcast to all users)
  Future<bool> sendMicStatus({
    required String roomId,
    required String userId,
    required bool isMuted,
    int? seatNumber,
  }) async {
    try {
      print("🎤 [SeatProvider] Sending mic status via WebSocket:");
      print("   - Room ID: $roomId");
      print("   - User ID: $userId");
      print("   - Is Muted: $isMuted");
      print("   - Seat Number: $seatNumber");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "mic:on" or "mic:off", "room_id": 173, "user_id": 718, "seat_number": 17}
      final roomIdInt = int.tryParse(roomId) ?? 0;
      final userIdInt = int.tryParse(userId) ?? 0;
      
      if (roomIdInt == 0 || userIdInt == 0) {
        print("❌ [SeatProvider] ERROR: Invalid IDs for mic status");
        return false;
      }
      
      final action = isMuted ? 'mic:off' : 'mic:on';
      final micData = <String, dynamic>{
        'room_id': roomIdInt,
        'user_id': userIdInt,
        'is_muted': isMuted ? 1 : 0,
      };
      
      if (seatNumber != null) {
        micData['seat_number'] = seatNumber;
      }
      
      final sent = _wsService.sendAction(action, micData);

      if (sent) {
        print("✅ [SeatProvider] Mic status action sent via WebSocket: $action");
        print(
          "✅ [SeatProvider] Expected server response: mic:on/mic:off event broadcast to all users",
        );
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send mic status request");
        return false;
      }
    } catch (e) {
      print("❌ [SeatProvider] Send Mic Status Error: $e");
      _errorMessage = 'Failed to send mic status: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Send gift via WebSocket
  Future<bool> sendGift({
    required String roomId,
    required int senderId,
    required int receiverId,
    required int giftId,
    required double giftValue,
    int? seatNumber,
  }) async {
    try {
      print("🎁 Sending gift via WebSocket:");
      print("   - Room ID: $roomId");
      print("   - Sender ID: $senderId");
      print("   - Receiver ID: $receiverId");
      print("   - Gift ID: $giftId");
      print("   - Gift Value: $giftValue");
      print("   - Seat Number: $seatNumber");

      if (!_wsService.isConnected) {
        _errorMessage = 'Not connected to WebSocket';
        print("❌ [SeatProvider] Not connected to WebSocket");
        notifyListeners();
        return false;
      }

      // ✅ SERVER EXPECTS: {"action": "gift:send", "receiver_id": 456, "gift_id": 6, "room_id": 55, "seat_number": 3}
      // Note: Server expects "gift:send" (colon format) not "send_gift" (underscore format)
      final roomIdInt = int.tryParse(roomId) ?? 0;
      
      if (roomIdInt == 0 || senderId == 0 || receiverId == 0 || giftId == 0) {
        print("❌ [SeatProvider] ERROR: Invalid IDs for gift:send");
        return false;
      }
      
      final giftData = <String, dynamic>{
        'receiver_id': receiverId,
        'gift_id': giftId,
        'room_id': roomIdInt,
        'sender_id': senderId,
        'gift_value': giftValue,
      };
      
      if (seatNumber != null) {
        giftData['seat_number'] = seatNumber;
      }
      
      final sent = _wsService.sendAction('gift:send', giftData);

      if (sent) {
        print("✅ [SeatProvider] Send gift action sent via WebSocket");
        print(
          "✅ [SeatProvider] Expected server response: gift:received or gift_sent event",
        );
        return true;
      } else {
        print("❌ [SeatProvider] Failed to send gift:send request");
        return false;
      }
    } catch (e) {
      print("❌ Send Gift Error: $e");
      _errorMessage = 'Failed to send gift: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ Simple join method (wrapper)
  Future<bool> joinSeatSimple({
    required String roomId,
    required String userId,
    required int seatNumber,
  }) async {
    print("🎯 Joining seat $seatNumber for user $userId");

    try {
      final success = await occupySeat(
        roomId: roomId,
        userId: userId,
        seatNumber: seatNumber,
      );

      if (success) {
        print("✅ Seat join request sent successfully!");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Join error: $e");
      return false;
    }
  }

  // ✅ Handle seats:update event
  // Note: Room filtering is handled at WebSocketService level
  void _handleSeatsUpdate(Map<String, dynamic> data) {
    try {
      print("📊 ===== HANDLING SEATS UPDATE EVENT =====");
      print("📊 Event received at: ${DateTime.now().toIso8601String()}");
      print("📊 Data keys: ${data.keys.toList()}");
      print("📊 Full data: $data");
      print("📊 Current room ID: ${_wsService.currentRoomId}");
      print("📊 Current user ID: ${_wsService.currentUserId}");
      
      // ✅ Clear waiting flag - we received a response!
      print("✅ [SeatProvider] Received seats response - cleared waiting flag");

      // ✅ FIX: Handle nested data structures
      // Server might send: {seats: [...]} or {data: {seats: [...]}}
      List<dynamic>? seatsList;
      
      // Try direct seats array first
      if (data['seats'] != null && data['seats'] is List) {
        seatsList = data['seats'] as List<dynamic>;
        print("📊 Found seats array at root level");
      } 
      // Try nested in data field
      else if (data['data'] != null && data['data'] is Map) {
        final dataMap = data['data'] as Map<String, dynamic>;
        if (dataMap['seats'] != null && dataMap['seats'] is List) {
          seatsList = dataMap['seats'] as List<dynamic>;
          print("📊 Found seats array in data.seats");
        }
      }
      
      seatsList ??= [];
      print("📊 Found ${seatsList.length} seats in data");
      
      // ✅ DEBUG: Log first seat data to see structure
      if (seatsList.isNotEmpty) {
        print("📊 ===== FIRST SEAT DATA STRUCTURE =====");
        final firstSeat = seatsList[0];
        if (firstSeat is Map<String, dynamic>) {
          print("📊 First seat keys: ${firstSeat.keys.toList()}");
          print("📊 First seat data: $firstSeat");
          print("📊   - user_id: ${firstSeat['user_id']}");
          print("📊   - username: ${firstSeat['username']}");
          print("📊   - user_name: ${firstSeat['user_name']}");
          print("📊   - profile_url: ${firstSeat['profile_url']}");
          print("📊   - is_occupied: ${firstSeat['is_occupied']}");
        }
        print("📊 =====================================");
      }
      
      if (seatsList.isEmpty) {
        print("⚠️ WARNING: seats array is empty!");
      }
      
      // ✅ Store old seats to detect new users joining (only if not initial load)
      // ✅ CRITICAL: Create a map of existing seats by seatNumber to preserve user data
      // This ensures that when backend sends incomplete data, we preserve existing user info
      final Map<int, Seat> existingSeatsMap = {};
      for (final seat in _seats) {
        existingSeatsMap[seat.seatNumber] = seat;
      }
      print("📊 Preserving ${existingSeatsMap.length} existing seats with user data");
      
      final oldSeats = List<Seat>.from(_seats);
      final oldOccupiedUserIds = oldSeats
          .where((s) => s.isOccupied && s.userId != null)
          .map((s) => s.userId!)
          .toSet();
      
      print("📊 Old occupied user IDs: $oldOccupiedUserIds");
      print("📊 Existing seats map size: ${existingSeatsMap.length}");
      
      // ✅ FIX: Parse seats - Backend now sends user data, normalize and filter
      // ✅ Filter out "User X" patterns from backend data
      // ✅ CRITICAL: Preserve existing user data if backend sends incomplete data
      _seats = seatsList.map((seatJson) {
        final seatJsonMap = seatJson as Map<String, dynamic>;
        final seat = Seat.fromJson(seatJsonMap);
        final seatNumber = seat.seatNumber;
        
        // ✅ Get existing seat data (if available) to preserve user info
        final existingSeat = existingSeatsMap[seatNumber];
        
        // ✅ FILTER OUT "User X" patterns from backend data
        String? filteredUsername = _filterUserXPattern(seat.username);
        String? filteredUserName = _filterUserXPattern(seat.userName);
        
        // ✅ If both are filtered out, try to preserve from existing seat
        if (filteredUsername == null && filteredUserName == null) {
          if (existingSeat != null && existingSeat.isOccupied) {
            // ✅ Preserve existing username if backend didn't send one
            filteredUsername = _filterUserXPattern(existingSeat.username);
            filteredUserName = _filterUserXPattern(existingSeat.userName);
            if (filteredUsername == null && filteredUserName == null) {
              filteredUsername = null;
              filteredUserName = null;
            }
          } else {
            filteredUsername = null;
            filteredUserName = null;
          }
        } else {
          // ✅ Use the non-filtered value
          filteredUsername ??= filteredUserName;
          filteredUserName ??= filteredUsername;
        }
        
        // ✅ Normalize profile URL (backend may send relative path)
        // ✅ NO FALLBACKS - only use backend data
        String? normalizedProfileUrl = _normalizeProfileUrl(seat.profileUrl);
        
        // ✅ CRITICAL: Preserve user data if existing seat was occupied
        // This prevents database sync delays from clearing seats that were just occupied
        // If database shows seat as empty but existing seat has user data, preserve it
        final finalIsOccupied = seat.isOccupied;
        String? finalUserId = seat.userId;
        
        // ✅ Check if existing seat has user data (was recently occupied)
        bool shouldPreserveUserData = false;
        if (!finalIsOccupied && existingSeat != null && existingSeat.isOccupied) {
          // Database shows empty, but existing seat has user data - preserve it
          // This handles cases where get_all_seats_info doesn't include user data
          // or database hasn't synced yet after seat:occupied event
          if (existingSeat.userId != null || 
              existingSeat.username != null || 
              existingSeat.profileUrl != null) {
            shouldPreserveUserData = true;
            print("📊 Preserving user data for seat $seatNumber (database shows empty but seat was recently occupied)");
          }
        }
        
        // ✅ Only clear user data if backend says empty AND we don't need to preserve
        if (!finalIsOccupied && !shouldPreserveUserData) {
          // Seat is empty - clear all user data
          filteredUsername = null;
          filteredUserName = null;
          normalizedProfileUrl = null;
        } else if (shouldPreserveUserData) {
          // Preserve user data from existing seat
          if (filteredUsername == null && filteredUserName == null) {
            filteredUsername = _filterUserXPattern(existingSeat!.username);
            filteredUserName = _filterUserXPattern(existingSeat.userName);
          }
          if (normalizedProfileUrl == null || normalizedProfileUrl.isEmpty) {
            normalizedProfileUrl = existingSeat!.profileUrl;
          }
          if (finalUserId == null || finalUserId.isEmpty) {
            finalUserId = existingSeat!.userId;
          }
        }
        
        // ✅ Get country from backend data (optional - don't require it)
        String? country = seatJsonMap['country']?.toString();
        
        // ✅ If no country from backend, preserve from existing seat
        if ((country == null || country.isEmpty) && existingSeat?.country != null && existingSeat!.country!.isNotEmpty) {
          country = existingSeat.country;
          print("📊 Preserved country for seat $seatNumber from existing seat: $country");
        }
        
        // ✅ Use preserved occupied state if we preserved user data
        final finalOccupiedState = shouldPreserveUserData ? true : finalIsOccupied;
        
        return Seat(
          seatNumber: seatNumber,
          isOccupied: finalOccupiedState, // ✅ Use preserved state if needed
          isReserved: seat.isReserved,
          userId: finalOccupiedState ? finalUserId : null, // ✅ Preserve userId if occupied
          username: finalOccupiedState ? filteredUsername : null, // ✅ Preserve username if occupied
          userName: finalOccupiedState ? filteredUserName : null, // ✅ Preserve userName if occupied
          profileUrl: finalOccupiedState ? normalizedProfileUrl : null, // ✅ Preserve profileUrl if occupied
          country: finalOccupiedState ? country : null, // ✅ Country is optional, preserved if available
        );
      }).toList();
      
      // ✅ DEBUG: Log parsed seats to verify user data for ALL users
      print("📊 ===== PARSED SEATS WITH USER DATA (ALL USERS) =====");
      int seatsWithUserData = 0;
      int seatsNeedingData = 0;
      for (final seat in _seats) {
        if (seat.isOccupied && seat.userId != null) {
          final hasUsername = (seat.username != null && seat.username!.isNotEmpty) || 
                              (seat.userName != null && seat.userName!.isNotEmpty);
          final hasProfile = seat.profileUrl != null && seat.profileUrl!.isNotEmpty;
          
          // ✅ Log ALL occupied seats (not just ones needing data)
          print("📊 Seat ${seat.seatNumber} (Occupied):");
          print("   - User ID: ${seat.userId}");
          print("   - Username: ${seat.username ?? seat.userName ?? 'NULL'}");
          print("   - Profile URL: ${seat.profileUrl ?? 'NULL'}");
          print("   - Has Username: $hasUsername");
          print("   - Has Profile: $hasProfile");
          
          if (hasUsername && hasProfile) {
            seatsWithUserData++;
            print("   ✅ Complete data");
          } else {
            seatsNeedingData++;
            print("   ⚠️ NEEDS DATA");
          }
        }
      }
      print("📊 Summary: $seatsWithUserData seats have complete data, $seatsNeedingData seats need data");
      print("📊 Total occupied seats: ${_seats.where((s) => s.isOccupied).length}");
      print("📊 ======================================");
      
      // ✅ Fetch missing user data from API for seats with user_id but no username/profile
      if (seatsNeedingData > 0) {
        print("🔄 [SeatProvider] Fetching missing user data for $seatsNeedingData seat(s)...");
        _fetchMissingUserData();
      } else {
        print("✅ [SeatProvider] All seats have complete user data - no fetch needed");
      }

      // ✅ REMOVED: Auto-detection of new users from seat occupation
      // ✅ This was causing users to appear on seats when they only joined the room
      // ✅ Backend sends user:joined events separately - we should only use those
      // ✅ Seats should only show users when backend explicitly marks them as occupied
        if (_isInitialSeatsLoad) {
          print("ℹ️ Initial seats load - skipping user joined detection");
          _isInitialSeatsLoad = false; // Mark that initial load is complete
        } else {
        print("ℹ️ Seat update received - using only backend data (no auto-detection)");
      }

      // Update stats
      _totalSeats = data['total_seats'] ?? _seats.length;
      _occupiedSeats = data['occupied_seats'] ?? 0;
      _availableSeats = data['available_seats'] ?? 0;

      print("✅ ${_seats.length} seats loaded");
      print(
        "📊 Stats - Total: $_totalSeats, Occupied: $_occupiedSeats, Available: $_availableSeats",
      );

      // ✅ AUTO-OCCUPY SEAT: If user is already on a seat but hasn't registered with backend
      if (_isInitialSeatsLoad &&
          !_hasAutoOccupiedSeat &&
          _wsService.isConnected) {
        final currentRoomId = _wsService.currentRoomId;
        
        if (currentRoomId != null) {
          // Get database user_id from SharedPreferences
          SharedPreferences.getInstance().then((prefs) async {
            // ✅ Safely get user_id (handles both int and String types)
            String? databaseUserId;
            try {
              int? userIdInt = prefs.getInt('user_id');
              if (userIdInt != null) {
                databaseUserId = userIdInt.toString();
              } else {
                databaseUserId = prefs.getString('user_id');
              }
            } catch (e) {
              // Fallback: try dynamic retrieval
              final dynamic userIdValue = prefs.get('user_id');
              if (userIdValue != null) {
                databaseUserId = userIdValue.toString();
              }
            }
            
            if (databaseUserId != null && databaseUserId.isNotEmpty) {
              // Find if current user (by database user_id) is on any seat
              final userSeat = _seats.firstWhere(
                (s) => s.isOccupied && s.userId == databaseUserId,
                orElse: () =>
                    Seat(seatNumber: 0, isOccupied: false, isReserved: false),
              );
              
              if (userSeat.seatNumber > 0 && userSeat.isOccupied) {
                print(
                  "🪑 [SeatProvider] ===== AUTO-OCCUPYING SEAT FOR CURRENT USER =====",
                );
                print(
                  "🪑 [SeatProvider] User (ID: $databaseUserId) is already on seat ${userSeat.seatNumber}",
                );
                print(
                  "🪑 [SeatProvider] Sending occupy_seat to register with backend...",
                );
                
                // Auto-send occupy_seat action to register user with backend
                final roomIdInt = int.tryParse(currentRoomId) ?? 0;
                final userIdInt = int.tryParse(databaseUserId) ?? 0;
                
                if (roomIdInt > 0 && userIdInt > 0) {
                  final sent = _wsService.sendAction('occupy_seat', {
                    'room_id': roomIdInt,
                    'user_id': userIdInt,
                    'seat_number': userSeat.seatNumber,
                  });
                  
                  if (sent) {
                    _hasAutoOccupiedSeat = true;
                    // Note: _isCurrentUserRegisteredAsSeated will be set to true when backend confirms via success event
                    print(
                      "✅ [SeatProvider] Auto-occupy_seat sent successfully",
                    );
                    print(
                      "✅ [SeatProvider] User $userIdInt registration request sent for seat ${userSeat.seatNumber} in room $roomIdInt",
                    );
                    print(
                      "⏳ [SeatProvider] Waiting for backend confirmation...",
                    );
                  } else {
                    print("❌ [SeatProvider] Failed to send auto-occupy_seat");
                  }
                } else {
                  print(
                    "❌ [SeatProvider] Invalid IDs for auto-occupy_seat: room_id=$roomIdInt, user_id=$userIdInt",
                  );
                }
                print(
                  "🪑 [SeatProvider] ==============================================",
                );
              } else {
                print(
                  "ℹ️ [SeatProvider] Current user (ID: $databaseUserId) is not on any seat - no auto-occupy needed",
                );
              }
            } else {
              print(
                "⚠️ [SeatProvider] Cannot auto-occupy: database user_id not found in SharedPreferences",
              );
            }
          });
        } else {
          print("⚠️ [SeatProvider] Cannot auto-occupy: currentRoomId is null");
        }
      }

      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      print("❌ Error handling seats:update: $e");
      _errorMessage = 'Failed to parse seats data: $e';
      notifyListeners();
    }
  }

  // ✅ Handle seat:occupied event
  // Note: Room filtering is handled at WebSocketService level
  void _handleSeatOccupied(Map<String, dynamic> data) {
    try {
      print("🪑 ===== HANDLING seat:occupied EVENT =====");
      print("🪑 Full event data: $data");
      print("🪑 Data keys: ${data.keys.toList()}");
      print("🪑 Current User ID from WebSocket: ${_wsService.currentUserId}");

      // ✅ CRITICAL: Backend sends nested structure: {event: 'seat:occupied', data: {...}}
      // Extract data from nested structure if present
      Map<String, dynamic> eventData = data;
      if (data['data'] != null && data['data'] is Map) {
        eventData = Map<String, dynamic>.from(data['data'] as Map);
        print("🪑 Extracted seat data from nested 'data' field");
        print("🪑 Extracted data keys: ${eventData.keys.toList()}");
      }

      final seatNumber = eventData['seat_number'] as int? ?? 
                         eventData['seat_id'] as int? ??
                         data['seat_number'] as int? ?? 
                         data['seat_id'] as int?;
      
      // ✅ Handle user_id in multiple formats (int, String, formatted, unformatted)
      dynamic userIdRaw = eventData['user_id'] ?? data['user_id'];
      String? userId;
      if (userIdRaw != null) {
        userId = userIdRaw.toString();
        // Remove leading zeros for comparison (100400 vs 00100400)
        userId = userId.replaceFirst(RegExp(r'^0+'), '');
      }

      // ✅ Normalize current user ID for comparison (remove leading zeros)
      String? normalizedCurrentUserId;
      if (_wsService.currentUserId != null &&
          _wsService.currentUserId!.isNotEmpty) {
        normalizedCurrentUserId = _wsService.currentUserId!.replaceFirst(
          RegExp(r'^0+'),
          '',
        );
      }
      
      print("🪑 Extracted - Seat Number: $seatNumber, User ID: $userId");
      print("🪑 Normalized User ID: $userId");
      print("🪑 Normalized Current User ID: $normalizedCurrentUserId");
      print(
        "🪑 Is Current User: ${userId != null && normalizedCurrentUserId != null && userId == normalizedCurrentUserId}",
      );

      if (seatNumber == null) {
        print("❌ seat:occupied event missing seat_number");
        print("❌ Available keys in eventData: ${eventData.keys.toList()}");
        print("❌ Available keys in data: ${data.keys.toList()}");
        return;
      }

      if (userId == null || userId.isEmpty) {
        print("⚠️ seat:occupied event missing user_id");
        print("⚠️ Will still update seat as occupied, but without user info");
      }

      // ✅ Get all user data fields from eventData (backend sends user data here)
      Map<String, dynamic> userData = eventData;
      if (eventData['user'] != null && eventData['user'] is Map) {
        userData = eventData['user'] as Map<String, dynamic>;
        print("🪑 Found nested user data in eventData.user");
      }
      
      // ✅ Get all user data fields (handle multiple possible field names)
      // ✅ FILTER OUT "User X" patterns - only use real usernames
      // ✅ Safely get username (handle int types) - check eventData first, then userData
      String? rawUsername;
      if (eventData['username'] != null) {
        rawUsername = eventData['username'].toString();
      } else if (eventData['user_name'] != null) {
        rawUsername = eventData['user_name'].toString();
      } else if (userData['username'] != null) {
        rawUsername = userData['username'].toString();
      } else if (userData['user_name'] != null) {
        rawUsername = userData['user_name'].toString();
      } else if (data['username'] != null) {
        rawUsername = data['username'].toString();
      } else if (data['user_name'] != null) {
        rawUsername = data['user_name'].toString();
      } else if (eventData['name'] != null) {
        rawUsername = eventData['name'].toString();
      } else if (userData['name'] != null) {
        rawUsername = userData['name'].toString();
      } else if (data['name'] != null) {
        rawUsername = data['name'].toString();
      }
      
      // ✅ Filter out "User X" patterns
      final username = _filterUserXPattern(rawUsername);
      
      // ✅ Safely get profileUrl (handle int types) - check eventData first, then userData
      String? profileUrl;
      if (eventData['profile_url'] != null) {
        profileUrl = eventData['profile_url'].toString();
      } else if (userData['profile_url'] != null) {
        profileUrl = userData['profile_url'].toString();
      } else if (data['profile_url'] != null) {
        profileUrl = data['profile_url'].toString();
      } else if (eventData['avatar'] != null) {
        profileUrl = eventData['avatar'].toString();
      } else if (userData['avatar'] != null) {
        profileUrl = userData['avatar'].toString();
      } else if (data['avatar'] != null) {
        profileUrl = data['avatar'].toString();
      } else if (eventData['avatar_url'] != null) {
        profileUrl = eventData['avatar_url'].toString();
      } else if (userData['avatar_url'] != null) {
        profileUrl = userData['avatar_url'].toString();
      } else if (data['avatar_url'] != null) {
        profileUrl = data['avatar_url'].toString();
      }
      
      final isReserved =
          (eventData['is_reserved'] == 1 ||
                         eventData['is_reserved'] == true ||
                         eventData['is_reserved'] == '1') ||
                        (data['is_reserved'] == 1 ||
                         data['is_reserved'] == true ||
                         data['is_reserved'] == '1') ||
                        (userData['is_reserved'] == 1 || 
                         userData['is_reserved'] == true ||
                         userData['is_reserved'] == '1');

      print("🪑 ===== EXTRACTED USER DATA =====");
      print("🪑 Username: $username");
      print("🪑 Profile URL: $profileUrl");
      print("🪑 User ID: $userId");
      print("🪑 Is Reserved: $isReserved");
      print("🪑 ===============================");

        // Update the specific seat
        final seatIndex = _seats.indexWhere((s) => s.seatNumber == seatNumber);
        if (seatIndex != -1) {
        // ✅ Seat exists - update it with all available data
        final oldSeat = _seats[seatIndex];
        print("🪑 Found existing seat at index $seatIndex");
        print(
          "🪑 Old seat state - Occupied: ${oldSeat.isOccupied}, User ID: ${oldSeat.userId}",
        );
        print(
          "🪑 Old seat - Username: ${oldSeat.username ?? oldSeat.userName}, Profile URL: ${oldSeat.profileUrl}",
        );
        
        // ✅ Backend now sends user data - normalize and filter
        // ✅ Filter out "User X" patterns from existing seat data too
        final oldSeatUsername = _filterUserXPattern(
          oldSeat.username ?? oldSeat.userName,
        );
        final finalUsername =
            username ?? oldSeatUsername; // Only use real usernames
        
        // ✅ Normalize profile URL (backend may send relative path)
        // ✅ CRITICAL: Use backend profile URL first, then fallback to existing seat data
        String? finalProfileUrl;
        if (profileUrl != null && profileUrl.isNotEmpty) {
          finalProfileUrl = _normalizeProfileUrl(profileUrl);
          print("🪑 Using profile URL from backend event: $finalProfileUrl");
        } else if (oldSeat.profileUrl != null && oldSeat.profileUrl!.isNotEmpty) {
          finalProfileUrl = oldSeat.profileUrl;
          print("🪑 Using existing profile URL from seat: $finalProfileUrl");
        } else {
          finalProfileUrl = null;
          print("⚠️ No profile URL available (neither from backend nor existing seat)");
        }
        
        print(
          "🪑 Final user data - Username: $finalUsername, Profile URL: $finalProfileUrl",
        );
        
        // ✅ Get country from multiple sources (backend event, existing seat, or SharedPreferences for current user)
        String? country = eventData['country'] as String? ?? 
                         userData['country'] as String? ?? 
                         data['country'] as String?;
        
        // ✅ If country not in event, try to preserve from existing seat
        if ((country == null || country.isEmpty) && oldSeat.country != null && oldSeat.country!.isNotEmpty) {
          country = oldSeat.country;
          print("🪑 Preserved country from existing seat: $country");
        }
        
        // ✅ If still no country and this is current user, try to get from SharedPreferences (async)
        if ((country == null || country.isEmpty) && userId != null) {
          try {
            final normalizedCurrentUserId = _wsService.currentUserId?.replaceFirst(RegExp(r'^0+'), '') ?? '';
            final normalizedEventUserId = userId.replaceFirst(RegExp(r'^0+'), '');
            if (normalizedEventUserId == normalizedCurrentUserId) {
              // This is current user - get country from SharedPreferences (async)
              SharedPreferences.getInstance().then((prefs) {
                final userIdValue = prefs.get('user_id');
                String? userIdKey;
                if (userIdValue is int) {
                  userIdKey = userIdValue.toString();
                } else if (userIdValue is String) {
                  userIdKey = userIdValue;
                }
                if (userIdKey != null) {
                  final countryFromPrefs = prefs.getString('country_$userIdKey');
                  if (countryFromPrefs != null && countryFromPrefs.isNotEmpty) {
                    // Update the seat with country from SharedPreferences
                    if (seatIndex < _seats.length) {
                      _seats[seatIndex] = Seat(
                        seatNumber: seatNumber,
                        isOccupied: true,
                        isReserved: isReserved,
                        userId: userId,
                        username: finalUsername,
                        userName: finalUsername,
                        profileUrl: finalProfileUrl,
                        country: countryFromPrefs,
                      );
                      print("🪑 Updated seat with country from SharedPreferences: $countryFromPrefs");
                      notifyListeners();
                    }
                  }
                }
              }).catchError((e) {
                print("⚠️ Error getting country from SharedPreferences: $e");
              });
            }
          } catch (e) {
            print("⚠️ Error getting country from SharedPreferences: $e");
          }
        }
        
        print("🪑 Final country: ${country ?? 'NULL'}");
        
          _seats[seatIndex] = Seat(
            seatNumber: seatNumber,
            isOccupied: true,
          isReserved: isReserved,
            userId: userId,
          username: finalUsername,
          userName: finalUsername, // Use same value for both fields
          profileUrl: finalProfileUrl, // ✅ CRITICAL: Save profile URL to seat
          country: country, // ✅ Save country for flag display
        );
        
        print("✅ Updated existing seat $seatNumber with user data");
        print("   - User ID: ${_seats[seatIndex].userId}");
        print(
          "   - Username: ${_seats[seatIndex].username ?? _seats[seatIndex].userName}",
        );
        print("   - Profile URL: ${_seats[seatIndex].profileUrl ?? 'NULL'}");
        print("   - Country: ${_seats[seatIndex].country ?? 'NULL'}");
        print("   - Is Occupied: ${_seats[seatIndex].isOccupied}");
        
        // ✅ CRITICAL: Notify listeners so UI updates with profile URL
        notifyListeners();
      } else {
        // Seat doesn't exist in list - add it
        print("⚠️ Seat $seatNumber not found in list, adding it");
        final finalUsername = username;
        final finalProfileUrl = profileUrl;
        
        // ✅ Get country from multiple sources (backend event or SharedPreferences for current user)
        String? country = eventData['country'] as String? ?? 
                         userData['country'] as String? ?? 
                         data['country'] as String?;
        
        // ✅ If no country and this is current user, try to get from SharedPreferences (async)
        if ((country == null || country.isEmpty) && userId != null) {
          try {
            final normalizedCurrentUserId = _wsService.currentUserId?.replaceFirst(RegExp(r'^0+'), '') ?? '';
            final normalizedEventUserId = userId.replaceFirst(RegExp(r'^0+'), '');
            if (normalizedEventUserId == normalizedCurrentUserId) {
              // This is current user - get country from SharedPreferences (async)
              SharedPreferences.getInstance().then((prefs) {
                final userIdValue = prefs.get('user_id');
                String? userIdKey;
                if (userIdValue is int) {
                  userIdKey = userIdValue.toString();
                } else if (userIdValue is String) {
                  userIdKey = userIdValue;
                }
                if (userIdKey != null) {
                  final countryFromPrefs = prefs.getString('country_$userIdKey');
                  if (countryFromPrefs != null && countryFromPrefs.isNotEmpty) {
                    // Find and update the seat with country
                    final seatIdx = _seats.indexWhere((s) => s.seatNumber == seatNumber && s.userId == userId);
                    if (seatIdx != -1) {
                      _seats[seatIdx] = Seat(
                        seatNumber: seatNumber,
                        isOccupied: true,
                        isReserved: isReserved,
                        userId: userId,
                        username: finalUsername,
                        userName: finalUsername,
                        profileUrl: finalProfileUrl,
                        country: countryFromPrefs,
                      );
                      print("🪑 Updated seat with country from SharedPreferences: $countryFromPrefs");
                      notifyListeners();
                    }
                  }
                }
              }).catchError((e) {
                print("⚠️ Error getting country from SharedPreferences: $e");
              });
            }
          } catch (e) {
            print("⚠️ Error getting country from SharedPreferences: $e");
          }
        }
        
        print("🪑 Final country: ${country ?? 'NULL'}");
        
        _seats.add(
          Seat(
          seatNumber: seatNumber,
          isOccupied: true,
          isReserved: isReserved,
          userId: userId,
          username: finalUsername,
          userName: finalUsername,
          profileUrl: finalProfileUrl,
          country: country, // ✅ Save country for flag display
          ),
        );
        // Sort seats by seat number
        _seats.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
        print("✅ Added new seat $seatNumber to list");
        print("   - User ID: $userId");
        print("   - Username: $finalUsername");
        print("   - Profile URL: $finalProfileUrl");
      }

          // Recalculate stats
          _occupiedSeats = _seats.where((s) => s.isOccupied).length;
          _availableSeats = _totalSeats - _occupiedSeats;

      print(
        "📊 Updated stats - Occupied: $_occupiedSeats, Available: $_availableSeats",
      );
      print("📊 Total seats in list: ${_seats.length}");
      
      // ✅ CRITICAL: Trigger user:joined callback if this is a new user (not current user)
      // ✅ Use normalized IDs for comparison
      final isCurrentUser =
          userId != null &&
                           normalizedCurrentUserId != null && 
                           userId == normalizedCurrentUserId;
      
      if (userId != null && userId.isNotEmpty && !isCurrentUser) {
        print("👤 ===== NEW USER OCCUPIED SEAT (seat_occupied event) =====");
        print(
          "👤 User ID: $userId (not current user: $normalizedCurrentUserId)",
        );
        
        // ✅ Get username from updated seat data (which has the final username after filtering)
        final updatedSeat = seatIndex != -1
            ? _seats[seatIndex]
            : _seats.firstWhere(
                             (s) => s.seatNumber == seatNumber && s.userId == userId,
                orElse: () =>
                    Seat(seatNumber: 0, isOccupied: false, isReserved: false),
                           );
        final finalUsername = updatedSeat.seatNumber > 0 
            ? (updatedSeat.username ?? updatedSeat.userName ?? username)
            : username;
        final finalProfileUrl = updatedSeat.seatNumber > 0 
            ? (updatedSeat.profileUrl ?? profileUrl)
            : profileUrl;
        
        print("👤 Username: $finalUsername");
        print("👤 Seat Number: $seatNumber");
        print("👤 Profile URL: $finalProfileUrl");
        print("👤 ======================================================");
        
        // ✅ Only trigger if we have a valid username (not "User X" pattern)
        if (finalUsername != null && finalUsername.isNotEmpty) {
          // ✅ Trigger onUserJoined callback if set
          if (onUserJoined != null) {
            onUserJoined!({
              'user_id': userId,
              'username': finalUsername,
              'user_name': finalUsername,
              'seat_number': seatNumber,
              'profile_url': finalProfileUrl,
              'room_id':
                  _wsService.currentRoomId, // ✅ Include room_id for filtering
            });
            print(
              "✅ onUserJoined callback triggered for user $userId with username: $finalUsername",
            );
          } else {
            print(
              "⚠️ onUserJoined callback is not set - chat message won't show",
            );
          }
        } else {
          print(
            "⚠️ Username is null or empty (filtered out 'User X' pattern) - skipping user:joined callback",
          );
        }
      } else {
        if (userId != null && userId.isNotEmpty) {
          // ✅ Check if this is the current user by comparing with database user_id
          SharedPreferences.getInstance().then((prefs) {
            // ✅ Safely get user_id (handles both int and String types)
            String? databaseUserId;
            try {
              int? userIdInt = prefs.getInt('user_id');
              if (userIdInt != null) {
                databaseUserId = userIdInt.toString();
              } else {
                databaseUserId = prefs.getString('user_id');
              }
            } catch (e) {
              // Fallback: try dynamic retrieval
              final dynamic userIdValue = prefs.get('user_id');
              if (userIdValue != null) {
                databaseUserId = userIdValue.toString();
              }
            }
            if (databaseUserId == userId) {
              print(
                "ℹ️ Current user (database ID: $databaseUserId) occupied seat - not triggering user:joined",
              );
              // ✅ Mark as registered when seat:occupied event is received for current user
              _isCurrentUserRegisteredAsSeated = true;
              print(
                "✅ [SeatProvider] Current user marked as registered/seated (from seat:occupied event)",
              );
              
              // ✅ Trigger onSeatOccupied callback for current user (for seat join messages)
              if (onSeatOccupied != null) {
                final seatIndex = _seats.indexWhere((s) => s.seatNumber == seatNumber);
                final updatedSeat = seatIndex != -1 ? _seats[seatIndex] : null;
                final finalUsername = updatedSeat != null 
                    ? (updatedSeat.username ?? updatedSeat.userName ?? username)
                    : username;
                final finalProfileUrl = updatedSeat != null 
                    ? (updatedSeat.profileUrl ?? profileUrl)
                    : profileUrl;
                
                onSeatOccupied!({
                  'user_id': userId,
                  'username': finalUsername,
                  'user_name': finalUsername,
                  'seat_number': seatNumber,
                  'profile_url': finalProfileUrl,
                  'room_id': _wsService.currentRoomId,
                });
                print("✅ onSeatOccupied callback triggered for current user (seat $seatNumber)");
              }
            }
          });
        } else {
          print("⚠️ User ID is null or empty - cannot trigger user:joined");
        }
      }
      
      // ✅ CRITICAL: Notify all listeners (UI widgets) to update
      print("🔔 Calling notifyListeners() to update UI...");
      notifyListeners();
      print("✅ notifyListeners() called - UI should update now");
      
      // ✅ If seat has user_id but missing username/profile, fetch from API
      if (userId != null && userId.isNotEmpty) {
        final updatedSeatIndex = _seats.indexWhere(
          (s) => s.seatNumber == seatNumber,
        );
        if (updatedSeatIndex != -1) {
          final updatedSeat = _seats[updatedSeatIndex];
          final hasMissingData =
              (updatedSeat.username == null ||
                  updatedSeat.username!.isEmpty ||
                  _isUserXPattern(updatedSeat.username)) ||
              (updatedSeat.profileUrl == null ||
                  updatedSeat.profileUrl!.isEmpty);
          
          if (hasMissingData) {
            print(
              "📡 Seat $seatNumber has user_id $userId but missing user data - fetching from API...",
            );
            _fetchUserDataForSeat(seatNumber, userId);
          }
        }
      }
      
      print("🪑 ==========================================");
    } catch (e, stackTrace) {
      print("❌ ===== ERROR HANDLING seat:occupied =====");
      print("❌ Error: $e");
      print("❌ Stack trace: $stackTrace");
      print("❌ Data that caused error: $data");
      print("❌ ========================================");
    }
  }

  // ✅ Handle seat:vacated event
  // Note: Room filtering is handled at WebSocketService level
  void _handleSeatVacated(Map<String, dynamic> data) {
    try {
      print("🪑 Handling seat:vacated event");
      print("   Data: $data");

      final seatNumber = data['seat_number'] as int?;

      if (seatNumber == null) {
        print("⚠️ seat:vacated event missing seat_number");
        return;
      }

        // Update the specific seat
        final seatIndex = _seats.indexWhere((s) => s.seatNumber == seatNumber);
        if (seatIndex != -1) {
          _seats[seatIndex] = Seat(
            seatNumber: seatNumber,
            isOccupied: false,
          isReserved: data['is_reserved'] == 1 || data['is_reserved'] == true,
            userId: null,
            username: null,
            userName: null,
            profileUrl: null,
          );

          // Recalculate stats
          _occupiedSeats = _seats.where((s) => s.isOccupied).length;
          _availableSeats = _totalSeats - _occupiedSeats;

          print("✅ Seat $seatNumber vacated");
        print(
          "📊 Updated stats - Occupied: $_occupiedSeats, Available: $_availableSeats",
        );
          notifyListeners();
      } else {
        print("⚠️ Seat $seatNumber not found in list when trying to vacate");
      }
    } catch (e) {
      print("❌ Error handling seat:vacated: $e");
      print("   Stack trace: ${StackTrace.current}");
    }
  }

  // ✅ Disconnect from WebSocket (uses global WebSocketService)
  Future<void> disconnect() async {
    try {
      print("🔌 [SeatProvider] Disconnecting from WebSocket");
      // Note: WebSocketService handles disconnection globally
      // We just clear our event listeners

      // ✅ Remove connection status listener
      if (_connectionListenerSet) {
        _wsService.removeListener(_onConnectionStatusChanged);
        _connectionListenerSet = false;
        print("✅ [SeatProvider] Connection status listener removed");
      }

      _wsService.offAll('seat_update');
      _wsService.offAll('seats:update');
      _wsService.offAll('seat_occupied');
      _wsService.offAll('seat:occupied');
      _wsService.offAll('seat_vacated');
      _wsService.offAll('seat:vacated');
      _wsService.offAll('user:joined');
      _wsService.offAll('user:left');
      _wsService.offAll('mic:on');
      _wsService.offAll('mic:off');
      _wsService.offAll('mic_status');
      _wsService.offAll('user:speaking');
      _wsService.offAll('speaking');
      _wsService.offAll('gift_sent');
      _wsService.offAll('gift:sent');
      _wsService.offAll('gifts:list');
      _wsService.offAll('gifts:update');
      _wsService.offAll('gifts:response');
      _wsService.offAll('gifts_list');
      _wsService.offAll('get_gifts');
      _wsService.offAll('message');
      _wsService.offAll('room_message');
      _wsService.offAll('message:received');
      _wsService.offAll('message_received');
      _wsService.offAll('error');
      _wsService.offAll('success');
      
      // ✅ Don't call notifyListeners() during disposal - widget tree is locked
      // Only notify if we're not being disposed (check if mounted/active)
      // Since this is called from dispose(), we skip notification to avoid errors
      print("✅ [SeatProvider] Disconnected and event listeners cleared");
    } catch (e) {
      print("❌ [SeatProvider] Error disconnecting: $e");
    }
  }

  // ✅ Fetch user data for a specific seat/user_id from API
  Future<void> _fetchUserDataForSeat(int seatNumber, String userId) async {
    try {
      print("📡 Fetching user data for seat $seatNumber, user_id: $userId");
      
      // ✅ Check cache first
      final cachedData = _userDataCache[userId];
      if (cachedData != null && 
          cachedData['username'] != null && 
          cachedData['profileUrl'] != null) {
        print("💾 Using cached user data for user $userId");
        final seatIndex = _seats.indexWhere((s) => s.seatNumber == seatNumber);
        if (seatIndex != -1) {
          _seats[seatIndex] = Seat(
            seatNumber: seatNumber,
            isOccupied: _seats[seatIndex].isOccupied,
            isReserved: _seats[seatIndex].isReserved,
            userId: userId,
            username: cachedData['username'],
            userName: cachedData['userName'],
            profileUrl: cachedData['profileUrl'],
          );
          notifyListeners();
          print("✅ Updated seat $seatNumber with cached user data");
        }
        return;
      }
      
      // ✅ Fetch all users from API
      final allUsers = await ApiManager.getAllUsers();
      
      if (allUsers.isEmpty) {
        print("⚠️ No users returned from API");
        return;
      }
      
      // ✅ Find user in API response by user_id
      final userData = allUsers.firstWhere((user) {
        final userUserId =
            user['id']?.toString() ?? user['user_id']?.toString() ?? '';
          return userUserId == userId;
      }, orElse: () => null);
      
      if (userData == null) {
        print("⚠️ User $userId not found in API response");
        return;
      }
      
      // ✅ Extract username and profile_url from API response
      // ✅ Safely get username (handle int types)
      String? username;
      if (userData['username'] != null) {
        username = userData['username'].toString();
      } else if (userData['user_name'] != null) {
        username = userData['user_name'].toString();
      } else if (userData['name'] != null) {
        username = userData['name'].toString();
      }
      // ✅ Safely get profileUrl (handle int types)
      String? profileUrl;
      if (userData['profile_url'] != null) {
        profileUrl = userData['profile_url'].toString();
      }
      
      // ✅ Normalize profile URL (add base URL if it's a relative path)
      profileUrl = _normalizeProfileUrl(profileUrl);
      if (profileUrl != null) {
        print("📝 Normalized profile URL: $profileUrl");
      }
      
      // ✅ Filter out "User X" patterns
      final filteredUsername = _filterUserXPattern(username);
      
      // ✅ Only require username - profileUrl is optional (API may not return it)
      if (filteredUsername == null) {
        print(
          "⚠️ User $userId has no valid username in API (profileUrl is optional)",
        );
        return;
      }
      
      // ✅ Update the seat
      final seatIndex = _seats.indexWhere((s) => s.seatNumber == seatNumber);
      if (seatIndex != -1) {
        _seats[seatIndex] = Seat(
          seatNumber: seatNumber,
          isOccupied: _seats[seatIndex].isOccupied,
          isReserved: _seats[seatIndex].isReserved,
          userId: userId,
          username: filteredUsername, // ✅ Guaranteed non-null (checked above)
          userName: filteredUsername, // ✅ Guaranteed non-null (checked above)
          profileUrl: profileUrl ?? _seats[seatIndex].profileUrl,
        );
        
        // ✅ Cache the user data (filteredUsername is guaranteed non-null)
        _userDataCache[userId] = {
          'username': filteredUsername,
          'userName': filteredUsername,
          'profileUrl': profileUrl,
        };
        print(
          "💾 Cached user data for user $userId: username=$filteredUsername, profileUrl=$profileUrl",
        );
        
        notifyListeners();
        print(
          "✅ Updated seat $seatNumber with user data from API: username=$filteredUsername, profileUrl=$profileUrl",
        );
      }
    } catch (e, stackTrace) {
      print(
        "❌ Error fetching user data for seat $seatNumber, user $userId: $e",
      );
      print("   Stack trace: $stackTrace");
    }
  }

  // ✅ Fetch missing user data from API for seats with user_id but no username/profile
  Future<void> _fetchMissingUserData() async {
    try {
      // ✅ Find seats that need user data (have user_id but missing username/profile)
      final seatsNeedingData = _seats
          .where(
            (seat) =>
        seat.isOccupied &&
        seat.userId != null &&
        seat.userId!.isNotEmpty &&
                (seat.username == null ||
                    seat.username!.isEmpty ||
                    _isUserXPattern(seat.username)) &&
                (seat.userName == null ||
                    seat.userName!.isEmpty ||
                    _isUserXPattern(seat.userName)) &&
                (seat.profileUrl == null || seat.profileUrl!.isEmpty),
          )
          .toList();
      
      if (seatsNeedingData.isEmpty) {
        print("✅ All seats have user data - no API fetch needed");
        return;
      }
      
      print(
        "📡 Fetching user data for ${seatsNeedingData.length} seat(s) with missing user info...",
      );
      
      // ✅ Fetch all users from API
      final allUsers = await ApiManager.getAllUsers();
      
      if (allUsers.isEmpty) {
        print("⚠️ No users returned from API");
        return;
      }
      
      print("📡 Received ${allUsers.length} users from API");
      
      // ✅ Update seats with fetched user data
      bool updated = false;
      for (final seat in seatsNeedingData) {
        if (seat.userId == null || seat.userId!.isEmpty) continue;
        
        // ✅ Find user in API response by user_id
        final userData = allUsers.firstWhere((user) {
          final userId =
              user['id']?.toString() ?? user['user_id']?.toString() ?? '';
            return userId == seat.userId;
        }, orElse: () => null);
        
        if (userData == null) {
          print("⚠️ User ${seat.userId} not found in API response");
          continue;
        }
        
        // ✅ Extract username and profile_url from API response
        // ✅ Safely get username (handle int types)
        String? username;
        if (userData['username'] != null) {
          username = userData['username'].toString();
        } else if (userData['user_name'] != null) {
          username = userData['user_name'].toString();
        } else if (userData['name'] != null) {
          username = userData['name'].toString();
        }
        // ✅ Safely get profileUrl (handle int types)
        String? profileUrl;
        if (userData['profile_url'] != null) {
          profileUrl = userData['profile_url'].toString();
        }
        
        // ✅ Normalize profile URL (add base URL if it's a relative path)
        profileUrl = _normalizeProfileUrl(profileUrl);
        if (profileUrl != null) {
          print("📝 Normalized profile URL: $profileUrl");
        }
        
        // ✅ Filter out "User X" patterns
        final filteredUsername = _filterUserXPattern(username);
        
        // ✅ Only require username - profileUrl is optional (API may not return it)
        if (filteredUsername == null) {
          print(
            "⚠️ User ${seat.userId} has no valid username in API (profileUrl is optional)",
          );
          continue;
        }
        
        // ✅ Find seat index and update
        final seatIndex = _seats.indexWhere(
          (s) => s.seatNumber == seat.seatNumber,
        );
        if (seatIndex != -1) {
          _seats[seatIndex] = Seat(
            seatNumber: seat.seatNumber,
            isOccupied: seat.isOccupied,
            isReserved: seat.isReserved,
            userId: seat.userId,
            username: filteredUsername, // ✅ Guaranteed non-null (checked above)
            userName: filteredUsername, // ✅ Guaranteed non-null (checked above)
            profileUrl: profileUrl ?? seat.profileUrl,
          );
          
          // ✅ Cache the user data (filteredUsername is guaranteed non-null, seat.userId checked in loop)
          if (seat.userId != null) {
            _userDataCache[seat.userId!] = {
              'username': filteredUsername,
              'userName': filteredUsername,
              'profileUrl': profileUrl,
            };
            print(
              "💾 Cached user data for user ${seat.userId}: username=$filteredUsername, profileUrl=$profileUrl",
            );
          }
          
          updated = true;
          print(
            "✅ Updated seat ${seat.seatNumber} with user data from API: username=$filteredUsername, profileUrl=$profileUrl",
          );
        }
      }
      
      if (updated) {
        notifyListeners();
        print(
          "✅ Updated ${seatsNeedingData.length} seat(s) with user data from API",
        );
      }
    } catch (e, stackTrace) {
      print("❌ Error fetching missing user data: $e");
      print("   Stack trace: $stackTrace");
    }
  }

  // ✅ Clear seats data
  void clearSeats() {
    _seats.clear();
    _totalSeats = 0;
    _occupiedSeats = 0;
    _availableSeats = 0;
    _errorMessage = '';
    print("🗑️ Seats data cleared");
    notifyListeners();
  }

  // ✅ Reset error
  void resetError() {
    _errorMessage = '';
    notifyListeners();
  }

  // ✅ Clear error (alias for resetError)
  void clearError() {
    resetError();
  }

  @override
  void dispose() {
    print("🗑️ Disposing SeatProvider");
    disconnect();
    super.dispose();
  }
}
