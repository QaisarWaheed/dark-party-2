import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateUser();
    });
  }

  // ✅ Check if user is banned by calling login API
  Future<Map<String, dynamic>?> _checkUserBanStatus(String googleId) async {
    try {
      print('🔍 Checking ban status for google_id: $googleId');
      final userData = await ApiManager.googleLogin(google_id: googleId);
      
      if (userData != null) {
        return {'is_banned': false}; // User is not banned
      }
      return null;
    } on BannedUserException catch (e) {
      // User is banned
      print('🚫 Ban detected: ${e.message}');
      return {
        'is_banned': true,
        'message': e.message,
        'ban_reason': e.banDetails['ban_reason'],
        'banned_until': e.banDetails['banned_until'],
      };
    } catch (e) {
      print('❌ Error checking ban status: $e');
      return null; // Fail-safe: allow user to proceed if check fails
    }
  }

  Future<void> _navigateUser() async {
    print('🚀 SPLASH: Navigation started');

    try {
      // ✅ Add minimum delay to show splash screen
      await Future.delayed(const Duration(seconds: 2));
      print('🚀 SPLASH: Delay completed');

      if (!mounted) {
        print('❌ SPLASH: Widget not mounted, aborting');
        return;
      }

      print('🚀 SPLASH: Loading SharedPreferences...');
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
        print('✅ SPLASH: SharedPreferences loaded');
      } catch (e) {
        print('❌ SPLASH: SharedPreferences error: $e');
        // Continue with null prefs - treat as not logged in
        prefs = null;
      }

      // ✅ If SharedPreferences failed, treat as not logged in
      if (prefs == null) {
        print('⚠️ SPLASH: SharedPreferences unavailable, navigating to signup');
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.signup);
        }
        return;
      }

      // ✅ Check both variants for compatibility
      final isLoggedInBool =
          prefs.getBool('is_logged_in') ?? prefs.getBool('isLoggedIn');
      final isNewUser = prefs.getBool('isNewUser') ?? false;

      // Handle user_id as both int and String (it can be stored either way)
      String? userId;
      if (prefs.containsKey('user_id')) {
        try {
          final userIdValue = prefs.get('user_id');
          if (userIdValue is int) {
            userId = userIdValue.toString();
            print('✅ SPLASH: user_id found as int: $userId');
          } else if (userIdValue is String) {
            userId = userIdValue;
            print('✅ SPLASH: user_id found as String: $userId');
          } else {
            print(
              '⚠️ SPLASH: user_id has unexpected type: ${userIdValue.runtimeType}',
            );
            // Try to convert anyway
            userId = userIdValue?.toString();
          }
        } catch (e) {
          print('❌ SPLASH: Error reading user_id: $e');
          userId = null;
        }
      } else {
        print('ℹ️ SPLASH: user_id key not found in SharedPreferences');
      }

      final apiToken = prefs.getString('api_token');
      final googleId = prefs.getString('google_id');

      // ✅ More robust login check: if user_id exists, consider logged in
      // This handles cases where the boolean flag might be missing but user data exists
      // Primary check: user_id existence is the strongest indicator of login
      final hasUserId = userId != null && userId.isNotEmpty;

      // User is logged in if:
      // 1. Login flag is explicitly set to true, OR
      // 2. user_id exists (strongest indicator - user has logged in before)
      final isLoggedIn = isLoggedInBool == true || hasUserId;

      print('🔐 SPLASH: Login Status Check:');
      print('   - is_logged_in: ${prefs.getBool('is_logged_in')}');
      print('   - isLoggedIn: ${prefs.getBool('isLoggedIn')}');
      print('   - isLoggedInBool: $isLoggedInBool');
      print('   - user_id: $userId');
      print(
        '   - api_token: ${apiToken != null ? "exists (${apiToken.length} chars)" : "null"}',
      );
      print('   - google_id: ${googleId != null ? "exists" : "null"}');
      print('   - Final isLoggedIn: $isLoggedIn');
      print('   - New User: $isNewUser');

      if (!mounted) {
        print('❌ SPLASH: Widget not mounted after prefs check');
        return;
      }

      String targetRoute;

      if (isLoggedIn) {
        // ✅ If login flag was missing but user data exists, restore it
        if (isLoggedInBool != true && userId != null && userId.isNotEmpty) {
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('isLoggedIn', true);
          print('✅ SPLASH: Restored login status from user data');
        }

        // ✅ Check ban status for logged-in users
        print('🔍 SPLASH: Checking ban status...');
        if (googleId != null && googleId.isNotEmpty) {
          try {
            final userBanCheck = await _checkUserBanStatus(googleId);
            
            if (userBanCheck != null && userBanCheck['is_banned'] == true) {
              print('🚫 SPLASH: User is BANNED! Logging out...');
              print('🚫 SPLASH: Ban Reason: ${userBanCheck['ban_reason']}');
              
              // Clear all login data
              await prefs.clear();
              
              if (mounted) {
                final message = userBanCheck['message'] ?? 'Your account has been banned';
                final banReason = userBanCheck['ban_reason'] ?? 'No reason provided';
                final bannedUntil = userBanCheck['banned_until'] ?? 'Permanent';
                
                // Show ban dialog that cannot be dismissed and close the app
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => WillPopScope(
                    onWillPop: () async => false, // Prevent back button
                    child: AlertDialog(
                      backgroundColor: Colors.red.shade900,
                      title: Row(
                        children: [
                          Icon(Icons.block, color: Colors.white, size: 30),
                          SizedBox(width: 10),
                          Text(
                            'Account Banned',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Reason:',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            banReason,
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Banned Until:',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            bannedUntil,
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade900,
                          ),
                          onPressed: () {
                            // Close the app
                            SystemNavigator.pop();
                          },
                          child: Text('Close App', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return;
            }
          } catch (e) {
            print('⚠️ SPLASH: Ban check failed: $e');
            // Continue to home screen even if ban check fails
          }
        }

        if (isNewUser) {
          // ✅ New user needs to update profile
          // targetRoute = AppRoutes.profileUpdate;
          targetRoute = AppRoutes.home;
          print('➡️ SPLASH: Navigating to Profile Update Screen');
        } else {
          // ✅ Logged in user -> Go to Home
          targetRoute = AppRoutes.home;
          print('➡️ SPLASH: Navigating to Home Screen');
        }
      } else {
        // ✅ User not logged in -> Go to Signup/Login Screen
        targetRoute = AppRoutes.signup;
        print('➡️ SPLASH: User not logged in, navigating to Signup Screen');
      }

      // ✅ Perform navigation
      if (mounted) {
        print('🚀 SPLASH: Attempting navigation to: $targetRoute');
        try {
          Navigator.pushReplacementNamed(context, targetRoute);
          print('✅ SPLASH: Navigation command executed');
          // Give navigation a moment to complete
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (navError) {
          print('❌ SPLASH: Navigation error: $navError');
          // Try fallback
          if (mounted) {
            print('🔄 SPLASH: Trying fallback navigation to signup');
            Navigator.pushReplacementNamed(context, AppRoutes.signup);
          }
        }
      } else {
        print('❌ SPLASH: Widget not mounted before navigation');
      }
    } catch (e, stackTrace) {
      print('❌ SPLASH: Critical Navigation Error: $e');
      print('Stack trace: $stackTrace');
      // ✅ Fallback navigation - always navigate somewhere
      if (mounted) {
        try {
          print('🔄 SPLASH: Attempting emergency fallback to signup');
          Navigator.pushReplacementNamed(context, AppRoutes.signup);
        } catch (navError) {
          print('❌ SPLASH: Fallback Navigation Error: $navError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo (Dark Party) - centered, fixed size
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: AppImage.asset(
                  'assets/images/app_logo.jpeg',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
