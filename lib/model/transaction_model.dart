class TransactionModel {
  final String transactionId;
  final String type; // 'transfer', 'payout', 'received', 'sent'
  final String amount;
  final String date;
  final String status; // 'completed', 'pending', 'failed'
  final String? payoutMethod; // 'Jazz Cash', 'Easy Paisa', 'Bank Transfer'
  final String? payoutNumber;
  final String? receiverId;
  final String? receiverName;
  final String? senderId;
  final String? senderName;
  final String? transactionType; // 'merchant_to_user', 'user_to_user', etc.
  final String? otherParty; // Name of the other party
  final String? otherPartyId; // ID of the other party
  final String? goldCoinsSent;
  final String? diamondCoinsReceived;
  final String? timestamp;

  TransactionModel({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    this.payoutMethod,
    this.payoutNumber,
    this.receiverId,
    this.receiverName,
    this.senderId,
    this.senderName,
    this.transactionType,
    this.otherParty,
    this.otherPartyId,
    this.goldCoinsSent,
    this.diamondCoinsReceived,
    this.timestamp,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
    // ✅ Helper function to safely convert to String (handles int, String, null)
    String? safeToString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }
    
    // ✅ Helper function to safely convert to String with default
    String safeToStringWithDefault(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      return value.toString();
    }
    
    return TransactionModel(
      transactionId: safeToStringWithDefault(json['transaction_id'] ?? json['id'], ''),
      type: safeToStringWithDefault(json['type'], ''),
      amount: safeToStringWithDefault(json['amount'], '0'),
      date: safeToStringWithDefault(
        json['date'] ?? json['timestamp'] ?? json['created_at'],
        '',
      ),
      status: safeToStringWithDefault(json['status'], 'completed'),
      payoutMethod: safeToString(json['payout_method']),
      payoutNumber: safeToString(json['payout_number'] ?? json['account_number']),
      receiverId: safeToString(json['receiver_id'] ?? json['other_party_id']),
      receiverName: safeToString(json['receiver_name'] ?? json['other_party']),
      senderId: safeToString(json['sender_id']),
      senderName: safeToString(json['sender_name']),
      transactionType: safeToString(json['transaction_type']),
      otherParty: safeToString(json['other_party']),
      otherPartyId: safeToString(json['other_party_id']),
      goldCoinsSent: safeToString(json['gold_coins_sent']),
      diamondCoinsReceived: safeToString(json['diamond_coins_received']),
      timestamp: safeToString(json['timestamp'] ?? json['created_at']),
    );
    } catch (e, stackTrace) {
      print('❌ [TransactionModel] Error in fromJson: $e');
      print('❌ [TransactionModel] Stack trace: $stackTrace');
      print('❌ [TransactionModel] JSON data: $json');
      // Return a default transaction instead of crashing
      return TransactionModel(
        transactionId: json['transaction_id']?.toString() ?? json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '0',
        date: json['date']?.toString() ?? json['timestamp']?.toString() ?? json['created_at']?.toString() ?? '',
        status: json['status']?.toString() ?? 'completed',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'type': type,
      'amount': amount,
      'date': date,
      'status': status,
      'payout_method': payoutMethod,
      'payout_number': payoutNumber,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'sender_id': senderId,
      'sender_name': senderName,
      'transaction_type': transactionType,
      'other_party': otherParty,
      'other_party_id': otherPartyId,
      'gold_coins_sent': goldCoinsSent,
      'diamond_coins_received': diamondCoinsReceived,
      'timestamp': timestamp,
    };
  }

  // Helper method to get display title
  String getDisplayTitle() {
    if (transactionType != null && transactionType!.isNotEmpty) {
   
      
      if (otherParty != null && otherParty!.isNotEmpty) {
        return '$otherParty';
      }
      return '$otherParty';
    }
    
    // Fallback to type
    if (otherParty != null && otherParty!.isNotEmpty) {
      if (type.toLowerCase() == 'sent') {
        return 'Transfer to $otherParty';
      } else if (type.toLowerCase() == 'received') {
        return 'Received from $otherParty';
      }
      return 'Transaction with $otherParty';
    } 
    
    // Final fallback
    if (type.isNotEmpty) {
      return type[0].toUpperCase() + type.substring(1);
    }
    return 'Transaction';
  }
}

class TransactionHistoryResponse {
  final String status;
  final String? message;
  final List<TransactionModel> transactions;

  TransactionHistoryResponse({
    required this.status,
    this.message,
    required this.transactions,
  });

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    List<TransactionModel> transactionsList = [];
    
    // ✅ Helper to safely parse a transaction item
    TransactionModel? safeParseTransaction(dynamic item) {
      try {
        if (item == null) return null;
        // Convert to Map if it's not already
        Map<String, dynamic> itemMap;
        if (item is Map<String, dynamic>) {
          itemMap = item;
        } else if (item is Map) {
          itemMap = Map<String, dynamic>.from(item);
        } else {
          return null;
        }
        return TransactionModel.fromJson(itemMap);
      } catch (e) {
        print('⚠️ Error parsing transaction item: $e');
        print('   Item: $item');
        return null;
      }
    }
    
    if (json['transactions'] != null) {
      if (json['transactions'] is List) {
        transactionsList = (json['transactions'] as List)
            .map((item) => safeParseTransaction(item))
            .whereType<TransactionModel>()
            .toList();
      } else if (json['transactions'] is Map) {
        // Handle case where transactions might be in a nested structure
        try {
          final transactionsData = json['transactions'] as Map<String, dynamic>;
          if (transactionsData['data'] != null && transactionsData['data'] is List) {
            transactionsList = (transactionsData['data'] as List)
                .map((item) => safeParseTransaction(item))
                .whereType<TransactionModel>()
                .toList();
          }
        } catch (e) {
          print('⚠️ Error parsing nested transactions: $e');
        }
      }
    } else if (json['data'] != null && json['data'] is List) {
      transactionsList = (json['data'] as List)
          .map((item) => safeParseTransaction(item))
          .whereType<TransactionModel>()
          .toList();
    }

    // ✅ Handle status - can be int or String
    String statusValue = 'error';
    if (json['status'] != null) {
      statusValue = json['status'].toString();
    }
    
    // ✅ Handle message - can be int or String
    String? messageValue;
    if (json['message'] != null) {
      messageValue = json['message'].toString();
    }

    return TransactionHistoryResponse(
      status: statusValue,
      message: messageValue,
      transactions: transactionsList,
    );
  }
}

