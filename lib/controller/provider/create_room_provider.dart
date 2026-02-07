


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/view/screens/room/room_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';

class CreateRoomProvider with ChangeNotifier {
  File? _avatarImage;
  bool isPrivate = false;
  bool _isLoading = false;
  bool _checkingRoom = false;
  bool _editingMode = false;
  String password = "";
  String? _errorMessage;
  Map<String, dynamic>? _existingRoomData;

  File? get avatarImage => _avatarImage;
  bool get isLoading => _isLoading;
  bool get checkingRoom => _checkingRoom;
  bool get editingMode => _editingMode;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get existingRoomData => _existingRoomData;

  /// 🟣 CHECK IF USER ALREADY HAS ROOM
  Future<bool> checkExistingRoom(String userId) async {
    _checkingRoom = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiManager.checkUserRoom(userId: userId);
      
      _checkingRoom = false;
      notifyListeners();

      // ✅ Check if response is empty
      if (response.isEmpty) {
        _errorMessage = "Network error: No response from server";
        notifyListeners();
        return false;
      }

      // ✅ Check if response has status field
      if (!response.containsKey("status")) {
        _errorMessage = "Network error: Invalid response format";
        notifyListeners();
        return false;
      }

      if (response["status"] == "success") {
        if (response["has_room"] == true) {
          _editingMode = true;
          await _fetchUserRoomDetails(userId);
          return true;
        } else {
          _editingMode = false;
          _existingRoomData = null;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = response["message"] ?? "Failed to check room status";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _checkingRoom = false;
      _errorMessage = "Network error: $e";
      notifyListeners();
      return false;
    }
  }

  /// 🟣 FETCH EXISTING ROOM DETAILS (backend API: check_user_room.php)
  /// Normalizes keys so UI can use room_id, room_name, topic, room_profile
  Future<void> _fetchUserRoomDetails(String userId) async {
    try {
      final response = await ApiManager.checkUserRoom(userId: userId);
      
      if (response["status"] == "success" && response["room"] != null) {
        final raw = response["room"] as Map<String, dynamic>;
        // Support backend keys: room_id/id, room_name/name, topic, room_profile/profile/room_profile_url
        _existingRoomData = {
          "room_id": raw["room_id"] ?? raw["id"],
          "room_name": raw["room_name"] ?? raw["name"] ?? "My Room",
          "topic": raw["topic"] ?? raw["description"] ?? "",
          "is_private": raw["is_private"] ?? raw["private"],
          "room_profile": raw["room_profile"] ?? raw["profile"] ?? raw["room_profile_url"] ?? raw["avatar"] ?? "",
        };
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_room_id_$userId', _existingRoomData!["room_id"].toString());
        await prefs.setString('user_room_name_$userId', _existingRoomData!["room_name"]?.toString() ?? '');
        await prefs.setString('user_room_topic_$userId', _existingRoomData!["topic"]?.toString() ?? '');
        await prefs.setString('user_room_private_$userId', _existingRoomData!["is_private"]?.toString() ?? '1');
        await prefs.setString('user_room_profile_$userId', _existingRoomData!["room_profile"]?.toString() ?? '');
        
        print("💾 Existing room data loaded for user: $userId");
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error fetching room details: $e");
    }
  }

  /// 🟣 LOAD EXISTING ROOM DATA FOR EDITING
  Future<void> loadExistingRoomData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    _existingRoomData = {
      "room_id": prefs.getString('user_room_id_$userId'),
      "room_name": prefs.getString('user_room_name_$userId'),
      "topic": prefs.getString('user_room_topic_$userId'),
      "is_private": prefs.getString('user_room_private_$userId'),
      "room_profile": prefs.getString('user_room_profile_$userId'),
    };
    
    print("📥 Loaded existing room data: $_existingRoomData");
    notifyListeners();
  }

  /// 🟣 Pick Room Avatar
  Future<void> pickRoomAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _avatarImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  /// 🟣 Toggle Private Room
  void togglePrivate(bool value) {
    isPrivate = value;
    if (!isPrivate) password = ""; // clear password if public
    notifyListeners();
  }

  /// 🟣 Set Password
  void setPassword(String value) {
    password = value;
  }

  /// 🟣 Clear Error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 🟣 SINGLE METHOD FOR CREATE & UPDATE ROOM
  Future<void> createOrUpdateRoom({
    required BuildContext context,
    required String roomName,
    required String topic,
    required String userId,
  }) async {
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Room name cannot be empty")),
      );
      return;
    }

    // ✅ REQUIRED: Room image is mandatory when creating a new room (not when editing)
    if (!_editingMode && _avatarImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select the room image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ If room is private, password is required
    if (isPrivate && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a password for your private room")),
      );
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? profilePath;
      if (_avatarImage != null) {
        profilePath = _avatarImage!.path;
        print("📸 Image path: $profilePath");
      }

      // ✅ SAME API FOR BOTH CREATE & UPDATE
      final response = await ApiManager.createRoom(
        name: roomName,
        topic: topic.isNotEmpty ? topic : "Welcome to our room!",
        userId: userId,
        isPrivate: isPrivate ? "0" : "1",
        password: isPrivate ? password : "",
        profile_url: profilePath,
      );

      debugPrint("🔵 Create/Update Room API Response: $response");

      // ✅ Check if response is empty
      if (response.isEmpty) {
        _errorMessage = "Network error: No response from server";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }

      // ✅ Check if response has status field
      if (!response.containsKey("status")) {
        _errorMessage = "Network error: Invalid response format";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }

      if (response["status"] == "success") {
        String roomId = response["room"]?["room_id"]?.toString() ?? "0";
        
        // ✅ Room data save karo SharedPreferences mein
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_room_id_$userId', roomId);
        await prefs.setString('user_room_name_$userId', roomName);
        await prefs.setString('user_room_topic_$userId', topic);
        await prefs.setString('user_room_private_$userId', isPrivate ? "0" : "1");
        
        if (response["room"]?["room_profile"] != null) {
          await prefs.setString('user_room_profile_$userId', response["room"]["room_profile"]);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingMode ? "Room updated successfully 🎉" : "Room created successfully 🎉")),
        );

        print("💾 Room ${_editingMode ? 'updated' : 'created'} for user $userId: $roomId");

        // ✅ Refresh rooms list immediately after creation (for real-time update)
        try {
          Provider.of<GetAllRoomProvider>(context, listen: false).fetchRooms();
          print("🔄 [CreateRoomProvider] Refreshed rooms list after room creation");
        } catch (e) {
          print("⚠️ [CreateRoomProvider] Could not refresh rooms: $e");
        }

        // ✅ Get room profile path from response or saved avatar
        String? roomProfilePath = response["room"]?["room_profile"];
        File? avatarFile;
        String? roomProfileUrl;
        
        // ✅ If room_profile is a local file path, check if it exists
        if (roomProfilePath != null && 
            (roomProfilePath.startsWith('/data/') || 
             roomProfilePath.startsWith('/storage/') || 
             roomProfilePath.contains('/cache/') ||
             roomProfilePath.contains('/data/user/'))) {
          final file = File(roomProfilePath);
          if (file.existsSync()) {
            avatarFile = file;
          } else {
            // ✅ File doesn't exist - extract filename and construct server URL
            final filename = roomProfilePath.split('/').last;
            if (filename.isNotEmpty && filename.contains('.')) {
              roomProfileUrl = 'https://shaheenstar.online/uploads/rooms/$filename';
            }
          }
        } else if (roomProfilePath != null && 
                   (roomProfilePath.startsWith('http://') || 
                    roomProfilePath.startsWith('https://'))) {
          // ✅ Already a network URL
          roomProfileUrl = roomProfilePath;
        } else if (roomProfilePath != null && 
                   roomProfilePath.startsWith('uploads/')) {
          // ✅ Relative server path
          roomProfileUrl = 'https://shaheenstar.online/$roomProfilePath';
        }
        
        // ✅ Only use _avatarImage if it's the CURRENT room's image (not from previous room)
        // Since we're creating a new room, we should only use the API response
        // Don't use _avatarImage as fallback to avoid showing old images
        
        // ✅ Clear _avatarImage after successful creation to prevent reuse
        final tempAvatarImage = _avatarImage;
        _avatarImage = null; // Clear immediately to prevent reuse
        
        // ✅ Only use tempAvatarImage if we have no other source
        // But prioritize API response over local _avatarImage
        if (avatarFile == null && roomProfileUrl == null && tempAvatarImage != null) {
          // Only use as last resort if API didn't return any profile
          final file = File(tempAvatarImage.path);
          if (file.existsSync()) {
            avatarFile = file;
          }
        }

        // ✅ Room screen par navigate karo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoomScreen(
              roomCreatorId:userId ,
              roomName: roomName,
              roomId: roomId,
              topic: topic,
              avatarUrl: avatarFile,
              roomProfileUrl: roomProfileUrl,
            ),
          ),
        );
        
        // ✅ Reset provider after navigation to clear all state
        reset();
      } else {
        _errorMessage = response["message"] ?? "Failed to ${_editingMode ? 'update' : 'create'} room";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      _errorMessage = "Something went wrong: $e";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🟣 RESET PROVIDER
  void reset() {
    _avatarImage = null;
    isPrivate = false;
    password = "";
    _errorMessage = null;
    _editingMode = false;
    _existingRoomData = null;
    notifyListeners();
  }
}