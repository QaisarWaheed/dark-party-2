# Zego Cloud Voice Call Setup Guide

This guide will help you set up Zego Cloud for voice calls in your Flutter app.

## Prerequisites

1. **Zego Cloud Account**: Sign up at https://console.zegocloud.com/
2. **App ID and App Sign**: Get these from your Zego Console project settings

## Step 1: Get Your Zego Credentials

1. Go to https://console.zegocloud.com/
2. Create a new project or select an existing one
3. Go to **Project Settings** > **Basic Information**
4. Copy your **App ID** and **App Sign**
5. Keep these credentials secure - never commit them to public repositories

## Step 2: Configure Zego in Your App

1. Open `lib/controller/api_manager/zego_config.dart`
2. Replace the placeholder values:

```dart
class ZegoConfig {
  static const int appID = YOUR_APP_ID_HERE; // Replace with your App ID
  static const String appSign = 'YOUR_APP_SIGN_HERE'; // Replace with your App Sign
  // ... rest of the file
}
```

## Step 3: Install Dependencies

Run the following command to install the Zego SDK packages:

```bash
flutter pub get
```

## Step 4: Platform-Specific Setup

### Android Setup

The Android configuration is already set up in:
- `android/app/build.gradle.kts` - NDK filters and minSdk
- `android/app/proguard-rules.pro` - ProGuard rules

### iOS Setup

The iOS permissions are already configured in:
- `ios/Runner/Info.plist` - Microphone and camera permissions

## Step 5: API Compatibility Note

⚠️ **Important**: The Zego Flutter SDK API may vary between versions. If you encounter compilation errors in `zego_voice_service.dart`, you may need to adjust the API calls based on your SDK version.

Common issues and solutions:

1. **Engine Creation**: The `createEngine` method signature may differ
2. **Event Handlers**: Event handler setup may use different patterns
3. **Stream Methods**: Method names for publishing/playing streams may vary

Refer to the official Zego Flutter SDK documentation for your specific version:
https://docs.zegocloud.com/article/quick-start

## How It Works

### Voice Call Flow

1. **User Joins Room**: 
   - Zego service initializes and joins the Zego room
   - User can hear audio from speakers already in the room

2. **User Takes a Seat**:
   - When a user occupies a seat, Zego automatically starts publishing their audio stream
   - Other users in the room will automatically receive and play the new stream

3. **User Leaves Seat**:
   - When a user vacates a seat, Zego stops publishing their audio stream
   - Other users will stop receiving that stream

4. **User Leaves Room**:
   - Zego stops all publishing and playing
   - User leaves the Zego room

### Integration Points

The Zego voice service is integrated at these points:

- **Room Initialization**: `room_screen.dart` - `_initializeAllData()`
- **Seat Occupation**: `room_screen.dart` - `_joinSeatDirect()`
- **Seat Vacation**: `room_screen.dart` - `_vacateSeat()`
- **Room Exit**: `room_screen.dart` - `_leaveRoom()` and `dispose()`

## Testing

1. Run the app on two devices or emulators
2. Join the same room on both devices
3. Have one user take a seat - they should start publishing audio
4. The other user should automatically hear the audio
5. Test leaving the seat - audio should stop

## Troubleshooting

### No Audio
- Check microphone permissions are granted
- Verify Zego App ID and App Sign are correct
- Check console logs for Zego errors

### Compilation Errors
- Ensure `flutter pub get` completed successfully
- Check that your Flutter SDK version is compatible
- Verify Zego SDK version matches the API calls in `zego_voice_service.dart`

### Connection Issues
- Check internet connectivity
- Verify Zego credentials are correct
- Check Zego Console for service status

## Support

For Zego-specific issues, refer to:
- Zego Documentation: https://docs.zegocloud.com/
- Zego Support: https://www.zegocloud.com/support

For app-specific issues, check the console logs which include detailed Zego service messages.

