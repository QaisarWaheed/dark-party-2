class GiftTransactionsResponse1 {
  final String status;
  final String message;
  final GiftTransactionsData1 data;

  GiftTransactionsResponse1({
    required this.status,
    required this.message,
    required this.data,
  });

  factory GiftTransactionsResponse1.fromJson(Map<String, dynamic> json) {
    return GiftTransactionsResponse1 (
      status: json['status'],
      message: json['message'],
      data: GiftTransactionsData1.fromJson(json['data']),
    );
  }
}

// ================= DATA =================

class GiftTransactionsData1 {
  final List<GiftTransaction1> transactions;
  final Pagination1  pagination;
  final FiltersApplied1 filtersApplied;
  final Summary1 summary;
  final Metadata1 metadata;
  

  GiftTransactionsData1({
    required this.transactions,
    required this.pagination,
    required this.filtersApplied,
    required this.summary,
    required this.metadata,
  });

  factory GiftTransactionsData1.fromJson(Map<String, dynamic> json) {
    return GiftTransactionsData1(
      transactions: (json['transactions'] as List)
          .map((e) => GiftTransaction1.fromJson(e))
          .toList(),
      pagination: Pagination1.fromJson(json['pagination']),
      filtersApplied: FiltersApplied1.fromJson(json['filters_applied']),
      summary: Summary1.fromJson(json['room_statistics']),
      metadata: Metadata1 .fromJson(json['metadata']),
    );
  }
}

// ================= TRANSACTION =================

class GiftTransaction1 {
  final int id;
  final int transactionId;
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
  final int seatNumber;
  final String createdAt;
  final String dateOnly;
  final String timeOnly;
  final String message;

  GiftTransaction1({
    required this.id,
    required this.transactionId,
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
    required this.seatNumber,
    required this.createdAt,
    required this.dateOnly,
    required this.timeOnly,
    required this.message,
  });

  factory GiftTransaction1.fromJson(Map<String, dynamic> json) {
    return GiftTransaction1(
      id: json['id'],
      transactionId: json['transaction_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      senderUsername: json['sender_username'],
      receiverUsername: json['receiver_username'],
      giftId: json['gift_id'],
      giftName: json['gift_name'],
      giftImage: json['gift_image'],
      giftPrice: json['gift_price'],
      coinType: json['coin_type'],
      roomId: json['room_id'],
      seatNumber: json['seat_number'],
      createdAt: json['created_at'],
      dateOnly: json['date_only'],
      timeOnly: json['time_only'],
      message: json['message'],
    );
  }
}

// ================= PAGINATION =================

class Pagination1    {
  final int currentPage;
  final int totalPages;
  final int totalTransactions;
  final int transactionsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  Pagination1({
    required this.currentPage,
    required this.totalPages,
    required this.totalTransactions,
    required this.transactionsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory Pagination1.fromJson(Map<String, dynamic> json) {
    return Pagination1(
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      totalTransactions: json['total_transactions'],
      transactionsPerPage: json['transactions_per_page'],
      hasNextPage: json['has_next_page'],
      hasPreviousPage: json['has_previous_page'],
    );
  }
}

// ================= FILTERS =================

class FiltersApplied1 {
  final String? senderId;
  final String? receiverId;
  final String? giftId;
  final String? roomId;
  final String? coinType;
  final String? startDate;
  final String? endDate;
  final String sortBy;
  final String sortOrder;

  FiltersApplied1({
    this.senderId,
    this.receiverId,
    this.giftId,
    this.roomId,
    this.coinType,
    this.startDate,
    this.endDate,
    required this.sortBy,
    required this.sortOrder,
  });

  factory FiltersApplied1.fromJson(Map<String, dynamic> json) {
    return FiltersApplied1(
      senderId: json['sender_id']?.toString(),
      receiverId: json['receiver_id']?.toString(),
      giftId: json['gift_id']?.toString(),
      roomId: json['room_id']?.toString(),
      coinType: json['coin_type'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      sortBy: json['sort_by'],
      sortOrder: json['sort_order'],
    );
  }
}

// ================= SUMMARY =================

class Summary1 {
  final int totalTransactions;
  final int todayTransactions;
  final List<CoinSummary1> byCoinType;
  final int uniqueSenders;
  final int uniqueReceivers;
  final int uniqueGifts;
  final Last24Hours1 last24Hours;

  Summary1({
    required this.totalTransactions,
    required this.todayTransactions,
    required this.byCoinType,
    required this.uniqueSenders,
    required this.uniqueReceivers,
    required this.uniqueGifts,
    required this.last24Hours,
  });

  factory Summary1.fromJson(Map<String, dynamic> json) {
    return Summary1   (
      totalTransactions: json['total_transactions'],
      todayTransactions: json['today_transactions'],
      byCoinType: (json['by_coin_type'] as List)
          .map((e) => CoinSummary1.fromJson(e))
          .toList(),
      uniqueSenders: json['unique_senders'],
      uniqueReceivers: json['unique_receivers'],
      uniqueGifts: json['unique_gifts'],
      last24Hours: Last24Hours1.fromJson(json['last_24_hours']),
    );
  }
}

class CoinSummary1 {
  final String coinType;
  final int count;
  final int totalValue;

  CoinSummary1({
    required this.coinType,
    required this.count,
    required this.totalValue,
  });

  factory CoinSummary1.fromJson(Map<String, dynamic> json) {
    return CoinSummary1(
      coinType: json['coin_type'],
      count: json['count'],
      totalValue: json['total_value'],
    );
  }
}

class Last24Hours1 {
  final int count;
  final int totalValue;

  Last24Hours1({
    required this.count,
    required this.totalValue,
  });

  factory Last24Hours1.fromJson(Map<String, dynamic> json) {
    return Last24Hours1(
      count: json['count'],
      totalValue: json['total_value'],
    );
  }
}

// ================= METADATA =================

class Metadata1 {
  final String timestamp;
  final String serverTimezone;
  final String apiVersion;
  final int totalReturned;

  Metadata1({
    required this.timestamp,
    required this.serverTimezone,
    required this.apiVersion,
    required this.totalReturned,
  });

  factory Metadata1.fromJson(Map<String, dynamic> json) {
    return Metadata1(
      timestamp: json['timestamp'],
      serverTimezone: json['server_timezone'],
      apiVersion: json['api_version'],
      totalReturned: json['total_returned'],
    );
  }
}
