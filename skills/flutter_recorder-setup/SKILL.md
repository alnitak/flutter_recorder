---
name: flutter_recorder-setup
version: 1
description: Teaches how to add flutter_recorder to a Flutter app, configure permissions on Android, iOS, macOS, and Linux, configure the web platform (script tags and WASM module), initialize and deinitialize the capture engine, enumerate input devices, configure AndroidInputPreset, and set up logging. Use when a user asks to install flutter_recorder, initialize the recorder, configure microphone permissions, troubleshoot web setup, or choose audio input devices.
---

# flutter_recorder setup

`flutter_recorder` is a cross-platform Flutter audio capture plugin powered by the [miniaudio](https://github.com/mackron/miniaudio) C library. It operates via Dart FFI on mobile/desktop and WebAssembly (WASM) on web. All capture functionality is coordinated through the singleton `Recorder.instance` (`import 'package:flutter_recorder/flutter_recorder.dart'`), which must be initialized with `init()` before capture starts, and cleaned up with `deinit()` when finished.

## Minimal example

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  // 1. Request microphone permission on mobile/desktop platforms
  if (!kIsWeb) {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return; // Handle permission denied
    }
  }

  // 2. Optional: inspect available capture devices (safe pre-init)
  final devices = Recorder.instance.listCaptureDevices();

  // 3. Initialize capture engine
  await Recorder.instance.init(
    format: PCMFormat.f32le, // f32le required for visualization & silence detection
    sampleRate: 22050,
    channels: RecorderChannels.mono,
    // deviceID: devices.firstWhere((d) => d.isDefault).id,
  );

  // 4. Start hardware capture device
  Recorder.instance.start();

  // 5. On shutdown / dispose:
  Recorder.instance.deinit(); // stops capture and frees native resources
}
```

## Adding the package

```sh
flutter pub add flutter_recorder
```

Native C++ sources are built automatically using Dart build hooks and native toolchains. No manual CMake or CocoaPods configuration is required.

## Platform setup & permissions

### Android
Add the audio recording permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

Android also supports hardware capture presets via `AndroidInputPreset`:

```dart
await Recorder.instance.init(
  androidInputPreset: AndroidInputPreset.voiceCommunication,
);
```

Available presets:
- `AndroidInputPreset.generic`: Standard Android capture preset.
- `AndroidInputPreset.camcorder`: Tuned for video recording directionality.
- `AndroidInputPreset.voiceRecognition`: Optimized for ASR/speech-to-text with minimal AGC/filtering.
- `AndroidInputPreset.voiceCommunication`: Optimized for VoIP/calls with system AEC/NS.
- `AndroidInputPreset.unprocessed`: Clean, raw audio without OEM DSP.

*Note: Android 15 16k page sizes are supported out of the box.*

### iOS & macOS
Add the microphone usage description to `ios/Runner/Info.plist` and `macos/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record audio.</string>
```

On **macOS**, you must also enable the "Audio input" capability in Xcode or add the entitlement to `macos/Runner/*.entitlements`:

```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

### Web
Add the following script tags inside the `<head>` of `web/index.html`:

```html
<script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
<script src="assets/packages/flutter_recorder/web/init_recorder_module.dart.js" defer></script>
```

To run web apps locally during development:
```sh
flutter run -d chrome --web-renderer canvaskit --web-browser-flag '--disable-web-security' -t lib/main.dart --release
```

*Web note: On web, initialize `Recorder.instance.init()` and wait for user interaction to grant microphone permissions before calling `Recorder.instance.start()`.*

### Linux
Linux uses ALSA and GStreamer:
- Install development libraries: `sudo apt-get install libasound2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev`
- *Avoid installing Flutter via Snap*, as Snap sandboxing can prevent native audio plugins from linking to ALSA/GStreamer.

## The API Shape

All methods live on `Recorder.instance` (`import 'package:flutter_recorder/flutter_recorder.dart'`):

- `Future<void> init({int deviceID = -1, PCMFormat format = PCMFormat.s16le, int sampleRate = 22050, RecorderChannels channels = RecorderChannels.mono, AndroidInputPreset? androidInputPreset})`: Initializes the audio capture device. Throws `RecorderInitializeFailedException` on failure.
- `void start()`: Starts audio capture. Throws `RecorderNotInitializedException` or `RecorderFailedToStartDeviceException`.
- `void stop()`: Stops audio capture without deinitializing the engine.
- `void deinit()`: Stops capture and disposes all native device resources.
- `bool isDeviceInitialized()` / `bool get isInitialized`: Checks whether the capture engine is ready.
- `bool isDeviceStarted()` / `bool get isStarted`: Checks whether the microphone capture is active.
- `List<CaptureDevice> listCaptureDevices()`: Enumerates available input devices. Returns `CaptureDevice(name, isDefault, id)`. Safe to call before `init()`.
- `void setLoopback({required bool enable})` / `bool isLoopbackEnabled()`: Enables low-latency (< 15ms) native duplex loopback (mic routed directly to speakers/headphones).
- `double getVolumeDb()`: Returns current RMS volume level in dB `[-100, 0]`. Requires `PCMFormat.f32le`.

## Logging

`flutter_recorder` logs all diagnostic and error messages via standard `package:logging` under the logger name `flutter_recorder.Recorder`:

```dart
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
```

## Traps & Gotchas

- **Always initialize with `PCMFormat.f32le` if you need Visualization or Silence Detection**: Features like `audioVisualizationEvents`, `getFft()`, `getWave()`, `getVolumeDb()`, and `setSilenceDetection()` require `PCMFormat.f32le`.
- **Calling `init()` while already initialized deinitializes first**: Guard with `if (!Recorder.instance.isInitialized)` if you don't intend to reset the device.
- **Microphone Permissions are runtime requirements**: Calling `init()` or `start()` without user permission will throw exceptions on mobile.
- **Web requires the two `<script>` tags in `web/index.html`**: Missing tags lead to WASM initialization errors.
- **File paths on Web are ignored**: When calling `startRecording()`, the browser automatically prompts for file download upon `stopRecording()`.

## More depth

- [references/web.md](references/web.md) — WebAssembly module, web worker architecture, and browser permission nuances.
- [references/platform-permissions.md](references/platform-permissions.md) — Permission and manifest configurations across Android, iOS, macOS, Windows, and Linux.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check if an updated version is available, run:

```sh
dart run flutter_recorder:skills --check
```
