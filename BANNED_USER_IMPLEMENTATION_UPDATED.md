# Banned User Implementation - Updated

## Overview
This implementation prevents banned users from logging in and automatically logs out already logged-in users if they get banned by an admin.

## Backend Response Structure
The backend returns the following response when a user is banned:

```json
{
  "status": "banned",
  "message": "Your account has been banned. Please contact admin.",
  "ban_type": "account_ban",
  "ban_details": {
    "room": "All Rooms",
    "ban_reason": "Violation of community guidelines",
    "banned_until": "2026-03-02 18:17:53",
    "banned_at": "2026-02-02 18:17:53",
    "banned_by": 1
  }
}
```

**Key Fields:**
- `status`: Will be `"banned"` instead of `"success"`
- `message`: Ban message from backend
- `ban_details.ban_reason`: Reason for ban
- `ban_details.banned_until`: Expiry date (or `null` for permanent ban)
- `ban_details.banned_at`: When the user was banned
- `ban_details.banned_by`: Admin user ID who banned the user

## Implementation Details

### 1. Custom Exception Class
Created `BannedUserException` in [lib/controller/api_manager/api_manager.dart](lib/controller/api_manager/api_manager.dart):

```dart
class BannedUserException implements Exception {
  final String message;
  final Map<String, dynamic> banDetails;
  
  BannedUserException({
    required this.message,
    required this.banDetails,
  });
  
  @override
  String toString() => message;
}
```

### 2. API Manager Update
Updated `googleLogin()` method in [lib/controller/api_manager/api_manager.dart](lib/controller/api_manager/api_manager.dart):

```dart
if (response.statusCode == 200) {
  // ⚠️ CHECK IF USER IS BANNED (Backend sends status="banned")
  if (data['status'] == 'banned') {
    print('🚫 ========== USER IS BANNED ==========');
    print('   🚫 Message: ${data['message']}');
    print('   🚫 Ban Details: ${data['ban_details']}');
    print('🚫 ========== BAN CHECK END ==========');
    
    // Throw exception to be caught by provider
    throw BannedUserException(
      message: data['message'] ?? 'Your account has been banned',
      banDetails: Map<String, dynamic>.from(data['ban_details'] ?? {}),
    );
  }
  
  // Continue with normal success response...
}
```

### 3. Login Flow Ban Check
Updated [lib/controller/provider/sign_up_provider.dart](lib/controller/provider/sign_up_provider.dart):

```dart
UserSignUpModel? loginUser;
try {
  loginUser = await ApiManager.googleLogin(google_id: uid);
  
  if (loginUser != null) {
    // Login successful - navigate to home
    await _saveUserData(loginUser, googleId: uid);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainBottomNavScreen()),
    );
    return;
  }
} on BannedUserException catch (e) {
  // User is banned
  print('🚫 User is BANNED!');
  print('🚫 Message: ${e.message}');
  
  // Sign out from Google
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
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }
  return;
}
```

### 4. Splash Screen Ban Check
Updated [lib/view/screens/login/splash_screen.dart](lib/view/screens/login/splash_screen.dart):

**Helper method:**
```dart
Future<Map<String, dynamic>?> _checkUserBanStatus(String googleId) async {
  try {
    final userData = await ApiManager.googleLogin(google_id: googleId);
    
    if (userData != null) {
      return {'is_banned': false}; // User is not banned
    }
    return null;
  } on BannedUserException catch (e) {
    // User is banned
    return {
      'is_banned': true,
      'message': e.message,
      'ban_reason': e.banDetails['ban_reason'],
      'banned_until': e.banDetails['banned_until'],
    };
  } catch (e) {
    return null; // Fail-safe: allow user to proceed if check fails
  }
}
```

**Ban check in `_navigateUser()`:**
```dart
if (googleId != null && googleId.isNotEmpty) {
  final userBanCheck = await _checkUserBanStatus(googleId);
  
  if (userBanCheck != null && userBanCheck['is_banned'] == true) {
    // Clear login data
    await prefs.clear();
    
    if (mounted) {
      final message = userBanCheck['message'] ?? 'Your account has been banned';
      final banReason = userBanCheck['ban_reason'] ?? 'No reason provided';
      final bannedUntil = userBanCheck['banned_until'] ?? 'Permanent';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🚫 $message\n'
            'Reason: $banReason\n'
            'Banned Until: $bannedUntil',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 7),
        ),
      );
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
    return;
  }
}
```

## Testing

### 1. API Testing (Using curl)
```bash
curl -X POST https://shaheenstar.online/login.php \
  -F "google_id=113646238399615228422"
```

**Expected Response (Banned User):**
```json
{
  "status": "banned",
  "message": "Your account has been banned. Please contact admin.",
  "ban_type": "account_ban",
  "ban_details": {
    "room": "All Rooms",
    "ban_reason": "Violation of community guidelines",
    "banned_until": "2026-03-02 18:17:53",
    "banned_at": "2026-02-02 18:17:53",
    "banned_by": 1
  }
}
```

### 2. App Testing Scenarios

#### Scenario 1: Login with Banned User
1. Open app
2. Try to login with banned Google account
3. **Expected Result:**
   - Login blocked
   - Red SnackBar appears showing:
     - Ban message
     - Ban reason
     - Ban expiry date
   - User remains on login screen
   - User signed out from Google

#### Scenario 2: Already Logged-in User Gets Banned
1. Login with normal account
2. Close app (don't logout)
3. Admin bans the user from backend
4. Reopen the app
5. **Expected Result:**
   - App checks ban status at splash screen
   - Detects user is banned
   - Clears all login data (logout)
   - Shows ban message
   - Redirects to login screen

### 3. Test Users
- **Banned User:** Google ID `113646238399615228422` (Ali Jaan151)
  - Ban Reason: "Violation of community guidelines"
  - Banned Until: 2026-03-02 18:17:53

## Files Modified
1. [lib/controller/api_manager/api_manager.dart](lib/controller/api_manager/api_manager.dart) - Added BannedUserException and ban checking
2. [lib/controller/provider/sign_up_provider.dart](lib/controller/provider/sign_up_provider.dart) - Added ban check in login flow
3. [lib/view/screens/login/splash_screen.dart](lib/view/screens/login/splash_screen.dart) - Added ban check for logged-in users

## Error Handling
- **Fail-Safe Design:** If ban check fails due to network error, user is allowed to proceed
- This prevents blocking legitimate users due to temporary network issues
- Ban checks happen at two critical points:
  1. During login attempt
  2. During app startup (for already logged-in users)

## UI/UX Messages
- Ban message includes: Message, Reason, and Expiry Date
- Red SnackBar for visibility
- 6-7 second duration for user to read
- Clear indication of why account is banned
- Auto-logout and redirect to login screen
