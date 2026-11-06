# ── Flutter engine & embedding ──────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Keep annotations / generics / signatures (needed by several plugins)
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# ── Plugins that may use reflection / native bridges ────────────────────────
# printing / pdf (pdfium native)
-keep class net.nfet.** { *; }
-dontwarn net.nfet.**
# image_picker, share_plus, url_launcher, secure_storage — keep their plugin classes
-dontwarn com.google.android.**

# Suppress benign warnings from optional/desugar deps
-dontwarn javax.annotation.**
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
