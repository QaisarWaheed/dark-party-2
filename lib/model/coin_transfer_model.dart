class CoinTransferResponse {
  final String status;
  final String message;
  final String? transactionId;
  final double? newBalance;
  final double? merchantBalance;
  final Map<String, dynamic>? data;

  CoinTransferResponse({
    required this.status,
    required this.message,
    this.transactionId,
    this.newBalance,
    this.merchantBalance,
    this.data,
  });

  factory CoinTransferResponse.fromJson(Map<String, dynamic> json) {
    // Extract data object if present
    final dataObj = json['data'] as Map<String, dynamic>?;
    
    // Parse transaction_id from data object or root level
    String? transactionId;
    if (dataObj != null && dataObj['transaction_id'] != null) {
      transactionId = dataObj['transaction_id'].toString();
    } else {
      transactionId = json['transaction_id']?.toString() ?? json['id']?.toString();
    }
    
    // Parse merchant_new_balance from data object (new API format)
    double? merchantBalance;
    if (dataObj != null && dataObj['merchant_new_balance'] != null) {
      merchantBalance = double.tryParse(dataObj['merchant_new_balance'].toString());
    } else if (json['merchant_balance'] != null) {
      merchantBalance = double.tryParse(json['merchant_balance'].toString());
    } else if (dataObj != null && dataObj['merchant_balance'] != null) {
      merchantBalance = double.tryParse(dataObj['merchant_balance'].toString());
    }
    
    // Parse new_balance (for user balance if provided)
    double? newBalance;
    if (json['new_balance'] != null) {
      newBalance = double.tryParse(json['new_balance'].toString());
    } else if (json['balance'] != null) {
      newBalance = double.tryParse(json['balance'].toString());
    } else if (dataObj != null && dataObj['new_balance'] != null) {
      newBalance = double.tryParse(dataObj['new_balance'].toString());
    }
    
    return CoinTransferResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? '',
      transactionId: transactionId,
      newBalance: newBalance,
      merchantBalance: merchantBalance,
      data: dataObj,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

