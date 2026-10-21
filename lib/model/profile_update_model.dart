

class UpdateProfileModel {
  final String status;
  final String message;
  final String profileUrl;

  UpdateProfileModel({
    required this.status,
    required this.message,
    required this.profileUrl,
  });

  factory UpdateProfileModel.fromJson(Map<String, dynamic> json) {
    String profileUrl = '';

    print('🔍 ========== UpdateProfileModel.fromJson - PARSING RESPONSE ==========');
    print('   📦 Full JSON response: $json');
    print('   📋 JSON keys: ${json.keys.toList()}');
    
    // ✅ NESTED user object se profile_url extract karo
    if (json['user'] is Map) {
      final userData = json['user'] as Map<String, dynamic>;
      print('   ✅ User object found');
      print('   📋 User object keys: ${userData.keys.toList()}');
      print('   📋 User object full data: $userData');
      print('   🖼️ profile_url value: ${userData['profile_url']}');
      print('   🖼️ profile_url type: ${userData['profile_url']?.runtimeType}');
      print('   🖼️ profile_url is null: ${userData['profile_url'] == null}');
      print('   🖼️ profile_url is empty: ${userData['profile_url']?.toString().isEmpty ?? true}');
      
      if (userData['profile_url'] != null) {
        profileUrl = userData['profile_url'].toString();
        print('   ✅ Found profile_url in user object: "$profileUrl"');
        print('   ✅ Profile URL length: ${profileUrl.length}');
      } else {
        print('   ❌ profile_url is NULL in user object');
        print('   ⚠️ Backend did not return profile_url in user object');
      }
    } else {
      print('   ⚠️ User object not found or not a Map');
      print('   ⚠️ User object type: ${json['user']?.runtimeType}');
      print('   ⚠️ User object value: ${json['user']}');
    }

    // ✅ Agar nested se nahi mila to top level check karo
    if (profileUrl.isEmpty) {
      print('   🔍 Checking top-level for profile_url...');
      if (json['profile_url'] != null) {
        profileUrl = json['profile_url'].toString();
        print('   ✅ Found profile_url at top level: "$profileUrl"');
      } else {
        print('   ❌ profile_url not found at top level either');
      }
    }

    // ✅ Check for alternative field names
    if (profileUrl.isEmpty) {
      print('   🔍 Checking alternative field names...');
      final alternatives = ['profileUrl', 'profile_image', 'image_url', 'avatar', 'avatar_url'];
      for (final alt in alternatives) {
        if (json[alt] != null) {
          profileUrl = json[alt].toString();
          print('   ✅ Found profile URL in alternative field "$alt": "$profileUrl"');
          break;
        }
      }
      if (profileUrl.isEmpty) {
        print('   ❌ No profile URL found in any alternative fields');
      }
    }

    if (profileUrl.isEmpty) {
      print('   ❌ ========== CRITICAL WARNING ==========');
      print('   ❌ profile_url is EMPTY after parsing!');
      print('   ❌ This means backend did NOT return a profile URL');
      print('   ❌ Possible causes:');
      print('      1. Backend did not save the uploaded image');
      print('      2. Backend did not return profile_url in response');
      print('      3. Backend returned profile_url in unexpected format');
      print('   ❌ ======================================');
    } else {
      print('   ✅ Profile URL successfully extracted: "$profileUrl"');
    }

    print('🔍 ========== UpdateProfileModel.fromJson - PARSING END ==========');

    return UpdateProfileModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      profileUrl: profileUrl,
    );
  }

  get username => null;
}