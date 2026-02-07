class RoomGiftResponse {
  final String status;
  final String message;
  final UnifiedData data;

  RoomGiftResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory RoomGiftResponse.fromJson(Map<String, dynamic> json) {
    return RoomGiftResponse(
      status: json['status'],
      message: json['message'],
      data: UnifiedData.fromJson(json['data']),
    );
  }
}
class UnifiedData {
  // All rooms API
  final OverallStatistics? overallStatistics;
  final List<TopRoom>? topRoomsByValue;
  final List<Room>? rooms;

  // Single room API
  final Room? room;

  UnifiedData({
    this.overallStatistics,
    this.topRoomsByValue,
    this.rooms,
    this.room,
  });

  factory UnifiedData.fromJson(Map<String, dynamic> json) {
    return UnifiedData(
      overallStatistics: json['overall_statistics'] != null
          ? OverallStatistics.fromJson(json['overall_statistics'])
          : null,

      topRoomsByValue: json['top_rooms_by_value'] != null
          ? (json['top_rooms_by_value'] as List)
              .map((e) => TopRoom.fromJson(e))
              .toList()
          : null,

      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((e) => Room.fromJson(e))
              .toList()
          : null,

      // Single room fallback
      room: json['room_info'] != null
          ? Room.fromSingleRoomJson(json)
          : null,
    );
  }
}
class Room {
  final AllUsers allSenders;
  final AllUsers allReceivers;
  final String apiEndpoint;

  Room({
    required this.allSenders,
    required this.allReceivers,
    required this.apiEndpoint,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      allSenders: AllUsers.fromJson(json['all_senders']),
      allReceivers: AllUsers.fromJson(json['all_receivers']),
     
      apiEndpoint: json['api_endpoint'],
    );
  }

  // 👇 For single-room API
  factory Room.fromSingleRoomJson(Map<String, dynamic> json) {
    return Room(
      allSenders: AllUsers.fromJson(json['all_senders']),
      allReceivers: AllUsers.fromJson(json['all_receivers']),
      apiEndpoint: json['api_endpoint'] ?? '',
    );
  }
}
class OverallStatistics {
  final int totalRooms;
  final int totalTransactions;
  final int totalGiftValue;
  final int totalUniqueSenders;
  final int totalUniqueReceivers;
  final int totalUniqueGifts;

  OverallStatistics({
    required this.totalRooms,
    required this.totalTransactions,
    required this.totalGiftValue,
    required this.totalUniqueSenders,
    required this.totalUniqueReceivers,
    required this.totalUniqueGifts,
  });

  factory OverallStatistics.fromJson(Map<String, dynamic> json) {
    return OverallStatistics(
      totalRooms: json['total_rooms'],
      totalTransactions: json['total_transactions'],
      totalGiftValue: json['total_gift_value'],
      totalUniqueSenders: json['total_unique_senders'],
      totalUniqueReceivers: json['total_unique_receivers'],
      totalUniqueGifts: json['total_unique_gifts'],
    );
  }
}
class TopRoom {
  final int roomId;
  final String roomName;
  final int totalTransactions;
  final int totalGiftValue;
  final String apiEndpoint;

  TopRoom({
    required this.roomId,
    required this.roomName,
    required this.totalTransactions,
    required this.totalGiftValue,
    required this.apiEndpoint,
  });

  factory TopRoom.fromJson(Map<String, dynamic> json) {
    return TopRoom(
      roomId: json['room_id'],
      roomName: json['room_name'],
      totalTransactions: json['total_transactions'],
      totalGiftValue: json['total_gift_value'],
      apiEndpoint: json['api_endpoint'],
    );
  }
}
class AllUsers {
  final List<User> list;

  AllUsers({ required this.list});

  factory AllUsers.fromJson(Map<String, dynamic> json) {
    return AllUsers(
      list: (json['list'] as List)
          .map((e) => User.fromJson(e))
          .toList(),
    );
  }
}
class User {
  final int userId;
  final String username;
  final int totalGifts;
  final int totalValue;
  final int uniqueCount;
  final String firstGiftTime;
  final String lastGiftTime;
  final String apiEndpoint;

  User({
    required this.userId,
    required this.username,
    required this.totalGifts,
    required this.totalValue,
    required this.uniqueCount,
    required this.firstGiftTime,
    required this.lastGiftTime,
    required this.apiEndpoint,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['sender_id'] ?? json['receiver_id'],
      username: json['username'],
      totalGifts:
          json['total_gifts_sent'] ?? json['total_gifts_received'],
      totalValue:
          json['total_value_sent'] ?? json['total_value_received'],
      uniqueCount: json['unique_receivers_sent_to'] ??
          json['unique_senders_received_from'],
      firstGiftTime: json['first_gift_time'],
      lastGiftTime: json['last_gift_time'],
      apiEndpoint: json['api_endpoint'],
    );
  }
}
