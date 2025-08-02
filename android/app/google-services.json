# Avoid stripping Jackson-related classes
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.**
-dontwarn org.conscrypt.**

-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

-keepattributes *Annotation*
-keep class com.fasterxml.** { *; }
-dontwarn com.fasterxml.**

# Keep reflection-related classes for JSON parsing
-keep class javax.annotation.** { *; }
-dontwarn javax.annotation.**

# Prevent DOM-related missing classes
-dontwarn org.w3c.dom.**

# General safe keep rules
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.**
