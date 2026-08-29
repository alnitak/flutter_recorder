# Platform Permissions & Requirements

## Android

### Manifest Configuration
In `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <application
        ... >
    </application>
</manifest>
```

### Runtime Permission (`permission_handler`)
```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkAndRequestMicPermission() async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    status = await Permission.microphone.request();
  }
  return status.isGranted;
}
```

### Android 15 Support
`flutter_recorder` CMake files are configured with 16k page-size alignment support required by Android 15.

---

## iOS

### Info.plist
In `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio.</string>
```

---

## macOS

### Info.plist
In `macos/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app requires microphone access to record audio.</string>
```

### Entitlements
In `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

---

## Linux

### Package Dependencies
Install ALSA and GStreamer headers on Debian / Ubuntu:
```sh
sudo apt-get install libasound2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```
On Arch Linux:
```sh
sudo pacman -S alsa-lib gstreamer gst-plugins-base
```
On Fedora:
```sh
sudo dnf install alsa-lib-devel gstreamer1-devel gstreamer1-plugins-base-devel
```

---

## Windows

Windows uses the Windows Audio Session API (WASAPI) natively bundled with miniaudio. No additional drivers or manifest configurations are required.
