# R8 rules for the release build (minify + resource shrinking are enabled in
# build.gradle.kts). The Flutter Gradle plugin already contributes its own
# rules for the embedding; these cover the plugins this app uses.

# Flutter embedding + plugin registrant.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Deferred-components / Play Core classes are referenced by the Flutter
# embedding but not bundled, since this app does not use deferred components.
-dontwarn com.google.android.play.core.**

# Firebase/Firestore model reflection and annotations.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}
-dontwarn com.google.firebase.**
