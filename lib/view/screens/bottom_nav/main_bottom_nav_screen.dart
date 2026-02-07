// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shaheen_star_app/components/custom_bottom_nav.dart';
// import 'package:shaheen_star_app/controller/provider/bottom_nav_provider.dart';
// import 'package:shaheen_star_app/view/screens/home/follower_screen.dart';
// import 'package:shaheen_star_app/view/screens/home/home_screen.dart';
// import 'package:shaheen_star_app/view/screens/home/message_screen.dart';
// import 'package:shaheen_star_app/view/screens/profile/profile_screen.dart';
// // import 'package:shaheen_star_app/view/widgets/custom_bottom_nav_bar.dart';

// class MainBottomNavScreen extends StatelessWidget {
//   const MainBottomNavScreen({super.key});

//   // 👇 Screens for each taba
//   final List<Widget> _screens = const [
//     HomeScreen(),
//     FollowerScreen(),
//     MessageScreen(),
//     ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final bottomProvider = context.watch<BottomNavProvider>();

//     return Scaffold(
//       extendBody: true,
//       body: _screens[bottomProvider.currentIndex],

//       // 👇 Your Custom Bottom Navigation
//       bottomNavigationBar: CustomBottomNavBar(
//         backgroundImage: 'assets/images/bg_bottom_nav.png', selectedIndex: bottomProvider.currentIndex,
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/custom_bottom_nav.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:shaheen_star_app/controller/provider/bottom_nav_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/view/screens/home/discover_screen.dart';
import 'package:shaheen_star_app/view/screens/home/home_screen.dart';
import 'package:shaheen_star_app/view/screens/user_chat/user_chat_list_screen.dart';
import 'package:shaheen_star_app/view/screens/home/moment_screen.dart';
import 'package:shaheen_star_app/view/screens/profile/profile_screen.dart';
import 'package:shaheen_star_app/view/screens/login/signup_screen.dart';
import 'package:shaheen_star_app/controller/provider/sign_up_provider.dart';
import 'package:shaheen_star_app/utils/auth_event_bus.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainBottomNavScreen extends StatefulWidget {
  const MainBottomNavScreen({super.key});

  @override
  State<MainBottomNavScreen> createState() => _MainBottomNavScreenState();
}

class _MainBottomNavScreenState extends State<MainBottomNavScreen> {
  Timer? _banCheckTimer;
  StreamSubscription<AuthEvent>? _authEventSub;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // ✅ Reset to home tab (index 0) when navigating to bottom nav screen
    // This ensures users always start at home after login/signup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bottomProvider = Provider.of<BottomNavProvider>(
        context,
        listen: false,
      );
      bottomProvider.resetToHome();
      print("🏠 Bottom Nav reset to home (index 0)");

      // ✅ Start periodic ban check (every 30 seconds)
      _startBanCheck();
    });

    _authEventSub = AuthEventBus().stream.listen((event) {
      if (!mounted) return;
      if (event.type == 'invalid_token') {
        _handleInvalidToken(event.message);
      }
    });
  }

  @override
  void dispose() {
    _authEventSub?.cancel();
    _banCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleInvalidToken(String? message) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    _banCheckTimer?.cancel();

    try {
      await Provider.of<SignUpProvider>(context, listen: false).logout();
    } catch (e) {
      print("❌ [Auth] Logout failed after token invalid: $e");
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
      (route) => false,
    );

    if (mounted) {
      final reason = (message == null || message.isEmpty)
          ? 'Session expired. Please log in again.'
          : message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason), backgroundColor: Colors.red),
      );
    }
  }

  void _startBanCheck() {
    // Check immediately
    _checkIfUserIsBanned();

    // Then check every 30 seconds
    _banCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkIfUserIsBanned();
    });

    print("🔍 [BanCheck] Started periodic ban checking (every 30 seconds)");
  }

  Future<void> _checkIfUserIsBanned() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final googleId = prefs.getString('google_id');

      if (googleId == null || googleId.isEmpty) {
        print("⚠️ [BanCheck] No google_id found, skipping ban check");
        return;
      }

      print("🔍 [BanCheck] Checking ban status for google_id: $googleId");

      // Try to login with google_id (this will throw BannedUserException if banned)
      final userData = await ApiManager.googleLogin(google_id: googleId);

      if (userData != null) {
        // If we reach here, user is not banned
        print("✅ [BanCheck] User is not banned");
      } else {
        print("⚠️ [BanCheck] Login returned null (no ban signal)");
      }
    } on BannedUserException catch (e) {
      // User is banned - log them out
      print("🚫 [BanCheck] User is BANNED! Logging out...");
      print("🚫 [BanCheck] Ban reason: ${e.banDetails['ban_reason']}");

      if (!mounted) return;

      // Stop the timer
      _banCheckTimer?.cancel();

      // Log out user
      await _logoutBannedUser(e);
    } catch (e) {
      print("❌ [BanCheck] Error checking ban status: $e");
      // Don't logout on network errors, only on explicit ban
    }
  }

  Future<void> _logoutBannedUser(BannedUserException banException) async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Google
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      print("✅ [BanCheck] User logged out successfully");

      if (!mounted) return;

      // Show ban message
      final banReason =
          banException.banDetails['ban_reason'] ?? 'No reason provided';
      final bannedUntil =
          banException.banDetails['ban_expires_at'] ?? 'Permanent';

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignupScreen()),
        (route) => false,
      );

      // Show ban message after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🚫 ${banException.message}\n'
                'Reason: $banReason\n'
                'Banned Until: $bannedUntil',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.buttonColorPrimary,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      });
    } catch (e) {
      print("❌ [BanCheck] Error logging out banned user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Screens list
    final List<Widget> screens = const [
      HomeScreen(),
      DiscoverScreen(),
      MomentScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];

    return Consumer<BottomNavProvider>(
      builder: (context, bottomProvider, child) {
        // Get unread message count
        int unreadCount = 0;
        try {
          final chatProvider = Provider.of<UserChatProvider>(
            context,
            listen: false,
          );
          unreadCount = chatProvider.chatRooms.fold(
            0,
            (sum, room) => sum + (room.unreadCount ?? 0),
          );
        } catch (e) {
          // If provider not available, use default
          unreadCount = 1; // Default for demo
        }

        return Scaffold(
          extendBody:
              false, // ✅ Changed to false to ensure bottom nav is always accessible
          // ✅ Current screen based on selected tab
          body: IndexedStack(
            index: bottomProvider.currentIndex,
            children: screens,
          ),

          // ✅ Bottom Navigation Bar
          bottomNavigationBar: CustomBottomNavBar(
            backgroundImage: 'assets/images/bg_bottom_nav.png',
            selectedIndex: bottomProvider.currentIndex,
            unreadMessageCount: unreadCount > 0 ? unreadCount : null,
          ),
        );
      },
    );
  }
}
