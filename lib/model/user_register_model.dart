// class UserRegisterModel {
//   final String status;
//   final String message;
//   final String? userId;
//   final String? username;

//   UserRegisterModel({
//     required this.status,
//     required this.message,
//     this.userId,
//     this.username,
//   });

//   factory UserRegisterModel.fromJson(Map<String, dynamic> json) {
//     return UserRegisterModel(
//       status: json['status'] ?? '',
//       message: json['message'] ?? '',
//       userId: json['user_id']?.toString(),
//       username: json['username'],
//     );
//   }
// }

class RegisterResponseModel {
  final String status;
  final String message;
  final UserModel user;

  RegisterResponseModel({
    required this.status,
    required this.message,
    required this.user,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      status: json['status'],
      message: json['message'],
      user: UserModel.fromJson(json['user']),
    );
  }
}

class UserModel {
  final int id;
  final String? googleId;
  final String username;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String gender;
  final String? dob;
  final int host;
  final int merchant;
  final int merchantCoins;
  final int uniqueUserId;
  final String myReferralCode;
  final String? userReferralCode;

  UserModel({
    required this.id,
    this.googleId,
    required this.username,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.gender,
    this.dob,
    required this.host,
    required this.merchant,
    required this.merchantCoins,
    required this.uniqueUserId,
    required this.myReferralCode,
    this.userReferralCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      googleId: json['google_id'],
      username: json['username'],
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      country: json['country'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'],
      host: json['host'],
      merchant: json['merchant'],
      merchantCoins: json['merchant_coins'],
      uniqueUserId: json['unique_user_id'],
      myReferralCode: json['my_referral_code'],
      userReferralCode: json['user_referral_code'],
    );
  }
}
