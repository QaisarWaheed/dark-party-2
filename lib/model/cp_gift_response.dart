class CpUserResponse {
  final String status;
  final int count;
  final CpData data;

  CpUserResponse({
    required this.status,
    required this.count,
    required this.data,
  });

  factory CpUserResponse.fromJson(Map<String, dynamic> json) {
    return CpUserResponse(
      status: (json['status'] ?? '').toString(),
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      data: CpData.fromJson(json['data'] ?? json),
    );
  }
}
class CpData {
  final List<CpUser> users;

  CpData({required this.users});

  factory CpData.fromJson(Map<String, dynamic> json) {
    return CpData(
      users: (json['users'] as List?)
              ?.map((e) => CpUser.fromJson(e as Map<String, dynamic>))
              .toList() ?? <CpUser>[],
    );
  }
}
class CpUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String gender;
  final String profileUrl;
  final bool isCp;
final String cpSince;
  final double totalDiamond;
  final double totalAmount;
  final String weekStart;
  final String weekEnd;
  final CpUserPartner? cpUser;

  CpUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.gender,
    required this.profileUrl,
    required this.isCp,
    required this.cpSince,
    required this.totalDiamond,
    required this.totalAmount,
    required this.weekStart,
    required this.weekEnd,
    this.cpUser,
  });

  factory CpUser.fromJson(Map<String, dynamic> json) {
    return CpUser(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      profileUrl: (json['profile_url'] ?? '').toString(),
      isCp: json['is_cp'] == 1 || json['is_cp']?.toString() == '1',
      cpSince: (json['cp_since'] ?? '').toString(),
      totalDiamond: double.tryParse(json['total_diamond']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      weekStart: (json['week_start'] ?? '').toString(),
      weekEnd: (json['week_end'] ?? '').toString(),
      cpUser: json['cpUser'] != null
          ? CpUserPartner.fromJson(json['cpUser'])
          : null,
    );
  }
}

class CpUserPartner {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String gender;
  final String profileUrl;
  final String cpSince;
  final double totalDiamond;
  final String weekStart;
  final String weekEnd;

  CpUserPartner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.gender,
    required this.profileUrl,
    required this.cpSince,
    required this.totalDiamond,
    required this.weekStart,
    required this.weekEnd,
  });

  factory CpUserPartner.fromJson(Map<String, dynamic> json) {
    return CpUserPartner(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      profileUrl: (json['profile_url'] ?? '').toString(),
      cpSince: (json['cp_since'] ?? '').toString(),
      totalDiamond: double.tryParse(json['total_diamond']?.toString() ?? '0') ?? 0.0,
      weekStart: (json['week_start'] ?? '').toString(),
      weekEnd: (json['week_end'] ?? '').toString(),
    );
  }
}
