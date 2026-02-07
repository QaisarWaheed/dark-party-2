import 'package:shared_preferences/shared_preferences.dart';

/// Utility functions for formatting and handling user IDs
class UserIdUtils {
  /// Format user_id to 8 digits by padding with leading zeros
  /// 
  /// Examples:
  /// - "8" → "00000008"
  /// - "123" → "00000123"
  /// - "12345" → "00012345"
  /// - "12345678" → "12345678" (already 8 digits)
  /// - "123456789" → "123456789" (more than 8 digits, returns as is)
  /// 
  /// Returns null if input is null or empty
  static String? formatTo8Digits(String? userId) {
    if (userId == null || userId.isEmpty) {
      return null;
    }

    // Remove any leading/trailing whitespace
    final trimmed = userId.trim();

    // If it's already 8 or more digits, return as is
    if (trimmed.length >= 8) {
      return trimmed;
    }

    // Pad with leading zeros to make it 8 digits
    return trimmed.padLeft(8, '0');
  }

  /// Format user_id to 8 digits from int
  static String? formatTo8DigitsFromInt(int? userId) {
    if (userId == null) {
      return null;
    }
    return formatTo8Digits(userId.toString());
  }

  /// Format user_id to 8 digits from dynamic (handles both int and String)
  static String? formatTo8DigitsFromDynamic(dynamic userId) {
    if (userId == null) {
      return null;
    }

    if (userId is int) {
      return formatTo8DigitsFromInt(userId);
    } else if (userId is String) {
      return formatTo8Digits(userId);
    } else {
      // Try to convert to string
      return formatTo8Digits(userId.toString());
    }
  }

  /// Validate if user_id is in 8-digit format
  static bool isValid8DigitFormat(String? userId) {
    if (userId == null || userId.isEmpty) {
      return false;
    }

    // Check if it's exactly 8 digits (numeric)
    final regex = RegExp(r'^\d{8}$');
    return regex.hasMatch(userId);
  }

  /// Get numeric value from 8-digit formatted user_id (removes leading zeros)
  /// 
  /// Examples:
  /// - "00000008" → 8
  /// - "00000123" → 123
  /// - "00012345" → 12345
  static int? getNumericValue(String? userId) {
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return int.tryParse(userId);
  }

  /// Safely get user_id from SharedPreferences
  /// Handles both int and String types to avoid type casting errors
  /// Returns user_id as String, or empty string if not found
  /// 
  /// This method tries to get user_id as int first (since it's commonly stored as int),
  /// then falls back to String, and finally tries dynamic retrieval.
  static Future<String> getUserIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get as int first (since it's often stored as int)
      // This avoids the type cast error when user_id is stored as int
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        return userIdInt.toString();
      }
      
      // If not found as int, try as String
      String? userIdString = prefs.getString('user_id');
      if (userIdString != null && userIdString.isNotEmpty) {
        return userIdString;
      }
      
      return '';
    } catch (e) {
      // If there's an error, try alternative methods
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Try the opposite type first
        String? userIdString = prefs.getString('user_id');
        if (userIdString != null && userIdString.isNotEmpty) {
          return userIdString;
        }
        
        int? userIdInt = prefs.getInt('user_id');
        if (userIdInt != null) {
          return userIdInt.toString();
        }
      } catch (e2) {
        // Ignore
      }
      
      // Final fallback: try to get as dynamic and convert
      try {
        final prefs = await SharedPreferences.getInstance();
        final dynamic userId = prefs.get('user_id');
        if (userId != null) {
          return userId.toString();
        }
      } catch (e3) {
        // Ignore
      }
      return '';
    }
  }
}

