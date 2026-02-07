class BanUserResponse {
  final String status;
  final String message;
  final BanData? data;

  BanUserResponse({required this.status, required this.message, this.data});

  factory BanUserResponse.fromJson(Map<String, dynamic> json) {
    return BanUserResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? BanData.fromJson(json['data']) : null,
    );
  }
}

class BanData {
  final int bannedUserId;
  final int roomId;
  final int bannedBy;
  final String banDuration;
  final String bannedUntil;
  final String bannedAt;

  BanData({
    required this.bannedUserId,
    required this.roomId,
    required this.bannedBy,
    required this.banDuration,
    required this.bannedUntil,
    required this.bannedAt,
  });

  factory BanData.fromJson(Map<String, dynamic> json) {
    return BanData(
      bannedUserId: json['banned_user_id'],
      roomId: json['room_id'],
      bannedBy: json['banned_by'],
      banDuration: json['ban_duration'],
      bannedUntil: json['banned_until'],
      bannedAt: json['banned_at'],
    );
  }
}
