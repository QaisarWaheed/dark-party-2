// gift_transaction_model.dart

class GiftTransactionResponse1 {
  final String status;
  final String message;
  final GiftTransactionData data;

  GiftTransactionResponse1({
    required this.status,
    required this.message,
    required this.data,
  });

  bool get success => status.toLowerCase() == 'success';

  factory GiftTransactionResponse1.fromJson(Map<String, dynamic> json) {
    return GiftTransactionResponse1(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: GiftTransactionData.fromJson(json['data'] ?? {}),
    );
  }
}

// ======================================================

class GiftTransactionData {
  final List<GiftTransaction> transactions;
  final Pagination pagination;
  final Summary summary;

  GiftTransactionData({
    required this.transactions,
    required this.pagination,
    required this.summary,
  });

  factory GiftTransactionData.fromJson(Map<String, dynamic> json) {
    return GiftTransactionData(
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => GiftTransaction.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      summary: Summary.fromJson(json['summary'] ?? {}),
    );
  }
}

// ======================================================

class GiftTransaction {
  final int id;
  final int senderId;
  final int receiverId;
  final String senderUsername;
  final String receiverUsername;
  final int giftId;
  final String giftName;
  final String giftImage;
  final int giftPrice;
  final String coinType;
  final int roomId;
  final String createdAt;
  final String dateOnly;
  final String timeOnly;
  final String message;

  GiftTransaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderUsername,
    required this.receiverUsername,
    required this.giftId,
    required this.giftName,
    required this.giftImage,
    required this.giftPrice,
    required this.coinType,
    required this.roomId,
    required this.createdAt,
    required this.dateOnly,
    required this.timeOnly,
    required this.message,
  });

  factory GiftTransaction.fromJson(Map<String, dynamic> json) {
    return GiftTransaction(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      senderUsername: json['sender_username'] ?? 'Unknown',
      receiverUsername: json['receiver_username'] ?? 'Unknown',
      giftId: json['gift_id'] ?? 0,
      giftName: json['gift_name'] ?? '',
      giftImage: json['gift_image'] ?? '',
      giftPrice: json['gift_price'] ?? 0,
      coinType: json['coin_type'] ?? '',
      roomId: json['room_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      dateOnly: json['date_only'] ?? '',
      timeOnly: json['time_only'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

// ======================================================

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalTransactions;
  final int transactionsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalTransactions,
    required this.transactionsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalTransactions: json['total_transactions'] ?? 0,
      transactionsPerPage: json['transactions_per_page'] ?? 0,
      hasNextPage: json['has_next_page'] ?? false,
      hasPreviousPage: json['has_previous_page'] ?? false,
    );
  }
}

// ======================================================

class Summary {
  final int totalTransactions;
  final int todayTransactions;
  final int uniqueSenders;
  final int uniqueReceivers;
  final int uniqueGifts;

  Summary({
    required this.totalTransactions,
    required this.todayTransactions,
    required this.uniqueSenders,
    required this.uniqueReceivers,
    required this.uniqueGifts,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalTransactions: json['total_transactions'] ?? 0,
      todayTransactions: json['today_transactions'] ?? 0,
      uniqueSenders: json['unique_senders'] ?? 0,
      uniqueReceivers: json['unique_receivers'] ?? 0,
      uniqueGifts: json['unique_gifts'] ?? 0,
    );
  }
}
