# ✅ ProGuard rules for Zego Cloud SDK
# Add project specific ProGuard rules here.

# ---------- Firebase (required for release APK - fixes [core/no-app]) ----------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Zego classes (if using Zego Cloud)
-keep class im.zego.** { *; }
-keep class com.zego.** { *; }
-dontwarn im.zego.**
-dontwarn com.zego.**

# Keep WebRTC classes
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

