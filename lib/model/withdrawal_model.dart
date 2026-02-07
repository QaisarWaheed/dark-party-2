class PaymentMethod {
  final int id;
  final String name;
  final String accountNumber;
  final String description;
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.description,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: (json['is_active'] ?? 0).toString() == '1',
    );
  }
}

class WithdrawalRequest {
  final int id;
  final int userId;
  final double amount;
  final String paymentMethodName;
  final String userAccount;
  final String status;
  final DateTime createdAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.amount,
    required this.paymentMethodName,
    required this.userAccount,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentMethodName: json['payment_method_name']?.toString() ?? '',
      userAccount: json['user_account']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WithdrawalBalance {
  final double diamondCoins;
  final String userName;
  final String username;

  WithdrawalBalance({
    required this.diamondCoins,
    required this.userName,
    required this.username,
  });

  factory WithdrawalBalance.fromJson(Map<String, dynamic> json) {
    return WithdrawalBalance(
      diamondCoins: double.tryParse(json['diamond_coins'].toString()) ?? 0.0,
      userName: json['user_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

class WithdrawalResponse {
  final String status;
  final String message;
  final Map<String, dynamic>? data;

  WithdrawalResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Handle status - can be int or String
    String statusValue = 'error';
    if (json['status'] != null) {
      statusValue = json['status'].toString();
    }
    
    // ✅ Handle message - can be int or String
    String messageValue = '';
    if (json['message'] != null) {
      messageValue = json['message'].toString();
    }
    
    // ✅ Handle data - can be Map or null
    Map<String, dynamic>? dataValue;
    if (json['data'] != null && json['data'] is Map) {
      dataValue = json['data'] as Map<String, dynamic>;
    }
    
    return WithdrawalResponse(
      status: statusValue,
      message: messageValue,
      data: dataValue,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class PaymentMethodsResponse {
  final String status;
  final String? message;
  final List<PaymentMethod> paymentMethods;

  PaymentMethodsResponse({
    required this.status,
    this.message,
    required this.paymentMethods,
  });

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) {
    List<PaymentMethod> methods = [];
    if (json['data'] != null && json['data'] is List) {
      for (var item in json['data']) {
        if (item is Map<String, dynamic>) {
          methods.add(PaymentMethod.fromJson(item));
        }
      }
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
    
    return PaymentMethodsResponse(
      status: statusValue,
      message: messageValue,
      paymentMethods: methods,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class WithdrawalsListResponse {
  final String status;
  final String? message;
  final List<WithdrawalRequest> withdrawals;

  WithdrawalsListResponse({
    required this.status,
    this.message,
    required this.withdrawals,
  });

  factory WithdrawalsListResponse.fromJson(Map<String, dynamic> json) {
    List<WithdrawalRequest> withdrawals = [];
    if (json['data'] != null && json['data'] is List) {
      for (var item in json['data']) {
        if (item is Map<String, dynamic>) {
          withdrawals.add(WithdrawalRequest.fromJson(item));
        }
      }
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
    
    return WithdrawalsListResponse(
      status: statusValue,
      message: messageValue,
      withdrawals: withdrawals,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class WithdrawalBalanceResponse {
  final String status;
  final String? message;
  final WithdrawalBalance? balance;

  WithdrawalBalanceResponse({
    required this.status,
    this.message,
    this.balance,
  });

  factory WithdrawalBalanceResponse.fromJson(Map<String, dynamic> json) {
    WithdrawalBalance? balanceData;
    if (json['data'] != null && json['data'] is Map) {
      balanceData = WithdrawalBalance.fromJson(json['data'] as Map<String, dynamic>);
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
    
    return WithdrawalBalanceResponse(
      status: statusValue,
      message: messageValue,
      balance: balanceData,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

