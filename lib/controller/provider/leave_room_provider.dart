


import 'package:flutter/material.dart';
import 'package:shaheen_star_app/model/leave_room_model.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRoomProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  LeaveRoomModel? _leaveResponse;
  bool _leaveSuccess = false;
  bool _showExitDialog = false;
  bool _isMinimized = false;
  String? _minimizedRoomId;
  String? _minimizedRoomName;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  LeaveRoomModel? get leaveResponse => _leaveResponse;
  bool get leaveSuccess => _leaveSuccess;
  bool get showExitDialog => _showExitDialog;
  bool get isMinimized => _isMinimized;
  String? get minimizedRoomId => _minimizedRoomId;
  String? get minimizedRoomName => _minimizedRoomName;

  // Set show exit dialog
  void setShowExitDialog(bool value) {
    _showExitDialog = value;
    notifyListeners();
  }

  // Minimize room
  void minimizeRoom(String roomId, String roomName) async {
    _isMinimized = true;
    _minimizedRoomId = roomId;
    _minimizedRoomName = roomName;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_room_minimized', true);
    await prefs.setString('minimized_room_id', roomId);
    await prefs.setString('minimized_room_name', roomName);
    
    print("📦 Room minimized: $roomName ($roomId)");
    notifyListeners();
  }

  // Restore minimized room
  void restoreMinimizedRoom() async {
    final prefs = await SharedPreferences.getInstance();
    _isMinimized = prefs.getBool('is_room_minimized') ?? false;
    _minimizedRoomId = prefs.getString('minimized_room_id');
    _minimizedRoomName = prefs.getString('minimized_room_name');
    
    if (_isMinimized) {
      print("🔄 Minimized room found: $_minimizedRoomName ($_minimizedRoomId)");
    }
    notifyListeners();
  }

  // Clear minimized state
  void clearMinimizedState() async {
    _isMinimized = false;
    _minimizedRoomId = null;
    _minimizedRoomName = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_room_minimized');
    await prefs.remove('minimized_room_id');
    await prefs.remove('minimized_room_name');
    
    print("🗑️ Minimized state cleared");
    notifyListeners();
  }

  // ✅ MAIN LEAVE ROOM FUNCTION
  Future<void> leaveRoom({required String roomId}) async {
    _isLoading = true;
    _errorMessage = '';
    _leaveResponse = null;
    _leaveSuccess = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Safely get user_id (handles both int and String types)
      String? userId;
      try {
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          userId = userIdInt.toString();
        } else {
          userId = prefs.getString('user_id');
        }
      } catch (e) {
        // Fallback: try dynamic retrieval
        final dynamic userIdValue = prefs.get('user_id');
        if (userIdValue != null) {
          userId = userIdValue.toString();
        }
      }

      print("🎯 LEAVE ROOM DEBUG:");
      print("   User ID: $userId");
      print("   Room ID: $roomId");

      if (userId == null) {
        _errorMessage = 'User not logged in';
        _leaveSuccess = false;
        return;
      }

      if (roomId.isEmpty) {
        _errorMessage = 'Room ID is required';
        _leaveSuccess = false;
        return;
      }

      print("🚀 Calling Leave Room API...");

      // API Call
      LeaveRoomModel response = await ApiManager.leaveRoom(
        userId: userId,
        roomId: roomId,
      );

      _leaveResponse = response;

      print("📥 API Response - Status: ${response.status}, Message: ${response.message}");

      // Success conditions
      if (response.status == 'success') {
        _leaveSuccess = true;
        clearMinimizedState();
        print("✅ Leave Room Success");
      } 
      // Even if user not in room, consider success
      else if (response.message.toLowerCase().contains('user is not in this room') ||
               response.message.toLowerCase().contains('not in room')) {
        _leaveSuccess = true;
        clearMinimizedState();
        print("✅ User not in room - considered success");
      }
      else {
        _errorMessage = response.message;
        _leaveSuccess = false;
        print("❌ Leave Room Failed: ${response.message}");
      }
    } catch (e) {
      _errorMessage = 'Error leaving room: $e';
      _leaveSuccess = false;
      print("❌ Leave Room Exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ FORCE LEAVE - API ke bina
  void forceLeaveRoom() {
    _leaveSuccess = true;
    _errorMessage = '';
    clearMinimizedState();
    _showExitDialog = false;
    print("🔄 Force leaving room");
    notifyListeners();
  }

  void resetLeaveStatus() {
    _isLoading = false;
    _errorMessage = '';
    _leaveResponse = null;
    _leaveSuccess = false;
    _showExitDialog = false;
    notifyListeners();
  }
}