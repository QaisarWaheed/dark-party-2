# Banned User Implementation Guide

## Overview
Implemented comprehensive banned user handling to prevent banned users from accessing the application. When admin bans a user from the admin panel, the system will:
1. Block banned users from logging in
2. Automatically logout already logged-in users who get banned

## Implementation Details

### 1. User Model Updates
**File**: `lib/model/user_sign_up_model.dart`

Added new fields to track ban status:
- `isBanned` (int): 0 = not banned, 1 = banned
- `banReason` (String): Reason provided by admin
- `bannedAt` (String): Timestamp when user was banned
- `banExpiresAt` (String): Expiry date (null = permanent ban)
- `isUserBanned` (getter): Helper method to check if user is currently banned

### 2. Login Flow Ban Check
**File**: `lib/controller/provider/sign_up_provider.dart`

**Location**: `googleSignup()` method, around line 400

When user tries to login:
```dart
if (loginUser != null) {
  // Check if user is banned
  if (loginUser.isUserBanned) {
    // Show ban message
    // Sign out user
    // Prevent navigation to home screen
    return;
  }
  // ... continue login
}
```

**Behavior**:
- If banned, shows SnackBar with ban reason and expiry
- Signs out the user from Google
- Prevents navigation to home screen
- User stays on login screen

### 3. Already Logged-In User Check
**File**: `lib/view/screens/login/splash_screen.dart`

**Location**: `_navigateUser()` method, around line 120

When app starts and user is already logged in:
```dart
if (isLoggedIn) {
  // Check ban status
  final userBanCheck = await _checkUserBanStatus(googleId);
  
  if (userBanCheck['is_banned'] == true) {
    // Clear all login data
    await prefs.clear();
    // Show ban message
    // Navigate to login screen
    return;
  }
  // ... continue to home
}
```

**Behavior**:
- Calls login API to get fresh user data
- Checks ban status from API response
- If banned:
  - Clears all SharedPreferences (logout)
  - Shows SnackBar with ban reason
  - Redirects to login/signup screen

### 4. Backend Response Structure Expected

The login API (`login.php`) should return user data with ban fields:

```json
{
  "status": "success",
  "user": {
    "id": 1928890,
    "name": "User Name",
    "email": "user@example.com",
    "is_banned": 1,
    "ban_reason": "Violation of community guidelines",
    "banned_at": "2026-02-03 12:00:00",
    "ban_expires_at": "2026-03-03 12:00:00"
  }
}
```

**Ban Fields**:
- `is_banned`: 1 (banned) or 0 (not banned)
- `ban_reason`: Text explaining why user was banned
- `banned_at`: ISO timestamp when ban was applied
- `ban_expires_at`: ISO timestamp when ban expires (null for permanent)

## Testing Scenarios

### Scenario 1: User tries to login when already banned
1. Admin bans user from admin panel
2. User tries to login with Google
3. **Expected**: Login blocked, ban message shown, stays on login screen

### Scenario 2: User is already logged in, then gets banned
1. User is logged in and using the app
2. Admin bans the user
3. User closes app
4. User reopens app
5. **Expected**: User is logged out automatically, ban message shown, redirected to login screen

### Scenario 3: Temporary ban expires
1. Admin sets temporary ban (e.g., 30 days)
2. After 30 days, `ban_expires_at` date passes
3. Backend should set `is_banned = 0`
4. User can login normally again

## Error Handling

1. **Ban check fails**: If ban status check fails on splash screen, user is allowed to continue to home screen (fail-safe to prevent blocking legitimate users due to network issues)

2. **Missing ban fields**: If API doesn't return ban fields, user is treated as not banned

3. **Network issues**: Ban check is wrapped in try-catch to prevent app crashes

## UI Messages

**Login Ban Message**:
```
🚫 Your account has been banned.
Reason: [ban_reason from API]
Ban expires: [ban_expires_at] OR "This is a permanent ban."
```

**Splash Screen Ban Message**:
```
🚫 Your account has been banned by admin.
Reason: [ban_reason from API]
Ban expires: [ban_expires_at] OR "This is a permanent ban."
```

## Files Modified

1. `lib/model/user_sign_up_model.dart`
   - Added 4 new fields for ban tracking
   - Added `isUserBanned` getter method

2. `lib/controller/provider/sign_up_provider.dart`
   - Added ban check in `googleSignup()` method
   - Shows ban message and blocks login

3. `lib/view/screens/login/splash_screen.dart`
   - Added import for `ApiManager`
   - Added `_checkUserBanStatus()` helper method
   - Added ban check in `_navigateUser()` method
   - Auto-logout and redirect if user is banned

## Backend Requirements

The backend `login.php` API must return:
- `is_banned` field in user object
- `ban_reason` field when user is banned
- `banned_at` timestamp
- `ban_expires_at` timestamp (null for permanent ban)

Example backend response from your logs shows correct structure:
```json
{
  "id": 1928987,
  "is_banned": 1,
  "ban_reason": "Violation of community guidelines",
  "banned_at": "2026-02-02 18:17:53",
  "ban_expires_at": "2026-03-02 18:17:53"
}
```

## Notes

1. Ban check happens at 2 points:
   - **Login time**: When user tries to login
   - **App startup**: When app opens and user is already logged in

2. Both temporary and permanent bans are supported:
   - Temporary: `ban_expires_at` has a future date
   - Permanent: `ban_expires_at` is null

3. The implementation is fail-safe:
   - If ban check fails, user is allowed to proceed
   - Prevents legitimate users from being blocked due to network issues
   - Real ban enforcement happens on backend APIs

4. User experience:
   - Clear ban messages with reason
   - Shows expiry date if temporary ban
   - Automatic logout with redirect to login screen
