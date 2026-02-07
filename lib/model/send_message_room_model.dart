


// send_message_room_model.dart
class SendMessageRoomModel {
  final String userId;
  final String roomId;
  final String message;
  final String? userName;
  final String? profileUrl;
  final String? timestamp;
  final bool isLocalMessage;
  final bool isSystemMessage;

  SendMessageRoomModel({
    required this.userId,
    required this.roomId,
    required this.message,
    this.userName,
    this.profileUrl,
    this.timestamp,
    this.isLocalMessage = false,
    this.isSystemMessage = false,
  });

  // ✅ FROM API DATA
  factory SendMessageRoomModel.fromApiData(Map<String, dynamic> data) {
    return SendMessageRoomModel(
      userId: data['user_id']?.toString() ?? '',
      roomId: data['room_id']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      userName: data['user_name']?.toString() ?? data['username']?.toString(),
      profileUrl: data['profile_url']?.toString(),
      timestamp: data['timestamp']?.toString() ?? data['sent_at']?.toString(),
      isLocalMessage: false,
      isSystemMessage: data['is_system_message'] == true,
    );
  }

  // ✅ CREATE LOCAL MESSAGE
  factory SendMessageRoomModel.createLocal({
    required String userId,
    required String roomId,
    required String message,
    required String userName,
    String? profileUrl,
  }) {
    return SendMessageRoomModel(
      userId: userId,
      roomId: roomId,
      message: message,
      userName: userName,
      profileUrl: profileUrl,
      timestamp: DateTime.now().toIso8601String(),
      isLocalMessage: true,
      isSystemMessage: false,
    );
  }

  // ✅ CREATE SYSTEM MESSAGE
  factory SendMessageRoomModel.createSystemMessage({
    required String roomId,
    required String message,
  }) {
    return SendMessageRoomModel(
      userId: 'system',
      roomId: roomId,
      message: message,
      userName: 'System',
      profileUrl: null,
      timestamp: DateTime.now().toIso8601String(),
      isLocalMessage: true,
      isSystemMessage: true,
    );
  }

  // ✅ CREATE FROM WEBSOCKET (for real-time messages from other users)
  factory SendMessageRoomModel.createFromWebSocket({
    required String userId,
    required String roomId,
    required String message,
    required String userName,
    String? profileUrl,
    String? timestamp,
  }) {
    return SendMessageRoomModel(
      userId: userId,
      roomId: roomId,
      message: message,
      userName: userName,
      profileUrl: profileUrl,
      timestamp: timestamp ?? DateTime.now().toIso8601String(),
      isLocalMessage: false,
      isSystemMessage: false,
    );
  }

  // ✅ FROM JSON
  factory SendMessageRoomModel.fromJson(Map<String, dynamic> json) {
    return SendMessageRoomModel(
      userId: json['user_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      userName: json['user_name']?.toString(),
      profileUrl: json['profile_url']?.toString(),
      timestamp: json['timestamp']?.toString(),
      isLocalMessage: json['is_local_message'] == true,
      isSystemMessage: json['is_system_message'] == true,
    );
  }

  // ✅ TO JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'message': message,
      'user_name': userName,
      'profile_url': profileUrl,
      'timestamp': timestamp,
      'is_local_message': isLocalMessage,
      'is_system_message': isSystemMessage,
    };
  }

  // ✅ GETTERS
  bool get isCurrentUser => false; // You can implement this based on your user context
  
  @override
  String toString() {
    return 'SendMessageRoomModel(userId: $userId, roomId: $roomId, message: $message, userName: $userName, isLocal: $isLocalMessage, isSystem: $isSystemMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SendMessageRoomModel &&
        other.userId == userId &&
        other.roomId == roomId &&
        other.message == message &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ roomId.hashCode ^ message.hashCode ^ timestamp.hashCode;
  }
}