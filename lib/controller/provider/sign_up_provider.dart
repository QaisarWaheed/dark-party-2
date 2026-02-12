// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shaheen_star_app/view/screens/bottom_nav/main_bottom_nav_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
// import 'package:shaheen_star_app/model/user_sign_up_model.dart';
// import 'package:shaheen_star_app/view/screens/login/profile_update_screen.dart';
// import 'package:shaheen_star_app/utils/user_id_utils.dart';

// class SignUpProvider with ChangeNotifier {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email'],
//     serverClientId:
//         '210203557045-2j29mo7n5cnreqpng50h5pb1o09hsekg.apps.googleusercontent.com',
//   );

//   bool _isLoading = false;
//   UserSignUpModel? _user;
//   String? _errorMessage;

//   bool get isLoading => _isLoading;
//   UserSignUpModel? get user => _user;
//   String? get errorMessage => _errorMessage;

//   static const String _bearerToken = 'mySuperSecretStaticToken123';

//   Future<void> googleSignup(BuildContext context) async {
//     try {
//       _isLoading = true;
//       _errorMessage = null;
//       notifyListeners();

//       print('🔵 Starting Google Sign In...');

//       // ✅ Sign out from previous session
//       await _googleSignIn.signOut();

//       // ✅ Google Sign In
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         print('⚠️ User cancelled Google sign in');
//         _isLoading = false;
//         notifyListeners();
//         return;
//       }

//       print('✅ Google account selected: ${googleUser.email}');
//       print('✅ Google User ID: ${googleUser.id}');

//       // ✅ Get user data from Google Sign-In
//       final String uid = googleUser.id; // Google Sign-In ID
//       final String email = googleUser.email;
//       String name = googleUser.displayName ?? '';

//       // ✅ Data validation and name fallback
//       if (email.isEmpty) {
//         throw Exception('Email not available from Google account');
//       }

//       // ✅ Ensure name is not empty
//       if (name.isEmpty) {
//         name = email.split('@').first;
//         print('⚠️ Display name not available, using email prefix: $name');
//       }

//       print("✅ Google ID: $uid");
//       print("📧 Email: $email");
//       print("👤 Username: $name");

//       // 🔹 STEP 1 — Pehle Login try karein (existing user check)
//       print("🔄 Checking for existing user (Login First)...");
//       final loginUser = await ApiManager.googleLogin(google_id: uid);

//       if (loginUser != null) {
//         // ✅ Existing user - login successful, directly home screen
//         print('🎉 Existing user logged in successfully - Direct to Home');
//         print('✅ User ID: ${loginUser.id}');
//         print('✅ User Email: ${loginUser.email}');
//         await _saveUserData(loginUser, googleId: uid);

//         if (context.mounted) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) =>    MainBottomNavScreen()),
//           );
//         }
//       } else {
//         // 🔹 STEP 2 — Login failed, try Signup (new user)
//         print('🔄 Login failed, trying Google Signup...');
//         try {
//           final signupUser = await ApiManager.googleSignup(
//             google_id: uid,
//             email: email,
//             username: name, // ✅ username field
//             name: name, // ✅ name field (same as username for new users)
//             firebaseToken: _bearerToken,
//           );

//           if (signupUser != null) {
//             // ✅ New user - signup successful
//             print('🎉 New user registered successfully - Go to Profile Update');
//             print('✅ New User ID: ${signupUser.id}');
//             await _saveUserData(signupUser, googleId: uid);

//             if (context.mounted) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const ProfileUpdateScreen()),
//               );
//             }
//           } else {
//             // ❌ Signup failed for unknown reason
//             print('❌ Signup failed');
//             _errorMessage = 'Authentication failed. Please try again.';

//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Authentication failed. Please try again.'),
//                   backgroundColor: Colors.red,
//                   duration: Duration(seconds: 3),
//                 ),
//               );
//             }
//           }
//         } on EmailAlreadyExistsException {
//           // ✅ Email already exists - user exists, try to fetch user data again
//           print('✅ Email already exists - User exists, retrying login to get user_id...');
//           print('📧 Existing user email: $email');

//           // ✅ Retry login API (maybe it was a temporary 500 error)
//           // This will get us the user_id and full user data
//           final retryLoginUser = await ApiManager.googleLogin(google_id: uid);

//           if (retryLoginUser != null) {
//             // ✅ Successfully got user data - save it properly
//             print('🎉 Retry login successful - Got user data');
//             print('✅ User ID: ${retryLoginUser.id}');
//             await _saveUserData(retryLoginUser, googleId: uid);

//             if (context.mounted) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
//               );
//             }
//           } else {
//             // ✅ Login still failing - save basic info and navigate
//             // User can retry later or we'll fetch user_id when they access profile
//             print('⚠️ Retry login still failed - Saving basic info only');
//             final prefs = await SharedPreferences.getInstance();
//             await prefs.setString('email', email);
//             await prefs.setString('username', name);
//             await prefs.setString('google_id', uid);
//             await prefs.setBool('is_logged_in', true);
//             await prefs.setBool('isLoggedIn', true);
//             await prefs.setString('login_method', 'google');

//             print('⚠️ WARNING: user_id not saved - User may need to login again');

//             if (context.mounted) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
//               );
//             }
//           }
//         }
//       }
//     } catch (e, s) {
//       print('❌ Google SignIn Error: $e\n$s');
//       _errorMessage = e.toString();

//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // ✅ Better user data saving
//   Future<void> _saveUserData(UserSignUpModel user, {String? googleId}) async {
//     _user = user;
//     final prefs = await SharedPreferences.getInstance();
//     final userId = user.id;

//     // ✅ Format user_id to 8 digits before saving
//     final formattedUserId = UserIdUtils.formatTo8Digits(userId);
//     final userIdToSave = formattedUserId ?? userId;

//     // ✅ USER-SPECIFIC DATA SAVE KARO
//     await prefs.setString('user_id', userIdToSave);
//     await prefs.setString('email_$userId', user.email);
//     await prefs.setString('username_$userId', user.name);

//     // ✅ SAVE MERCHANT STATUS
//     if (user.merchant != null) {
//       await prefs.setInt('merchant_$userId', user.merchant!);
//       print('💾 Saved Merchant Status: ${user.merchant} (isMerchant: ${user.isMerchant})');
//     }

//     // ✅ SAVE GOOGLE ID FOR FETCHING FRESH DATA LATER
//     if (googleId != null && googleId.isNotEmpty) {
//       await prefs.setString('google_id_$userId', googleId);
//       await prefs.setString('google_id', googleId);
//       print('💾 Saved Google ID: $googleId');
//     }

//     // ✅ CURRENT SESSION DATA
//     await prefs.setString('email', user.email);
//     await prefs.setString('username', user.name);

//     // ✅ Save API token
//     if (user.apiToken != null && user.apiToken!.isNotEmpty) {
//       await prefs.setString('api_token_$userId', user.apiToken!);
//       await prefs.setString('api_token', user.apiToken!);
//       print('🔑 ========== SAVING LOGIN TOKEN ==========');
//       print('🔑 Token: ${user.apiToken}');
//       print('🔑 Token Length: ${user.apiToken!.length}');
//       print('🔑 Saved to: api_token_$userId and api_token');
//       print('🔑 ========== TOKEN SAVED ==========');
//     } else {
//       print('⚠️ API Token is null or empty - not saving');
//     }

//     await prefs.setBool('is_logged_in', true);
//     await prefs.setBool('isLoggedIn', true); // Also save camelCase for backward compatibility
//     await prefs.setString('login_method', 'google');

//     print('💾 User data saved for ID: $userId, Email: ${user.email}');
//     print('💾 Login status saved: is_logged_in=true, isLoggedIns=true');

//     // ✅ Debug: Check saved data
//     final savedId = prefs.getString('user_id');
//     final savedEmail = prefs.getString('email');
//     print('💾 Saved User ID: $savedId');
//     print('💾 Saved Email: $savedEmail');
//   }

//   // ✅ Check existing login status with debug
//   Future<bool> checkLoginStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
//     final userId = prefs.getString('user_id');
//     final email = prefs.getString('email');

//     print('🔍 Login Status Check:');
//     print('🔍 is_logged_in: $isLoggedIn');
//     print('🔍 user_id: $userId');
//     print('🔍 email: $email');

//     return isLoggedIn;
//   }

//   Future<void> logout() async {
//     try {
//       await _googleSignIn.signOut();
//     } catch (e) {
//       print('⚠️ Error signing out from Google: $e');
//     }

//     final prefs = await SharedPreferences.getInstance();

//     // ✅ CLEAR ALL LOGIN-RELATED FLAGS
//     await prefs.remove('userName');
//     await prefs.remove('country');
//     await prefs.remove('gender');
//     await prefs.remove('dob');
//     await prefs.remove('userImage');
//     await prefs.remove('email');
//     await prefs.remove('username');
//     await prefs.remove('api_token');
//     await prefs.remove('is_logged_in');
//     await prefs.remove('isLoggedIn');
//     await prefs.remove('isNewUser');
//     await prefs.remove('login_method');
//     await prefs.remove('google_id');

//     final userId = prefs.getString('user_id');
//     if (userId != null) {
//       await prefs.remove('userName_$userId');
//       await prefs.remove('country_$userId');
//       await prefs.remove('gender_$userId');
//       await prefs.remove('dob_$userId');
//       await prefs.remove('userImage_$userId');
//       await prefs.remove('email_$userId');
//       await prefs.remove('google_id_$userId');
//     }

//     _user = null;
//     _isLoading = false;
//     _errorMessage = null;

//     print('🚪 User logged out successfully');
//     notifyListeners();
//   }
// }

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/api_manager/auth_api.dart';
import 'package:shaheen_star_app/model/user_sign_up_model.dart';
import 'package:shaheen_star_app/utils/user_id_utils.dart';
import 'package:shaheen_star_app/utils/user_session.dart'; // ✅ ADD THIS
import 'package:shaheen_star_app/view/screens/bottom_nav/main_bottom_nav_screen.dart';
import 'package:shaheen_star_app/view/screens/login/register_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpProvider with ChangeNotifier {
  // final GoogleSignIn _googleSignIn = GoogleSignIn(
  //   scopes: ['email'],
  //   serverClientId:
  //       '828536498276-494l5kh303de7hk640rkeo4nlh9kc6g4.apps.googleusercontent.com',
  // );

  bool _isLoading = false;
  UserSignUpModel? _user;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  UserSignUpModel? get user => _user;
  String? get errorMessage => _errorMessage;

  static const String _bearerToken = 'mySuperSecretStaticToken123';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '729065531351-5tr13doaf36e1ote6atguf8vnke0fm67.apps.googleusercontent.com',
  );

  Future<void> googleSignup(BuildContext context) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔵 Starting Google Sign In...');

      // ✅ Sign out from previous session
      await _googleSignIn.signOut();

      // ✅ Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ User cancelled Google sign in');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      print('✅ Google account selected: ${googleUser.email}');
      print('✅ Google User ID: ${googleUser.id}');

      // ✅ Get user data from Google Sign-In
      final String uid = googleUser.id; // Google Sign-In ID
      final String email = googleUser.email;
      String name = googleUser.displayName ?? '';

      // ✅ Data validation and name fallback
      if (email.isEmpty) {
        throw Exception('Email not available from Google account');
      }

      // ✅ Ensure name is not empty
      if (name.isEmpty) {
        name = email.split('@').first;
        print('⚠️ Display name not available, using email prefix: $name');
      }

      print("✅ Google ID: $uid");
      print("📧 Email: $email");
      print("👤 Username: $name");

      print("🔄 Checking for existing user (Login First)...");

      UserSignUpModel? loginUser;
      try {
        loginUser = await ApiManager.googleLogin(google_id: uid);

        if (loginUser != null) {
          // ✅ Existing user - login successful, directly home screen
          print('🎉 Existing user logged in successfully - Direct to Home');
          print('✅ User ID: ${loginUser.id}');
          print('✅ User Email: ${loginUser.email}');
          await _saveUserData(loginUser, googleId: uid);

          /// bhai yahan pr gmail se login kro
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
            );
          }
          _isLoading = false;
          notifyListeners();
          return; // Exit after successful login
        }
      } on BannedUserException catch (e) {
        // User is banned - show ban message
        print('🚫 User is BANNED!');
        print('🚫 Message: ${e.message}');
        print('🚫 Ban Details: ${e.banDetails}');

        _isLoading = false;
        notifyListeners();

        // Sign out the user
        await _googleSignIn.signOut();

        if (context.mounted) {
          final banReason = e.banDetails['ban_reason'] ?? 'No reason provided';
          final bannedUntil = e.banDetails['banned_until'] ?? 'Permanent';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🚫 ${e.message}\n'
                'Reason: $banReason\n'
                'Banned Until: $bannedUntil',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      } catch (e) {
        print('⚠️ Login API error: $e');
      }

      // 🔹 STEP 2 — Login returned null, try Signup (new user)
      if (loginUser == null) {
        // 🔹 STEP 2 — Login failed, try Signup (new user)
        print('🔄 Login failed, trying Google Signup...');
        try {
          final signupUser = await ApiManager.googleSignup(
            google_id: uid,
            email: email,
            username: name, // ✅ username field
            name: name, // ✅ name field (same as username for new users)
            firebaseToken: _bearerToken,
          );

          if (signupUser != null) {
            // ✅ New user - signup successful
            print('🎉 New user registered successfully - Go to Profile Setup');
            print('✅ New User ID: ${signupUser.id}');
            await _saveUserData(signupUser, googleId: uid);

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
            }
          } else {
            // ❌ Signup failed for unknown reason
            print('❌ Signup failed');
            _errorMessage = 'Authentication failed. Please try again.';

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Authentication failed. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } on EmailAlreadyExistsException {
          // ✅ Email already exists - user exists, try to fetch user data again
          print(
            '✅ Email already exists - User exists, retrying login to get user_id...',
          );
          print('📧 Existing user email: $email');

          // ✅ Retry login API (maybe it was a temporary 500 error)
          // This will get us the user_id and full user data
          final retryLoginUser = await ApiManager.googleLogin(google_id: uid);

          if (retryLoginUser != null) {
            // ✅ Successfully got user data - save it properly
            print('🎉 Retry login successful - Got user data');
            print('✅ User ID: ${retryLoginUser.id}');
            await _saveUserData(retryLoginUser, googleId: uid);

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
              );
            }
          } else {
            // ✅ Login still failing - save basic info and navigate
            // User can retry later or we'll fetch user_id when they access profile
            print('⚠️ Retry login still failed - Saving basic info only');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('email', email);
            await prefs.setString('username', name);
            await prefs.setString('google_id', uid);
            await prefs.setBool('is_logged_in', true);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('login_method', 'google');

            print(
              '⚠️ WARNING: user_id not saved - User may need to login again',
            );

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
              );
            }
          }
        }
      }
    } on PlatformException catch (e) {
      // ✅ Handle PlatformException (Google Sign In errors)
      print('❌ Google SignIn PlatformException: ${e.code} - ${e.message}');
      print('❌ Details: ${e.details}');

      String errorMessage = 'Google Sign In failed. Please try again.';

      // ✅ Specific error messages based on error code
      if (e.code == 'sign_in_failed') {
        if (e.message?.contains('ApiException: 10') == true) {
          errorMessage =
              'Google Sign In configuration error. Please check app settings.';
          print(
            '⚠️ DEVELOPER_ERROR (10): Check SHA-1 fingerprint and OAuth client ID configuration',
          );
        } else {
          errorMessage =
              'Google Sign In failed. Please check your internet connection and try again.';
        }
      } else if (e.code == 'network_error') {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.code == 'sign_in_canceled') {
        errorMessage = 'Sign in was cancelled.';
        _isLoading = false;
        notifyListeners();
        return; // Don't show error for user cancellation
      }

      _errorMessage = errorMessage;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, s) {
      print('❌ Google SignIn Error: $e\n$s');
      _errorMessage = e.toString();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Better user data saving WITH UserSession integration
  Future<void> _saveUserData(UserSignUpModel user, {String? googleId}) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    final userId = user.id;

    // ✅ Format user_id to 8 digits before saving
    final formattedUserId = UserIdUtils.formatTo8Digits(userId);
    final userIdToSave = formattedUserId ?? userId;

    print('💾 ========== SAVING USER DATA ==========');
    print('💾 User ID: $userId');
    print('💾 Formatted ID: $userIdToSave');
    print('💾 Email: ${user.email}');
    print('💾 Name: ${user.name}');

    // ✅ USER-SPECIFIC DATA SAVE KARO (Original logic maintained)
    await prefs.setString('user_id', userIdToSave);
    await prefs.setString('email_$userId', user.email);
    await prefs.setString('username_$userId', user.name);

    // ✅ SAVE MERCHANT STATUS
    if (user.merchant != null) {
      await prefs.setInt('merchant_$userId', user.merchant!);
      print(
        '💾 Saved Merchant Status: ${user.merchant} (isMerchant: ${user.isMerchant})',
      );
    }

    // ✅ SAVE WEALTH LEVEL
    if (user.wealthLevel != null) {
      await prefs.setInt('wealth_level_$userId', user.wealthLevel!);
      await prefs.setInt('wealth_level', user.wealthLevel!); // Global key
      print('💾 Saved Wealth Level: ${user.wealthLevel}');
    }

    // ✅ SAVE AGENCY INFO (NEW STRUCTURE)
    if (user.agencyInfo != null) {
      // Save agency_info as JSON string
      final agencyInfoJson = user.agencyInfo!.toJson();
      await prefs.setString('agency_info_$userId', jsonEncode(agencyInfoJson));
      await prefs.setString(
        'agency_info',
        jsonEncode(agencyInfoJson),
      ); // Also save global key
      await prefs.setBool('has_agency_$userId', user.agencyInfo!.hasAgency);
      await prefs.setBool('is_member_$userId', user.agencyInfo!.isMember);
      print(
        '💾 Saved Agency Info: has_agency=${user.agencyInfo!.hasAgency}, is_member=${user.agencyInfo!.isMember}',
      );
      print(
        '💾 Owned Agency: ${user.agencyInfo!.ownedAgency?.agencyName ?? "None"}',
      );
      print('💾 Member Agencies: ${user.agencyInfo!.agencies.length}');
    }

    // ✅ SAVE LEGACY AGENCY AVAILABILITY STATUS (for backward compatibility)
    if (user.isAgencyAvailable != null) {
      await prefs.setInt(
        'is_agency_available_$userId',
        user.isAgencyAvailable!,
      );
      await prefs.setInt(
        'is_agency_available',
        user.isAgencyAvailable!,
      ); // Also save global key
      print('💾 Saved Legacy Agency Availability: ${user.isAgencyAvailable}');
    } else if (user.agencyInfo != null) {
      // Set legacy value from new structure (owner OR member)
      final legacyValue =
          (user.agencyInfo!.hasAgency || user.agencyInfo!.isMember) ? 1 : 0;
      await prefs.setInt('is_agency_available_$userId', legacyValue);
      await prefs.setInt('is_agency_available', legacyValue);
      print('💾 Set Legacy Agency Availability from agency_info: $legacyValue');
    }

    // ✅ SAVE GOOGLE ID FOR FETCHING FRESH DATA LATER
    if (googleId != null && googleId.isNotEmpty) {
      await prefs.setString('google_id_$userId', googleId);
      await prefs.setString('google_id', googleId);
      print('💾 Saved Google ID: $googleId');
    }

    // ✅ CURRENT SESSION DATA
    await prefs.setString('email', user.email);
    await prefs.setString('username', user.name);
    await prefs.setString('name', user.name); // ✅ ADD THIS for UserSession

    // ✅ Save API token
    if (user.apiToken != null && user.apiToken!.isNotEmpty) {
      await prefs.setString('api_token_$userId', user.apiToken!);
      await prefs.setString('api_token', user.apiToken!);
      await prefs.setString(
        'token',
        user.apiToken!,
      ); // ✅ ADD THIS for UserSession
      print('🔑 ========== SAVING LOGIN TOKEN ==========');
      print('🔑 Token: ${user.apiToken}');
      print('🔑 Token Length: ${user.apiToken!.length}');
      print('🔑 Saved to: api_token_$userId, api_token, and token');
      print('🔑 ========== TOKEN SAVED ==========');
    } else {
      print('⚠️ API Token is null or empty - not saving');
    }

    await prefs.setBool('is_logged_in', true);
    await prefs.setBool(
      'isLoggedIn',
      true,
    ); // Also save camelCase for backward compatibility
    await prefs.setString('login_method', 'google');

    // ✅ Save profile URL if available
    if (user.profileUrl != null && user.profileUrl!.isNotEmpty) {
      await prefs.setString('profile_url', user.profileUrl!);
      print('💾 Saved Profile URL: ${user.profileUrl}');
    }

    print('💾 User data saved for ID: $userId, Email: ${user.email}');
    print('💾 Login status saved: is_logged_in=true, isLoggedIn=true');

    // ✅ Debug: Check saved data
    // ✅ Safely get user_id (handles both int and String types)
    String? savedId;
    try {
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        savedId = userIdInt.toString();
      } else {
        savedId = prefs.getString('user_id');
      }
    } catch (e) {
      // Fallback: try dynamic retrieval
      final dynamic userIdValue = prefs.get('user_id');
      if (userIdValue != null) {
        savedId = userIdValue.toString();
      }
    }
    final savedEmail = prefs.getString('email');
    final savedName = prefs.getString('name');
    final savedUsername = prefs.getString('username');
    print('💾 Saved User ID: $savedId');
    print('💾 Saved Email: $savedEmail');
    print('💾 Saved Name: $savedName');
    print('💾 Saved Username: $savedUsername');

    // ✅ ✅ ✅ NEW: ALSO SAVE TO UserSession for chat functionality
    try {
      print('💾 ========== SAVING TO UserSession ==========');
      final userSession = UserSession();

      // userId ko directly pass karo - UserSession.saveSession() handles both String and int
      await userSession.saveSession(
        userId: userId, // Can be String or int - handled by UserSession
        username: user.name,
        name: user.name,
        email: user.email,
        profileUrl: user.profileUrl ?? '',
        token: user.apiToken ?? '',
      );

      print('✅ UserSession saved successfully for chat!');
      print('💾 ========== UserSession SAVED ==========');
    } catch (e) {
      print('❌ Failed to save UserSession: $e');
      print('⚠️ Chat may not work until user logs in again');
    }

    print('💾 ========== ALL DATA SAVED ==========');
  }

  // ✅ Check existing login status with debug
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    // ✅ Safely get user_id (handles both int and String types)
    String? userId;
    try {
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        userId = userIdInt.toString();
      } else {
        userId = prefs.getString('user_id');
      }
    } catch (e) {
      // Fallback: try dynamic retrieval
      final dynamic userIdValue = prefs.get('user_id');
      if (userIdValue != null) {
        userId = userIdValue.toString();
      }
    }
    final email = prefs.getString('email');

    print('🔍 Login Status Check:');
    print('🔍 is_logged_in: $isLoggedIn');
    print('🔍 user_id: $userId');
    print('🔍 email: $email');

    return isLoggedIn;
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('⚠️ Error signing out from Google: $e');
    }

    final prefs = await SharedPreferences.getInstance();

    // ✅ CLEAR ALL LOGIN-RELATED FLAGS
    await prefs.remove('userName');
    await prefs.remove('country');
    await prefs.remove('gender');
    await prefs.remove('dob');
    await prefs.remove('userImage');
    await prefs.remove('email');
    await prefs.remove('username');
    await prefs.remove('name'); // ✅ ADD THIS
    await prefs.remove('api_token');
    await prefs.remove('token'); // ✅ ADD THIS
    await prefs.remove('profile_url'); // ✅ ADD THIS
    await prefs.remove('is_logged_in');
    await prefs.remove('isLoggedIn');
    await prefs.remove('isNewUser');
    await prefs.remove('login_method');
    await prefs.remove('google_id');

    // ✅ Safely get user_id (handles both int and String types)
    String? userId;
    try {
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        userId = userIdInt.toString();
      } else {
        userId = prefs.getString('user_id');
      }
    } catch (e) {
      // Fallback: try dynamic retrieval
      final dynamic userIdValue = prefs.get('user_id');
      if (userIdValue != null) {
        userId = userIdValue.toString();
      }
    }
    if (userId != null) {
      await prefs.remove('userName_$userId');
      await prefs.remove('country_$userId');
      await prefs.remove('gender_$userId');
      await prefs.remove('dob_$userId');
      await prefs.remove('userImage_$userId');
      await prefs.remove('email_$userId');
      await prefs.remove('google_id_$userId');
      await prefs.remove('username_$userId');
      await prefs.remove('api_token_$userId');
    }

    await prefs.remove('user_id'); // ✅ Clear user_id last

    // ✅ ✅ ✅ NEW: ALSO CLEAR UserSession
    try {
      final userSession = UserSession();
      await userSession.clearSession();
      print('✅ UserSession cleared');
    } catch (e) {
      print('⚠️ Failed to clear UserSession: $e');
    }

    _user = null;
    _isLoading = false;
    _errorMessage = null;

    print('🚪 User logged out successfully');
    notifyListeners();
  }

  // ✅ Reviewer Login Method used for Google Play Review
  Future<void> reviewerLogin(BuildContext context) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔵 Starting Reviewer Login...');

      final loginUser = await ApiManager.reviewLogin();

      if (loginUser != null) {
        print('🎉 Reviewer logged in successfully - Direct to Home');
        print('✅ User ID: ${loginUser.id}');
        await _saveUserData(loginUser, googleId: 'reviewer_${loginUser.id}');

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
          );
        }
      } else {
        _errorMessage = 'Reviewer Login Failed';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reviewer Login Failed')),
          );
        }
      }
    } catch (e) {
      print('❌ Reviewer Login Error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //..................Register Functionality....................//

  final AuthService _authService = AuthService();

  String? error;

  Future<void> register({
    required BuildContext context,
    required String username,
    required String email,
    required String password,
    required String name,
    required String phone,
    required String country,
    required String gender,
    required String dob,
  }) async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _authService.registerUser(
        username: username,
        email: email,
        password: password,
        name: name,
        phone: phone,
        country: country,
        gender: gender,
        dob: dob,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    } catch (e) {
      error = e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error!)));
    }

    _isLoading = false;
    notifyListeners();
  }
}
