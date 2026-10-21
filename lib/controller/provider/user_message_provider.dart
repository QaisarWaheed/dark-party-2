import 'package:flutter/foundation.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/admin_message_model.dart';
import 'package:shaheen_star_app/model/user_message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shaheen_star_app/model/user_system_message_model.dart'; // ✅ Import Add Karo

class UserMessageProvider with ChangeNotifier {
  int? _currentUserId;
  int? _currentChatroomId;
  List<ChatMessage> _messages = [];
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  List<AdminMessage> _adminMessages = [];
  List<UserSystemMessage> _systemMessages =
      []; // ✅ New List for System Messages

  List<AdminMessage> get adminMessages => _adminMessages;
  List<UserSystemMessage> get systemMessages =>
      _systemMessages; // ✅ Getter for System Messages

  // Getters
  int? get currentUserId => _currentUserId;
  int? get currentChatroomId => _currentChatroomId;
  List<ChatMessage> get messages => _messages;
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized; // ✅ Getter add karo

  Future<void> initializeUser() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      print('🔄 Initializing User...');
      print('📱 All SharedPreferences Keys: ${prefs.getKeys()}');

      // ✅ SMART TYPE HANDLING
      dynamic userIdValue = prefs.get('user_id');
      print(
        '🔍 Raw user_id value: $userIdValue (Type: ${userIdValue.runtimeType})',
      );

      if (userIdValue != null) {
        if (userIdValue is int) {
          _currentUserId = userIdValue;
          print('✅ User ID found as int: $_currentUserId');
        } else if (userIdValue is String) {
          _currentUserId = int.tryParse(userIdValue);
          print('✅ User ID found as string: $userIdValue -> $_currentUserId');
        }
      }

      // ❌ HARCODED ID HATA DIYA - صرف login user کی ID استعمال کریں
      if (_currentUserId == null) {
        _error = 'User not logged in. Please login first.';
        print('❌ $_error');
        _isInitialized = false;
      } else {
        await loadChatRooms();
        _isInitialized = true;
        print('🎉 User initialized successfully: $_currentUserId');
      }
    } catch (e) {
      _error = 'Error initializing user: $e';
      print('❌ $_error');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ ADMIN MESSAGES LOAD KARO
  // Future<void> loadAdminMessages() async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     _adminMessages = await ApiManager.getAdminMessages(_currentUserId!);
  //     print('✅ Loaded ${_adminMessages.length} admin messages');
  //   } catch (e) {
  //     _error = 'Error loading admin messages: $e';
  //     print('❌ $_error');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // ✅ COMBINED MESSAGES LOAD KARO
  // Future<void> loadAllMessages() async {
  //   print('🔄 Loading all messages...');

  //   // User chat rooms load karo
  //   await loadChatRooms();

  //   // Admin messages load karo
  //   // await loadAdminMessages();

  //   print('✅ All messages loaded - User chats: ${_chatRooms.length}, Admin messages: ${_adminMessages.length}');
  // }

  // ✅ ADMIN SE CHAT SHURU KARNE KA FUNCTION
  Future<bool> startAdminChat() async {
    if (_currentUserId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Starting admin chat for user $_currentUserId...');

      final int adminId = 1;

      final response = await ApiManager.createChatroom(
        _currentUserId!,
        adminId,
      );

      print(
        '📡 Admin chat creation response: ${response.success} - ${response.message}',
      );

      if (response.success) {
        print('✅ Admin chatroom created successfully');
        await loadChatRooms();
        return true;
      } else {
        _error = 'Failed to start admin chat: ${response.message}';
        print('❌ $_error');
        return false;
      }
    } catch (e) {
      _error = 'Error starting admin chat: $e';
      print('❌ $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ MANUAL USER SETTER
  void setCurrentUser(int userId) {
    _currentUserId = userId;
    _error = null;
    _isInitialized = true;
    print('👤 User set manually: $userId');
    loadChatRooms();
  }

  // ✅ LOAD CHAT ROOMS
  // Future<void> loadChatRooms() async {
  //   if (_currentUserId == null) {
  //     _error = 'User ID not available';
  //     notifyListeners();
  //     return;
  //   }

  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     _chatRooms = await ApiManager.getUserChatRooms(_currentUserId!);
  //     print('✅ Loaded ${_chatRooms.length} chat rooms for user $_currentUserId');
  //   } catch (e) {
  //     _error = 'Error loading chat rooms: $e';
  //     print('❌ $_error');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
  // ✅ LOAD CHAT ROOMS - Fixed version
  Future<void> loadChatRooms() async {
    if (_currentUserId == null) {
      _error = 'User ID not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chatRooms = await ApiManager.getUserChatRooms(_currentUserId!);
      print(
        '✅ Loaded ${_chatRooms.length} chat rooms for user $_currentUserId',
      );
    } catch (e) {
      _error = 'Error loading chat rooms: $e';
      print('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ YE UNCOMMENT KARO (Line ~80 pe hai)
  Future<void> loadAdminMessages() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading admin messages for user $_currentUserId...');
      _adminMessages = await ApiManager.getAdminMessages(_currentUserId!);
      print('✅ Loaded ${_adminMessages.length} admin messages');

      // ✅ Also load System Messages (Coin Transactions etc)
      await loadUserSystemMessages();
    } catch (e) {
      _error = 'Error loading admin messages: $e';
      print('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ New Method to Load System Messages (get_user_messages.php)
  Future<void> loadUserSystemMessages() async {
    if (_currentUserId == null) return;

    try {
      print(
        '🔄 Fetching system messages (transactions) for user $_currentUserId...',
      );
      // Using API calls: get_user_messages.php?user_id=...&limit=50&offset=0
      final response = await ApiManager.getUserMessagesApi(
        userId: _currentUserId.toString(),
        limit: 50,
        offset: 0,
      );

      if (response != null && response.success) {
        _systemMessages = response.messages;
        print('✅ Loaded ${_systemMessages.length} system messages');
      } else {
        print('⚠️ Failed to load system messages or no messages found');
        _systemMessages = []; // Clear if failed or empty to avoid stale data
      }
    } catch (e) {
      print('❌ Error loading system messages: $e');
      // Don't set global error to avoid blocking other UI, just log it
    }
    // notifyListeners() is called in finally block of loadAdminMessages if called from there,
    // otherwise we might need it here if called independently. Use manual notify if needed.
  }

  // ✅ YE BHI UPDATE KARO (Line ~90 pe hai)
  Future<void> loadAllMessages() async {
    print('🔄 Loading all messages...');

    // User chat rooms load karo
    await loadChatRooms();

    // ✅ ADMIN MESSAGES LOAD KARO (YE UNCOMMENT KARO)
    await loadAdminMessages();

    print(
      '✅ All messages loaded - User chats: ${_chatRooms.length}, Admin messages: ${_adminMessages.length}',
    );
  }

  // ✅ LOAD MESSAGES - Fixed version
  Future<void> loadMessages() async {
    if (_currentChatroomId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await ApiManager.getUserMessages(_currentChatroomId!);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      print(
        '✅ Loaded ${_messages.length} messages for chatroom $_currentChatroomId',
      );
    } catch (e) {
      _error = 'Error loading messages: $e';
      print('❌ Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ SET CURRENT CHATROOM
  void setCurrentChatroom(int chatroomId) {
    _currentChatroomId = chatroomId;
    _error = null;
    notifyListeners();
    loadMessages();
  }

  // ✅ SEND MESSAGE
  Future<bool> sendMessage(String messageText) async {
    if (_currentUserId == null || _currentChatroomId == null) {
      _error = 'User ID or Chatroom ID not set';
      notifyListeners();
      return false;
    }

    if (messageText.trim().isEmpty) return false;

    // Optimistic update
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatroomId: _currentChatroomId!,
      senderId: _currentUserId!,
      senderName: 'You',
      message: messageText,
      messageType: 'text',
      createdAt: DateTime.now(),
    );

    _messages.add(tempMessage);
    _error = null;
    notifyListeners();

    try {
      final response = await ApiManager.userSendMessage(
        chatroomId: _currentChatroomId!,
        senderId: _currentUserId!,
        message: messageText,
      );

      if (response.success) {
        await loadMessages();
        await loadChatRooms();
        return true;
      } else {
        _messages.remove(tempMessage);
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _messages.remove(tempMessage);
      _error = 'Error sending message: $e';
      notifyListeners();
      return false;
    }
  }

  // ✅ LOAD MESSAGES
  // Future<void> loadMessages() async {
  //   if (_currentChatroomId == null) return;

  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     _messages = await ApiManager.getUserMessages(_currentChatroomId!);
  //     _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  //     print('✅ Loaded ${_messages.length} messages for chatroom $_currentChatroomId');
  //   } catch (e) {
  //     _error = 'Error loading messages: $e';
  //     print('❌ Error loading messages: $e');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // ✅ CLEAR ERROR
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ CLEAR CHAT DATA
  void clearChatData() {
    _currentChatroomId = null;
    _messages.clear();
    notifyListeners();
  }
}
