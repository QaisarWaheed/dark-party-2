import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
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

  /// 🟣 Fetch all rooms from API
  Future<void> fetchRooms() async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await ApiManager.getAllRooms();
      _rooms = data.map((e) => GetAllRoomModel.fromJson(e)).toList();
      await _fetchCreatorProfiles();
    } catch (e, stackTrace) {
      debugPrint("❌ [GetAllRoomProvider] fetchRooms: $e");
    }

    isLoading = false;
    notifyListeners();
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
        );
      }).toList();
      
      debugPrint("✅ Fetched creator profiles and countries for ${_rooms.length} rooms");
    } catch (e) {
      debugPrint("❌ Error fetching creator profiles: $e");
    }
  }
}
