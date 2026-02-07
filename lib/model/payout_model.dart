class PayoutResponse {
  final String status;
  final String message;
  final String? transactionId;
  final String? payoutStatus; // 'pending', 'approved', 'rejected'
  final Map<String, dynamic>? data;

  PayoutResponse({
    required this.status,
    required this.message,
    this.transactionId,
    this.payoutStatus,
    this.data,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    // Extract payout_status, but don't fallback to main 'status' to avoid confusion
    String? payoutStatusValue;
    if (json['payout_status'] != null) {
      payoutStatusValue = json['payout_status'].toString();
    } else if (json['transaction_status'] != null) {
      payoutStatusValue = json['transaction_status'].toString();
    }
    
    return PayoutResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? json['id']?.toString(),
      payoutStatus: payoutStatusValue,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

