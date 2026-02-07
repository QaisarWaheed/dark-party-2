import 'package:shaheen_star_app/model/gift_transaction_model.dart';

/// ================= ROOM RANKING MODEL =================
class RoomRanking {
  final int roomId;
  final String roomName;
  final String? roomCode;
  final String? roomTopic;
  final String? roomProfileImage;
  final int? creatorId;
  final String? creatorName;
  final int totalGiftsSent;
  final int totalGoldValue;
  final int totalDiamondValue;
  final int uniqueSenders;
  final int uniqueReceivers;
  final int weeklyGiftsSent;
  final int monthlyGiftsSent;
  final int todayGiftsSent;
  // Gold values for each period
  final int weeklyGoldValue;
  final int monthlyGoldValue;
  final int todayGoldValue;

  RoomRanking({
    required this.roomId,
    required this.roomName,
    this.roomCode,
    this.roomTopic,
    this.roomProfileImage,
    this.creatorId,
    this.creatorName,
      required this.totalGiftsSent,
      required this.totalGoldValue,
      required this.totalDiamondValue,
      required this.uniqueSenders,
      required this.uniqueReceivers,
      required this.weeklyGiftsSent,
      required this.monthlyGiftsSent,
      required this.todayGiftsSent,
      required this.weeklyGoldValue,
      required this.monthlyGoldValue,
      required this.todayGoldValue,
  });

  factory RoomRanking.fromJson(Map<String, dynamic> json) {
    // Handle nested gift_analytics structure from actual API response
    final giftAnalytics = json['gift_analytics'] ?? {};
    final totalStats = giftAnalytics['total'] ?? {};
    final weeklyStats = giftAnalytics['weekly'] ?? {};
    final monthlyStats = giftAnalytics['monthly'] ?? {};
    final todayStats = giftAnalytics['today'] ?? {};

    // Handle creator object
    final creator = json['creator'] ?? {};
    final creatorId = creator['id'] ?? json['creator_id'];

    // Parse gold values - handle both int and string types
    int parseGoldValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    final roomId = json['room_id'] ?? json['id'] ?? 0;
    final roomName = json['room_name'] ?? json['name'] ?? 'Unknown Room';
    
    // Debug print to verify parsing
    print("🔹 Parsing Room: $roomName (ID: $roomId)");
    print("   - Today gold_value: ${todayStats['gold_value']}");
    print("   - Weekly gold_value: ${weeklyStats['gold_value']}");
    print("   - Monthly gold_value: ${monthlyStats['gold_value']}");
    print("   - Total gold_value: ${totalStats['gold_value']}");

    return RoomRanking(
      roomId: roomId is int ? roomId : int.tryParse(roomId.toString()) ?? 0,
      roomName: roomName,
      roomCode: json['room_code'] ?? json['code'],
      roomTopic: json['topic'],
      roomProfileImage: json['room_profile'],
      creatorId: creatorId != null ? (creatorId is int ? creatorId : int.tryParse(creatorId.toString())) : null,
      creatorName: creator['username'] ?? creator['name'] ?? json['creator_name'],
      totalGiftsSent: totalStats['gifts_sent'] ?? 0,
      totalGoldValue: parseGoldValue(totalStats['gold_value']),
      totalDiamondValue: parseGoldValue(totalStats['diamond_value']),
      uniqueSenders: totalStats['unique_senders'] ?? 0,
      uniqueReceivers: totalStats['unique_receivers'] ?? 0,
      weeklyGiftsSent: weeklyStats['gifts_sent'] ?? 0,
      monthlyGiftsSent: monthlyStats['gifts_sent'] ?? 0,
      todayGiftsSent: todayStats['gifts_sent'] ?? 0,
      weeklyGoldValue: parseGoldValue(weeklyStats['gold_value']),
      monthlyGoldValue: parseGoldValue(monthlyStats['gold_value']),
      todayGoldValue: parseGoldValue(todayStats['gold_value']),
    );
  }
}

/// ================= ROOM STATS RESPONSE MODEL =================
class RoomStatsResponse {
  final String status;
  final String message;
    final GiftTransactionsData1 data;
    
  final List<RoomRanking> rooms;
  final Map<String, dynamic>? summary;

  RoomStatsResponse({
    required this.status,
    required this.message,
    required this.rooms,
    required this.data,
    this.summary,
  });

  factory RoomStatsResponse.fromJson(Map<String, dynamic> json) {
    List<RoomRanking> roomsList = [];
    
    if (json['data'] != null) {
      if (json['data'] is List) {
        roomsList = (json['data'] as List)
            .map((e) => RoomRanking.fromJson(e))
            .toList();
      } else if (json['data']['rooms'] != null) {
        roomsList = (json['data']['rooms'] as List)
            .map((e) => RoomRanking.fromJson(e))
            .toList();
      }
    } else if (json['rooms'] != null) {
      roomsList = (json['rooms'] as List)
          .map((e) => RoomRanking.fromJson(e))
          .toList();
    }

    return RoomStatsResponse(
      status: json['status'] ?? 'success',
      message: json['message'] ?? '',
          data: GiftTransactionsData1.fromJson(json['data']),
      rooms: roomsList,
      summary: json['summary'] ?? json['data']?['summary'],
    );
  }
}

