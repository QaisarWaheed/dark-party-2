// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/model/agency_info_model.dart';
import 'package:shaheen_star_app/model/user_level_model.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:shaheen_star_app/view/screens/bottom_nav/main_bottom_nav_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper function to normalize profile URL - converts relative paths to full URLs
/// ✅ FIXED: Properly detects local file paths and prevents treating them as network URLs
String _normalizeProfileUrl(String? profileUrl) {
  if (profileUrl == null ||
      profileUrl.isEmpty ||
      profileUrl == 'yyyy' ||
      profileUrl == 'Profile Url') {
    return '';
  }

  // If it's already a full URL, return as is
  if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
    return profileUrl;
  }

  // ✅ Check for local file paths (Android/iOS file system paths)
  // Check for absolute paths starting with /data/, /storage/, /private/, etc.
  if (profileUrl.startsWith('/data/') ||
      profileUrl.startsWith('/storage/') ||
      profileUrl.startsWith('/private/') ||
      profileUrl.startsWith('/var/') ||
      profileUrl.startsWith('/tmp/') ||
      // Check for paths containing cache directories
      profileUrl.contains('/cache/') ||
      profileUrl.contains('cache/') ||
      // Check for Android app-specific paths
      profileUrl.contains('/com.example.') ||
      profileUrl.contains('/com.') ||
      // Check for file:// protocol
      profileUrl.startsWith('file://')) {
    print(
      "⚠️ [ProfileUpdateProvider] Detected local file path, returning as-is: $profileUrl",
    );
    return profileUrl; // Return local path as-is, don't convert to network URL
  }

  // ✅ Check if it's a relative server path (starts with uploads/ or similar)
  // Only convert to network URL if it looks like a server-relative path
  if (profileUrl.startsWith('uploads/') ||
      profileUrl.startsWith('images/') ||
      profileUrl.startsWith('profiles/') ||
      profileUrl.startsWith('room_profiles/') ||
      profileUrl.startsWith('gifts/')) {
    // It's a relative server path, construct full URL
    String cleanPath = profileUrl.startsWith('/')
        ? profileUrl.substring(1)
        : profileUrl;
    return 'https://shaheenstar.online/$cleanPath';
  }

  // ✅ If it doesn't match any known pattern, return empty to avoid errors
  // This prevents trying to load invalid URLs
  print(
    "⚠️ [ProfileUpdateProvider] Unknown path format, returning empty: $profileUrl",
  );
  return '';
}

class ProfileUpdateProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  dynamic userCpData;
  Map<String, dynamic>? cpPartnerData;
  String? _userId;
  bool _isIdChanged = false;
  String? _displayUserId;
  String? _userName;
  String? _country;
  String? _gender;
  String? _dob;
  String? _userImage;
  int? _merchant; // ✅ Merchant status
  int? _wealthLevel; // ✅ Wealth Level
  int?
  _isAgencyAvailable; // ✅ Legacy: Agency availability status (for backward compatibility)
  AgencyInfo? _agencyInfo; // ✅ New: Complete agency information
  String? _email; // ✅ Email from API
  String? _phone; // ✅ Phone from API
  UserLevelModel? _userLevels; // ✅ User level data
  List<String> _tags = []; // ✅ User tags

  String? get userId => _userId;
  bool get isIdChanged => _isIdChanged;
  String? get displayUserId => _displayUserId ?? _userId;
  String? get username => _userName;
  String? get country => _country;
  String? get gender => _gender;
  String? get dob => _dob;
  String? get profile_url => _userImage;
  int? get merchant => _merchant;
  int? get wealthLevel => _wealthLevel; // ✅ Wealth level from login/user API
  int? get isAgencyAvailable => _isAgencyAvailable; // ✅ Legacy getter
  AgencyInfo? get agencyInfo => _agencyInfo; // ✅ New getter
  String? get email => _email;
  String? get phone => _phone;
  UserLevelModel? get userLevels => _userLevels; // ✅ Get user levels
  List<String> get tags => _tags; // ✅ Get user tags
  bool get isMerchant =>
      _merchant != null && _merchant! > 0; // ✅ Helper to check if merchant
  bool get hasAgencyAvailable {
    // ✅ True if user owns an agency OR has joined one as member
    if (_agencyInfo != null) {
      return _agencyInfo!.hasAgency || _agencyInfo!.isMember;
    }
    return _isAgencyAvailable != null && _isAgencyAvailable! > 0;
  }

  /// Manually update merchant status (workaround when API fails)
  Future<void> updateMerchantStatus(int merchantStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _userId ?? '718'; // Use current user ID or fallback

      print("💼 ========== MANUALLY UPDATING MERCHANT STATUS ==========");
      print("   📤 User ID: $userId");
      print("   📤 New Merchant Status: $merchantStatus");

      await prefs.setInt('merchant_$userId', merchantStatus);
      _merchant = merchantStatus;

      print("   ✅ Merchant status updated successfully");
      print("   ✅ New merchant value: $_merchant");
      print("   ✅ isMerchant: $isMerchant");
      print("💼 ========== MERCHANT STATUS UPDATED ==========");

      notifyListeners();
    } catch (e) {
      print("❌ Error updating merchant status: $e");
    }
  }

  Future<void> submitUserData({
    required BuildContext context,
    required String name,
    required String country,
    required String gender,
    required String dob,
    required File? image,
  }) async {
    print("🚀 ========== SUBMIT USER DATA STARTED ==========");
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ CRITICAL FIX: Retrieve user_id from SharedPreferences if _userId is null
      // This is especially important for new accounts where fetchUserData() hasn't been called yet
      if (_userId == null || _userId!.isEmpty) {
        print(
          "🔍 User ID is null or empty, retrieving from SharedPreferences...",
        );
        final prefs = await SharedPreferences.getInstance();

        // ✅ SMART TYPE HANDLING (same as fetchUserData)
        dynamic userIdValue = prefs.get('user_id');

        if (userIdValue != null) {
          if (userIdValue is int) {
            _userId = userIdValue.toString();
          } else if (userIdValue is String) {
            _userId = userIdValue;
          }
          print("✅ Retrieved user_id from SharedPreferences: $_userId");
        } else {
          print("❌ user_id not found in SharedPreferences");
          print("   - This should not happen for a logged-in user");
          print("   - User may need to log in again");
        }
      }

      print(
        "🔍 Debug User IDs: userId: ${_userId ?? 'EMPTY'} user_id: ${(await SharedPreferences.getInstance()).get('user_id')}",
      );
      print("👤 Updating profile for USER: $userId");
      print("   - User ID: $userId");
      print("   - Name: $name");
      print("   - Country: $country");
      print("   - Gender: $gender");
      print("   - DOB: $dob");

      String imagePath = '';
      if (image != null) {
        imagePath = image.path;

        // ✅ CHECK IF IMAGE FILE ACTUALLY EXISTS
        bool fileExists = await image.exists();
        print("📸 ========== IMAGE VALIDATION ==========");
        print("   - Image path: $imagePath");
        print("   - File exists: $fileExists");

        if (fileExists) {
          final fileSize = await image.length();
          print("   - File size: ${fileSize / 1024} KB");
          print("   - File size (bytes): $fileSize");

          // Check file permissions
          try {
            final stat = await image.stat();
            print("   - File readable: true");
            print("   - File modified: ${stat.modified}");
          } catch (e) {
            print("   ❌ ERROR reading file stats: $e");
          }
        } else {
          print("   ❌ ERROR: Image file does not exist at path: $imagePath");
          print("   ⚠️ Upload will proceed but image may not be uploaded");
        }
        print("📸 ========== IMAGE VALIDATION END ==========");
      } else {
        print("⚠️ No image provided for upload");
      }

      // ✅ VALIDATE: Ensure we have a valid user ID before proceeding
      if (_userId == null || _userId!.isEmpty) {
        print("❌ ========== CRITICAL ERROR: USER ID IS MISSING ==========");
        print("   - Cannot update profile without a valid user ID");
        print("   - User may need to log in again");
        print("❌ ======================================================");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User ID not found. Please log in again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      print("📤 Calling ApiManager.updateProfile...");
      print("   - User ID: $userId");
      print(
        "   - Image path being sent: ${image?.path.isEmpty ?? true ? 'EMPTY' : image?.path}",
      );

      final response = await ApiManager.updateProfile(
        id: _userId!, // ✅ Now guaranteed to be non-null and non-empty
        username: name,
        name: name, // ✅ Also send as name field so backend updates both
        country: country,
        gender: gender,
        dob: dob,
        profile_url: image?.path ?? '',
      );

      print("📥 API Response received: $response");
      print("   - Response is null: ${response == null}");
      if (response != null) {
        print("   - Status: ${response.status}");
        print("   - Profile URL from response: ${response.profileUrl}");
      }

      if (response != null && response.status == "success") {
        // ✅ BACKEND SE PROPER URL AAYEGI AB
        String backendProfilePath = response.profileUrl;

        // ✅ Normalize the profile URL (convert relative path to full URL if needed)
        String normalizedProfileUrl = _normalizeProfileUrl(backendProfilePath);

        print("✅ ========== BACKEND SUCCESS RESPONSE ==========");
        print("   - Status: ${response.status}");
        print("   - Profile URL from backend (raw): $backendProfilePath");
        print("   - Profile URL (normalized): $normalizedProfileUrl");
        print("   - Username from backend: ${response.username}");
        print("   - Name being saved: $name");
        print("   - Image URL being saved: $normalizedProfileUrl");

        // Validate the profile URL
        if (normalizedProfileUrl.isNotEmpty) {
          print("   ✅ Profile URL is valid");
          if (normalizedProfileUrl.startsWith('http://') ||
              normalizedProfileUrl.startsWith('https://')) {
            print("   ✅ Profile URL is a network URL");
          } else {
            print(
              "   ⚠️ Profile URL is not a network URL: $normalizedProfileUrl",
            );
          }
        } else {
          print("   ⚠️ Profile URL is invalid or empty");
          print("   - Raw value: '$backendProfilePath'");
        }
        print("✅ ========== BACKEND SUCCESS RESPONSE END ==========");

        // ✅ SAVE DATA - Make sure we save even if empty (to preserve user input)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName_$_userId', name);
        await prefs.setString('country_$_userId', country);
        await prefs.setString('gender_$_userId', gender);
        await prefs.setString('dob_$_userId', dob);

        // ✅ Only save image if we have a valid URL from backend
        if (normalizedProfileUrl.isNotEmpty) {
          await prefs.setString('userImage_$_userId', normalizedProfileUrl);
          print(
            "✅ Profile image saved to SharedPreferences: $normalizedProfileUrl",
          );
          print("✅ Profile image will be available for display");
        } else {
          print("❌ ========== PROFILE IMAGE NOT SAVED ==========");
          print("❌ Profile image is EMPTY or INVALID");
          print("❌ Backend returned: '$backendProfilePath'");
          print("❌ Normalized URL: '$normalizedProfileUrl'");
          print("❌ This means backend did NOT return a valid profile URL");
          print("❌ Possible backend issues:");
          print("   1. Backend did not process/save the uploaded image");
          print("   2. Backend returned null/empty profile_url");
          print("   3. Backend image upload failed silently");
          print("❌ ============================================");
          // ✅ REMOVED: Do not save empty/invalid URLs
          // ✅ REMOVED: Do not keep old image if backend returns empty
        }

        // ✅ UPDATE PROVIDER - Only use backend data (no fallback)
        _userName = name;
        _country = country;
        _gender = gender;
        _dob = dob;
        _userImage =
            normalizedProfileUrl; // ✅ No fallback - use backend value only (empty if backend returns empty)

        print("💾 ========== SAVING TO SHARED PREFERENCES ==========");
        print("✅ Profile updated for user: $userId");
        print("   - Saved Name: $name");
        print("   - Saved Image URL: $_userImage");
        print(
          "   - Image URL is valid: ${_userImage != null && _userImage!.isNotEmpty && _userImage != 'yyyy' && _userImage != 'Profile Url'}",
        );

        // ✅ Mark user as not new anymore
        await prefs.setBool('isNewUser', false);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool(
          'is_logged_in',
          true,
        ); // ✅ Also set snake_case for consistency
        print("💾 ========== SHARED PREFERENCES SAVED ==========");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        print("🔄 Fetching fresh user data...");
        await fetchUserData();
        print("✅ Fresh data fetched");

        // ✅ Navigate to home screen after successful update
        if (context.mounted) {
          // Wait a bit for snackbar to show, then navigate
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            print("🧭 Navigating to home screen...");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainBottomNavScreen()),
            );
          }
        }
      } else {
        print("❌ ========== BACKEND RESPONSE FAILED ==========");
        if (response == null) {
          print("   - Response is null");
        } else {
          print("   - Status: ${response.status}");
          print("   - Profile URL: ${response.profileUrl}");
        }
        print("❌ ========== BACKEND RESPONSE FAILED END ==========");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print("❌ ========== EXCEPTION IN SUBMIT USER DATA ==========");
      print("   - Error: $e");
      print("   - Error type: ${e.runtimeType}");
      print("   - Stack trace: $stackTrace");
      print("❌ ========== EXCEPTION END ==========");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      print("🚀 ========== SUBMIT USER DATA ENDED ==========");
    }
  }

  /// Check if admin changed user ID via get_user_info. Updates session and provider if changed.
  Future<void> checkUserIdChange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dynamic userIdValue = prefs.get('user_id');
      if (userIdValue == null) return;
      final currentId = userIdValue is int
          ? userIdValue.toString()
          : userIdValue.toString();
      final idInt = int.tryParse(currentId);
      if (idInt == null || idInt <= 0) return;

      final data = await ApiManager.getUserInfoWithIdCheck(idInt);
      if (data == null) return;

      // Robust check: is_id_changed can be bool true, string "true", or int 1
      final isIdChanged = data['is_id_changed'] == true ||
          data['is_id_changed'] == 'true' ||
          data['is_id_changed'] == 1;
      final newIdVal = data['new_id']?.toString();

      if (isIdChanged && newIdVal != null && newIdVal.isNotEmpty) {
        await prefs.setString('user_id', newIdVal);
        _userId = newIdVal;
        _isIdChanged = true;
        _displayUserId = newIdVal;
        await prefs.setBool('user_id_was_changed', true); // Persist for UI
        print('✅ [ProfileUpdateProvider] User ID updated: $currentId -> $newIdVal (is_id_changed=true)');
      } else if (isIdChanged && (newIdVal == null || newIdVal.isEmpty)) {
        // is_id_changed true but no new_id - user found by id, has old_user_id set
        _isIdChanged = true;
        _displayUserId = _userId;
        await prefs.setBool('user_id_was_changed', true);
        print('✅ [ProfileUpdateProvider] is_id_changed=true (user has old_user_id)');
      } else {
        _isIdChanged = await prefs.getBool('user_id_was_changed') ?? false;
        _displayUserId = null;
        if (!_isIdChanged) await prefs.remove('user_id_was_changed');
      }
      notifyListeners();
    } catch (e) {
      print('⚠️ [ProfileUpdateProvider] checkUserIdChange error: $e');
    }
  }

  Future<void> fetchUserData() async {
    try {
      // ✅ Set loading state
      _isLoading = true;

      //notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      // ✅ SMART TYPE HANDLING
      String userId;
      dynamic userIdValue = prefs.get('user_id');

      if (userIdValue != null) {
        if (userIdValue is int) {
          userId = userIdValue.toString();
        } else if (userIdValue is String) {
          userId = userIdValue;
        } else {
          userId = '33';
        }
      } else {
        userId = '33';
      }

      print("📥 Fetching data for user: $userId");

      _userId = userId;

      // ✅ Check if admin changed user ID - update session immediately
      await checkUserIdChange();
      userId = _userId ?? userId;

      // ✅ FIRST: Try to fetch from backend API (fresh data)
      try {
        String? googleId = prefs.getString('google_id_$userId');
        if (googleId == null || googleId.isEmpty) {
          googleId = prefs.getString('google_id');
          print(
            "🔍 Checking global google_id: ${googleId != null ? 'found' : 'not found'}",
          );
        }

        if (googleId == null || googleId.isEmpty) {
          // Try to get from email or other sources
          String? email =
              prefs.getString('email_$userId') ?? prefs.getString('email');
          if (email != null && email.isNotEmpty) {
            print("⚠️ Google ID not found, but email found: $email");
            print(
              "⚠️ Cannot fetch user data without google_id - API will fail",
            );
          } else {
            print("⚠️ Google ID and email not found - cannot fetch user data");
          }
        }

        // ✅ Try to fetch from backend if we have google_id
        if (googleId != null && googleId.isNotEmpty) {
          final userData = await ApiManager.googleLogin(google_id: googleId);
          if (userData != null) {
            if (userId == '33' || userIdValue == null) {
              print("✅ Found missing user_id from API: ${userData.id}");
              // ✅ Format user_id to 8 digits before saving
              final formattedUserId = UserIdUtils.formatTo8Digits(userData.id);
              await prefs.setString('user_id', formattedUserId ?? userData.id);
              userId = userData.id;
              _userId = userId;
            }
            print("✅ Fetched fresh data from backend for user: $userId");

            // ✅ REMOVED FALLBACKS - Only use backend data
            final nameValue = userData.name.isNotEmpty ? userData.name : '';
            final countryValue = userData.country ?? '';
            final genderValue = userData.gender ?? '';
            final dobValue = userData.dob ?? '';
            final emailValue = userData.email.isNotEmpty ? userData.email : '';
            final phoneValue = userData.phone ?? '';

            print("📋 ========== DATA EXTRACTION (NO FALLBACKS) ==========");
            print(
              "   📋 Backend name: '${userData.name}' → Final: '$nameValue'",
            );
            print(
              "   📋 Backend country: '${userData.country}' → Final: '$countryValue'",
            );
            print(
              "   📋 Backend gender: '${userData.gender}' → Final: '$genderValue'",
            );
            print("   📋 Backend dob: '${userData.dob}' → Final: '$dobValue'");
            print("📋 ========== DATA EXTRACTION END ==========");

            print("🖼️ ========== PROFILE IMAGE LOGIC ==========");
            print("   📦 Backend profileUrl (raw): ${userData.profileUrl}");
            print(
              "   📦 Backend profileUrl is null: ${userData.profileUrl == null}",
            );
            print(
              "   📦 Backend profileUrl is empty: ${userData.profileUrl?.isEmpty ?? true}",
            );

            // ✅ Use backend data first, fallback to SharedPreferences if backend doesn't return it
            String rawImageValue = '';
            if (userData.profileUrl != null &&
                userData.profileUrl!.isNotEmpty) {
              rawImageValue = userData.profileUrl!;
              print("   ✅ Using backend profileUrl: '$rawImageValue'");
              print("   ✅ Backend returned valid profile URL");
            } else {
              print("   ❌ Backend profileUrl is NULL or EMPTY");
              print("   🔍 Checking SharedPreferences as fallback...");

              // ✅ Fallback to SharedPreferences when backend doesn't return profile_url
              final cachedImage = prefs.getString('userImage_$userId');
              if (cachedImage != null && cachedImage.isNotEmpty) {
                rawImageValue = cachedImage;
                print(
                  "   ✅ Found cached profile image in SharedPreferences: '$rawImageValue'",
                );
                print(
                  "   ✅ Using cached image as fallback (backend didn't return profile_url)",
                );
              } else {
                rawImageValue = '';
                print(
                  "   ⚠️ No cached image found in SharedPreferences either",
                );
                print("   ⚠️ This indicates:");
                print(
                  "      1. Backend is not returning profile_url in login response",
                );
                print("      2. Profile image was never saved to cache");
              }
            }

            print(
              "   📋 Raw image value before normalization: '$rawImageValue'",
            );
            final imageValue = _normalizeProfileUrl(rawImageValue);
            print("   📋 Final imageValue after normalization: '$imageValue'");
            print("   📋 Final imageValue is empty: ${imageValue.isEmpty}");
            print("🖼️ ========== PROFILE IMAGE LOGIC END ==========");

            final merchantValue = userData.merchant;
            final wealthLevelValue = userData.wealthLevel; // ✅ new wealth level
            final isAgencyAvailableValue = userData.isAgencyAvailable;
            final agencyInfoValue = userData.agencyInfo;

            print("💼 Merchant Status Logic:");
            print("   - Backend merchant: ${userData.merchant}");
            print("   - Final merchantValue: $merchantValue (from API only)");
            print(
              "   - isMerchant: ${merchantValue != null && merchantValue > 0}",
            );

            print("💰 Wealth Level Logic:");
            print("   - Backend wealth_level: ${userData.wealthLevel}");
            print("   - Final wealthLevelValue: $wealthLevelValue");

            print("🏢 Agency Information Logic:");
            print(
              "   - Backend agency_info: ${userData.agencyInfo != null ? "exists" : "null"}",
            );
            if (userData.agencyInfo != null) {
              print("   - has_agency: ${userData.agencyInfo!.hasAgency}");
              print("   - is_member: ${userData.agencyInfo!.isMember}");
              print(
                "   - owned_agency: ${userData.agencyInfo!.ownedAgency?.agencyName ?? "None"}",
              );
              print(
                "   - member_agencies: ${userData.agencyInfo!.agencies.length}",
              );
            }
            print(
              "   - Legacy is_agency_available: ${userData.isAgencyAvailable}",
            );
            print(
              "   - Final isAgencyAvailableValue: $isAgencyAvailableValue (from API only)",
            );
            print(
              "   - hasAgencyAvailable: ${agencyInfoValue?.hasAgency ?? (isAgencyAvailableValue != null && isAgencyAvailableValue > 0)}",
            );

            _userName = nameValue;
            _country = countryValue;
            _gender = genderValue;
            _dob = dobValue;
            _userImage = imageValue;
            _merchant = merchantValue;
            _wealthLevel = wealthLevelValue; // ✅ Update wealth level
            _isAgencyAvailable = isAgencyAvailableValue; // ✅ Legacy support
            _agencyInfo = agencyInfoValue; // ✅ New structure
            _email = emailValue;
            _phone = phoneValue;

            print("👤 Name Logic:");
            print("   - Backend name: ${userData.name}");
            print("   - Final nameValue: $nameValue");

            if (nameValue.isNotEmpty) {
              await prefs.setString('userName_$userId', nameValue);
            }
            if (countryValue.isNotEmpty) {
              await prefs.setString('country_$userId', countryValue);
            }
            if (genderValue.isNotEmpty) {
              await prefs.setString('gender_$userId', genderValue);
            }
            if (dobValue.isNotEmpty) {
              await prefs.setString('dob_$userId', dobValue);
            }
            if (imageValue.isNotEmpty) {
              await prefs.setString('userImage_$userId', imageValue);
              print(
                "   ✅ Saved normalized profile image to SharedPreferences: $imageValue",
              );
            } else {
              print(
                "   ⚠️ Profile image is empty, not saving to SharedPreferences",
              );
            }
            if (merchantValue != null) {
              await prefs.setInt('merchant_$userId', merchantValue);
              print("   💾 Saved merchant status to cache: $merchantValue");
            }
            if (wealthLevelValue != null) {
              await prefs.setInt('wealth_level_$userId', wealthLevelValue);
              print("   💾 Saved wealth level to cache: $wealthLevelValue");
            }

            print("📊 Loaded FRESH data from backend for USER $userId:");
            print("   - Name: $_userName");
            print("   - Country: $_country");
            print("   - Gender: $_gender");
            print("   - DOB: $_dob");
            print("   - Image: $_userImage");
            print("   - Merchant: $_merchant (isMerchant: $isMerchant)");

            // ✅ Clear loading state
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      } catch (apiError) {
        print("❌ ========== API CALL EXCEPTION ==========");
        print("❌ Error: $apiError");
        print("❌ ======================================");
      }

      // ✅ Clear loading state if API call failed
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("❌ Error fetching user data: $e");
      // ✅ Clear loading state on error
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Fetch a specific user's data by userId (for viewing other users' profiles)
  /// This method fetches user data from getUserInfoById API (single user)
  Future<void> fetchUserDataByUserId(String targetUserId) async {
    try {
      // ✅ Set loading state
      _isLoading = true;
      notifyListeners();

      print("📥 ========== FETCHING USER DATA BY ID ==========");
      print("📥 Target User ID: $targetUserId");

      final targetIdInt = int.tryParse(targetUserId);
      if (targetIdInt == null) {
        print("⚠️ Invalid target user id: $targetUserId");
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ✅ Fetch a single user from API
      final userMap = await ApiManager.getUserInfoById(targetIdInt);
      if (userMap == null || userMap.isEmpty) {
        print("⚠️ User $targetUserId not found in API response");
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ✅ Extract user data
      final nameValue =
          (userMap['name']?.toString() ?? userMap['username']?.toString() ?? '')
              .trim();
      final countryValue = userMap['country']?.toString() ?? '';
      final genderValue = userMap['gender']?.toString() ?? '';
      final dobValue = userMap['dob']?.toString() ?? '';
      final emailValue = userMap['email']?.toString() ?? '';
      final phoneValue = userMap['phone']?.toString() ?? '';

      // ✅ Extract and normalize profile URL
      String? rawImageValue = userMap['profile_url']?.toString();
      String imageValue = '';
      if (rawImageValue != null && rawImageValue.isNotEmpty) {
        imageValue = _normalizeProfileUrl(rawImageValue);
      }

      // ✅ Extract merchant status
      int? merchantValue;
      if (userMap['merchant'] != null) {
        merchantValue = userMap['merchant'] is int
            ? userMap['merchant']
            : int.tryParse(userMap['merchant'].toString());
      }

      // ✅ Extract wealth_level
      int? wealthLevelValue;
      if (userMap['wealth_level'] != null) {
        wealthLevelValue = userMap['wealth_level'] is int
            ? userMap['wealth_level']
            : int.tryParse(userMap['wealth_level'].toString());
      }

      // ✅ Extract is_agency_available status (LEGACY)
      int? isAgencyAvailableValue;
      final agencyAvailableKey = userMap.containsKey('is_agency_available')
          ? 'is_agency_available'
          : (userMap.containsKey('Is_agency_avaiable')
                ? 'Is_agency_avaiable'
                : (userMap.containsKey('isAgencyAvailable')
                      ? 'isAgencyAvailable'
                      : null));

      if (agencyAvailableKey != null && userMap[agencyAvailableKey] != null) {
        isAgencyAvailableValue = userMap[agencyAvailableKey] is int
            ? userMap[agencyAvailableKey]
            : int.tryParse(userMap[agencyAvailableKey].toString());
      }

      // ✅ Extract agency_info (NEW STRUCTURE)
      AgencyInfo? agencyInfoValue;
      if (userMap.containsKey('agency_info') &&
          userMap['agency_info'] != null) {
        try {
          agencyInfoValue = AgencyInfo.fromJson(userMap['agency_info']);
          // Set legacy value from new structure if not already set
          isAgencyAvailableValue ??= agencyInfoValue.hasAgency ? 1 : 0;
        } catch (e) {
          print('❌ Error parsing agency_info in loadUserDataForTargetUser: $e');
        }
      }

      // ✅ Update provider state with target user's data
      _userId = targetUserId;
      _userName = nameValue;
      _country = countryValue;
      _gender = genderValue;
      _dob = dobValue;
      _userImage = imageValue;
      _merchant = merchantValue;
      _wealthLevel = wealthLevelValue; // ✅ Update wealth level
      _isAgencyAvailable = isAgencyAvailableValue; // ✅ Legacy support
      _agencyInfo = agencyInfoValue; // ✅ New structure
      _email = emailValue;
      _phone = phoneValue;

      print("📊 Loaded data for TARGET USER $targetUserId:");
      print("   - Name: $_userName");
      print("   - Country: $_country");
      print("   - Gender: $_gender");
      print("   - DOB: $_dob");
      print("   - Image: $_userImage");
      print("   - Email: $_email");
      print("   - Phone: $_phone");
      print("   - Merchant: $_merchant");

      // ✅ Clear loading state
      _isLoading = false;
      notifyListeners();
      print("✅ ========== FETCH USER DATA BY ID COMPLETE ==========");
    } catch (e) {
      print("❌ Error fetching user data by ID: $e");
      // ✅ Clear loading state on error
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCpUserDataByUserId(String targetUserId) async {
    try {
      notifyListeners();

      print("📥 ========== FETCHING USER DATA BY ID ==========");
      print("📥 Target User ID: $targetUserId");

      // ✅ Fetch all users from API
      final allUsers = await ApiManager.getAllCpUsers();

      print("!!!!!!!!!!!All cp user!!!!!!!!!!!!!!!");

      if (allUsers.isEmpty) {
        print("⚠️ No users returned from API");
        return;
      }
      userCpData = false;
      cpPartnerData = null;
      notifyListeners();
      // ✅ Find the target user in the list
      final userData = allUsers.firstWhere((user) {
        final userMap = user as Map<String, dynamic>;
        final userId =
            userMap['id']?.toString() ?? userMap['user_id']?.toString() ?? '';
        return userId == targetUserId;
      }, orElse: () => null);

      if (userData == null) {
        userCpData = false;
        cpPartnerData = null;
        print("⚠️ User $targetUserId not found in API response");
        _isLoading = false;
        notifyListeners();
        return;
      } else {
        userCpData = true;

        // ✅ Extract CP partner data from the nested cpUser object
        final userMap = userData as Map<String, dynamic>;

        print("📊 User Data Keys: ${userMap.keys.toList()}");
        print("📊 Full User Data: ${jsonEncode(userMap)}");

        // Check if cpUser exists in the response
        if (userMap.containsKey('cpUser') && userMap['cpUser'] != null) {
          cpPartnerData = userMap['cpUser'] as Map<String, dynamic>;
          print("✅ Found CP Partner in cpUser field:");
          print("   Partner Name: ${cpPartnerData!['name']}");
          print("   Partner ID: ${cpPartnerData!['id']}");
          print("   Partner Profile: ${cpPartnerData!['profile_url']}");
        } else {
          // Fallback: try to find by cp_partner_id
          final partnerId = userMap['cp_partner_id']?.toString();

          if (partnerId != null && partnerId.isNotEmpty && partnerId != '0') {
            print("🔍 Searching for partner by ID: $partnerId");
            // Find partner in the list
            final partner = allUsers.firstWhere((user) {
              final u = user as Map<String, dynamic>;
              final uid = u['id']?.toString() ?? u['user_id']?.toString() ?? '';
              return uid == partnerId;
            }, orElse: () => null);

            if (partner != null) {
              cpPartnerData = partner as Map<String, dynamic>;
              print(
                "✅ Found CP Partner by ID search: ${cpPartnerData!['name']} (ID: $partnerId)",
              );
            } else {
              print("⚠️ Partner ID $partnerId not found in users list");
            }
          } else {
            print("⚠️ No CP partner data found for this user");
          }
        }

        notifyListeners();
      }

      // ✅ Print the target user data
      print("✅ Target User Data:");
      print(jsonEncode(userData)); // prints full user info as JSON string

      // ✅ Clear loading state
      _isLoading = false;
      notifyListeners();
      print("✅ ========== FETCH USER DATA BY ID COMPLETE ==========");
    } catch (e) {
      print("❌ Error fetching user data by ID: $e");
      // ✅ Clear loading state on error
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Fetch user levels from API
  Future<void> fetchUserLevels(String userId) async {
    try {
      print("📊 ========== FETCHING USER LEVELS ==========");
      print("📊 User ID: $userId");

      final userIdInt = int.tryParse(userId);
      if (userIdInt == null) {
        print("❌ Invalid user ID: $userId");
        return;
      }

      final levelData = await ApiManager.getUserLevels(userIdInt);

      if (levelData != null) {
        _userLevels = levelData;
        notifyListeners();
        print("✅ User levels fetched successfully");
        print("   - Sending Level: ${levelData.sending.currentLevel}");
        print("   - Receiving Level: ${levelData.receiving.currentLevel}");
      } else {
        print("⚠️ Failed to fetch user levels");
      }
    } catch (e) {
      print("❌ Error fetching user levels: $e");
    }
  }

  /// ✅ Fetch user tags from API
  Future<void> fetchUserTags(String userId) async {
    try {
      print("🏷️ ========== FETCHING USER TAGS ==========");
      print("🏷️ User ID: $userId");

      final userIdInt = int.tryParse(userId);
      if (userIdInt == null) {
        print("❌ Invalid user ID: $userId");
        return;
      }

      final tagsResponse = await ApiManager.getUserTags(userIdInt);

      if (tagsResponse != null && tagsResponse['status'] == 'success') {
        final data = tagsResponse['data'] as Map<String, dynamic>?;
        if (data != null && data['tags'] != null) {
          final tagsList = data['tags'] as List<dynamic>;
          _tags = tagsList.map((tag) => tag.toString()).toList();
          notifyListeners();
          print("✅ User tags fetched successfully");
          print("   - Tags: $_tags");
          print("   - Tags Count: ${_tags.length}");
        } else {
          _tags = [];
          notifyListeners();
          print("⚠️ No tags found in response");
        }
      } else {
        _tags = [];
        notifyListeners();
        print("⚠️ Failed to fetch user tags");
      }
    } catch (e) {
      print("❌ Error fetching user tags: $e");
      _tags = [];
      notifyListeners();
    }
  }
}
