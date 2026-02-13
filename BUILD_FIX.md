# Build Error Fix Guide

## Issue: "Unable to delete directory" / "The specified version SDK already exists!"

This error occurs when:
1. Files are locked by another process (IDE, Gradle daemon, etc.)
2. Build cache is corrupted
3. Multiple build processes are running

## Solution Steps:

### Step 1: Close All Processes
1. Close Android Studio / VS Code / Cursor completely
2. Close any running Flutter/Dart processes
3. Close any Gradle daemon processes

### Step 2: Clean Build Directories
Run these commands in PowerShell (from project root):

```powershell
# Clean Flutter build
flutter clean

# Clean Android build
cd android
if (Test-Path build) { Remove-Item -Recurse -Force build }
if (Test-Path .gradle) { Remove-Item -Recurse -Force .gradle }
cd ..

# Clean any locked files manually if needed
# Navigate to: shaheen_star_app\build\app\intermediates\assets\debug\mergeDebugAssets
# Delete the folder manually if it still exists
```

### Step 3: Kill Gradle Daemon (if still running)
```powershell
# Stop Gradle daemon
cd android
.\gradlew --stop
cd ..
```

### Step 4: Rebuild
```powershell
# Get dependencies
flutter pub get

# Try building again
flutter build apk --debug
# OR
flutter run
```

### Alternative: Use Invalidate Caches (if using Android Studio)
1. File → Invalidate Caches / Restart
2. Select "Invalidate and Restart"
3. Wait for Android Studio to restart
4. Try building again

### If Still Failing:
1. Restart your computer (this releases all file locks)
2. After restart, run `flutter clean` and `flutter pub get`
3. Try building again

### Check for Version Conflicts:
The "The specified version SDK already exists!" error might indicate a version conflict. Check:
- `pubspec.yaml` for conflicting package versions
- `android/build.gradle` for SDK version conflicts
- Ensure all Zego packages are compatible versions

## Quick Fix Command Sequence:
```powershell
# Run all at once
flutter clean
cd android; .\gradlew --stop; cd ..
flutter pub get
flutter run
```

