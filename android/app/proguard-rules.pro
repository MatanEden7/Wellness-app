## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Drift/SQLite Database
-keep class drift.** { *; }
-keep class com.simolus.** { *; }

## Local Notifications
-keep class com.dexterous.** { *; }

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

## Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

## Keep custom classes
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

## Galaxy S25 Ultra optimizations - keep all R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

## Prevent obfuscation of model classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
