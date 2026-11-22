# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit rules - ignore unbundled language packs (Korean, Chinese, Japanese, Devanagari)
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
