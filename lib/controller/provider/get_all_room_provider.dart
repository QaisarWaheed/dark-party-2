import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/api_manager/room_list_websocket_service.dart';
import 'package:shaheen_star_app/model/get_all_room_model.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';

class GetAllRoomProvider with ChangeNotifier {
  List<GetAllRoomModel> _rooms = [];
  Map<int, Map<String, dynamic>> allUsersMap = {};
  List<GetAllRoomModel> get rooms => _rooms;

  bool isLoading = false;

  // ✅ Cache for user profiles (key: user_id or name, value: profile_url)
  final Map<String, String> _userProfileCache = {};

  // ✅ Cache for user countries (key: user_id or name, value: country name)
  final Map<String, String> _userCountryCache = {};

  // ✅ Room list WebSocket (push updates for participant count)
  final RoomListWebSocketService _roomListWs =
      RoomListWebSocketService.instance;
  bool _roomListWsInitialized = false;

  /// 🟣 Fetch all rooms from API
  Future<void> fetchRooms() async {
    print("🔄 [GetAllRoomProvider] fetchRooms() called - reloading all rooms");
    isLoading = true;
    notifyListeners();

    try {
      final data = await ApiManager.getAllRooms();
      _rooms = data.map((e) => GetAllRoomModel.fromJson(e)).toList();
      print("✅ [GetAllRoomProvider] Loaded ${_rooms.length} rooms from API");
      await _fetchCreatorProfiles();
      _ensureRoomListWs();
    } catch (e, stackTrace) {
      debugPrint("❌ [GetAllRoomProvider] fetchRooms: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  void _ensureRoomListWs() {
    if (_roomListWsInitialized) return;
    _roomListWsInitialized = true;

    _roomListWs.connect();
    _roomListWs.on('user:joined', _handleRoomUserJoined);
    _roomListWs.on('user:left', _handleRoomUserLeft);
    _roomListWs.on('room:count', _handleRoomCountUpdate);

    // ✅ Join all rooms to receive their broadcasts (user:joined, user:left, room:count)
    Future.delayed(const Duration(milliseconds: 300), _joinAllRooms);

    // ❌ DISABLED: Periodic API refresh was causing double-counting
    // The API refresh + notifyListeners -> rebuild -> fetchRooms() cycle was duplicating updates
    // Instead, rely on WebSocket events only
    print(
      "✅ [GetAllRoomProvider] WebSocket initialized - relying on live events only",
    );
  }

  void _joinAllRooms() {
    for (final room in _rooms) {
      if (room.id != null) {
        // ✅ Reset count to 0 before requesting actual count from server
        final index = _rooms.indexWhere((r) => r.id == room.id);
        if (index != -1) {
          _rooms[index] = _copyRoom(_rooms[index], participantCount: 0);
        }

        _roomListWs.joinRoom(room.id!);
        // ✅ Request initial count for each room
        _roomListWs.requestRoomCount(room.id!);
      }
    }

    // ✅ Notify after all resets
    notifyListeners();
  }

  @override
  void dispose() {
    _roomListWs.offAll('user:joined');
    _roomListWs.offAll('user:left');
    _roomListWs.offAll('room:count');

    // ✅ Leave all rooms we joined
    for (final room in _rooms) {
      if (room.id != null) {
        _roomListWs.leaveRoom(room.id!);
      }
    }

    _roomListWs.disconnect();
    super.dispose();
  }

  void _handleRoomUserJoined(Map<String, dynamic> data) {
    // ✅ When user joins, increment count by 1
    final roomId = _extractRoomId(data);
    if (roomId == null) {
      print("⚠️ [GetAllRoomProvider] user:joined event missing room_id: $data");
      return;
    }

    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index == -1) {
      print("⚠️ [GetAllRoomProvider] user:joined for unknown room: $roomId");
      return;
    }

    final currentCount = _rooms[index].participantCount ?? 0;
    final newCount = currentCount + 1;

    _rooms[index] = _copyRoom(_rooms[index], participantCount: newCount);
    print(
      "👤 [GetAllRoomProvider] Room $roomId: user joined → $currentCount → $newCount",
    );

    notifyListeners();
  }

  void _handleRoomUserLeft(Map<String, dynamic> data) {
    // ✅ When user leaves, decrement count by 1
    final roomId = _extractRoomId(data);
    if (roomId == null) {
      print("⚠️ [GetAllRoomProvider] user:left event missing room_id: $data");
      return;
    }

    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index == -1) {
      print("⚠️ [GetAllRoomProvider] user:left for unknown room: $roomId");
      return;
    }

    final currentCount = _rooms[index].participantCount ?? 0;
    final newCount = (currentCount - 1).clamp(0, 999);

    _rooms[index] = _copyRoom(_rooms[index], participantCount: newCount);
    print(
      "👋 [GetAllRoomProvider] Room $roomId: user left → $currentCount → $newCount",
    );

    notifyListeners();
  }

  void _handleRoomCountUpdate(Map<String, dynamic> data) {
    final roomId = _extractRoomId(data);
    if (roomId == null) {
      print("⚠️ [GetAllRoomProvider] room:count event has no room_id: $data");
      return;
    }

    final count = _parseCountFromEvent(data);
    if (count == null) {
      print(
        "⚠️ [GetAllRoomProvider] room:count event has no valid count field. Event data: $data",
      );
      return;
    }

    final safeCount = count < 0 ? 0 : count;

    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index == -1) {
      print(
        "⚠️ [GetAllRoomProvider] room:count received for unknown room: $roomId",
      );
      return;
    }

    final oldCount = _rooms[index].participantCount ?? 0;
    _rooms[index] = _copyRoom(_rooms[index], participantCount: safeCount);

    print(
      "📊 [GetAllRoomProvider] Room $roomId count updated: $oldCount → $safeCount (from event: $data)",
    );
    notifyListeners();
  }

  String? _extractRoomId(Map<String, dynamic> data) {
    if (data.containsKey('room_id')) return data['room_id']?.toString();
    if (data.containsKey('roomId')) return data['roomId']?.toString();
    if (data.containsKey('room')) return data['room']?.toString();

    if (data.containsKey('data') && data['data'] is Map) {
      final eventData = data['data'] as Map;
      return eventData['room_id']?.toString() ??
          eventData['roomId']?.toString() ??
          eventData['room']?.toString();
    }

    return null;
  }

  int? _parseCountFromEvent(Map<String, dynamic> data) {
    // ✅ Try direct fields first
    dynamic raw =
        data['participant_count'] ??
        data['total_members'] ??
        data['current_members'] ??
        data['count'];

    // ✅ Try nested 'data' object
    if (raw == null && data.containsKey('data') && data['data'] is Map) {
      final eventData = data['data'] as Map;
      raw =
          eventData['participant_count'] ??
          eventData['total_members'] ??
          eventData['current_members'] ??
          eventData['count'];
    }

    if (raw == null) return null;

    // ✅ If it's a list, return the length (in case server sends user list instead of count)
    if (raw is List) {
      print(
        "🔍 [GetAllRoomProvider] Received list instead of count, using length: ${raw.length}",
      );
      return raw.length;
    }

    return int.tryParse(raw.toString());
  }

  // ❌ DISABLED: API refresh was causing double-counting
  // The cycle was: API refresh → notifyListeners → rebuild → fetchRooms() → another count update
  // Now we rely entirely on WebSocket user:joined/user:left events for real-time accurate counts

  GetAllRoomModel _copyRoom(
    GetAllRoomModel room, {
    int? participantCount,
    List<String>? participantAvatars,
  }) {
    return GetAllRoomModel(
      id: room.id,
      roomCode: room.roomCode,
      name: room.name,
      topic: room.topic,
      creatorName: room.creatorName,
      creatorId: room.creatorId,
      roomProfile: room.roomProfile,
      creatorProfileUrl: room.creatorProfileUrl,
      countryFlag: room.countryFlag,
      views: room.views,
      participantCount: participantCount ?? room.participantCount,
      participantAvatars: participantAvatars ?? room.participantAvatars,
    );
  }

  /// ✅ Fetch creator profile URLs and countries from getAllUsers API
  Future<void> _fetchCreatorProfiles() async {
    try {
      // ✅ Fetch all users to get their profile URLs and countries
      final allUsers = await ApiManager.getAllUsers();

      // ✅ Build cache: map user_id and name to profile_url and country
      for (var user in allUsers) {
        final userMap = user as Map<String, dynamic>;
        final userId = userMap['id'];
        if (userId != null) {
          allUsersMap[userId] = userMap;

          final userName = userMap['name']?.toString() ?? '';
          final profileUrl = userMap['profile_url']?.toString();
          final country = userMap['country']?.toString() ?? '';

          // Optional: cache profile and country by userId and name
          if (profileUrl != null && profileUrl.isNotEmpty) {
            _userProfileCache[userId.toString()] = profileUrl;
            if (userName.isNotEmpty) {
              _userProfileCache[userName.toLowerCase().trim()] = profileUrl;
            }
          }

          if (country.isNotEmpty) {
            _userCountryCache[userId.toString()] = country;
            if (userName.isNotEmpty) {
              _userCountryCache[userName.toLowerCase().trim()] = country;
            }
          }
        }
      }

      // ✅ Update rooms with creator profile URLs and country flags
      _rooms = _rooms.map((room) {
        String? profileUrl;
        String? countryName;
        String? countryFlag;

        // ✅ Try to find by creator_id first
        if (room.creatorId != null) {
          if (_userProfileCache.containsKey(room.creatorId)) {
            profileUrl = _userProfileCache[room.creatorId];
          }
          if (_userCountryCache.containsKey(room.creatorId)) {
            countryName = _userCountryCache[room.creatorId];
          }
        }
        // ✅ Fallback: try to find by creator name
        else if (room.creatorName.isNotEmpty) {
          final creatorNameKey = room.creatorName.toLowerCase().trim();
          if (_userProfileCache.containsKey(creatorNameKey)) {
            profileUrl = _userProfileCache[creatorNameKey];
          }
          if (_userCountryCache.containsKey(creatorNameKey)) {
            countryName = _userCountryCache[creatorNameKey];
          }
        }

        String? normalizedRoomProfile = room.roomProfile;
        if (normalizedRoomProfile != null &&
            normalizedRoomProfile.isNotEmpty &&
            normalizedRoomProfile != 'yyyy' &&
            normalizedRoomProfile != 'Profile Url' &&
            normalizedRoomProfile != 'upload' &&
            normalizedRoomProfile != 'jgh' &&
            normalizedRoomProfile != 'null') {
          // Use as-is, no URL construction
        } else {
          normalizedRoomProfile = null;
        }

        // ✅ Convert country name to flag emoji
        if (countryName != null && countryName.isNotEmpty) {
          countryFlag = CountryFlagUtils.getFlagEmoji(countryName);
        } else {
          // Use existing countryFlag from API if available, otherwise default
          countryFlag = room.countryFlag?.isNotEmpty == true
              ? room.countryFlag
              : CountryFlagUtils.getFlagEmoji(null);
        }

        // ✅ Return updated room with creator profile URL and country flag
        return GetAllRoomModel(
          id: room.id,
          roomCode: room.roomCode,
          name: room.name,
          topic: room.topic,
          creatorName: room.creatorName,
          creatorId: room.creatorId,
          roomProfile: normalizedRoomProfile, // ✅ Use normalized room profile
          creatorProfileUrl: profileUrl,
          countryFlag: countryFlag,
          views: room.views,
          participantCount: room.participantCount,
          participantAvatars: room.participantAvatars,
        );
      }).toList();

      debugPrint(
        "✅ Fetched creator profiles and countries for ${_rooms.length} rooms",
      );
    } catch (e) {
      debugPrint("❌ Error fetching creator profiles: $e");
    }
  }
}
