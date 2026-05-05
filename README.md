# FaceBio Flutter

A Flutter demo application for face liveness detection and biometric identity verification. 
The app wraps native Android and iOS face detection SDKs through Flutter's platform channel 
mechanism and communicates results to a backend REST API.

---

## How It Works

```
User taps Register / Verify
        │
        ▼
HomeScreen → asks for User ID → requests camera permission
        │
        ▼
FaceScanScreen
        │  embeds
        ▼
FaceBioView (Flutter widget)
        │  platform channel (AndroidView / UiKitView)
        ▼
Native SDK (Android AAR  /  iOS XCFramework)
   • FaceDetectionView  — live camera feed
   • Face Liveness Check  — check face mask, fake image, etc...
        │  EventChannel (face_detection_events_{viewId})
        ▼
FaceScanScreen receives FaceLivenessResult
        │
        ├─ isLive = false → retry dialog (max 3 attempts)
        │
        └─ isLive = true  → POST captured image to API
                                │
                                ├─ Register → /api/v1/img/register → stores embedding
                                └─ Verify  → /api/v1/img/verify   → similarity check
                                        │
                                        ▼
                                    ResultScreen
```

### Platform Channel Contract

The Flutter side is intentionally thin. It never changes regardless of what the native SDK does internally — only the two sides of this contract must stay consistent:

| Item | Value |
|---|---|
| Platform view type | `face_detection_view` |
| Event channel name | `face_detection_events_{viewId}` |
| Creation param | `maskColor` (int, ARGB32) |

**Events received from native:**

```
// Intermediate state updates
{ "event": "state", "state": String, "message": String }

// Final liveness result
{
  "event":      "liveness_result",
  "prediction": "Live" | "Spoof",
  "confidence": Float,
  "status":     "pass" | "fail",
  "message":    String,
  "imagePath":  String   // temp file path on device
}
```

---

## Project Structure

```
lib/
├── main.dart
├── face_bio_view.dart               # public barrel export
└── src/
    ├── app.dart                     # MaterialApp root
    ├── config/
    │   └── api_config.dart          # base URL & auth credentials
    ├── models/
    │   ├── face_liveness_result.dart
    │   ├── scan_mode.dart           # Register | Verify
    │   ├── scan_result.dart
    │   ├── register_response.dart
    │   └── verify_response.dart
    ├── screens/
    │   ├── home_screen.dart         # entry point, permission gate
    │   ├── face_scan_screen.dart    # orchestrates scan + API call
    │   └── result_screen.dart
    ├── services/
    │   ├── face_api_service.dart    # HTTP multipart calls
    │   └── embedding_storage_service.dart
    └── widgets/
        ├── face_bio_view.dart       # platform channel widget
        └── user_id_dialog.dart

android/
└── app/
    ├── libs/
    │   └── facebioflutter-release.aar   ← drop updated AAR here
    └── src/main/kotlin/com/acleda/facebio_flutter/
        ├── MainActivity.kt
        ├── FaceDetectionViewFactory.kt
        └── FaceDetectionPlatformView.kt

ios/
├── Frameworks/
│   └── FaceBioFlutter.xcframework       ← drop updated XCFramework here
├── FaceBioFlutter.podspec
└── Runner/
    ├── AppDelegate.swift
    ├── FaceDetectionViewFactory.swift
    └── FaceDetectionFlutterView.swift
```

---

## Requirements

| | Minimum |
|---|---|
| Flutter | 3.11.5 |
| Dart | 3.11.5 |
| Android | SDK 24 (Android 7.0) |
| iOS | 15.0 |
| Xcode | 15+ |
| CocoaPods | 1.12+ |

---

## Integration

### Android — Update the AAR

1. Build a new release AAR from the native Android SDK project.
2. Replace the existing file:
   ```
   android/app/libs/facebioflutter-release.aar
   ```
3. Verify that the dependency versions in `android/app/build.gradle.kts` still match what the new AAR was compiled against (ONNX Runtime, CameraX, ML Kit). Update those versions if the native project changed them.
4. Run the app — no Flutter or Kotlin changes required.

The AAR is picked up automatically via:
```kotlin
// android/app/build.gradle.kts
implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
```

### iOS — Update the XCFramework

1. Build a new XCFramework from the native iOS SDK project.
2. Replace the existing bundle:
   ```
   ios/Frameworks/FaceBioFlutter.xcframework
   ```
3. Re-run CocoaPods to relink:
   ```bash
   cd ios && pod install
   ```
4. Run the app — no Flutter or Swift changes required.

The XCFramework is declared in the local podspec:
```ruby
# ios/FaceBioFlutter.podspec
s.vendored_frameworks = 'Frameworks/FaceBioFlutter.xcframework'
```

And referenced from the Podfile:
```ruby
# ios/Podfile
pod 'FaceBioFlutter', :path => '.'
```

---

## Running the App

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Configure the API

Edit `lib/src/config/api_config.dart`:

```dart
class ApiConfig {
  // This is a testing API endpoint for testing.
  static const String baseUrl = 'https://face.chlat.dev';

  // Option A: provide a pre-built Basic auth header
  static const String basicAuthHeaderOverride = '';

  // Option B: provide username + password (used when override is empty)
  static const String basicAuthUsername = 'your_username';
  static const String basicAuthPassword = 'your_password';
}
```

### 3. Run on a physical device

> Camera-based features do not work on simulators or emulators.

```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

## Permissions

| Permission | Platform | Reason |
|---|---|---|
| `CAMERA` | Android & iOS | Live camera feed for face detection |

Android permission is declared in `AndroidManifest.xml`. iOS `NSCameraUsageDescription` is set in `Info.plist`. The app requests camera permission at runtime via `permission_handler` before opening the scan screen.

---

## API Endpoints

Base URL: `https://face.chlat.dev`

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/v1/img/register` | POST multipart | Upload face image, receive embedding |
| `/api/v1/img/verify` | POST multipart | Upload face image, receive similarity score |

Both endpoints require HTTP Basic Authentication. The registered embedding is also cached locally on device via `EmbeddingStorageService` (`shared_preferences`).