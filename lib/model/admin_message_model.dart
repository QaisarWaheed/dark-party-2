class AdminMessage {
  final int id;
  final String messageType;
  final String title;
  final String content;
  final String country;
  final DateTime createdAt;

  AdminMessage({
    required this.id,
    required this.messageType,
    required this.title,
    required this.content,
    required this.country,
    required this.createdAt,
  });

  factory AdminMessage.fromJson(Map<String, dynamic> json) {
    return AdminMessage(
      id: json['id'] ?? 0,
      messageType: json['message_type'] ?? 'application',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      country: json['country'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_type': messageType,
      'title': title,
      'content': content,
      'country': country,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ✅ Helper method for formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}