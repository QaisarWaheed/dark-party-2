/// Model for a single user system message from get_user_messages.php
/// (e.g. coin transaction when merchant sends coins, admin welcome 5000 coins on register)
class UserSystemMessage {
  final int id;
  final int? userId;
  final String message;
  final String? messageType;
  final num? amount;
  final String? createdAt;
  final DateTime? createdAtDate;
  final Map<String, dynamic>? raw;

  UserSystemMessage({
    required this.id,
    this.userId,
    required this.message,
    this.messageType,
    this.amount,
    this.createdAt,
    this.createdAtDate,
    this.raw,
  });

  factory UserSystemMessage.fromJson(Map<String, dynamic> json) {
    String? createdAtStr = json['created_at']?.toString();
    DateTime? dt;
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        dt = DateTime.tryParse(createdAtStr);
      } catch (_) {}
    }
    num? amount;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        amount = json['amount'] as num;
      } else {
        amount = num.tryParse(json['amount'].toString());
      }
    }
    return UserSystemMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] != null ? (json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id'].toString())) : null,
      message: json['message']?.toString() ?? '',
      messageType: json['message_type']?.toString(),
      amount: amount,
      createdAt: createdAtStr,
      createdAtDate: dt,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'message_type': messageType,
      'amount': amount,
      'created_at': createdAt,
      ...?raw,
    };
  }
}

/// Response from get_user_messages.php
class GetUserMessagesResponse {
  final bool success;
  final String? message;
  final List<UserSystemMessage> messages;
  final int? total;

  GetUserMessagesResponse({
    required this.success,
    this.message,
    required this.messages,
    this.total,
  });

  factory GetUserMessagesResponse.fromJson(Map<String, dynamic> json) {
    List<UserSystemMessage> list = [];
    dynamic data = json['data'];
    if (data is List) {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          list.add(UserSystemMessage.fromJson(item));
        } else if (item is Map) {
          list.add(UserSystemMessage.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (data is Map && data['messages'] is List) {
      for (var item in data['messages'] as List) {
        if (item is Map<String, dynamic>) {
          list.add(UserSystemMessage.fromJson(item));
        } else if (item is Map) {
          list.add(UserSystemMessage.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (json['messages'] is List) {
      for (var item in json['messages'] as List) {
        if (item is Map<String, dynamic>) {
          list.add(UserSystemMessage.fromJson(item));
        } else if (item is Map) {
          list.add(UserSystemMessage.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return GetUserMessagesResponse(
      success: json['status'] == 'success' || json['success'] == true,
      message: json['message']?.toString(),
      messages: list,
      total: json['total'] is int ? json['total'] as int : int.tryParse(json['total']?.toString() ?? ''),
    );
  }
}
