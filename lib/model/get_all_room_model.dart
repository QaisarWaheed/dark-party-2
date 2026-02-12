

// class GetAllRoomModel {
//   final String id;
//   final String name;
//   final String topic;
//   final String creatorName;
//   final String? roomProfile;

//   GetAllRoomModel({
//     required this.id,
//     required this.name,
//     required this.topic,
//     required this.creatorName,
//     this.roomProfile,
//   });

//   factory GetAllRoomModel.fromJson(Map<String, dynamic> json) {
//     return GetAllRoomModel(
//       id: json["id"].toString(),
//       name: json["name"] ?? "",
//       topic: json["topic"] ?? "",
//       creatorName: json["creator_name"]?.trim() ?? "",
//       roomProfile: json["room_profile"],
//     );
//   }
// }


class GetAllRoomModel {
  final String id;
  final String name;
  final String topic;
  final String creatorName;
  final String? creatorId;
  final String? roomProfile;
  final String? creatorProfileUrl; // ✅ Store creator's profile URL
  final   String? countryFlag;
  final int? views;
  final String roomCode; // ✅ NAYA FIELD ADD KARO
  final int? participantCount; // ✅ Total members currently in room
  final List<String>? participantAvatars; // ✅ Avatars of users currently joined in room

  GetAllRoomModel({
    required this.id,
    required this.name,
    required this.topic,
    required this.creatorName,
    this.creatorId,
    this.roomProfile,
    this.creatorProfileUrl, 
    this.countryFlag,
    this.views,
    required this.roomCode, // ✅ NAYA FIELD ADD KARO
    this.participantCount, // ✅ Total members currently in room
    this.participantAvatars,
  });

  factory GetAllRoomModel.fromJson(Map<String, dynamic> json) {
    // Debug: Print all available keys to see what fields backend returns
    print("🔍 Room JSON keys: ${json.keys.toList()}");
    print("🔍 Room JSON: $json");
    
    // Try multiple possible field names for views
    int? viewsValue;
    if (json["views"] != null) {
      try {
        viewsValue = int.parse(json["views"].toString());
      } catch (e) {
        print("⚠️ Error parsing views: $e");
      }
    } else if (json["view_count"] != null) {
      try {
        viewsValue = int.parse(json["view_count"].toString());
      } catch (e) {
        print("⚠️ Error parsing view_count: $e");
      }
    } else if (json["total_views"] != null) {
      try {
        viewsValue = int.parse(json["total_views"].toString());
      } catch (e) {
        print("⚠️ Error parsing total_views: $e");
      }
    } else if (json["viewers"] != null) {
      try {
        viewsValue = int.parse(json["viewers"].toString());
      } catch (e) {
        print("⚠️ Error parsing viewers: $e");
      }
    } else if (json["participant_count"] != null) {
      // ✅ Use participant_count as fallback for views (current live viewers)
      try {
        viewsValue = int.parse(json["participant_count"].toString());
        print("✅ Using participant_count as views: $viewsValue");
      } catch (e) {
        print("⚠️ Error parsing participant_count: $e");
      }
    }
    
    print("🔍 Parsed views value: $viewsValue");
    
    // ✅ Parse participant_count for total members
    int? participantCountValue;
    if (json["participant_count"] != null) {
      try {
        participantCountValue = int.parse(json["participant_count"].toString());
        print("✅ Parsed participant_count (total members): $participantCountValue");
      } catch (e) {
        print("⚠️ Error parsing participant_count: $e");
      }
    } else if (json["total_members"] != null) {
      try {
        participantCountValue = int.parse(json["total_members"].toString());
        print("✅ Parsed total_members: $participantCountValue");
      } catch (e) {
        print("⚠️ Error parsing total_members: $e");
      }
    } else if (json["current_members"] != null) {
      try {
        participantCountValue = int.parse(json["current_members"].toString());
        print("✅ Parsed current_members: $participantCountValue");
      } catch (e) {
        print("⚠️ Error parsing current_members: $e");
      }
    }

    List<String>? participantAvatarsValue;
    if (json["participant_avatars"] != null && json["participant_avatars"] is List) {
      participantAvatarsValue = (json["participant_avatars"] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return GetAllRoomModel(
      id: json["id"].toString(),
      name: json["name"] ?? "",
      topic: json["topic"] ?? "",
      creatorName: json["creator_name"]?.trim() ?? "",
      creatorId: json["creator_id"]?.toString(),
      roomProfile: json["room_profile"],
      creatorProfileUrl: json["creator_profile_url"] ?? "",
      countryFlag: json["country_flag"] ?? "",
      views: viewsValue ?? 0,
      roomCode: json["room_code"] ?? "", // ✅ YEH ADD KARO
      participantCount: participantCountValue ?? 0, // ✅ Total members currently in room
      participantAvatars: participantAvatarsValue,
    );
  }
}