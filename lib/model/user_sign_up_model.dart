import 'package:shaheen_star_app/model/agency_info_model.dart';

class UserSignUpModel {
  final String id;
  final String name;
  final String email;
  final String? apiToken;
  final bool? isNewUser;
  final String? country;
  final String? gender;
  final String? dob;
  final String? profileUrl;
  final int? merchant; // ✅ Merchant status (0 = not merchant, 1 = merchant)
  final int? wealthLevel; // ✅ Wealth Level
  final String? phone; // ✅ Phone number from API
  final int?
  isAgencyAvailable; // ✅ Legacy: Agency availability status (0 = not available, 1 = available) - DEPRECATED
  final AgencyInfo?
  agencyInfo; // ✅ New: Complete agency information from login API
  final int? isBanned; // ✅ Ban status (0 = not banned, 1 = banned)
  final String? banReason; // ✅ Reason for ban
  final String? bannedAt; // ✅ When user was banned
  final String? banExpiresAt; // ✅ When ban expires (null = permanent)

  UserSignUpModel({
    required this.id,
    required this.name,
    required this.email,
    this.apiToken,
    this.isNewUser,
    this.country,
    this.gender,
    this.dob,
    this.profileUrl,
    this.merchant,
    this.wealthLevel,
    this.phone,
    this.isAgencyAvailable,
    this.agencyInfo,
    this.isBanned,
    this.banReason,
    this.bannedAt,
    this.banExpiresAt,
  });

  factory UserSignUpModel.fromJson(Map<String, dynamic> json) {
    print(
      '🔍 ========== UserSignUpModel.fromJson - PARSING USER DATA ==========',
    );
    print('   📦 Full JSON: $json');
    print('   📋 JSON keys: ${json.keys.toList()}');

    // ✅ Handle name: use username if name is null or empty
    String nameValue = json['name']?.toString() ?? '';
    if (nameValue.isEmpty) {
      nameValue = json['username']?.toString() ?? '';
    }

    // ✅ Handle merchant: convert to int (0 or 1)
    int? merchantValue;
    if (json['merchant'] != null) {
      merchantValue = json['merchant'] is int
          ? json['merchant']
          : int.tryParse(json['merchant'].toString());
    }

    // ✅ Handle wealth_level
    int? wealthLevelValue;
    if (json['wealth_level'] != null) {
      wealthLevelValue = json['wealth_level'] is int
          ? json['wealth_level']
          : int.tryParse(json['wealth_level'].toString());
    }

    // ✅ Handle is_agency_available: convert to int (0 or 1) - LEGACY SUPPORT
    // Also check for camelCase and snake_case variants
    int? isAgencyAvailableValue;
    final agencyAvailableKey = json.containsKey('is_agency_available')
        ? 'is_agency_available'
        : (json.containsKey('Is_agency_avaiable')
              ? 'Is_agency_avaiable'
              : (json.containsKey('isAgencyAvailable')
                    ? 'isAgencyAvailable'
                    : null));

    if (agencyAvailableKey != null && json[agencyAvailableKey] != null) {
      isAgencyAvailableValue = json[agencyAvailableKey] is int
          ? json[agencyAvailableKey]
          : int.tryParse(json[agencyAvailableKey].toString());
      print('   ✅ Found is_agency_available (legacy): $isAgencyAvailableValue');
    } else {
      print('   ℹ️ is_agency_available (legacy) not found in response');
    }

    // ✅ Parse new agency_info structure from login API
    AgencyInfo? agencyInfoValue;
    if (json.containsKey('agency_info') && json['agency_info'] != null) {
      try {
        agencyInfoValue = AgencyInfo.fromJson(json['agency_info']);
        print(
          '   ✅ Found agency_info: has_agency=${agencyInfoValue.hasAgency}, is_member=${agencyInfoValue.isMember}',
        );
        print(
          '   ✅ Owned agency: ${agencyInfoValue.ownedAgency?.agencyName ?? "None"}',
        );
        print('   ✅ Member agencies: ${agencyInfoValue.agencies.length}');
        // Set legacy isAgencyAvailable based on has_agency for backward compatibility
        if (isAgencyAvailableValue == null) {
          isAgencyAvailableValue = agencyInfoValue.hasAgency ? 1 : 0;
          print(
            '   ✅ Set legacy isAgencyAvailable from agency_info.has_agency: $isAgencyAvailableValue',
          );
        }
      } catch (e) {
        print('   ❌ Error parsing agency_info: $e');
      }
    } else {
      print('   ℹ️ agency_info not found in response');
    }

    // ✅ Extract profileUrl with detailed logging
    String? profileUrl;
    print('   🖼️ ========== PROFILE URL EXTRACTION ==========');
    print('   🖼️ profile_url value: ${json['profile_url']}');
    print('   🖼️ profile_url type: ${json['profile_url']?.runtimeType}');
    print('   🖼️ profile_url is null: ${json['profile_url'] == null}');

    if (json['profile_url'] != null) {
      profileUrl = json['profile_url'].toString();
      print('   ✅ Found profile_url: "$profileUrl"');
      print('   ✅ Profile URL length: ${profileUrl.length}');
      print('   ✅ Profile URL is empty: ${profileUrl.isEmpty}');
    } else {
      print('   ❌ profile_url is NULL in JSON response');
      print('   ⚠️ Backend did not return profile_url');

      // Check alternative field names
      final alternatives = [
        'profileUrl',
        'profile_image',
        'image_url',
        'avatar',
        'avatar_url',
      ];
      for (final alt in alternatives) {
        if (json[alt] != null) {
          profileUrl = json[alt].toString();
          print(
            '   ✅ Found profile URL in alternative field "$alt": "$profileUrl"',
          );
          break;
        }
      }

      if (profileUrl == null || profileUrl.isEmpty) {
        print('   ❌ No profile URL found in any field');
        print('   ⚠️ This means backend is NOT returning profile image URL');
      }
    }
    print('   🖼️ ========== PROFILE URL EXTRACTION END ==========');

    // ✅ EXTRACT ID - Check both 'id' and 'user_id' fields
    // ⚠️ One might be 4 digits, other might be 7 digits
    // Prefer the 4-digit one (database user ID) over 7-digit one
    String userIdValue = '';
    String? idField = json['id']?.toString();
    String? userIdField = json['user_id']?.toString();

    print('   🔍 ========== USER ID EXTRACTION ==========');
    print('   🔍 id field: $idField (${idField?.length ?? 0} digits)');
    print(
      '   🔍 user_id field: $userIdField (${userIdField?.length ?? 0} digits)',
    );

    // ✅ Prefer 4-digit ID (database user ID) over 7-digit ID
    if (userIdField != null && userIdField.isNotEmpty) {
      if (userIdField.length == 4) {
        userIdValue = userIdField;
        print('   ✅ Using user_id field (4 digits): $userIdValue');
      } else if (idField != null && idField.isNotEmpty && idField.length == 4) {
        userIdValue = idField;
        print('   ✅ Using id field (4 digits): $userIdValue');
      } else {
        // If user_id is not 4 digits, use it anyway (might be correct)
        userIdValue = userIdField;
        print(
          '   ⚠️ Using user_id field (${userIdValue.length} digits): $userIdValue',
        );
      }
    } else if (idField != null && idField.isNotEmpty) {
      userIdValue = idField;
      print('   ✅ Using id field: $userIdValue (${userIdValue.length} digits)');
    } else {
      print('   ❌ No valid ID found in either id or user_id field');
    }
    print('   🔍 ========== USER ID EXTRACTION END ==========');

    // ✅ Parse ban status fields
    int? isBannedValue;
    if (json['is_banned'] != null) {
      isBannedValue = json['is_banned'] is int
          ? json['is_banned']
          : int.tryParse(json['is_banned'].toString());
    }

    print('🚫 ========== BAN STATUS EXTRACTION ==========');
    print('   🚫 is_banned: $isBannedValue');
    print('   🚫 ban_reason: ${json['ban_reason']}');
    print('   🚫 banned_at: ${json['banned_at']}');
    print('   🚫 ban_expires_at: ${json['ban_expires_at']}');
    print('🚫 ========== BAN STATUS END ==========');

    print('🔍 ========== UserSignUpModel.fromJson - PARSING END ==========');

    return UserSignUpModel(
      id: userIdValue.isNotEmpty ? userIdValue : (idField ?? ''),
      name: nameValue,
      email: json['email'] ?? '',
      apiToken: json['api_token'],
      isNewUser: json['isNewUser'],
      country: json['country']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      profileUrl: profileUrl,
      merchant: merchantValue,
      wealthLevel: wealthLevelValue,
      phone: json['phone']?.toString(),
      isAgencyAvailable: isAgencyAvailableValue,
      agencyInfo: agencyInfoValue,
      isBanned: isBannedValue,
      banReason: json['ban_reason']?.toString(),
      bannedAt: json['banned_at']?.toString(),
      banExpiresAt: json['ban_expires_at']?.toString(),
    );
  }

  // ✅ Helper method to check if user is a merchant
  bool get isMerchant => merchant != null && merchant! > 0;

  // ✅ Helper method to check if agency is available (owns OR joined as member)
  bool get hasAgencyAvailable {
    if (agencyInfo != null) {
      return agencyInfo!.hasAgency || agencyInfo!.isMember;
    }
    return isAgencyAvailable != null && isAgencyAvailable! > 0;
  }

  // ✅ Helper method to check if user is currently banned
  bool get isUserBanned => isBanned != null && isBanned! > 0;
}
