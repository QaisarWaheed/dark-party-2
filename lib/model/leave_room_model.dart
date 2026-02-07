class LeaveRoomModel {
  final String status;
  final String message;
  final LeaveRoomData? data;

  LeaveRoomModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory LeaveRoomModel.fromJson(Map<String, dynamic> json) {
    return LeaveRoomModel(
      status: json['status'] ?? 'error',
      message: json['message'] ?? '',
      data: json['data'] != null ? LeaveRoomData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class LeaveRoomData {
  final String userId;
  final String roomId;
  final String leftAt;

  LeaveRoomData({
    required this.userId,
    required this.roomId,
    required this.leftAt,
  });

  factory LeaveRoomData.fromJson(Map<String, dynamic> json) {
    return LeaveRoomData(
      userId: json['user_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      leftAt: json['left_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'left_at': leftAt,
    };
  }
}