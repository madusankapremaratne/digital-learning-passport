# MediaPipe LLM inference (flutter_gemma) references proto classes that
# are not present at runtime in the genai artifacts; keep what exists and
# silence the rest.
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Protocol Buffers
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Missing proto descriptors reported by R8 (missing_rules.txt)
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
