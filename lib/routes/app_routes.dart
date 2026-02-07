import 'package:flutter/material.dart';
import 'package:shaheen_star_app/view/screens/bottom_nav/main_bottom_nav_screen.dart';
import 'package:shaheen_star_app/view/screens/login/profile_update_screen.dart';
import 'package:shaheen_star_app/view/screens/login/register_profile.dart';
import 'package:shaheen_star_app/view/screens/login/signup_screen.dart';
import 'package:shaheen_star_app/view/screens/login/splash_screen.dart';
import 'package:shaheen_star_app/view/screens/merchant/wallet_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profileUpdate = '/profile-update';
  static const String wallet = '/wallet';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('🔄 NAVIGATING TO: ${settings.name}');

    // ✅ Wrap route builder with error handling
    return MaterialPageRoute(
      builder: (context) {
        try {
          Widget page;

          // ✅ Route selection
          switch (settings.name) {
            case splash:
              page = const SplashScreen();
              break;
            case signup:
              page = _buildWithErrorHandling(() => const SignupScreen());
              break;
            case home:
              page = _buildWithErrorHandling(() => const MainBottomNavScreen());
              break;
            case profileUpdate:
              page = _buildWithErrorHandling(() => const ProfileSetupScreen());
              break;
            case wallet:
              page = _buildWithErrorHandling(() => const WalletScreen());
              break;
            default:
              page = _errorPage(settings.name ?? 'Unknown');
          }

          return page;
        } catch (e, stackTrace) {
          print('❌ ROUTE BUILD ERROR for ${settings.name}: $e');
          print('Stack trace: $stackTrace');
          return _errorPage('${settings.name} (Error: $e)');
        }
      },
      settings: settings,
    );
  }

  // ✅ Error boundary wrapper for screens
  static Widget _buildWithErrorHandling(Widget Function() builder) {
    try {
      return Builder(
        builder: (context) {
          try {
            return builder();
          } catch (e, stackTrace) {
            print('❌ SCREEN BUILD ERROR: $e');
            print('Stack trace: $stackTrace');
            return _errorScreen('Screen build failed: $e');
          }
        },
      );
    } catch (e) {
      print('❌ WIDGET CREATION ERROR: $e');
      return _errorScreen('Widget creation failed: $e');
    }
  }

  // ✅ Simple error screen
  static Widget _errorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Screen Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Try to navigate back or to splash
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Improved error page
  static Widget _errorPage(String routeName) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Title
                const Text(
                  'Page Not Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Error Message
                Text(
                  'Route "$routeName" does not exist',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Try to go back or navigate to splash
                      // Note: This won't work in error page as there's no context
                      // Better to handle this in the app
                    },
                    icon: const Icon(Icons.home),
                    label: const Text(
                      'Go to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A32FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Alternative: Simple MaterialPageRoute (if animation issues occur)
  static Route<dynamic> generateRouteSimple(RouteSettings settings) {
    print('🔄 NAVIGATING TO: ${settings.name}');

    Widget page;

    switch (settings.name) {
      case splash:
        page = const SplashScreen();
        break;
      case signup:
        page = const SignupScreen();
        break;
      case home:
        page = const MainBottomNavScreen();
        break;
      case profileUpdate:
        page = const ProfileUpdateScreen();
        break;
      default:
        page = _errorPage(settings.name ?? 'Unknown');
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
