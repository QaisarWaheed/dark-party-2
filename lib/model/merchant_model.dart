class MerchantModel {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String? phone;
  final String? country;
  final String? profileUrl;
  final String? uniqueUserId;
  final String? createdAt;
  final String? whatsappNumber;
  final double? accountBalance;
  final int merchant;

  MerchantModel({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.phone,
    this.country,
    this.profileUrl,
    this.uniqueUserId,
    this.createdAt,
    this.whatsappNumber,
    this.accountBalance,
    required this.merchant,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    // Handle name: use username if name is null or empty
    String nameValue = json['name']?.toString() ?? '';
    if (nameValue.isEmpty) {
      nameValue = json['username']?.toString() ?? '';
    }

    // Handle account balance (merchant_coins or balance)
    double? balance;
    if (json['merchant_coins'] != null) {
      balance = double.tryParse(json['merchant_coins'].toString());
    } else if (json['balance'] != null) {
      balance = double.tryParse(json['balance'].toString());
    } else if (json['account_balance'] != null) {
      balance = double.tryParse(json['account_balance'].toString());
    }

    // Handle merchant status
    // ⚠️ If merchant field is missing, default to 0 (not a merchant)
    // This allows the model to work even when API doesn't return merchant field
    int merchantValue = 0;
    if (json['merchant'] != null) {
      merchantValue = json['merchant'] is int
          ? json['merchant']
          : (int.tryParse(json['merchant'].toString()) ?? 0);
    }
    // Note: If merchant field is completely missing, merchantValue remains 0

    return MerchantModel(
      id: json['id']?.toString() ?? '',
      name: nameValue,
      username: json['username']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      country: json['country']?.toString(),
      profileUrl: json['profile_url']?.toString() ?? json['profileUrl']?.toString(),
      uniqueUserId: json['unique_user_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      whatsappNumber: json['whatsapp']?.toString() ?? json['whatsapp_number']?.toString() ?? json['phone']?.toString(),
      accountBalance: balance,
      merchant: merchantValue,
    );
  }

  // Format balance for display - show actual number without decimals
  String get formattedBalance {
    if (accountBalance == null) return '0';
    // Convert to int to remove decimals and show actual number
    return accountBalance!.toInt().toString();
  }

  // Format date for display (e.g., 17-02/2025)
  String get formattedDate {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt!);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return createdAt!;
    }
  }
}

