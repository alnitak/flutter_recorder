# flutter_recorder

A low-level audio recorder plugin that uses miniaudio as the backend and supports all the platforms. It can detect silence and save to a WAV audio file. Audio wave and FFT data can be obtained in real-time as for the volume level.

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

|Linux|Windows|Android|MacOS (under test)|iOS (under test)|web|
|:-:|:-:|:-:|:-:|:-:|:-:|
|💙|💙|💙|💙|💙|💙|

**Note:** not yet available on pub.dev

## 🌟 Key Features:
- 🖥️ **Cross-platform**: Supports Linux, Windows, Android, MacOS, iOS, and web.
- ⚡ **High performance**: Built using the fast and efficient miniaudio C library with FFI.
- 🎙️ **WAV Recording with Pause**: Record in WAV format with pause functionality.
- 🎛️ **Device Flexibility**: Choose your recording device.
- 🔇 **Silence Detection**: Automatically detects silence via callback or Stream.
- 📊 **Customizable Silence Threshold**: Define what’s considered “silence” for your recordings.
- ⏱️ **Adjustable Pause Timing**: Set how long silence lasts before pausing, and how soon to resume recording.
- 🔊 **Real-time Audio Metrics**: Access volume, audio wave, and FFT data in real-time.

[A web example compiled in WASM.](https://marcobavagnoli.com/flutter_recorder/)

## 🚀 Setup Permissions
After setting up permission for you Android, MacOS or iOS, in your app, you will need to ask for permission to use the microphonem maybe using [permission_handler](https://pub.dev/packages/permission_handler) plugin.
https://pub.dev/packages/permission_handler

#### Android
Add the permission in the `AndroidManifest.xml`.
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### MacOS, iOS
Add the permission in `Runner/Info.plist`.
```
<key>NSMicrophoneUsageDescription</key>
<string>Some message to describe why you need this permission</string>
```

#### Web
Add this in `web/index.html` under the `<head>` tag.
```
<script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
```

## 🛠️ Usage Example
```dart
import 'package:permission_handler/permission_handler.dart';
[...]
/// If you are running on Android, MacOS or iOS, ask the permission to use the microphone:
if (defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS) {
    Permission.microphone.request().isGranted.then((value) async {
    if (!value) {
        await [Permission.microphone].request();
    }
});

/// Initialize the capture device and start listening to it:
try {
    Recorder.instance.init();
    Recorder.instance.startListen();
} on Exception catch (e) {
    debugPrint('init() error: $e\n');
}
/// On Web platform it is better to initialize and wait the user to give
/// mic permission. Then use `startListen()` when it's needed.

//Start recording:
Recorder.instance.startRecording(completeFilePath: 'audioCompleteFilenameWithPath.wav`);

/// Stop recording:
Recorder.instance.stopRecording();
```
**Tip:** Use `Recorder.instance.listCaptureDevices()` to see available devices and pass an optional `deviceID` to `Recorder.instance.init()`.

### 🔇 Silence Detection Example

Want to skip the silence? Here’s how to configure it:

```dart
Recorder.instance.setSilenceDetection(
    enable: true,
    onSilenceChanged: (isSilent, decibel) {
        /// Here you can check if silence is changed.
        /// Or you can do the same thing with the Stream
        /// [Recorder.instance.silenceChangedEvents]
    },
);
/// the silence threshold in dB. A volume under this value is considered to be silence.
Recorder.instance.setSilenceThresholdDb(-27);
/// the value in seconds of silence after which silence is considered as such.
Recorder.instance.setSilenceDuration(0.5);
/// Set seconds of audio to write before starting recording again after silence.
Recorder.instance.setSecondsOfAudioToWriteBefore(0.0);
```

### 📊 Audio, FFT, and Volume Data
You can also access raw audio data and volume information like this:

```dart
/// Get the current volume in dB in the [-100, 0] range.
double volume = Recorder.instance.getVolumeDb();
/// Return a 256 float array containing wave data in the range [-1.0, 1.0] not clamped.
Float32List waveAudio = Recorder.instance.getWave();
/// Return a 256 float array containing FFT data in the range [-1.0, 1.0] not clamped.
Float32List fftAudio = Recorder.instance.getFft();
```

![Image](https://github.com/alnitak/flutter_recorder/raw/main/images/audio_data.png)
