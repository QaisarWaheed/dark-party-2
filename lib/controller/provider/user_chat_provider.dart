// import 'dart:convert';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shaheen_star_app/controller/api_manager/user_web_socket_service.dart';
// import 'package:shaheen_star_app/model/user_chat_model.dart';
// import 'package:shaheen_star_app/utils/user_session.dart';

// class UserChatProvider extends ChangeNotifier {
//   final UserChatWebSocket _websocket = UserChatWebSocket();
//   final UserSession _session = UserSession();

//   // State
//   List<UserChatRoom> _chatRooms = [];
//   List<UserChatRoom> _filteredChatRooms = []; // Add this line
//   List<UserChatMessage> _messages = [];
//   List<SearchedUser> _searchResults = [];
  
//   int? _currentChatroomId;
//   bool _isLoading = false;
//   bool _isSearching = false;
//   String? _error;
//   String _searchQuery = '';
//   bool _isInitializing = false;

//   // Getters - Add filteredChatRooms getter here
//   List<UserChatRoom> get chatRooms => _chatRooms;
//   List<UserChatRoom> get filteredChatRooms => _filteredChatRooms; // Add this getter
//   List<UserChatMessage> get messages => _messages;
//   List<SearchedUser> get searchResults => _searchResults;
//   bool get isLoading => _isLoading;
//   bool get isConnected => _websocket.isConnected;
//   bool get isSearching => _isSearching;
//   String? get error => _error;
//   int? get currentChatroomId => _currentChatroomId;
//   int? get currentUserId => _session.userId;
//   bool get isInitializing => _isInitializing;

//   // Initialize
//   Future<void> initialize() async {
//     try {
//       // Prevent multiple simultaneous initializations
//       if (_isInitializing) {
//         print('⚠️ Already initializing, skipping...');
//         return;
//       }

//       print('🚀 Starting chat initialization...');
//       _isInitializing = true;
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       // STEP 1: Load session first
//       print('📂 Loading user session...');
//       await _session.loadSession();
      
//       // STEP 2: Verify session is properly loaded
//       if (!_session.isInitialized) {
//         _handleError('Please login to use chat', showToUser: true);
//         return;
//       }

//       if (_session.userId == null) {
//         _handleError('User ID not found. Please login again.', showToUser: true);
//         return;
//       }

//       if (_session.username == null) {
//         _handleError('Username not found. Please complete your profile.', showToUser: true);
//         return;
//       }

//       // Use username as name if name is not available
//       final userName = _session.name ?? _session.username!;

//       print('✅ Session verified: UserID=${_session.userId}, Username=${_session.username}, Name=$userName');

//       // STEP 3: Setup WebSocket callbacks
//       _setupWebSocketCallbacks();

//       // STEP 4: Connect to WebSocket
//       print('🔌 Connecting to WebSocket...');
//       _websocket.connect(
//         userId: _session.userId!,
//         username: _session.username!,
//         name: userName,
//         profileUrl: _session.profileUrl,
//       );

//       print('✅ Chat initialization completed');

//     } catch (e, stackTrace) {
//       print('❌ Initialization error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError(
//         'Failed to initialize chat. Please try again.', 
//         showToUser: true,
//         exception: e
//       );
//     } finally {
//       _isInitializing = false;
//     }
//   }
//   // Setup WebSocket callbacks
//   void _setupWebSocketCallbacks() {
//     _websocket.onMessage = _handleMessage;
    
//     _websocket.onConnected = () {
//       print('🔗 WebSocket connection established - Getting chat rooms');
//       _isLoading = false;
//       _error = null;
//       notifyListeners();
      
//       // Wait 500ms then get chat rooms
//       Future.delayed(Duration(milliseconds: 500), () {
//         getChatRooms();
//       });
//     };
    
//     _websocket.onDisconnected = () {
//       print('⚠️ WebSocket disconnected');
//       _error = 'Disconnected from server. Reconnecting...';
//       notifyListeners();
//       _autoReconnect();
//     };
    
//     _websocket.onError = (error) {
//       print('❌ WebSocket error: $error');
//       _handleError(
//         'Connection error. Please check your internet connection.',
//         showToUser: true,
//         exception: error
//       );
//     };
//   }

//   // Auto reconnect with exponential backoff
//   void _autoReconnect() {
//     Future.delayed(Duration(seconds: 5), () {
//       if (!_websocket.isConnected && _session.isInitialized && !_isInitializing) {
//         print('🔄 Auto-reconnecting...');
//         initialize();
//       }
//     });
//   }

//   // Handle incoming messages
//  // Handle incoming messages
// void _handleMessage(dynamic message) {
//   try {
//     print('📨 Processing message: ${message.toString()}');
    
//     if (message == null || message.toString().isEmpty) {
//       return;
//     }

//     final data = json.decode(message.toString());
//     print('📊 Full message data: $data');
    
//     // Check if it's an error response
//     if (data['status'] == 'error') {
//       final errorMsg = data['message'] ?? 'Unknown error';
//       print('❌ Server error: $errorMsg');
//       _handleError(errorMsg, showToUser: true);
//       return;
//     }
    
//     // Check for success response format
//     if (data['status'] == 'success' && data['event'] != null) {
//       final event = data['event']?.toString();
//       final responseData = data['data'];

//       print('📊 Event: $event, Data: $responseData');

//       switch (event) {
//         case 'user:initial_data':
//           print('✅ Initial data received');
//           _handleSuccess('Connected to chat server');
//           break;
//         case 'user:chatrooms':
//           _handleChatRooms(data['data']);
//           break;
//         case 'user:chatroom_created':
//           _handleChatroomCreated(data['data']);
//           break;
//         case 'user:messages':
//           _handleMessages(data['data']);
//           break;
//         case 'user:new_message':
//           _handleNewMessage(data['data']);
//           break;
//         case 'user:message_sent':
//           _handleMessageSent(data['data']);
//           break;
//         case 'users:search_results':
//           _handleSearchResults(data['data']);
//           break;
//         case 'user:online_status':
//           _handleOnlineStatus(data['data']);
//           break;
//         default:
//           print('⚠️ Unknown event: $event');
//       }
//     } else {
//       // Try alternative format
//       final event = data['event']?.toString();
//       if (event != null) {
//         print('📊 Event (alt format): $event');
//         // Handle events in alternative format
//         switch (event) {
//           case 'user:initial_data':
//             _handleSuccess('Connected to chat server');
//             break;
//           case 'user:chatrooms':
//             _handleChatRooms(data);
//             break;
//           // Add other cases as needed
//         }
//       }
//     }
//   } catch (e, stackTrace) {
//     print('❌ Message processing error: $e');
//     print('Stack trace: $stackTrace');
//   }
// }
//   void _handleChatRooms(dynamic data) {
//     try {
//       print('📊 Processing chat rooms data: $data');
      
//       if (data == null) {
//         _handleError('No chat rooms data received', showToUser: false);
//         return;
//       }

//       final List chatRoomsData = data['chatrooms'] ?? [];
//       print('📋 Found ${chatRoomsData.length} chat rooms');
      
//       _chatRooms = chatRoomsData.map((room) => UserChatRoom.fromJson(room)).toList();
//       _chatRooms.sort((a, b) {
//         if (a.lastMessageTime == null) return 1;
//         if (b.lastMessageTime == null) return -1;
//         return b.lastMessageTime!.compareTo(a.lastMessageTime!);
//       });
      
//       _handleSuccess('Loaded ${_chatRooms.length} chat rooms');
//     } catch (e, stackTrace) {
//       print('❌ Chat rooms error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError(
//         'Failed to load chat rooms',
//         showToUser: false,
//         exception: e
//       );
//     }
//   }

//   void _handleChatroomCreated(dynamic data) {
//     try {
//       print('📊 Processing chatroom created data: $data');
      
//       if (data == null) {
//         _handleError('Invalid chatroom data received', showToUser: false);
//         return;
//       }

//       final newRoom = UserChatRoom.fromJson(data);
//       print('🆕 New chatroom created: ${newRoom.id} with ${newRoom.otherUserName}');
      
//       final existingIndex = _chatRooms.indexWhere((room) => room.id == newRoom.id);
      
//       if (existingIndex != -1) {
//         _chatRooms[existingIndex] = newRoom;
//       } else {
//         _chatRooms.insert(0, newRoom);
//       }
      
//       _currentChatroomId = newRoom.id;
//       _handleSuccess('Chat room created successfully');
      
//       // Load messages for new chatroom
//       loadMessages(newRoom.id);
//     } catch (e, stackTrace) {
//       print('❌ Chatroom created error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError(
//         'Failed to create chat room',
//         showToUser: true,
//         exception: e
//       );
//     }
//   }

//   void _handleMessages(dynamic data) {
//     try {
//       print('📊 Processing messages data: $data');
      
//       if (data == null) {
//         _handleError('Invalid messages data received', showToUser: false);
//         return;
//       }

//       final List messagesData = data['messages'] ?? [];
//       print('📨 Found ${messagesData.length} messages');
      
//       _messages = messagesData.map((msg) => UserChatMessage.fromJson(msg)).toList();
//       _handleSuccess('Loaded ${_messages.length} messages');
//     } catch (e, stackTrace) {
//       print('❌ Messages error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError(
//         'Failed to load messages',
//         showToUser: true,
//         exception: e
//       );
//     }
//   }

//   void _handleNewMessage(dynamic data) {
//     try {
//       if (data == null) return;

//       final newMessage = UserChatMessage.fromJson(data);
//       print('💬 New message from ${newMessage.senderName}: ${newMessage.message}');
      
//       if (newMessage.chatroomId == _currentChatroomId) {
//         _messages.add(newMessage);
//       }
      
//       _updateChatroomLastMessage(newMessage);
//     } catch (e, stackTrace) {
//       print('❌ New message error: $e');
//       print('Stack trace: $stackTrace');
//     }
//   }

//   void _handleMessageSent(dynamic data) {
//     try {
//       if (data == null) return;

//       final sentMessage = UserChatMessage.fromJson(data);
//       final exists = _messages.any((msg) => msg.id == sentMessage.id);
//       if (!exists) {
//         _messages.add(sentMessage);
//       }
//       _updateChatroomLastMessage(sentMessage);
//     } catch (e, stackTrace) {
//       print('❌ Message sent error: $e');
//       print('Stack trace: $stackTrace');
//     }
//   }

//   void _updateChatroomLastMessage(UserChatMessage message) {
//     final roomIndex = _chatRooms.indexWhere((room) => room.id == message.chatroomId);
//     if (roomIndex != -1) {
//       final isCurrentChat = message.chatroomId == _currentChatroomId;
//       _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
//         lastMessage: message.message,
//         lastMessageTime: message.createdAt,
//         unreadCount: isCurrentChat ? 0 : _chatRooms[roomIndex].unreadCount + 1,
//       );
//       final room = _chatRooms.removeAt(roomIndex);
//       _chatRooms.insert(0, room);
//     }
//   }

//   void _handleSearchResults(dynamic data) {
//     try {
//       if (data == null) {
//         _handleError('Invalid search results data received', showToUser: false);
//         return;
//       }

//       final List usersData = data['users'] ?? [];
//       _searchResults = usersData.map((user) => SearchedUser.fromJson(user)).toList();
//       _isSearching = false;
//       _handleSuccess('Found ${_searchResults.length} users');
//     } catch (e, stackTrace) {
//       print('❌ Search results error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError(
//         'Failed to load search results',
//         showToUser: false,
//         exception: e
//       );
//     }
//   }

//   void _handleOnlineStatus(dynamic data) {
//     try {
//       if (data == null) return;

//       final int? userId = data['user_id'];
//       final bool isOnline = data['is_online'] ?? false;
//       final String? status = data['status'];
      
//       if (userId == null) return;

//       for (int i = 0; i < _chatRooms.length; i++) {
//         if (_chatRooms[i].otherUserId == userId) {
//           _chatRooms[i] = _chatRooms[i].copyWith(isOnline: isOnline, status: status);
//         }
//       }
//       notifyListeners();
//     } catch (e) {
//       print('❌ Error: $e');
//     }
//   }

//   // Enhanced error handling
//   void _handleError(String errorMessage, {bool showToUser = false, dynamic exception}) {
//     print('❌ Error: $errorMessage');
//     if (exception != null) {
//       print('Exception: $exception');
//     }
    
//     if (showToUser) {
//       _error = errorMessage;
//     }
    
//     _isLoading = false;
//     _isSearching = false;
//     notifyListeners();
//   }

//   void _handleSuccess(String message) {
//     print('✅ Success: $message');
//     _error = null;
//     _isLoading = false;
//     _isSearching = false;
//     notifyListeners();
//   }


//   void getChatRooms() {
//   try {
//     print('📥 Fetching chat rooms for user ${_session.userId}...');
//     _isLoading = true;
//     notifyListeners();
    
//     // Call WebSocket method
//     _websocket.getChatRooms(_session.userId!);
    
//     // Set timeout to check if response received
//     Future.delayed(Duration(seconds: 3), () {
//       if (_chatRooms.isEmpty && _error == null) {
//         print('⚠️ No response from server, retrying...');
//         _retryGetChatRooms();
//       }
//     });
    
//   } catch (e, stackTrace) {
//     print('❌ Get chat rooms error: $e');
//     print('Stack trace: $stackTrace');
//     _handleError('Failed to get chat rooms', showToUser: true, exception: e);
//   }
// }

// void _retryGetChatRooms() {
//   if (!_websocket.isConnected) {
//     print('🔁 Reconnecting WebSocket...');
//     reconnect();
//     return;
//   }
  
//   print('🔄 Retrying getChatRooms...');
//   Future.delayed(Duration(seconds: 2), () {
//     _websocket.getChatRooms(_session.userId!);
//   });
// }

//   // Public methods
//   // void getChatRooms() {
//   //   try {
//   //     if (!_session.isInitialized) {
//   //       _handleError('User not logged in', showToUser: true);
//   //       return;
//   //     }

//   //     if (_session.userId == null) {
//   //       _handleError('User ID not found', showToUser: true);
//   //       return;
//   //     }

//   //     print('📥 Fetching chat rooms for user ${_session.userId}...');
//   //     _isLoading = true;
//   //     notifyListeners();
      
//   //     // Call WebSocket method
//   //     _websocket.getChatRooms(_session.userId!);
      
//   //   } catch (e, stackTrace) {
//   //     print('❌ Get chat rooms error: $e');
//   //     print('Stack trace: $stackTrace');
//   //     _handleError('Failed to get chat rooms', showToUser: true, exception: e);
//   //   }
//   // }

//   Future<void> createChatroom(int otherUserId) async {
//     try {
//       if (!_session.isInitialized) {
//         _handleError('User not logged in', showToUser: true);
//         return;
//       }

//       if (_session.userId == null) {
//         _handleError('User ID not found', showToUser: true);
//         return;
//       }

//       if (otherUserId <= 0) {
//         _handleError('Invalid user selected', showToUser: true);
//         return;
//       }

//       print('🆕 Creating chatroom with user: $otherUserId');
//       _isLoading = true;
//       notifyListeners();
//       _websocket.createChatroom(_session.userId!, otherUserId);
//     } catch (e, stackTrace) {
//       print('❌ Create chatroom error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError('Failed to create chat room', showToUser: true, exception: e);
//     }
//   }

//   Future<void> setCurrentChatroom(int chatroomId) async {
//     try {
//       if (chatroomId <= 0) {
//         _handleError('Invalid chat room', showToUser: true);
//         return;
//       }

//       print('💬 Setting current chatroom: $chatroomId');
//       _currentChatroomId = chatroomId;
//       _messages.clear();
//       notifyListeners();
//       loadMessages(chatroomId);
//       markAsRead(chatroomId);
//     } catch (e, stackTrace) {
//       print('❌ Set chatroom error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError('Failed to set current chatroom', showToUser: true, exception: e);
//     }
//   }

//   void loadMessages(int chatroomId) {
//     try {
//       if (!_session.isInitialized) {
//         _handleError('User not logged in', showToUser: true);
//         return;
//       }

//       if (_session.userId == null) {
//         _handleError('User ID not found', showToUser: true);
//         return;
//       }

//       if (chatroomId <= 0) {
//         _handleError('Invalid chat room', showToUser: true);
//         return;
//       }

//       print('📬 Loading messages for chatroom: $chatroomId');
//       _isLoading = true;
//       notifyListeners();
//       _websocket.getMessages(_session.userId!, chatroomId);
//     } catch (e, stackTrace) {
//       print('❌ Load messages error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError('Failed to load messages', showToUser: true, exception: e);
//     }
//   }

//   Future<bool> sendChatMessage(String messageText) async {
//     try {
//       if (!_session.isInitialized) {
//         _handleError('User not logged in', showToUser: true);
//         return false;
//       }

//       if (_session.userId == null) {
//         _handleError('User ID not found', showToUser: true);
//         return false;
//       }

//       if (_currentChatroomId == null) {
//         _handleError('No chat room selected', showToUser: true);
//         return false;
//       }

//       final trimmedText = messageText.trim();
//       if (trimmedText.isEmpty) {
//         _handleError('Message cannot be empty', showToUser: true);
//         return false;
//       }

//       if (!_websocket.isConnected) {
//         _handleError('Not connected to server', showToUser: true);
//         return false;
//       }

//       print('💬 Sending message: $trimmedText');
//       _websocket.sendMessage(_session.userId!, _currentChatroomId!, trimmedText);
//       return true;
//     } catch (e, stackTrace) {
//       print('❌ Send message error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError('Failed to send message', showToUser: true, exception: e);
//       return false;
//     }
//   }

//   void searchUsers(String query) {
//     try {
//       if (!_session.isInitialized) {
//         _handleError('User not logged in', showToUser: true);
//         return;
//       }

//       if (_session.userId == null) {
//         _handleError('User ID not found', showToUser: true);
//         return;
//       }
      
//       print('🔍 Searching users: $query');
//       _searchQuery = query;
//       _isSearching = true;
//       notifyListeners();
      
//       if (query.isEmpty) {
//         _searchResults.clear();
//         _filteredChatRooms.clear();
//         _isSearching = false;
//         notifyListeners();
//         return;
//       }
      
//       // Filter existing chat rooms
//       _filteredChatRooms = _chatRooms.where((room) {
//         return room.otherUserName.toLowerCase().contains(query.toLowerCase()) ||
//                room.otherUserUsername.toLowerCase().contains(query.toLowerCase());
//       }).toList();
      
//       // Search for new users
//       _websocket.searchUsers(_session.userId!, query);
//     } catch (e, stackTrace) {
//       print('❌ Search users error: $e');
//       print('Stack trace: $stackTrace');
//       _handleError('Failed to search users', showToUser: false, exception: e);
//     }
    
//     // Filter existing chat rooms
//     _filteredChatRooms = _chatRooms.where((room) {
//       return room.otherUserName.toLowerCase().contains(query.toLowerCase()) ||
//              room.otherUserUsername.toLowerCase().contains(query.toLowerCase());
//     }).toList();
    
//     // Search for new users
//     _websocket.searchUsers(_session.userId!, query);
//   }

//   void markAsRead(int chatroomId) {
//     try {
//       if (!_session.isInitialized || _session.userId == null) {
//         return;
//       }

//       if (chatroomId <= 0) {
//         return;
//       }

//       _websocket.markAsRead(_session.userId!, chatroomId);
      
//       // Update local state
//       final roomIndex = _chatRooms.indexWhere((room) => room.id == chatroomId);
//       if (roomIndex != -1) {
//         _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(unreadCount: 0);
//         notifyListeners();
//       }
//     } catch (e, stackTrace) {
//       print('⚠️ Failed to mark as read: $e');
//       print('Stack trace: $stackTrace');
//     }
//   }

//   UserChatRoom? getChatroomByUserId(int otherUserId) {
//     try {
//       if (otherUserId <= 0) return null;
//       return _chatRooms.firstWhere(
//         (room) => room.otherUserId == otherUserId,
//         orElse: () => throw Exception('Chatroom not found'),
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   // Clear error manually
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }

//   void clearSearch() {
//     _searchQuery = '';
//     _searchResults.clear();
//     _filteredChatRooms.clear();
//     _isSearching = false;
//     notifyListeners();
//   }

//   // Reconnect to WebSocket
//   Future<void> reconnect() async {
//     print('🔄 Manual reconnect requested');
//     _error = null;
//     _isLoading = true;
//     notifyListeners();
    
//     // Disconnect existing connection if any
//     if (_websocket.isConnected) {
//       _websocket.disconnect();
//     }
    
//     // Reinitialize connection
//     await initialize();
//   }

//   @override
//   void dispose() {
//     _websocket.disconnect();
//     super.dispose();
//   }
// }


import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/user_web_socket_service.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/model/user_message_model.dart';
import 'package:shaheen_star_app/utils/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserChatProvider extends ChangeNotifier {
  final UserChatWebSocket _websocket = UserChatWebSocket();
  final UserSession _session = UserSession();

  // ⭐ ADD STREAM SUBSCRIPTIONS
  StreamSubscription? _chatRoomsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _userSearchSubscription;

  // State
  List<UserChatRoom> _chatRooms = [];
  List<UserChatRoom> _filteredChatRooms = [];
  List<UserChatMessage> _messages = [];
  List<SearchedUser> _searchResults = [];
  
  int? _currentChatroomId;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';
  bool _isInitializing = false;

  // Admin room constants
  static const int _kAdminRoomId = 999999999;


  // Getters
  List<UserChatRoom> get chatRooms => _chatRooms;
  List<UserChatRoom> get filteredChatRooms => _filteredChatRooms;
  List<UserChatMessage> get messages => _messages;
  List<SearchedUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isConnected => _websocket.isConnected;
  bool get isSearching => _isSearching;
  String? get error => _error;
  int? get currentChatroomId => _currentChatroomId;
  int? get currentUserId => _session.userId;
  bool get isInitializing => _isInitializing;

  // Initialize
  Future<void> initialize() async {
    try {
      if (_isInitializing) {
        print('⚠️ Already initializing, skipping...');
        return;
      }

      print('🚀 Starting chat initialization...');
      _isInitializing = true;
      _isLoading = true;
      _error = null;
      notifyListeners();

      // STEP 1: Load session first
      print('📂 Loading user session...');
      await _session.loadSession();
      
      // STEP 2: Verify session is properly loaded
      if (!_session.isInitialized) {
        _handleError('Please login to use chat', showToUser: true);
        return;
      }

      if (_session.userId == null) {
        _handleError('User ID not found. Please login again.', showToUser: true);
        return;
      }

      if (_session.username == null) {
        _handleError('Username not found. Please complete your profile.', showToUser: true);
        return;
      }

      final userName = _session.name ?? _session.username!;
      print('✅ Session verified: UserID=${_session.userId}, Username=${_session.username}, Name=$userName');

      // STEP 3: Setup WebSocket callbacks AND streams
      _setupWebSocketCallbacks();
      _setupStreamListeners(); // ⭐ NEW - Listen to streams

      // STEP 4: Connect to WebSocket
      print('🔌 Connecting to WebSocket...');
      _websocket.connect(
        userId: _session.userId!,
        username: _session.username!,
        name: userName,
        profileUrl: _session.profileUrl,
      );

      print('✅ Chat initialization completed');

    } catch (e, stackTrace) {
      print('❌ Initialization error: $e');
      print('Stack trace: $stackTrace');
      _handleError(
        'Failed to initialize chat. Please try again.', 
        showToUser: true,
        exception: e
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// Send an image file to the current chat recipient using multipart form-data.
Future<bool> sendImageMessage(File imageFile, {String? message}) async {
  try {
    // 1️⃣ Ensure session and user are valid
    if (!_session.isInitialized) {
      _handleError('User not logged in', showToUser: true);
      return false;
    }

    if (_session.userId == null) {
      _handleError('User ID not found', showToUser: true);
      return false;
    }

    if (_currentChatroomId == null) {
      _handleError('No chat room selected', showToUser: true);
      return false;
    }

    // 2️⃣ Determine recipient id from current chatroom
    UserChatRoom? room;
    for (var r in _chatRooms) {
      if (r.id == _currentChatroomId || r.id.toString() == _currentChatroomId.toString()) {
        room = r;
        break;
      }
    }

    int toUserId = 0;
    if (room != null) {
      toUserId = room.otherUserId;
    }

    if (toUserId <= 0) {
      for (var m in _messages.reversed) {
        if (m.chatroomId == _currentChatroomId) {
          if (m.senderId != _session.userId && m.senderId > 0) {
            toUserId = m.senderId;
            break;
          }
        }
      }
    }

    if (toUserId <= 0) {
      _handleError('Unable to send image (recipient unknown)', showToUser: true);
      return false;
    }

    // 3️⃣ Send the image via API
    final resp = await ApiManager.sendImageMessage(
      fromUserId: _session.userId!,
      toUserId: toUserId,
      imageFile: imageFile,
      message: message,
    );

    if (resp != null) {
      print('🔁 sendImageMessage response: $resp');
      // 4️⃣ Extract media URL from response
      String? mediaUrl;
      try {
        if (resp['data'] is Map && resp['data']['media_url'] != null) {
          mediaUrl = resp['data']['media_url'].toString();
        } else if (resp['data'] is Map && resp['data']['mediaUrl'] != null) {
          mediaUrl = resp['data']['mediaUrl'].toString();
        }
      } catch (_) {
        mediaUrl = null;
      }

      // 5️⃣ Create local message object
      final localMsg = UserChatMessage(
        id: resp['data']?['message_id'] is int ? resp['data']['message_id'] : 0,
        chatroomId: _currentChatroomId!,
        senderId: _session.userId!,
        senderName: _session.username ?? '',
        senderUsername: _session.username ?? '',
        senderProfileUrl: _session.profileUrl,
        message: message ?? "", // null if purely an image
        attachmentUrl: mediaUrl ?? imageFile.path,
        attachmentType: 'image',
        createdAt: DateTime.now(),
        isRead: true,
      );

      // 6️⃣ Add to local chat list
      _messages.add(localMsg);
      _updateChatroomLastMessage(localMsg);
      _error = null;
      _isLoading = false;
      notifyListeners();

      // Refresh messages from server so persisted message appears after refresh
      try {
        if (_currentChatroomId != null) {
          // small delay to allow backend to finalize
          Future.delayed(const Duration(seconds: 1), () => loadMessages(_currentChatroomId!));
        }
      } catch (_) {}

      print('✅ Image sent via HTTP');
      return true;
    } else {
      _handleError('Failed to send image', showToUser: true);
      return false;
    }
  } catch (e, st) {
    print('❌ sendImageMessage error: $e');
    print(st);
    _handleError('Failed to send image', showToUser: true, exception: e);
    return false;
  }
}

  /// Send a voice message (recorded locally) via HTTP. Uses same API as image (send_chat_message.php with voice file).
  Future<bool> sendVoiceMessage(File voiceFile, {int? durationSeconds}) async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return false;
      }
      if (_currentChatroomId == null) {
        _handleError('No chat room selected', showToUser: true);
        return false;
      }

      UserChatRoom? room;
      for (var r in _chatRooms) {
        if (r.id == _currentChatroomId || r.id.toString() == _currentChatroomId.toString()) {
          room = r;
          break;
        }
      }
      int toUserId = room?.otherUserId ?? 0;
      if (toUserId <= 0) {
        for (var m in _messages.reversed) {
          if (m.chatroomId == _currentChatroomId && m.senderId != _session.userId && m.senderId > 0) {
            toUserId = m.senderId;
            break;
          }
        }
      }
      if (toUserId <= 0) {
        _handleError('Unable to send voice (recipient unknown)', showToUser: true);
        return false;
      }

      final ok = await ApiManager.sendVoiceMessage(
        fromUserId: _session.userId!,
        toUserId: toUserId,
        voiceFile: voiceFile,
        duration: durationSeconds,
        message: null,
      );
      if (!ok) {
        _handleError('Failed to send voice message', showToUser: true);
        return false;
      }

      final localMsg = UserChatMessage(
        id: 0,
        chatroomId: _currentChatroomId!,
        senderId: _session.userId!,
        senderName: _session.username ?? '',
        senderUsername: _session.username ?? '',
        senderProfileUrl: _session.profileUrl,
        message: 'Voice message',
        attachmentUrl: voiceFile.path,
        attachmentType: 'voice',
        createdAt: DateTime.now(),
        isRead: true,
      );
      _messages.add(localMsg);
      _updateChatroomLastMessage(localMsg);
      _error = null;
      _isLoading = false;
      notifyListeners();

      try {
        if (_currentChatroomId != null) {
          Future.delayed(const Duration(seconds: 1), () => loadMessages(_currentChatroomId!));
        }
      } catch (_) {}
      print('✅ Voice message sent via HTTP');
      return true;
    } catch (e, st) {
      print('❌ sendVoiceMessage error: $e');
      print(st);
      _handleError('Failed to send voice message', showToUser: true, exception: e);
      return false;
    }
  }

  // ⭐ NEW METHOD - Setup Stream Listeners
  void _setupStreamListeners() {
    print('🎧 Setting up stream listeners...');

    // Listen to chatrooms stream
    _chatRoomsSubscription = _websocket.chatRoomsStream.listen(
      (data) {
        print('🎯 [Stream] Received chatrooms data: $data');
        _handleChatRoomsFromStream(data);
      },
      onError: (error) {
        print('❌ [Stream] Chatrooms error: $error');
      },
    );

    // Listen to messages stream
    _messagesSubscription = _websocket.messagesStream.listen(
      (data) {
        print('🎯 [Stream] Received messages data: $data');
        _handleMessagesFromStream(data);
      },
      onError: (error) {
        print('❌ [Stream] Messages error: $error');
      },
    );

    // Listen to user search stream
    _userSearchSubscription = _websocket.userSearchStream.listen(
      (data) {
        print('🎯 [Stream] Received search data: $data');
        _handleSearchResultsFromStream(data);
      },
      onError: (error) {
        print('❌ [Stream] Search error: $error');
      },
    );

    print('✅ Stream listeners setup complete');
  }

  // ⭐ NEW METHOD - Handle chatrooms from stream
  void _handleChatRoomsFromStream(Map<String, dynamic> data) {
    try {
      print('📊 Processing chat rooms from stream: $data');
      
      if (data.isEmpty) {
        print('⚠️ Empty chatrooms data');
        _isLoading = false;
        notifyListeners();
        return;
        }

      final List chatRoomsData = data['chatrooms'] ?? [];
      print('📋 Found ${chatRoomsData.length} chat rooms from stream');
      
      _chatRooms = chatRoomsData.map((room) => UserChatRoom.fromJson(room)).toList();
      _chatRooms.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      // Ensure dedicated admin room exists at top
      _ensureAdminRoomExists();
      
      _isLoading = false;
      _error = null;
      // After chatrooms are loaded, fetch admin messages and attach to admin room
      _loadAdminMessagesToAdminRoom();
      notifyListeners();
      
      // Persist chat rooms to cache for faster startup next time
      try {
        SharedPreferences.getInstance().then((prefs) {
          final cacheKey = 'cached_chat_rooms_v1_${_session.userId}';
          final serial = json.encode(_chatRooms.map((r) => r.toJson()).toList());
          prefs.setString(cacheKey, serial);
          print('💾 Cached ${_chatRooms.length} chat rooms from stream');
        });
      } catch (e) {
        print('⚠️ Failed to cache chat rooms from stream: $e');
      }

      print('✅ Loaded ${_chatRooms.length} chat rooms from stream');
    } catch (e, stackTrace) {
      print('❌ Chat rooms stream error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to load chat rooms', showToUser: false, exception: e);
    }
  }

  // ⭐ NEW METHOD - Handle messages from stream (data may be Map or List from server)
  void _handleMessagesFromStream(dynamic data) {
    try {
      print('📊 Processing messages from stream: $data');
      
      List messagesData = [];
      if (data is List) {
        messagesData = data;
      } else if (data is Map<String, dynamic>) {
        if (data.isEmpty) {
          print('⚠️ Empty messages data');
          _isLoading = false;
          notifyListeners();
          return;
        }
        messagesData = data['messages'] ?? data['data'] ?? [];
        if (messagesData.isEmpty && data.length == 1 && data.values.single is List) {
          messagesData = data.values.single as List;
        }
      }
      print('📨 Found ${messagesData.length} messages from stream');

      if (messagesData.isEmpty) {
        // Don't clear existing messages if server sent an empty payload
        print('⚠️ Stream provided empty messages list; keeping existing ${_messages.length} messages');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Parse incoming messages and merge with existing ones (dedupe by id)
      final incoming = messagesData.map((msg) => UserChatMessage.fromJson(msg)).toList();

      final Map<int, UserChatMessage> merged = {};
      for (var m in _messages) {
        merged[m.id] = m;
      }
      for (var m in incoming) {
        merged[m.id] = m; // overwrite or add
      }

      _messages = merged.values.toList();
      // Sort by createdAt ascending
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _isLoading = false;
      _error = null;
      notifyListeners();

      // Cache merged messages for this chatroom
      try {
        SharedPreferences.getInstance().then((prefs) {
          if (_currentChatroomId != null) {
            final cacheKey = 'cached_messages_chat_v1_$_currentChatroomId';
            try {
              final serial = json.encode(_messages.map((m) => m.toJson()).toList());
              prefs.setString(cacheKey, serial);
              print('💾 Cached ${_messages.length} messages for chat $_currentChatroomId (stream)');
            } catch (e) {
              print('⚠️ Failed to serialize messages for cache: $e');
            }
          }
        });
      } catch (e) {
        print('⚠️ Failed to cache messages from stream: $e');
      }

      print('✅ Merged messages; total now ${_messages.length}');
    } catch (e, stackTrace) {
      print('❌ Messages stream error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to load messages', showToUser: true, exception: e);
    }
  }

  // ⭐ NEW METHOD - Handle search results from stream
  void _handleSearchResultsFromStream(Map<String, dynamic> data) {
    try {
      print('📊 Processing search results from stream: $data');
      
      if (data.isEmpty) {
        _searchResults = [];
        _isSearching = false;
        notifyListeners();
        return;
      }

      final List usersData = data['users'] ?? [];
      _searchResults = usersData.map((user) => SearchedUser.fromJson(user)).toList();
      
      _isSearching = false;
      _error = null;
      notifyListeners();
      
      print('✅ Found ${_searchResults.length} users from stream');
    } catch (e, stackTrace) {
      print('❌ Search stream error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to load search results', showToUser: false, exception: e);
    }
  }

  // Setup WebSocket callbacks
  void _setupWebSocketCallbacks() {
    _websocket.onMessage = _handleMessage;
    
    _websocket.onConnected = () {
      print('🔗 WebSocket connection established - Getting chat rooms');
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      // Wait 500ms then get chat rooms
      Future.delayed(Duration(milliseconds: 500), () {
        getChatRooms();
      });
    };
    
    _websocket.onDisconnected = () {
      print('⚠️ WebSocket disconnected');
      _error = 'Disconnected from server. Reconnecting...';
      notifyListeners();
      _autoReconnect();
    };
    
    _websocket.onError = (error) {
      print('❌ WebSocket error: $error');
      _handleError(
        'Connection error. Please check your internet connection.',
        showToUser: true,
        exception: error
      );
    };
  }

  // Auto reconnect with exponential backoff
  void _autoReconnect() {
    Future.delayed(Duration(seconds: 5), () {
      if (!_websocket.isConnected && _session.isInitialized && !_isInitializing) {
        print('🔄 Auto-reconnecting...');
        initialize();
      }
    });
  }
// user_chat_provider.dart mein fix karo:

void _handleMessage(dynamic message) {
  try {
    print('📨 Processing message: ${message.toString()}');
    
    if (message == null || message.toString().isEmpty) {
      return;
    }

    final data = json.decode(message.toString());
    print('📊 Full message data: $data');
    
    // Check if it's an error response
    if (data['status'] == 'error') {
      final errorMsg = data['message'] ?? 'Unknown error';
      print('❌ Server error: $errorMsg');
      _handleError(errorMsg, showToUser: true);
      return;
    }
    
    // ⭐ SIMPLIFIED EVENT HANDLING
    final event = data['event']?.toString();
    print('📊 Event received: $event');
    
    // Let streams handle most events, only handle special cases here
    switch (event) {
      case 'chatroom:created':
        _handleChatroomCreated(data['data']);
        break;
      case 'message:new':
        _handleNewMessage(data['data']);
        break;
      case 'message:sent':
        _handleMessageSent(data['data']);
        break;
      case 'user:online_status':
        _handleOnlineStatus(data['data']);
        break;
      default:
        print('ℹ️ Event $event handled by stream');
        // Streams will handle: chatrooms:list, messages:history, users:search
    }
  } catch (e, stackTrace) {
    print('❌ Message processing error: $e');
    print('Stack trace: $stackTrace');
  }
}
  // Handle incoming messages (Legacy support - kept for compatibility)
  // void _handleMessage(dynamic message) {
  //   try {
  //     print('📨 Processing message: ${message.toString()}');
      
  //     if (message == null || message.toString().isEmpty) {
  //       return;
  //     }

  //     final data = json.decode(message.toString());
  //     print('📊 Full message data: $data');
      
  //     // Check if it's an error response
  //     if (data['status'] == 'error') {
  //       final errorMsg = data['message'] ?? 'Unknown error';
  //       print('❌ Server error: $errorMsg');
  //       _handleError(errorMsg, showToUser: true);
  //       return;
  //     }
      
  //     // Check for success response format
  //     if (data['status'] == 'success' && data['event'] != null) {
  //       final event = data['event']?.toString();
  //       final responseData = data['data'];

  //       print('📊 Event: $event, Data: $responseData');

  //       // Note: Most events are now handled by streams
  //       // This is kept for backward compatibility and special cases
  //       switch (event) {
  //         case 'user:initial_data':
  //           print('✅ Initial data received');
  //           _handleSuccess('Connected to chat server');
  //           break;
  //         case 'chatroom:created':
  //           _handleChatroomCreated(responseData);
  //           break;
  //         case 'message:new':
  //           _handleNewMessage(responseData);
  //           break;
  //         case 'message:sent':
  //           _handleMessageSent(responseData);
  //           break;
  //         case 'user:online_status':
  //           _handleOnlineStatus(responseData);
  //           break;
  //         default:
  //           print('ℹ️ Event $event handled by stream');
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     print('❌ Message processing error: $e');
  //     print('Stack trace: $stackTrace');
  //   }
  // }

  // Legacy handlers (kept for events not handled by streams)
  void _handleChatRooms(dynamic data) {
    // This is now handled by stream, but kept for compatibility
    _handleChatRoomsFromStream(data is Map<String, dynamic> ? data : {'chatrooms': data});
  }

  void _handleChatroomCreated(dynamic data) {
    try {
      print('📊 Processing chatroom created data: $data');
      
      if (data == null) {
        _handleError('Invalid chatroom data received', showToUser: false);
        return;
      }

      final newRoom = UserChatRoom.fromJson(data);
      print('🆕 New chatroom created: ${newRoom.id} with ${newRoom.otherUserName}');
      
      final existingIndex = _chatRooms.indexWhere((room) => room.id == newRoom.id);
      
      if (existingIndex != -1) {
        _chatRooms[existingIndex] = newRoom;
      } else {
        _chatRooms.insert(0, newRoom);
      }
      
      _currentChatroomId = newRoom.id;
      _handleSuccess('Chat room created successfully');
      
      // Load messages for new chatroom
      loadMessages(newRoom.id);
    } catch (e, stackTrace) {
      print('❌ Chatroom created error: $e');
      print('Stack trace: $stackTrace');
      _handleError(
        'Failed to create chat room',
        showToUser: true,
        exception: e
      );
    }
  }

  void _handleMessages(dynamic data) {
    // This is now handled by stream, but kept for compatibility
    _handleMessagesFromStream(data is Map<String, dynamic> ? data : {'messages': data});
  }

  void _handleNewMessage(dynamic data) {
    try {
      if (data == null) return;

      final newMessage = UserChatMessage.fromJson(data);
      print('💬 New message from ${newMessage.senderName}: ${newMessage.message}');
      
      if (newMessage.chatroomId == _currentChatroomId) {
        _messages.add(newMessage);
        notifyListeners();
      }
      
      // If this looks like an admin message, route to dedicated admin room
      if (_isAdminMessage(newMessage)) {
        _routeMessageToAdminRoom(newMessage);
      } else {
        _updateChatroomLastMessage(newMessage);
      }
    } catch (e, stackTrace) {
      print('❌ New message error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _handleMessageSent(dynamic data) {
    try {
      if (data == null) return;

      final sentMessage = UserChatMessage.fromJson(data);
      final exists = _messages.any((msg) => msg.id == sentMessage.id);
      if (!exists) {
        _messages.add(sentMessage);
        notifyListeners();
      }
      _updateChatroomLastMessage(sentMessage);
    } catch (e, stackTrace) {
      print('❌ Message sent error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _updateChatroomLastMessage(UserChatMessage message) {
    final roomIndex = _chatRooms.indexWhere((room) => room.id == message.chatroomId);
    if (roomIndex != -1) {
      final isCurrentChat = message.chatroomId == _currentChatroomId;
      // Do not increment unread count for messages sent by the current user
      final isFromCurrentUser = message.senderId == (_session.userId ?? 0);
      final newUnread = isCurrentChat
          ? 0
          : (isFromCurrentUser ? _chatRooms[roomIndex].unreadCount : _chatRooms[roomIndex].unreadCount + 1);

      _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
        lastMessage: message.message,
        lastMessageTime: message.createdAt,
        unreadCount: newUnread,
      );
      final room = _chatRooms.removeAt(roomIndex);
      _chatRooms.insert(0, room);
      notifyListeners();
    }
  }

  void _handleSearchResults(dynamic data) {
    // This is now handled by stream, but kept for compatibility
    _handleSearchResultsFromStream(data is Map<String, dynamic> ? data : {'users': data});
  }

  void _handleOnlineStatus(dynamic data) {
    try {
      if (data == null) return;

      final int? userId = data['user_id'];
      final bool isOnline = data['is_online'] ?? false;
      final String? status = data['status'];
      
      if (userId == null) return;

      for (int i = 0; i < _chatRooms.length; i++) {
        if (_chatRooms[i].otherUserId == userId) {
          _chatRooms[i] = _chatRooms[i].copyWith(isOnline: isOnline, status: status);
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // Create or ensure the admin room exists in the local list
  void _ensureAdminRoomExists() {
    try {
      final idx = _chatRooms.indexWhere((r) => r.id == _kAdminRoomId);
      if (idx == -1) {
        final adminRoom = UserChatRoom(
          id: _kAdminRoomId,
          userId: _session.userId ?? 0,
          otherUserId: 0,
          otherUserName: 'Dark party Admin',
          otherUserUsername: 'dark_party_admin',
          otherUserProfileUrl: 'assets/images/app_logo.jpeg',
          lastMessage: null,
          lastMessageTime: null,
          unreadCount: 0,
          isOnline: false,
        );
        _chatRooms.insert(0, adminRoom);
      } else if (idx > 0) {
        // Move to top
        final room = _chatRooms.removeAt(idx);
        _chatRooms.insert(0, room);
      }
    } catch (e) {
      print('❌ _ensureAdminRoomExists error: $e');
    }
  }

  bool _isAdminMessage(UserChatMessage msg) {
    try {
      final name = msg.senderName.toLowerCase();
      final username = msg.senderUsername.toLowerCase();
      if (name.contains('admin') || username.contains('admin')) return true;
      if (name.contains('dark') || username.contains('dark')) return true;
      // If senderId is 0 or negative, consider system/admin
      if ((msg.senderId ?? 0) <= 0) return true;
    } catch (e) {
      // ignore
    }
    return false;
  }

  void _routeMessageToAdminRoom(UserChatMessage message) {
    try {
      final idx = _chatRooms.indexWhere((r) => r.id == _kAdminRoomId);
      if (idx == -1) {
        _ensureAdminRoomExists();
      }

      final adminIndex = _chatRooms.indexWhere((r) => r.id == _kAdminRoomId);
      if (adminIndex != -1) {
        // If admin chat is currently open, append to messages list for immediate display
        if (_currentChatroomId == _kAdminRoomId) {
          final exists = _messages.any((m) => m.id == message.id);
          if (!exists) {
            _messages.add(message);
            // keep messages sorted by createdAt
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }
        }
        final isCurrent = _currentChatroomId == _kAdminRoomId;
        final fromCurrentUser = message.senderId == (_session.userId ?? 0);
        final newUnread = isCurrent ? 0 : (fromCurrentUser ? _chatRooms[adminIndex].unreadCount : _chatRooms[adminIndex].unreadCount + 1);

        _chatRooms[adminIndex] = _chatRooms[adminIndex].copyWith(
          lastMessage: message.message,
          lastMessageTime: message.createdAt,
          unreadCount: newUnread,
        );

        final room = _chatRooms.removeAt(adminIndex);
        _chatRooms.insert(0, room);
        notifyListeners();
      }
    } catch (e) {
      print('❌ _routeMessageToAdminRoom error: $e');
    }
  }

  // Fetch admin messages via API and attach them to the admin room (used after chatrooms load)
  Future<void> _loadAdminMessagesToAdminRoom() async {
    try {
      if (!_session.isInitialized || _session.userId == null) return;
      final adminMsgs = await ApiManager.getAdminMessages(_session.userId!);
      if (adminMsgs.isEmpty) return;

      // Convert AdminMessage to UserChatMessage and compute last message/time
      final converted = adminMsgs.map((am) {
        return UserChatMessage(
          id: am.id ?? 0,
          chatroomId: _kAdminRoomId,
          senderId: 0,
          senderName: 'Dark party Admin',
          senderUsername: 'dark_party_admin',
          senderProfileUrl: 'assets/images/app_logo.jpeg',
          message: am.content ?? '',
          attachmentUrl: null,
          attachmentType: null,
          createdAt: am.createdAt ?? DateTime.now(),
          isRead: false,
        );
      }).toList();

      // Ensure admin room exists
      _ensureAdminRoomExists();
      final adminIndex = _chatRooms.indexWhere((r) => r.id == _kAdminRoomId);
      if (adminIndex != -1) {
        final last = converted.isNotEmpty ? converted.last : null;
        _chatRooms[adminIndex] = _chatRooms[adminIndex].copyWith(
          lastMessage: last?.message,
          lastMessageTime: last?.createdAt,
          unreadCount: last != null ? converted.length : 0,
        );
        // Keep admin room at top
        final room = _chatRooms.removeAt(adminIndex);
        _chatRooms.insert(0, room);
        notifyListeners();
      }
    } catch (e) {
      print('❌ _loadAdminMessagesToAdminRoom error: $e');
    }
  }

  // When admin room is opened, load messages into _messages for display
  Future<void> _loadAdminMessagesForOpenRoom() async {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        _handleError('User not logged in', showToUser: true);
        return;
      }
      final adminMsgs = await ApiManager.getAdminMessages(_session.userId!);
      final converted = adminMsgs.map((am) {
        return UserChatMessage(
          id: am.id ?? 0,
          chatroomId: _kAdminRoomId,
          senderId: 0,
          senderName: 'Dark party Admin',
          senderUsername: 'dark_party_admin',
          senderProfileUrl: 'assets/images/app_logo.jpeg',
          message: am.content ?? '',
          attachmentUrl: null,
          attachmentType: null,
          createdAt: am.createdAt ?? DateTime.now(),
          isRead: false,
        );
      }).toList();

      _messages = converted.toList();
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('❌ _loadAdminMessagesForOpenRoom error: $e');
      _isLoading = false;
      _error = 'Failed to load admin messages';
      notifyListeners();
    }
  }

  // Enhanced error handling
  void _handleError(String errorMessage, {bool showToUser = false, dynamic exception}) {
    print('❌ Error: $errorMessage');
    if (exception != null) {
      print('Exception: $exception');
    }
    
    if (showToUser) {
      _error = errorMessage;
    }
    
    _isLoading = false;
    _isSearching = false;
    notifyListeners();
  }

  void _handleSuccess(String message) {
    print('✅ Success: $message');
    _error = null;
    _isLoading = false;
    _isSearching = false;
    notifyListeners();
  }

  Future<void> getChatRooms() async {
    try {
      print('📥 Fetching chat rooms for user ${_session.userId}...');

      // Try load cached chat rooms first to avoid a blank loading screen
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_chat_rooms_v1_${_session.userId}';
      final cachedJson = prefs.getString(cacheKey);
      var hadCache = false;
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final List decoded = json.decode(cachedJson) as List;
          _chatRooms = decoded.map((e) => UserChatRoom.fromJson(Map<String, dynamic>.from(e))).toList();
          // sort and ensure admin room
          _chatRooms.sort((a, b) {
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          _ensureAdminRoomExists();
          _isLoading = false;
          _error = null;
          notifyListeners();
          hadCache = true;
          print('✅ Loaded ${_chatRooms.length} chat rooms from cache');
        } catch (e) {
          print('⚠️ Failed to parse cached chat rooms: $e');
        }
      }

      // If no cache, show loading indicator while fetching
      if (!hadCache) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }
      
      // Call WebSocket (may return "Invalid message format" — we rely on HTTP for list)
      _websocket.getChatRooms(_session.userId!);

      // Load chat list via HTTP immediately so user sees list or empty state quickly
      Future.microtask(() async {
        if (_chatRooms.isEmpty && _error == null) {
          try {
            final List<ChatRoom> rooms = await ApiManager.getUserChatRooms(_session.userId!);
            if (rooms.isNotEmpty) {
              final currentUserId = _session.userId!;
              _chatRooms = rooms.map((cr) => UserChatRoom(
                id: cr.id,
                userId: currentUserId,
                otherUserId: cr.getOtherUserId(currentUserId),
                otherUserName: cr.getOtherUserName(currentUserId),
                otherUserUsername: '',
                otherUserProfileUrl: null,
                lastMessage: cr.lastMessage?.message,
                lastMessageTime: cr.lastActivity,
                unreadCount: cr.unreadCount,
                isOnline: false,
                status: null,
              )).toList();
              _isLoading = false;
              _error = null;
              _ensureAdminRoomExists();
              try {
                final cacheKey = 'cached_chat_rooms_v1_${_session.userId}';
                prefs.setString(cacheKey, json.encode(_chatRooms.map((r) => r.toJson()).toList()));
              } catch (_) {}
              notifyListeners();
              print('✅ Loaded ${_chatRooms.length} chat rooms via HTTP getUserChatRooms');
            } else {
              _isLoading = false;
              _error = null;
              _ensureAdminRoomExists();
              notifyListeners();
              print('✅ Chat list loaded (0 rooms) via HTTP');
            }
          } catch (e) {
            print('⚠️ Early getUserChatRooms: $e');
          }
        }
      });

      // Set timeout to check if response received
      Future.delayed(Duration(seconds: 5), () {
        if (_isLoading && _chatRooms.isEmpty && _error == null) {
          print('⚠️ No response from server after 5s, retrying via websocket...');
          _retryGetChatRooms();

          // After retry, if still empty, fall back to HTTP API to fetch conversations
          Future.delayed(Duration(seconds: 3), () async {
            if (_chatRooms.isEmpty && _error == null) {
              try {
                print('ℹ️ WebSocket empty — falling back to HTTP getConversations');
                final conv = await ApiManager.getConversations(userId: _session.userId!);
                if (conv != null && conv.isNotEmpty) {
                  _chatRooms = conv.map((e) {
                    Map<String, dynamic> raw;
                    if (e is Map<String, dynamic>) {
                      raw = e;
                    } else if (e is String) {
                      raw = json.decode(e) as Map<String, dynamic>;
                    } else {
                      raw = Map<String, dynamic>.from(e);
                    }

                    // Debug: show raw conversation payload
                    print('🔍 Raw conversation payload: $raw');

                    // Create room defensively
                    var room = UserChatRoom.fromJson(raw);

                    // If parsed id is missing or zero, try to extract from common alternative keys
                    if (room.id <= 0) {
                      final altKeys = ['id', 'chatroom_id', 'room_id', 'conversation_id', 'chat_id', 'chatroomId'];
                      for (var k in altKeys) {
                        if (raw.containsKey(k) && raw[k] != null) {
                          try {
                            final parsed = int.tryParse(raw[k].toString());
                            if (parsed != null && parsed > 0) {
                              room = room.copyWith(id: parsed);
                              break;
                            }
                          } catch (_) {}
                        }
                      }
                    }

                    // If otherUserId missing, try to derive from common pairs (user1_id/user2_id)
                    if (room.otherUserId <= 0) {
                      try {
                        final keysToCheck = ['other_user_id', 'user2_id', 'user1_id', 'user_id', 'sender_id', 'receiver_id'];
                        int? candidateOther;
                        int? candidateUser1;
                        int? candidateUser2;

                        if (raw.containsKey('user1_id')) candidateUser1 = int.tryParse(raw['user1_id'].toString());
                        if (raw.containsKey('user2_id')) candidateUser2 = int.tryParse(raw['user2_id'].toString());

                        final myId = _session.userId;
                        if (candidateUser1 != null && candidateUser2 != null && myId != null) {
                          if (candidateUser1 == myId) {
                            candidateOther = candidateUser2;
                          } else if (candidateUser2 == myId) candidateOther = candidateUser1;
                        }

                        // fallback to other_user_id or sender/receiver fields
                        if (candidateOther == null) {
                          if (raw.containsKey('other_user_id')) candidateOther = int.tryParse(raw['other_user_id'].toString());
                          if (candidateOther == null && raw.containsKey('receiver_id')) candidateOther = int.tryParse(raw['receiver_id'].toString());
                          if (candidateOther == null && raw.containsKey('sender_id')) candidateOther = int.tryParse(raw['sender_id'].toString());

                          // Also check for nested user objects commonly returned by some APIs
                          final nestedKeys = ['other_user', 'other', 'user', 'participant'];
                          for (var nk in nestedKeys) {
                            if (candidateOther == null && raw.containsKey(nk) && raw[nk] is Map) {
                              final nested = Map<String, dynamic>.from(raw[nk]);
                              if (nested.containsKey('user_id')) candidateOther = int.tryParse(nested['user_id'].toString());
                              if (candidateOther == null && nested.containsKey('id')) candidateOther = int.tryParse(nested['id'].toString());
                              if (candidateOther == null && nested.containsKey('other_user_id')) candidateOther = int.tryParse(nested['other_user_id'].toString());
                              if (candidateOther == null && nested.containsKey('sender_id')) candidateOther = int.tryParse(nested['sender_id'].toString());
                              if (candidateOther == null && nested.containsKey('receiver_id')) candidateOther = int.tryParse(nested['receiver_id'].toString());
                            }
                          }
                        }

                        if (candidateOther != null && candidateOther > 0) {
                          room = room.copyWith(otherUserId: candidateOther);
                        }
                      } catch (_) {
                        // ignore
                      }
                    }

                    print('🔍 Parsed room => id: ${room.id}, otherUserId: ${room.otherUserId}, otherUserName: "${room.otherUserName}"');
                    return room;
                  }).toList();
                  _isLoading = false;
                  _error = null;
                  // Cache the fetched conversations for faster startup
                  try {
                    final cacheKey = 'cached_chat_rooms_v1_${_session.userId}';
                    final serial = json.encode(_chatRooms.map((r) => r.toJson()).toList());
                    prefs.setString(cacheKey, serial);
                    print('💾 Cached ${_chatRooms.length} chat rooms');
                  } catch (e) {
                    print('⚠️ Failed to cache chat rooms: $e');
                  }
                  // Ensure admin aggregate room exists at top
                  _ensureAdminRoomExists();
                  notifyListeners();
                  print('✅ Loaded ${_chatRooms.length} conversations via HTTP fallback');
                  return;
                }
                print('⚠️ HTTP getConversations returned no data');
              } catch (e) {
                print('❌ getConversations fallback error: $e');
              }
              // Fallback 2: use getUserChatRooms (User-to-User_Chat_API.php) and map to UserChatRoom
              if (_chatRooms.isEmpty && _error == null) {
                try {
                  print('ℹ️ Trying HTTP getUserChatRooms...');
                  final List<ChatRoom> rooms = await ApiManager.getUserChatRooms(_session.userId!);
                  if (rooms.isNotEmpty) {
                    final currentUserId = _session.userId!;
                    _chatRooms = rooms.map((cr) {
                      return UserChatRoom(
                        id: cr.id,
                        userId: currentUserId,
                        otherUserId: cr.getOtherUserId(currentUserId),
                        otherUserName: cr.getOtherUserName(currentUserId),
                        otherUserUsername: '',
                        otherUserProfileUrl: null,
                        lastMessage: cr.lastMessage?.message,
                        lastMessageTime: cr.lastActivity,
                        unreadCount: cr.unreadCount,
                        isOnline: false,
                        status: null,
                      );
                    }).toList();
                    _isLoading = false;
                    _error = null;
                    _ensureAdminRoomExists();
                    try {
                      final cacheKey = 'cached_chat_rooms_v1_${_session.userId}';
                      final serial = json.encode(_chatRooms.map((r) => r.toJson()).toList());
                      prefs.setString(cacheKey, serial);
                    } catch (_) {}
                    notifyListeners();
                    print('✅ Loaded ${_chatRooms.length} chat rooms via getUserChatRooms');
                    return;
                  }
                } catch (e) {
                  print('❌ getUserChatRooms fallback error: $e');
                }
              }
            }
          });
        }
      });
      
    } catch (e, stackTrace) {
      print('❌ Get chat rooms error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to get chat rooms', showToUser: true, exception: e);
    }
  }

  void _retryGetChatRooms() {
    if (!_websocket.isConnected) {
      print('🔁 Reconnecting WebSocket...');
      reconnect();
      return;
    }
    
    print('🔄 Retrying getChatRooms...');
    _websocket.getChatRooms(_session.userId!);
  }

  // Public methods
  Future<UserChatRoom?> createChatroom(int otherUserId) async {
    try {
      if (!_session.isInitialized) {
        _handleError('User not logged in', showToUser: true);
        return null;
      }

      if (_session.userId == null) {
        _handleError('User ID not found', showToUser: true);
        return null;
      }

      if (otherUserId <= 0) {
        _handleError('Invalid user selected', showToUser: true);
        return null;
      }

      print('🆕 Creating chatroom with user: $otherUserId');
      _isLoading = true;
      notifyListeners();

      // Prefer WebSocket when available for real-time behavior
      if (_websocket.isConnected) {
        _websocket.createChatroom(_session.userId!, otherUserId);

        // Wait briefly for websocket to report new room; if it appears in our local list return it
        await Future.delayed(const Duration(seconds: 6));

        final existingList = _chatRooms.where((r) => r.otherUserId == otherUserId).toList();
        if (existingList.isNotEmpty) {
          final existing = existingList.first;
          print('✅ Chatroom created via WebSocket');
          _isLoading = false;
          notifyListeners();
          return existing;
        }

        // WebSocket did not produce a chatroom -> fall back to HTTP
        print('⚠️ No chatroom response via WebSocket, falling back to HTTP createChatroom');
      }

      // Use HTTP createChatroom and navigate immediately using returned chatroom id
      print('ℹ️ Creating chatroom via HTTP');
      final resp = await ApiManager.createChatroom(_session.userId!, otherUserId);
      if (resp.success) {
        print('✅ Chatroom created via HTTP: ${resp.message}');

        try {
          final data = resp.data;
          if (data is Map<String, dynamic>) {
            final createdId = data['id'] is int
                ? data['id'] as int
                : int.tryParse((data['id'] ?? '').toString()) ?? 0;

            // Try multiple places for user info (backend may return different shapes)
            String otherName = '';
            String otherUsername = '';
            String? profileUrl;

            // Common keys
            if (data['other_user_name'] != null) otherName = data['other_user_name'].toString();
            if (data['other_user_username'] != null) otherUsername = data['other_user_username'].toString();
            if (data['other_user_profile_url'] != null) profileUrl = data['other_user_profile_url']?.toString();

            // Fallbacks: nested objects
            final candidateKeys = ['other_user', 'user', 'user_info', 'participant', 'receiver', 'other'];
            for (var key in candidateKeys) {
              if ((data[key] is Map) && (otherName.isEmpty || profileUrl == null)) {
                final m = Map<String, dynamic>.from(data[key] as Map);
                if (otherName.isEmpty) {
                  if (m['name'] != null) {
                    otherName = m['name'].toString();
                  } else if (m['username'] != null) otherName = m['username'].toString();
                }
                if (otherUsername.isEmpty && m['username'] != null) otherUsername = m['username'].toString();
                if (profileUrl == null && (m['profile_url'] != null || m['avatar'] != null || m['picture'] != null)) {
                  profileUrl = (m['profile_url'] ?? m['avatar'] ?? m['picture'])?.toString();
                }
              }
            }

            // If profileUrl is a relative path, prepend base URL
            if (profileUrl != null && profileUrl.isNotEmpty && !profileUrl.startsWith('http')) {
              try {
                profileUrl = ApiConstants.baseUrl + profileUrl.replaceFirst(RegExp(r'^/'), '');
              } catch (_) {}
            }

            // If we still don't have a name or profile, fetch user info by id
            if ((otherName.isEmpty || profileUrl == null || profileUrl.isEmpty)) {
              try {
                final ui = await ApiManager.getUserInfoById(otherUserId);
                if (ui != null) {
                  if (otherName.isEmpty) {
                    otherName = ui['name']?.toString() ?? ui['username']?.toString() ?? otherName;
                  }
                  if (otherUsername.isEmpty) {
                    otherUsername = ui['username']?.toString() ?? otherUsername;
                  }
                  if ((profileUrl == null || profileUrl.isEmpty) && ui['profile_url'] != null) {
                    profileUrl = ui['profile_url']?.toString();
                    if (profileUrl != null && profileUrl.isNotEmpty && !profileUrl.startsWith('http')) {
                      profileUrl = ApiConstants.baseUrl + profileUrl.replaceFirst(RegExp(r'^/'), '');
                    }
                  }
                }
              } catch (e) {
                print('⚠️ getUserInfoById fallback failed: $e');
              }
            }

            // Construct minimal UserChatRoom so UI can navigate immediately
            final room = UserChatRoom(
              id: createdId,
              userId: _session.userId ?? 0,
              otherUserId: otherUserId,
              otherUserName: otherName,
              otherUserUsername: otherUsername,
              otherUserProfileUrl: profileUrl,
            );

            // Add to local list so future lookups find it
            _chatRooms.insert(0, room);
            _isLoading = false;
            notifyListeners();
            return room;
          }
        } catch (e) {
          print('❌ Failed to construct chatroom from response: $e');
        }

        // If data shape unexpected, still stop loading and return null
        _isLoading = false;
        notifyListeners();
        return null;
      } else {
        _handleError('Failed to create chatroom: ${resp.message}', showToUser: true);
      }
    } catch (e, stackTrace) {
      print('❌ Create chatroom error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to create chat room', showToUser: true, exception: e);
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> setCurrentChatroom(int chatroomId) async {
    try {
      if (chatroomId <= 0) {
        _handleError('Invalid chat room', showToUser: true);
        return;
      }

      print('💬 Setting current chatroom: $chatroomId');
      _currentChatroomId = chatroomId;
      // Preserve any locally-created unsent messages for this chatroom (id==0)
      final pending = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();

      // Attempt to load cached messages for this chatroom so UI appears instantly
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'cached_messages_chat_v1_$chatroomId';
        final cached = prefs.getString(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          try {
            final List decoded = json.decode(cached) as List;
            final restored = decoded.map((e) {
              if (e is Map<String, dynamic>) return UserChatMessage.fromJson(e);
              if (e is String) return UserChatMessage.fromJson(json.decode(e));
              return UserChatMessage.fromJson(Map<String, dynamic>.from(e));
            }).toList();
            // Keep pending unsent messages at the end
            _messages = [];
            _messages.addAll(restored);
            _messages.addAll(pending);
            _isLoading = false; // show messages immediately
            _error = null;
            notifyListeners();
            print('✅ Loaded ${_messages.length} cached messages for chat $chatroomId');
          } catch (e) {
            print('⚠️ Failed to parse cached messages for chat $chatroomId: $e');
          }
        } else {
          // no cache — show pending only
          _messages = List<UserChatMessage>.from(pending);
          notifyListeners();
        }
      } catch (e) {
        print('⚠️ Error reading message cache: $e');
        _messages = List<UserChatMessage>.from(pending);
        notifyListeners();
      }

      // Kick off network load to refresh messages
      loadMessages(chatroomId);
      markAsRead(chatroomId);
    } catch (e, stackTrace) {
      print('❌ Set chatroom error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to set current chatroom', showToUser: true, exception: e);
    }
  }

  void loadMessages(int chatroomId) {
    try {
      if (!_session.isInitialized) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      if (_session.userId == null) {
        _handleError('User ID not found', showToUser: true);
        return;
      }

      if (chatroomId <= 0) {
        _handleError('Invalid chat room', showToUser: true);
        return;
      }

      print('📬 Loading messages for chatroom: $chatroomId');
      _isLoading = true;
      notifyListeners();

      // Special-case: admin aggregate room uses Admin API
      if (chatroomId == _kAdminRoomId) {
        _loadAdminMessagesForOpenRoom();
        return;
      }

      _websocket.getMessages(_session.userId!, chatroomId);

      // If websocket does not return messages within timeout, fallback to HTTP
      Future.delayed(const Duration(seconds: 2), () async {
        if (_messages.isEmpty && _isLoading) {
          try {
            // 1) Try by user pair first — get_conversation_messages.php often uses user_id + other_user_id
            UserChatRoom? room;
            for (final r in _chatRooms) {
              if (r.id == chatroomId) {
                room = r;
                break;
              }
            }
            if (room != null && room.otherUserId > 0) {
              print('ℹ️ Trying getConversationMessages by user pair (other_user_id=${room.otherUserId})');
              final msgsByUser = await ApiManager.getConversationMessages(userId: _session.userId, otherUserId: room.otherUserId);
              if (msgsByUser != null && msgsByUser.isNotEmpty) {
                print('📥 getConversationMessages (by users) returned ${msgsByUser.length} items');
                final fetched = msgsByUser.map((m) {
                  final raw = m is Map<String, dynamic> ? m : (m is String ? json.decode(m) as Map<String, dynamic> : Map<String, dynamic>.from(m));
                  final map = Map<String, dynamic>.from(raw);
                  // Normalize for get_conversation_messages API (may use user_id, from_user_id, etc.)
                  map['chatroom_id'] = chatroomId;
                  if (!map.containsKey('sender_id') && map.containsKey('user_id')) map['sender_id'] = map['user_id'];
                  if (!map.containsKey('sender_id') && map.containsKey('from_user_id')) map['sender_id'] = map['from_user_id'];
                  final msg = UserChatMessage.fromJson(map);
                  return msg.chatroomId == chatroomId ? msg : UserChatMessage(
                    id: msg.id,
                    chatroomId: chatroomId,
                    senderId: msg.senderId,
                    senderName: msg.senderName,
                    senderUsername: msg.senderUsername,
                    senderProfileUrl: msg.senderProfileUrl,
                    message: msg.message,
                    attachmentUrl: msg.attachmentUrl,
                    attachmentType: msg.attachmentType,
                    createdAt: msg.createdAt,
                    isRead: msg.isRead,
                  );
                }).toList();
                final pendingLocal = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();
                final merged = <UserChatMessage>[];
                merged.addAll(fetched);
                for (var p in pendingLocal) {
                  final exists = merged.any((fm) => fm.message.trim() == p.message.trim() && (fm.createdAt.difference(p.createdAt).inSeconds).abs() < 5);
                  if (!exists) merged.add(p);
                }
                _messages = merged;
                _error = null;
                _isLoading = false;
                notifyListeners();
                try {
                  final prefs = await SharedPreferences.getInstance();
                  final cacheKey = 'cached_messages_chat_v1_$chatroomId';
                  final serial = json.encode(_messages.map((m) => m.toJson()).toList());
                  prefs.setString(cacheKey, serial);
                  print('💾 Cached ${_messages.length} messages for chat $chatroomId (user-pair)');
                } catch (e) {
                  print('⚠️ Failed to cache messages: $e');
                }
                print('✅ Loaded ${_messages.length} messages via getConversationMessages (user pair)');
                return;
              }
            }

            print('ℹ️ WebSocket messages empty — falling back to HTTP getConversationMessages (conversation_id)');
            final msgs = await ApiManager.getConversationMessages(conversationId: chatroomId, userId: _session.userId);
            if (msgs != null && msgs.isNotEmpty) {
              print('📥 getConversationMessages returned ${msgs.length} items');
              final fetched = msgs.map((m) {
                if (m is Map<String, dynamic>) return UserChatMessage.fromJson(m);
                if (m is String) return UserChatMessage.fromJson(json.decode(m));
                return UserChatMessage.fromJson(Map<String, dynamic>.from(m));
              }).toList();
              // Merge fetched messages with any existing local pending messages (id==0)
              final pendingLocal = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();
              final merged = <UserChatMessage>[];
              merged.addAll(fetched);
              for (var p in pendingLocal) {
                final exists = merged.any((fm) => fm.message.trim() == p.message.trim() && (fm.createdAt.difference(p.createdAt).inSeconds).abs() < 5);
                if (!exists) merged.add(p);
              }
              _messages = merged;
              _error = null;
              _isLoading = false;
              notifyListeners();
              // Cache messages fetched from HTTP
              try {
                final prefs = await SharedPreferences.getInstance();
                final cacheKey = 'cached_messages_chat_v1_$chatroomId';
                final serial = json.encode(_messages.map((m) => m.toJson()).toList());
                prefs.setString(cacheKey, serial);
                print('💾 Cached ${_messages.length} messages for chat $chatroomId (HTTP)');
              } catch (e) {
                print('⚠️ Failed to cache messages after HTTP fetch: $e');
              }
              print('✅ Loaded ${_messages.length} messages via HTTP fallback (getConversationMessages)');
              return;
            }
            print('⚠️ HTTP getConversationMessages returned no data — trying /get_conversations.php');

            // Try alternative endpoint: getConversations and extract messages for this chatroom
            try {
              final convs = await ApiManager.getConversations(userId: _session.userId!);
              if (convs != null && convs.isNotEmpty) {
                print('📥 getConversations returned ${convs.length} conversations');
                // Find conversation matching chatroomId
                Map<String, dynamic>? matched;
                for (var c in convs) {
                  Map<String, dynamic> raw;
                  if (c is Map<String, dynamic>) {
                    raw = c;
                  } else if (c is String) raw = json.decode(c) as Map<String, dynamic>;
                  else raw = Map<String, dynamic>.from(c);

                  // Check common id keys
                  final idCandidates = [raw['conversation_id'], raw['conversationId'], raw['id'], raw['chatroom_id'], raw['chatroomId'], raw['conversation_id']];
                  for (var cand in idCandidates) {
                    if (cand == null) continue;
                    try {
                      if (int.tryParse(cand.toString()) == chatroomId) {
                        matched = raw;
                        break;
                      }
                    } catch (_) {}
                  }
                  if (matched != null) break;
                }

                if (matched != null) {
                  print('🔍 Found conversation in getConversations for chatroom=$chatroomId: $matched');
                  // Look for messages array in multiple possible keys
                  final possibleKeys = ['messages', 'conversation_messages', 'messages_list', 'chat_messages', 'data'];
                  List<dynamic>? rawMsgs;
                  for (var k in possibleKeys) {
                    if (matched.containsKey(k) && matched[k] is List) {
                      rawMsgs = List<dynamic>.from(matched[k]);
                      break;
                    }
                  }
                  // As a fallback, inspect nested 'data' -> 'messages'
                  if (rawMsgs == null && matched.containsKey('data') && matched['data'] is Map && (matched['data'] as Map).containsKey('messages')) {
                    rawMsgs = List<dynamic>.from((matched['data'] as Map)['messages']);
                  }

                  // If no messages field present, try using /get_conversation_messages.php with user_id + other_user_id
                  if ((rawMsgs == null || rawMsgs.isEmpty) && matched.containsKey('other_user')) {
                    try {
                      final other = matched['other_user'];
                      int? otherId;
                      if (other is Map) {
                        otherId = int.tryParse((other['user_id'] ?? other['id'])?.toString() ?? '0');
                      } else {
                        otherId = int.tryParse(other?.toString() ?? '0');
                      }
                      if (otherId != null && otherId > 0) {
                        print('📤 Trying getConversationMessages with user_id=${_session.userId} & other_user_id=$otherId');
                        final msgs2 = await ApiManager.getConversationMessages(userId: _session.userId, otherUserId: otherId);
                        if (msgs2 != null && msgs2.isNotEmpty) {
                          print('📥 getConversationMessages (by users) returned ${msgs2.length} items');
                          final fetched = msgs2.map((m) {
                            if (m is Map<String, dynamic>) return UserChatMessage.fromJson(m);
                            if (m is String) return UserChatMessage.fromJson(json.decode(m));
                            return UserChatMessage.fromJson(Map<String, dynamic>.from(m));
                          }).toList();
                          final pendingLocal = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();
                          final merged = <UserChatMessage>[];
                          merged.addAll(fetched);
                          for (var p in pendingLocal) {
                            final exists = merged.any((fm) => fm.message.trim() == p.message.trim() && (fm.createdAt.difference(p.createdAt).inSeconds).abs() < 5);
                            if (!exists) merged.add(p);
                          }
                          _messages = merged;
                          _error = null;
                          _isLoading = false;
                          notifyListeners();
                          print('✅ Loaded ${_messages.length} messages via HTTP fallback (getConversationMessages by users)');
                          return;
                        } else {
                          print('⚠️ getConversationMessages (by users) returned no messages');
                        }
                      }
                    } catch (e) {
                      print('❌ Error calling getConversationMessages by users: $e');
                    }
                  }

                  if (rawMsgs != null && rawMsgs.isNotEmpty) {
                    print('📥 getConversations contained ${rawMsgs.length} messages for chatroom');
                    final fetched = rawMsgs.map((m) {
                      if (m is Map<String, dynamic>) return UserChatMessage.fromJson(m);
                      if (m is String) return UserChatMessage.fromJson(json.decode(m));
                      return UserChatMessage.fromJson(Map<String, dynamic>.from(m));
                    }).toList();
                    final pendingLocal = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();
                    final merged = <UserChatMessage>[];
                    merged.addAll(fetched);
                    for (var p in pendingLocal) {
                      final exists = merged.any((fm) => fm.message.trim() == p.message.trim() && (fm.createdAt.difference(p.createdAt).inSeconds).abs() < 5);
                      if (!exists) merged.add(p);
                    }
                    _messages = merged;
                    _error = null;
                    _isLoading = false;
                    notifyListeners();
                    print('✅ Loaded ${_messages.length} messages via HTTP fallback (getConversations)');
                    return;
                  } else {
                    print('⚠️ No messages field found in matched conversation');
                    // Try to construct a single message from `last_message` if available
                    if (matched.containsKey('last_message') && matched['last_message'] is Map) {
                      try {
                        final lm = Map<String, dynamic>.from(matched['last_message']);
                        print('🔎 Found last_message in conversation: $lm');
                        final msgId = lm['message_id'] is int ? lm['message_id'] : int.tryParse(lm['message_id']?.toString() ?? '0') ?? 0;
                        final msgText = lm['message']?.toString() ?? lm['text']?.toString() ?? '';
                        final createdAt = () {
                          try {
                            if (lm['created_at'] is String) return DateTime.parse(lm['created_at']);
                            if (lm['created_at'] is int) return DateTime.fromMillisecondsSinceEpoch(lm['created_at']);
                          } catch (_) {}
                          return DateTime.now();
                        }();

                        // Determine sender id from last_message fields if present (preferred)
                        int senderId = 0;
                        final possibleSenderKeys = ['sender_id', 'user_id', 'from_user_id', 'owner_id', 'created_by'];
                        for (var k in possibleSenderKeys) {
                          if (lm.containsKey(k) && lm[k] != null) {
                            senderId = int.tryParse(lm[k].toString()) ?? senderId;
                            if (senderId > 0) break;
                          }
                        }

                        // If still unknown, try nested sender object
                        if (senderId <= 0 && lm.containsKey('sender') && lm['sender'] is Map) {
                          final s = Map<String, dynamic>.from(lm['sender']);
                          senderId = int.tryParse((s['id'] ?? s['user_id'])?.toString() ?? '0') ?? senderId;
                        }

                        // Fallback to conversation's other_user if available
                        if (senderId <= 0 && matched.containsKey('other_user') && matched['other_user'] is Map) {
                          senderId = int.tryParse((matched['other_user']['user_id'] ?? matched['other_user']['id'])?.toString() ?? '0') ?? senderId;
                        }

                        // Prepare sender display fields depending on whether sender is current user
                        String senderName = '';
                        String senderUsername = '';
                        String? senderProfileUrl;
                        if (senderId == _session.userId) {
                          senderName = _session.username ?? '';
                          senderUsername = _session.username ?? '';
                          senderProfileUrl = _session.profileUrl;
                        } else if (matched.containsKey('other_user') && matched['other_user'] is Map) {
                          final other = Map<String, dynamic>.from(matched['other_user']);
                          senderName = (other['name']?.toString() ?? other['user_name']?.toString() ?? other['username']?.toString() ?? '');
                          senderUsername = (other['username']?.toString() ?? other['user_name']?.toString() ?? '');
                          senderProfileUrl = (other['profile_url']?.toString());
                        }

                        final constructed = UserChatMessage(
                          id: msgId,
                          chatroomId: chatroomId,
                          senderId: senderId,
                          senderName: senderName,
                          senderUsername: senderUsername,
                          senderProfileUrl: senderProfileUrl,
                          message: msgText,
                          createdAt: createdAt,
                          isRead: true,
                        );
                        final pendingLocal = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();
                        final merged = <UserChatMessage>[];
                        merged.add(constructed);
                        for (var p in pendingLocal) {
                          final exists = merged.any((fm) => fm.message.trim() == p.message.trim() && (fm.createdAt.difference(p.createdAt).inSeconds).abs() < 5);
                          if (!exists) merged.add(p);
                        }
                        _messages = merged;
                        _error = null;
                        _isLoading = false;
                        notifyListeners();
                        print('✅ Constructed message from last_message and loaded ${_messages.length} messages');
                        return;
                      } catch (e) {
                        print('❌ Error constructing message from last_message: $e');
                      }
                    }
                  }
                } else {
                  print('⚠️ No matching conversation found in getConversations for chatroom=$chatroomId');
                }
              } else {
                print('⚠️ getConversations returned empty');
              }
            } catch (e) {
              print('❌ getConversations fallback error: $e');
            }

            // Last resort: User-to-User_Chat_API.php action=get_messages (same backend as chatrooms)
            try {
              final chatMessages = await ApiManager.getUserMessages(chatroomId, userId: _session.userId);
              if (chatMessages.isNotEmpty) {
                final fetched = chatMessages.map((cm) => UserChatMessage(
                  id: cm.id,
                  chatroomId: cm.chatroomId,
                  senderId: cm.senderId,
                  senderName: cm.senderName,
                  senderUsername: '',
                  senderProfileUrl: null,
                  message: cm.message,
                  attachmentUrl: cm.filePath.isNotEmpty ? cm.filePath : null,
                  attachmentType: cm.messageType,
                  createdAt: cm.createdAt,
                  isRead: true,
                )).toList();
                final pendingLocal = _messages.where((m) => m.id == 0 && m.chatroomId == chatroomId).toList();
                final merged = <UserChatMessage>[];
                merged.addAll(fetched);
                for (var p in pendingLocal) {
                  final exists = merged.any((fm) => fm.message.trim() == p.message.trim() && (fm.createdAt.difference(p.createdAt).inSeconds).abs() < 5);
                  if (!exists) merged.add(p);
                }
                _messages = merged;
                _error = null;
                _isLoading = false;
                notifyListeners();
                print('✅ Loaded ${_messages.length} messages via HTTP getUserMessages (User-to-User_Chat_API)');
                return;
              }
            } catch (e) {
              print('❌ getUserMessages fallback error: $e');
            }
          } catch (e) {
            print('❌ getConversationMessages fallback error: $e');
          }

          // Nothing returned — stop loading spinner
          _isLoading = false;
          notifyListeners();
        }
      });
    } catch (e, stackTrace) {
      print('❌ Load messages error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to load messages', showToUser: true, exception: e);
    }
  }

  Future<bool> sendChatMessage(String messageText) async {
    try {
      if (!_session.isInitialized) {
        _handleError('User not logged in', showToUser: true);
        return false;
      }

      if (_session.userId == null) {
        _handleError('User ID not found', showToUser: true);
        return false;
      }

      if (_currentChatroomId == null) {
        _handleError('No chat room selected', showToUser: true);
        return false;
      }

      final trimmedText = messageText.trim();
      if (trimmedText.isEmpty) {
        _handleError('Message cannot be empty', showToUser: true);
        return false;
      }

      // Do not block sending if WebSocket is disconnected; we'll fallback to HTTP below.

      print('💬 Sending message: $trimmedText');

      // Try WebSocket first
      var wsSent = false;
      try {
        if (_websocket.isConnected) {
          _websocket.sendMessage(_session.userId!, _currentChatroomId!, trimmedText);
          wsSent = true;
        } else {
          wsSent = false;
        }
      } catch (e) {
        print('❌ WebSocket send threw: $e');
        wsSent = false;
      }

      // Wait briefly for server ack via messages stream
      if (wsSent) {
        final start = DateTime.now();
        final timeout = Duration(seconds: 4);
        while (DateTime.now().difference(start) < timeout) {
          // Check if messages list contains the sent message (server echoed)
          final found = _messages.any((m) => m.senderId == _session.userId && m.message.trim() == trimmedText && DateTime.now().difference(m.createdAt).inSeconds < 30 && m.chatroomId == _currentChatroomId);
          if (found) {
            print('✅ Message acknowledged via WebSocket');
            return true;
          }
          // sleep briefly
          await Future.delayed(const Duration(milliseconds: 300));
        }
        print('⚠️ No WebSocket ack received within timeout');
      }

      // Fallback to HTTP send
      try {
        // Determine recipient id from current chatroom
        UserChatRoom? room;
        for (var r in _chatRooms) {
          if (r.id == _currentChatroomId || r.id.toString() == _currentChatroomId.toString()) {
            room = r;
            break;
          }
        }
        print('🔍 Lookup for chatroom=$_currentChatroomId found room: ${room != null ? 'id=${room.id}, otherUserId=${room.otherUserId}, otherUserName=${room.otherUserName}' : 'none'}');
        int toUserId = 0;
        if (room != null) {
          toUserId = room.otherUserId;
        }

        // If room.otherUserId is not available, attempt to infer recipient from recent messages in this chatroom
        if (toUserId <= 0) {
          for (var m in _messages.reversed) {
            if (m.chatroomId == _currentChatroomId) {
              // If message sender is not current user, they are the other participant
              if (m.senderId != _session.userId && m.senderId > 0) {
                toUserId = m.senderId;
                print('🔎 Inferred recipient from messages: $toUserId');
                break;
              }
            }
          }
        }

        if (toUserId <= 0) {
          print('❌ Could not determine recipient for HTTP fallback');
          _handleError('Unable to send message (recipient unknown)', showToUser: true);
          return false;
        }

        final ok = await ApiManager.sendChatMessage(fromUserId: _session.userId!, toUserId: toUserId, message: trimmedText);
        if (ok) {
          // Append locally so UI updates immediately
          final localMsg = UserChatMessage(
            id: 0,
            chatroomId: _currentChatroomId!,
            senderId: _session.userId!,
            senderName: _session.username ?? '',
            senderUsername: _session.username ?? '',
            senderProfileUrl: _session.profileUrl,
            message: trimmedText,
            createdAt: DateTime.now(),
            isRead: true,
          );
          _messages.add(localMsg);
          _updateChatroomLastMessage(localMsg);
          _error = null;
          _isLoading = false;
          notifyListeners();
          print('✅ Message sent via HTTP fallback');
          return true;
        } else {
          print('❌ HTTP sendChatMessage failed');
          _handleError('Failed to send message', showToUser: true);
          return false;
        }
      } catch (e, st) {
        print('❌ HTTP fallback error: $e');
        print('Stack: $st');
        _handleError('Failed to send message', showToUser: true, exception: e);
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Send message error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to send message', showToUser: true, exception: e);
      return false;
    }
  }

  void searchUsers(String query) {
    try {
      if (!_session.isInitialized) {
        _handleError('User not logged in', showToUser: true);
        return;
      }

      if (_session.userId == null) {
        _handleError('User ID not found', showToUser: true);
        return;
      }
      
      print('🔍 Searching users: $query');
      _searchQuery = query;
      _isSearching = true;
      notifyListeners();
      
      if (query.isEmpty) {
        _searchResults.clear();
        _filteredChatRooms.clear();
        _isSearching = false;
        notifyListeners();
        return;
      }
      
      // Filter existing chat rooms
      _filteredChatRooms = _chatRooms.where((room) {
        return room.otherUserName.toLowerCase().contains(query.toLowerCase()) ||
               room.otherUserUsername.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      // Search for new users via WebSocket
      _websocket.searchUsers(_session.userId!, query);
    } catch (e, stackTrace) {
      print('❌ Search users error: $e');
      print('Stack trace: $stackTrace');
      _handleError('Failed to search users', showToUser: false, exception: e);
    }
  }

  void markAsRead(int chatroomId) {
    try {
      if (!_session.isInitialized || _session.userId == null) {
        return;
      }

      if (chatroomId <= 0) {
        return;
      }

      // Use HTTP endpoint instead of WebSocket to reduce server format errors
      // Determine other_user_id from chatroom
      int otherUserId = 0;
      final roomIndex = _chatRooms.indexWhere((room) => room.id == chatroomId);
      if (roomIndex != -1) {
        otherUserId = _chatRooms[roomIndex].otherUserId;
      }

      if (otherUserId > 0) {
        ApiManager.markChatRead(userId: _session.userId!, otherUserId: otherUserId).then((ok) {
          if (ok) {
            print('✅ markChatRead successful for other_user_id=$otherUserId');
          } else {
            print('⚠️ markChatRead failed for other_user_id=$otherUserId');
          }
        });
      } else {
        print('⚠️ markAsRead: otherUserId unknown for chatroom $chatroomId');
      }

      // Update local state immediately
      if (roomIndex != -1) {
        _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(unreadCount: 0);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      print('⚠️ Failed to mark as read: $e');
      print('Stack trace: $stackTrace');
    }
  }

  UserChatRoom? getChatroomByUserId(int otherUserId) {
    try {
      if (otherUserId <= 0) return null;
      return _chatRooms.firstWhere(
        (room) => room.otherUserId == otherUserId,
        orElse: () => throw Exception('Chatroom not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Clear error manually
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _filteredChatRooms.clear();
    _isSearching = false;
    notifyListeners();
  }

  // Reconnect to WebSocket
  Future<void> reconnect() async {
    print('🔄 Manual reconnect requested');
    _error = null;
    _isLoading = true;
    notifyListeners();
    
    // Disconnect existing connection if any
    if (_websocket.isConnected) {
      _websocket.disconnect();
    }
    
    // Cancel existing subscriptions
    await _chatRoomsSubscription?.cancel();
    await _messagesSubscription?.cancel();
    await _userSearchSubscription?.cancel();
    
    // Reinitialize connection
    await initialize();
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _userSearchSubscription?.cancel();
    
    _websocket.disconnect();
    super.dispose();
  }
}