import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/user_search_web_socket.dart';
 import 'package:shaheen_star_app/model/user_chat_model.dart';
import 'package:shaheen_star_app/utils/user_session.dart';

/// Provider to manage follow/unfollow functionality and state
class UserFollowProvider extends ChangeNotifier {
  final UserSearchWebSocket _websocket = UserSearchWebSocket();
  final UserSession _session = UserSession();

  // State
  final Map<int, bool> _followStatus = {}; // userId -> isFollowing
  List<SearchedUser> _followers = [];
  List<SearchedUser> _following = [];
  List<SearchedUser> _suggestedUsers = [];
  List<SearchedUser> _onlineUsers = [];
  
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoading = false;
  String? _error;
  int? _currentUserId;
  int? _lastActionTargetUserId; // Track last action for error recovery
  bool? _lastActionWasFollow; // Track if last action was follow (true) or unfollow (false)

  // Getters
  Map<int, bool> get followStatus => _followStatus;
  List<SearchedUser> get followers => _followers;
  List<SearchedUser> get following => _following;
  List<SearchedUser> get suggestedUsers => _suggestedUsers;
  List<SearchedUser> get onlineUsers => _onlineUsers;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Check if current user is following a specific user
  bool isFollowing(int userId) => _followStatus[userId] ?? false;
  
  
  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Initialize the provider and set up WebSocket listeners
  void initialize() {
    // ✅ Try to load session if not initialized
    if (!_session.isInitialized) {
      print('⚠️ [UserFollowProvider] Session not initialized - attempting to load...');
      _session.loadSession().then((_) {
        if (_session.isInitialized && _session.userId != null) {
          _currentUserId = _session.userId;
          print('✅ [UserFollowProvider] Session loaded, userId: $_currentUserId');
          _setupWebSocket();
        } else {
          print('❌ [UserFollowProvider] Session still not initialized after load');
          _error = 'User session not initialized';
          notifyListeners();
        }
      });
      return;
    }

    

    if (_session.userId == null) {
      print('❌ [UserFollowProvider] Session initialized but userId is null');
      _error = 'User session incomplete';
      notifyListeners();
      return;
    }

    _currentUserId = _session.userId;
    print('✅ [UserFollowProvider] Initialized with userId: $_currentUserId');
    _setupWebSocket();
  }

  /// Set up WebSocket connection and listeners
  void _setupWebSocket() {
    // Add message listener (supports multiple listeners)
    _websocket.addMessageListener(_handleMessage);

    // ✅ Ensure WebSocket is connected
    if (!_websocket.isConnected) {
      print('⚠️ [UserFollowProvider] WebSocket not connected - connecting now...');
      _connectWebSocket();
    } else {
      print('✅ [UserFollowProvider] WebSocket already connected');
    }
  }

  /// Connect to WebSocket if not already connected
  void _connectWebSocket() {
    if (_session.userId == null || _session.username == null || _session.name == null) {
      print('❌ [UserFollowProvider] Cannot connect - missing session data');
      _error = 'User session incomplete';
      notifyListeners();
      return;
    }

    try {
      _websocket.connect(
        userId: _session.userId!,
        username: _session.username!,
        name: _session.name!,
        profileUrl: _session.profileUrl,
      );
      print('✅ [UserFollowProvider] WebSocket connection initiated');
    } catch (e) {
      print('❌ [UserFollowProvider] Failed to connect WebSocket: $e');
      _error = 'Failed to connect: $e';
      notifyListeners();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      print('📥 [UserFollowProvider] ===== RAW MESSAGE RECEIVED =====');
      print('📥 [UserFollowProvider] Message type: ${message.runtimeType}');
      print('📥 [UserFollowProvider] Message content: $message');
      
      final data = json.decode(message);
      print('📥 [UserFollowProvider] Parsed data keys: ${data is Map ? (data).keys.toList() : "Not a Map"}');
      print('📥 [UserFollowProvider] Full parsed data: $data');
      
      // ✅ Handle error responses (status: "error")
      if (data['status'] == 'error') {
        final rawErrorMessage = data['message'] as String? ?? 'An error occurred';
        print('❌ [UserFollowProvider] Server error: $rawErrorMessage');
        
        // ✅ Convert technical errors to user-friendly messages
        String userFriendlyError = rawErrorMessage;
        if (rawErrorMessage.contains('MySQL') || 
            rawErrorMessage.contains('database') ||
            rawErrorMessage.contains('server has gone away') ||
            rawErrorMessage.contains('connection')) {
          userFriendlyError = 'Server temporarily unavailable. Please try again in a moment.';
        } else if (rawErrorMessage.contains('timeout') || rawErrorMessage.contains('timed out')) {
          userFriendlyError = 'Request timed out. Please check your connection and try again.';
        } else if (rawErrorMessage.contains('network') || rawErrorMessage.contains('connection')) {
          userFriendlyError = 'Network error. Please check your connection and try again.';
        }
        
        // ✅ Revert optimistic update on error
        if (_lastActionTargetUserId != null && _lastActionWasFollow != null) {
          print('🔄 [UserFollowProvider] Reverting optimistic update for user: $_lastActionTargetUserId');
          _followStatus[_lastActionTargetUserId!] = !_lastActionWasFollow!; // Revert to previous state
          
          // Also update counts if needed
          if (_lastActionWasFollow == true) {
            // Was trying to follow, revert by removing from following count
            if (_followingCount > 0) _followingCount--;
          } else {
            // Was trying to unfollow, revert by adding back to following count
            _followingCount++;
          }
        }
        
        _error = userFriendlyError;
        _isLoading = false;
        _lastActionTargetUserId = null;
        _lastActionWasFollow = null;
        notifyListeners();
        return;
      }
      
      final event = data['event'] as String?;

      if (event == null) {
        // ✅ Handle responses without event field (direct status responses)
        if (data['status'] != null) {
          final status = data['status'].toString().toLowerCase();
          print('📨 [UserFollowProvider] Received response with status: $status');
          
          if (status == 'success') {
            // Check if this is a follow/unfollow response by checking the message
            final message = data['message']?.toString().toLowerCase() ?? '';
            final responseData = data['data'];
            
            if (responseData != null && responseData is Map) {
              // Cast to Map<String, dynamic>
              final responseDataMap = Map<String, dynamic>.from(responseData);
              
              // ✅ Check if this is a followers/following list response
              if (responseDataMap.containsKey('followers') || responseDataMap.containsKey('following')) {
                if (responseDataMap.containsKey('followers')) {
                  print('✅ [UserFollowProvider] Detected followers list in status response');
                  _handleFollowers(responseDataMap);
                  return;
                } else if (responseDataMap.containsKey('following')) {
                  print('✅ [UserFollowProvider] Detected following list in status response');
                  _handleFollowing(responseDataMap);
                  return;
                }
              }
              
              // Check for follow/unfollow indicators
              if (message.contains('followed') && !message.contains('unfollow')) {
                // This is a follow success response
                print('✅ [UserFollowProvider] Detected follow success from status response');
                _handleFollowSuccess(responseDataMap);
                return;
              } else if (message.contains('unfollow')) {
                // This is an unfollow success response
                print('✅ [UserFollowProvider] Detected unfollow success from status response');
                _handleUnfollowSuccess(responseDataMap);
                return;
              }
            }
            
            // ✅ If we have data but it's not a Map, try to handle it as a list
            if (responseData != null && responseData is List) {
              print('⚠️ [UserFollowProvider] Received list data without event - checking context');
              // This might be a direct list response, but we need context to know if it's followers or following
              // For now, clear loading state to prevent infinite loading
              _isLoading = false;
              notifyListeners();
              return;
            }
          } else if (status == 'error') {
            // Handle error response
            _error = data['message']?.toString() ?? 'An error occurred';
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
        
        // ✅ If no event and no status, check if data contains followers/following directly
        if (data.containsKey('followers')) {
          print('✅ [UserFollowProvider] Detected followers in data without event');
          _handleFollowers(data);
          return;
        } else if (data.containsKey('following')) {
          print('✅ [UserFollowProvider] Detected following in data without event');
          _handleFollowing(data);
          return;
        }
        
        // ✅ If we can't identify the response, log it and clear loading to prevent infinite loading
        print('⚠️ [UserFollowProvider] Received response without recognizable event or status');
        print('⚠️ [UserFollowProvider] Response data: $data');
        print('⚠️ [UserFollowProvider] Response keys: ${data is Map ? (data).keys.toList() : "Not a Map"}');
        
        // ✅ Try to detect if this is a response to get_followers or get_following by checking action
        final action = data['action'] as String?;
        if (action == 'get_followers' || action == 'get_following') {
          print('✅ [UserFollowProvider] Detected response for action: $action');
          // Try to extract data directly
          if (data.containsKey('data')) {
            final responseData = data['data'];
            if (action == 'get_followers') {
              final followersData = responseData is Map 
                  ? Map<String, dynamic>.from(responseData) 
                  : {'data': responseData};
              _handleFollowers(followersData);
            } else {
              final followingData = responseData is Map 
                  ? Map<String, dynamic>.from(responseData) 
                  : {'data': responseData};
              _handleFollowing(followingData);
            }
            return;
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('📨 [UserFollowProvider] Received event: $event');

      switch (event) {
        case 'user:followed_you':
          _handleFollowNotification(data['data']);
          break;
        case 'user:unfollowed':
          _handleUnfollowNotification(data['data']);
          break;
        case 'user:follow_status':
          _handleFollowStatus(data['data']);
          break;
        case 'user:followers':
          _handleFollowers(data['data']);
          break;
        case 'user:following':
          _handleFollowing(data['data']);
          break;
        case 'users:suggested':
          _handleSuggestedUsers(data['data']);
          break;
        case 'users:online':
          _handleOnlineUsers(data['data']);
          break;
        case 'user:follow_success':
          _handleFollowSuccess(data['data']);
          break;
        case 'user:unfollow_success':
          _handleUnfollowSuccess(data['data']);
          break;
        case 'error':
          _error = data['message'] ?? 'An error occurred';
          _isLoading = false;
          notifyListeners();
          break;
      }
    } catch (e) {
      print('❌ [UserFollowProvider] Error handling message: $e');
      _error = 'Error processing message: $e';
      notifyListeners();
    }
  }

  /// Follow a user
  Future<void> followUser(int targetUserId) async {
    print('🔘 [UserFollowProvider] followUser called for targetUserId: $targetUserId');
    print('   Current _currentUserId: $_currentUserId');
    print('   Session initialized: ${_session.isInitialized}');
    print('   Session userId: ${_session.userId}');
    
    // ✅ Ensure session is loaded and currentUserId is set
    if (!_session.isInitialized) {
      print('⚠️ [UserFollowProvider] Session not initialized - loading session...');
      await _session.loadSession();
      print('   After load - Session initialized: ${_session.isInitialized}');
      print('   After load - Session userId: ${_session.userId}');
    }
    
    // ✅ Get userId from session if _currentUserId is null
    if (_currentUserId == null) {
      _currentUserId = _session.userId;
      print('🔄 [UserFollowProvider] Updated _currentUserId from session: $_currentUserId');
    }
    
    if (_currentUserId == null) {
      print('❌ [UserFollowProvider] Cannot follow - user not logged in');
      print('   Session initialized: ${_session.isInitialized}');
      print('   Session userId: ${_session.userId}');
      print('   Session username: ${_session.username}');
      print('   Session name: ${_session.name}');
      _error = 'User not logged in. Please log in and try again.';
      notifyListeners();
      return;
    }
    
    print('✅ [UserFollowProvider] User is logged in, userId: $_currentUserId');

    // ✅ Try to connect if not connected
    if (!_websocket.isConnected) {
      print('⚠️ [UserFollowProvider] WebSocket not connected - attempting to connect...');
      _connectWebSocket();
      
      // Wait a bit for connection
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_websocket.isConnected) {
        print('❌ [UserFollowProvider] WebSocket still not connected after retry');
        _error = 'WebSocket not connected. Please try again.';
        notifyListeners();
        return;
      }
    }

    // Track action for error recovery
    _lastActionTargetUserId = targetUserId;
    _lastActionWasFollow = true;
    
    // Optimistically update UI
    _followStatus[targetUserId] = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('👤 [UserFollowProvider] Following user: $targetUserId (current user: $_currentUserId)');
    final success = _websocket.followUser(_currentUserId!, targetUserId);
    if (success) {
      print('✅ [UserFollowProvider] Follow request sent to WebSocket successfully');
      // Note: We'll wait for server response to confirm or handle error
    } else {
      print('❌ [UserFollowProvider] Failed to send follow request - WebSocket not connected');
      // Revert optimistic update
      _followStatus[targetUserId] = false;
      _lastActionTargetUserId = null;
      _lastActionWasFollow = null;
      _error = 'Failed to send follow request. Please check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(int targetUserId) async {
    // ✅ Ensure session is loaded and currentUserId is set
    if (!_session.isInitialized) {
      print('⚠️ [UserFollowProvider] Session not initialized - loading session...');
      await _session.loadSession();
    }
    
    // ✅ Get userId from session if _currentUserId is null
    if (_currentUserId == null) {
      _currentUserId = _session.userId;
      print('🔄 [UserFollowProvider] Updated _currentUserId from session: $_currentUserId');
    }
    
    if (_currentUserId == null) {
      print('❌ [UserFollowProvider] Cannot unfollow - user not logged in');
      print('   Session initialized: ${_session.isInitialized}');
      print('   Session userId: ${_session.userId}');
      _error = 'User not logged in. Please log in and try again.';
      notifyListeners();
      return;
    }

    // ✅ Try to connect if not connected
    if (!_websocket.isConnected) {
      print('⚠️ [UserFollowProvider] WebSocket not connected - attempting to connect...');
      _connectWebSocket();
      
      // Wait a bit for connection
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_websocket.isConnected) {
        print('❌ [UserFollowProvider] WebSocket still not connected after retry');
        _error = 'WebSocket not connected. Please try again.';
        notifyListeners();
        return;
      }
    }

    // Track action for error recovery
    _lastActionTargetUserId = targetUserId;
    _lastActionWasFollow = false;
    
    // Optimistically update UI
    _followStatus[targetUserId] = false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('👤 [UserFollowProvider] Unfollowing user: $targetUserId (current user: $_currentUserId)');
    final success = _websocket.unfollowUser(_currentUserId!, targetUserId);
    if (success) {
      print('✅ [UserFollowProvider] Unfollow request sent to WebSocket successfully');
      // Note: We'll wait for server response to confirm or handle error
    } else {
      print('❌ [UserFollowProvider] Failed to send unfollow request - WebSocket not connected');
      // Revert optimistic update
      _followStatus[targetUserId] = true;
      _lastActionTargetUserId = null;
      _lastActionWasFollow = null;
      _error = 'Failed to send unfollow request. Please check your connection.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if current user is following target user
  Future<void> checkFollowStatus(int targetUserId) async {
    if (_currentUserId == null) {
      return;
    }

    if (!_websocket.isConnected) {
      print('⚠️ [UserFollowProvider] WebSocket not connected, cannot check follow status');
      return;
    }

    // If already cached, don't request again
    if (_followStatus.containsKey(targetUserId)) {
      return;
    }

    print('🔍 [UserFollowProvider] Checking follow status for user: $targetUserId');
    _websocket.checkFollowStatus(_currentUserId!, targetUserId);
  }

  /// Get followers list for a user
  Future<void> getFollowers(int userId, {int limit = 50, int offset = 0}) async {
    if (!_websocket.isConnected) {
      _error = 'WebSocket not connected';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    print('👥 [UserFollowProvider] Getting followers for user: $userId');
    _websocket.getFollowers(userId, limit: limit, offset: offset);
    
    // ✅ Add timeout to clear loading state if no response received
    Future.delayed(const Duration(seconds: 10), () {
      if (_isLoading) {
        print('⚠️ [UserFollowProvider] Timeout waiting for followers response');
        _isLoading = false;
        _error = 'Request timed out. Please try again.';
        notifyListeners();
      }
    });
  }

  /// Get following list for a user
  Future<void> getFollowing(int userId, {int limit = 50, int offset = 0}) async {
    if (!_websocket.isConnected) {
      _error = 'WebSocket not connected';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    print('👥 [UserFollowProvider] Getting following for user: $userId');
    _websocket.getFollowing(userId, limit: limit, offset: offset);
    
    // ✅ Add timeout to clear loading state if no response received
    Future.delayed(const Duration(seconds: 10), () {
      if (_isLoading) {
        print('⚠️ [UserFollowProvider] Timeout waiting for following response');
        _isLoading = false;
        _error = 'Request timed out. Please try again.';
        notifyListeners();
      }
    });
  }

  /// Get suggested users to follow
  Future<void> getSuggestedUsers({int limit = 10}) async {
    if (_currentUserId == null) {
      return;
    }

    if (!_websocket.isConnected) {
      print('⚠️ [UserFollowProvider] WebSocket not connected, cannot get suggested users');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    print('💡 [UserFollowProvider] Getting suggested users');
    _websocket.getSuggestedUsers(_currentUserId!, limit: limit);
  }

  /// Get online users
  Future<void> getOnlineUsers({int limit = 50}) async {
    if (_currentUserId == null) {
      return;
    }

    if (!_websocket.isConnected) {
      print('⚠️ [UserFollowProvider] WebSocket not connected, cannot get online users');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🌐 [UserFollowProvider] Getting online users');
    _websocket.getOnlineUsers(_currentUserId!, limit: limit);
  }

  /// Update follow status in cache
  void updateFollowStatus(int userId, bool isFollowing) {
    _followStatus[userId] = isFollowing;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _followStatus.clear();
    _followers.clear();
    _following.clear();
    _suggestedUsers.clear();
    _onlineUsers.clear();
    _followersCount = 0;
    _followingCount = 0;
    _error = null;
    notifyListeners();
  }

  // ========== EVENT HANDLERS ==========

  void _handleFollowSuccess(Map<String, dynamic>? data) {
    if (data == null) return;

    // Handle both target_user_id and following_id field names
    final targetUserId = data['target_user_id'] as int? ?? 
                        data['following_id'] as int?;
    if (targetUserId != null) {
      _followStatus[targetUserId] = true;
      _followingCount++;
      _isLoading = false;
      _error = null;
      _lastActionTargetUserId = null; // Clear action tracking on success
      _lastActionWasFollow = null;
      print('✅ [UserFollowProvider] Successfully followed user: $targetUserId');
      
      // ✅ Add to following list if not already present
      final userExists = _following.any((user) => user.id == targetUserId);
      if (!userExists) {
        // Try to get user data from the response
        if (data['user'] != null) {
          try {
              final user = SearchedUser.fromJson(data['user'] as Map<String, dynamic>);
            _following.add(user);
            print('✅ [UserFollowProvider] Added user to following list');
          } catch (e) {
            print('⚠️ [UserFollowProvider] Could not add user to following list: $e');
          }
        } else {
          // If user data not in response, reload following list to get updated data
          if (_currentUserId != null) {
            getFollowing(_currentUserId!);
          }
        }
      }
      
      notifyListeners();
    }
  }

  void _handleUnfollowSuccess(Map<String, dynamic>? data) {
    if (data == null) return;

    // Handle both target_user_id and following_id field names
    final targetUserId = data['target_user_id'] as int? ?? 
                        data['following_id'] as int?;
    if (targetUserId != null) {
      _followStatus[targetUserId] = false;
      if (_followingCount > 0) {
        _followingCount--;
      }
      _isLoading = false;
      _error = null;
      _lastActionTargetUserId = null; // Clear action tracking on success
      _lastActionWasFollow = null;
      print('✅ [UserFollowProvider] Successfully unfollowed user: $targetUserId');
      
      // ✅ Remove from following list
      _following.removeWhere((user) => user.id == targetUserId);
      print('✅ [UserFollowProvider] Removed user from following list');
      
      notifyListeners();
    }
  }

  void _handleFollowStatus(Map<String, dynamic>? data) {
    if (data == null) return;

    final targetUserId = data['target_user_id'] as int?;
    final isFollowing = data['is_following'] as bool? ?? false;

    if (targetUserId != null) {
      _followStatus[targetUserId] = isFollowing;
      print('✅ [UserFollowProvider] Follow status for user $targetUserId: $isFollowing');
      notifyListeners();
    }
  }

  void _handleFollowers(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
   
      int? extractedCount;
      
      // Check if data has nested 'data' object
      if (data['data'] != null && data['data'] is Map) {
        final nestedData = data['data'] as Map<String, dynamic>;
        extractedCount = nestedData['total_followers'] as int? ?? 
                         nestedData['count'] as int? ??
                         nestedData['followers_count'] as int?;
      }
      
      // Also check direct access
      extractedCount ??= data['count'] as int? ?? 
                         data['followers_count'] as int? ?? 
                         data['total_followers'] as int?;
      
      // ✅ Update count immediately if found
      if (extractedCount != null) {
        _followersCount = extractedCount;
        print('✅ [UserFollowProvider] Extracted followers count: $_followersCount');
        notifyListeners(); // ✅ Notify immediately so UI updates
      }
      
      // Handle nested data structure: data.data.followers
      List<dynamic> followersList = [];
      
      // Check if data has nested 'data' object
      if (data['data'] != null && data['data'] is Map) {
        final nestedData = data['data'] as Map<String, dynamic>;
        // Safely extract followers list
        final followersValue = nestedData['followers'];
        if (followersValue is List) {
          followersList = followersValue;
        } else if (followersValue != null) {
          print('⚠️ [UserFollowProvider] followers is not a List, type: ${followersValue.runtimeType}');
          followersList = [];
        }
        // Update count from nested data if not already set
        if (_followersCount == 0 && extractedCount == null) {
        _followersCount = nestedData['total_followers'] as int? ?? 
                         nestedData['count'] as int? ?? 
                         followersList.length;
        }
      } else {
        // Fallback: try direct access
        final followersValue = data['followers'];
        if (followersValue is List) {
          followersList = followersValue;
        } else if (followersValue != null) {
          print('⚠️ [UserFollowProvider] followers is not a List (direct access), type: ${followersValue.runtimeType}');
          followersList = [];
        }
        // Update count if not already set
        if (_followersCount == 0 && extractedCount == null) {
        _followersCount = data['count'] as int? ?? 
                         data['followers_count'] as int? ?? 
                         data['total_followers'] as int? ??
                         followersList.length;
        }
      }
      
      _followers = followersList
          .map((item) => SearchedUser.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _isLoading = false;
      _error = null;
      print('✅ [UserFollowProvider] Loaded ${_followers.length} followers (count: $_followersCount)');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [UserFollowProvider] Error parsing followers: $e');
      print('❌ [UserFollowProvider] Stack trace: $stackTrace');
      print('❌ [UserFollowProvider] Data received: $data');
      _error = 'Error loading followers: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleFollowing(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      // ✅ FIRST: Extract count immediately (before parsing list)
      // This ensures counts are updated even if list parsing fails
      int? extractedCount;
      
      // Check if data has nested 'data' object
      if (data['data'] != null && data['data'] is Map) {
        final nestedData = data['data'] as Map<String, dynamic>;
        extractedCount = nestedData['total_following'] as int? ?? 
                         nestedData['count'] as int? ??
                         nestedData['following_count'] as int?;
      }
      
      // Also check direct access
      extractedCount ??= data['count'] as int? ?? 
                         data['following_count'] as int? ?? 
                         data['total_following'] as int?;
      
      // ✅ Update count immediately if found
      if (extractedCount != null) {
        _followingCount = extractedCount;
        print('✅ [UserFollowProvider] Extracted following count: $_followingCount');
        notifyListeners(); // ✅ Notify immediately so UI updates
      }
      
      // Handle nested data structure: data.data.following
      List<dynamic> followingList = [];
      
      // Check if data has nested 'data' object
      if (data['data'] != null && data['data'] is Map) {
        final nestedData = data['data'] as Map<String, dynamic>;
        // Safely extract following list
        final followingValue = nestedData['following'];
        if (followingValue is List) {
          followingList = followingValue;
        } else if (followingValue != null) {
          print('⚠️ [UserFollowProvider] following is not a List, type: ${followingValue.runtimeType}');
          followingList = [];
        }
        // Update count from nested data if not already set
        if (_followingCount == 0 && extractedCount == null) {
        _followingCount = nestedData['total_following'] as int? ?? 
                         nestedData['count'] as int? ?? 
                         followingList.length;
        }
      } else {
        // Fallback: try direct access
        final followingValue = data['following'];
        if (followingValue is List) {
          followingList = followingValue;
        } else if (followingValue != null) {
          print('⚠️ [UserFollowProvider] following is not a List (direct access), type: ${followingValue.runtimeType}');
          followingList = [];
        }
        // Update count if not already set
        if (_followingCount == 0 && extractedCount == null) {
        _followingCount = data['count'] as int? ?? 
                         data['following_count'] as int? ?? 
                         data['total_following'] as int? ??
                         followingList.length;
        }
      }
      
      _following = followingList
          .map((item) {
            final user = SearchedUser.fromJson(item as Map<String, dynamic>);
            // ✅ Mark all users in following list as followed in cache
            // Since they're in the following list, they must be followed
            _followStatus[user.id] = true;
            // ✅ Also ensure the user object has isFollowing = true
            return SearchedUser(
              id: user.id,
              username: user.username,
              name: user.name,
              profileUrl: user.profileUrl,
              isOnline: user.isOnline,
              status: user.status,
              isFollowing: true, // ✅ Always true for users in following list
              isFollower: user.isFollower,
            );
          })
          .toList();
      
      _isLoading = false;
      _error = null;
      print('✅ [UserFollowProvider] Loaded ${_following.length} following (count: $_followingCount)');
      print('✅ [UserFollowProvider] Marked all ${_following.length} users as followed in cache');
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ [UserFollowProvider] Error parsing following: $e');
      print('❌ [UserFollowProvider] Stack trace: $stackTrace');
      print('❌ [UserFollowProvider] Data received: $data');
      _error = 'Error loading following: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleSuggestedUsers(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final suggestedList = data['suggested'] as List? ?? data as List? ?? [];
      _suggestedUsers = suggestedList
          .map((item) => SearchedUser.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _isLoading = false;
      _error = null;
      print('✅ [UserFollowProvider] Loaded ${_suggestedUsers.length} suggested users');
      notifyListeners();
    } catch (e) {
      print('❌ [UserFollowProvider] Error parsing suggested users: $e');
      _error = 'Error loading suggested users: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleOnlineUsers(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final onlineList = data['online'] as List? ?? data as List? ?? [];
      _onlineUsers = onlineList
          .map((item) => SearchedUser.fromJson(item as Map<String, dynamic>))
          .toList();
      
      _isLoading = false;
      _error = null;
      print('✅ [UserFollowProvider] Loaded ${_onlineUsers.length} online users');
      notifyListeners();
    } catch (e) {
      print('❌ [UserFollowProvider] Error parsing online users: $e');
      _error = 'Error loading online users: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleFollowNotification(Map<String, dynamic>? data) {
    if (data == null) return;

    final followerId = data['follower_id'] as int?;
    final followerName = data['follower_name'] as String?;

    if (followerId != null) {
      _followersCount++;
      print('🔔 [UserFollowProvider] User $followerName ($followerId) followed you');
      notifyListeners();
      
      // You can show a notification here
      // ScaffoldMessenger.of(context).showSnackBar(...)
    }
  }

  void _handleUnfollowNotification(Map<String, dynamic>? data) {
    if (data == null) return;

    final unfollowerId = data['unfollower_id'] as int?;
    final unfollowerName = data['unfollower_name'] as String?;

    if (unfollowerId != null) {
      if (_followersCount > 0) {
        _followersCount--;
      }
      print('🔔 [UserFollowProvider] User $unfollowerName ($unfollowerId) unfollowed you');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Remove message listener
    _websocket.removeMessageListener(_handleMessage);
    super.dispose();
  }
}

