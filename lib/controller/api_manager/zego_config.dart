/// Zego Cloud Configuration — used only for LIVE ROOMS (room_screen) voice chat.
/// User-to-user chat uses local voice messages, not Zego.
///
/// Get credentials from: https://console.zegocloud.com/
class ZegoConfig {
  /// Zego App ID (Project Settings > Basic Information)
  static const int appID = 896923813;

  /// App Sign (testing). For production, prefer token auth to avoid error 1001005.
  static const String appSign = '9c5f52f6627b20ccf036d7bc9f35ceb0cb1292e3ee8cd2b2ad531967f410663e';

  /// Server Secret for server-side token generation (optional).
  /// If you get LOGIN_FAILED (1001005), enable token auth in Zego Console and add a backend endpoint
  /// (e.g. get_zego_token.php) that returns a token for roomID + userID; then pass it to joinRoom(roomID, token: token).
  static const String serverSecret = '8f027cfb32c74734d415684d521a0f73';
  
  // ✅ Check if configuration is valid
  static bool get isConfigured {
    return appID > 0 && appSign.isNotEmpty;
  }
  
  // ✅ Validate configuration
  static String? validate() {
    if (appID == 0) {
      return 'Zego App ID is not configured. Please set it in zego_config.dart';
    }
    if (appSign.isEmpty) {
      return 'Zego App Sign is not configured. Please set it in zego_config.dart';
    }
    return null;
  }
}

