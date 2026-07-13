# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ── Google Mobile Ads (AdMob) ─────────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ── Meta Audience Network (FAN SDK 6.21.0) ───────────────────────────────────
# FAN SDK references Facebook Infer annotation classes at compile-time only.
# These annotations are NOT present in the FAN AAR — suppress R8 warnings.
-dontwarn com.facebook.infer.annotation.**
-dontwarn com.facebook.soloader.**
# Keep all FAN runtime classes
-keep class com.facebook.** { *; }
-keep interface com.facebook.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn com.facebook.**

# ── Firebase ──────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ── General ───────────────────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
