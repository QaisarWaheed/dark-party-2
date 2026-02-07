 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';

class JoinRoomProvider with ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _joinResponse;
  bool _joinSuccess = false;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get joinResponse => _joinResponse;
  bool get joinSuccess => _joinSuccess;

  Future<void> joinRoom({
    required String roomId,
    required String password,
    required bool isPrivate,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _joinResponse = null;
    _joinSuccess = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('userId');
      
      if (userId == null) {
        _errorMessage = 'User not logged in';
        return;
      }

      print("🚀 Joining room - User: $userId, Room: $roomId");

      // ✅ USE API MANAGER
      final response = await ApiManager.joinRoom(
        userId: userId,
        roomId: roomId,
        password: password,
        isPrivate: isPrivate,
      );

      _joinResponse = response;

      if (response['status'] == 'success') {
        _joinSuccess = true;
        _errorMessage = '';
        print("🎉 Room joined successfully!");
      } else {
        _errorMessage = response['message'] ?? 'Failed to join room';
        _joinSuccess = false;
        print("❌ Join failed: $_errorMessage");
      }
    } catch (e) {
      _errorMessage = 'Join room error: $e';
      _joinSuccess = false;
      print("❌ Join Room Exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _isLoading = false;
    _errorMessage = '';
    _joinResponse = null;
    _joinSuccess = false;
    notifyListeners();
  }
}