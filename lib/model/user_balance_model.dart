class UserBalanceResponse {
  final String status;
  final String? message;
  final double balance;
  final String userId;
  final double? merchantCoins; // For merchant users
  final double? goldCoins; // Gold coins
  final double? diamondCoins; // Diamond coins
  final Map<String, dynamic>? data;

  UserBalanceResponse({
    required this.status,
    this.message,
    required this.balance,
    required this.userId,
    this.merchantCoins,
    this.goldCoins,
    this.diamondCoins,
    this.data,
  });

  factory UserBalanceResponse.fromJson(Map<String, dynamic> json) {
    try {
    // ✅ Helper to safely convert any type to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }
    
    // Try to extract balance from various possible fields
    double balanceValue = 0.0;
    
    if (json['balance'] != null) {
      balanceValue = safeToDouble(json['balance']);
    } else if (json['gold_coins'] != null) {
      // API returns gold_coins as the main balance
      balanceValue = safeToDouble(json['gold_coins']);
    } else if (json['coins'] != null) {
      balanceValue = safeToDouble(json['coins']);
    } else if (json['user_coins'] != null) {
      balanceValue = safeToDouble(json['user_coins']);
    } else if (json['data'] != null && json['data'] is Map) {
      // ✅ Safely convert to Map<String, dynamic>
      Map<String, dynamic> data;
      try {
        if (json['data'] is Map<String, dynamic>) {
          data = json['data'] as Map<String, dynamic>;
        } else {
          data = Map<String, dynamic>.from(json['data'] as Map);
        }
      } catch (e) {
        print('⚠️ [UserBalanceResponse] Error converting data to Map: $e');
        data = <String, dynamic>{};
      }
      if (data['gold_coins'] != null) {
        balanceValue = safeToDouble(data['gold_coins']);
      } else if (data['balance'] != null) {
        balanceValue = safeToDouble(data['balance']);
      } else if (data['coins'] != null) {
        balanceValue = safeToDouble(data['coins']);
      }
    }

    // ✅ Helper to safely convert any type to double?
    double? safeToDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString());
    }
    
    // Extract merchant coins if available
    double? merchantCoinsValue;
    if (json['merchant_coins'] != null) {
      merchantCoinsValue = safeToDoubleNullable(json['merchant_coins']);
    } else if (json['data'] != null && json['data'] is Map) {
      // ✅ Safely convert to Map<String, dynamic>
      Map<String, dynamic> data;
      try {
        if (json['data'] is Map<String, dynamic>) {
          data = json['data'] as Map<String, dynamic>;
        } else {
          data = Map<String, dynamic>.from(json['data'] as Map);
        }
      } catch (e) {
        data = <String, dynamic>{};
      }
      if (data['merchant_coins'] != null) {
        merchantCoinsValue = safeToDoubleNullable(data['merchant_coins']);
      }
    }

    // Extract gold_coins and diamond_coins
    double? goldCoinsValue;
    double? diamondCoinsValue;
    
    if (json['gold_coins'] != null) {
      goldCoinsValue = safeToDoubleNullable(json['gold_coins']);
    } else if (json['data'] != null && json['data'] is Map) {
      // ✅ Safely convert to Map<String, dynamic>
      Map<String, dynamic> data;
      try {
        if (json['data'] is Map<String, dynamic>) {
          data = json['data'] as Map<String, dynamic>;
        } else {
          data = Map<String, dynamic>.from(json['data'] as Map);
        }
      } catch (e) {
        data = <String, dynamic>{};
      }
      if (data['gold_coins'] != null) {
        goldCoinsValue = safeToDoubleNullable(data['gold_coins']);
      }
    }
    
    if (json['diamond_coins'] != null) {
      diamondCoinsValue = safeToDoubleNullable(json['diamond_coins']);
    } else if (json['data'] != null && json['data'] is Map) {
      // ✅ Safely convert to Map<String, dynamic>
      Map<String, dynamic> data;
      try {
        if (json['data'] is Map<String, dynamic>) {
          data = json['data'] as Map<String, dynamic>;
        } else {
          data = Map<String, dynamic>.from(json['data'] as Map);
        }
      } catch (e) {
        data = <String, dynamic>{};
      }
      if (data['diamond_coins'] != null) {
        diamondCoinsValue = safeToDoubleNullable(data['diamond_coins']);
      }
    }

    // ✅ Handle status - can be int or String
    String statusValue = 'error';
    if (json['status'] != null) {
      if (json['status'] is int) {
        statusValue = json['status'].toString();
      } else {
        statusValue = json['status'].toString();
      }
    }
    
    // ✅ Handle message - can be int or String
    String? messageValue;
    if (json['message'] != null) {
      messageValue = json['message'].toString();
    }
    
    // ✅ Handle user_id - can be int or String
    String userIdValue = '';
    if (json['user_id'] != null) {
      userIdValue = json['user_id'].toString();
    } else if (json['id'] != null) {
      userIdValue = json['id'].toString();
    }
    
    // ✅ Handle data - can be Map or null
    Map<String, dynamic>? dataValue;
    if (json['data'] != null && json['data'] is Map) {
      try {
        dataValue = json['data'] as Map<String, dynamic>;
      } catch (e) {
        // If cast fails, try to convert
        if (json['data'] is Map) {
          dataValue = Map<String, dynamic>.from(json['data'] as Map);
        }
      }
    }
    
    return UserBalanceResponse(
      status: statusValue,
      message: messageValue,
      balance: balanceValue,
      userId: userIdValue,
      merchantCoins: merchantCoinsValue,
      goldCoins: goldCoinsValue,
      diamondCoins: diamondCoinsValue,
      data: dataValue,
    );
    } catch (e, stackTrace) {
      print('❌ [UserBalanceResponse] Error in fromJson: $e');
      print('❌ [UserBalanceResponse] Stack trace: $stackTrace');
      print('❌ [UserBalanceResponse] JSON data: $json');
      // Return a default response instead of crashing
      return UserBalanceResponse(
        status: 'error',
        message: 'Failed to parse response: $e',
        balance: 0.0,
        userId: '',
      );
    }
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

