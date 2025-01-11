A low-level audio recorder plugin that uses miniaudio as the backend and supports all the platforms. It can detect silence and save to a WAV audio file. Audio wave and FFT data can be obtained in real-time as for the volume level.

[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

|Linux|Windows|Android|MacOS (under test)|iOS (under test)|web (WASM compatible)|
|:-:|:-:|:-:|:-:|:-:|:-:|
|💙|💙|💙|💙|💙|💙|

## 🌟 Key Features:
- 🖥️ **Cross-platform**: Supports Linux, Windows, Android, MacOS, iOS, and web.
- ⚡ **High performance**: Built using the fast and efficient miniaudio C library with FFI.
- 🎙️ **WAV Recording with Pause**: Record in WAV format with pause functionality.
- ⚙️ **Choose Data Type**: samplerate, mono or stereo, audio format (u8, s8, s16le, s24le, s32le or f32le).
- 🎛️ **Device Flexibility**: Choose your recording device.
- 📢 **Stream audio data**: Listen to PCM audio data stream.
- 🔇 **Silence Detection**: Automatically detects silence via callback or Stream.
- 📊 **Customizable Silence Threshold**: Define what’s considered “silence” for your recordings.
- ⏱️ **Adjustable Pause Timing**: Set how long silence lasts before pausing, and how soon to resume recording.
- 🔊 **Real-time Audio Metrics**: Access volume, audio wave, and FFT data in real-time.
- 🎚️ **Auto Gain**: Experimental Auto Gain filter.
- 🌐 **Cross Platform**: Supports all platforms with WASM support for the web.

[A web example compiled in WASM.](https://marcobavagnoli.com/flutter_recorder/)

## 🚀 Setup
After setting up permission for you Android, MacOS or iOS, in your app, you will need to ask for permission to use the microphone maybe using [permission_handler](https://pub.dev/packages/permission_handler) plugin.
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

on **MacOS** :

In capabilities, activate "Audio input" in debug and release schemes or add in `macos/Runner/*.entitlements` files:
```
<key>com.apple.security.device.audio-input</key>
<true/>
```

#### Web
Add this in `web/index.html` under the `<head>` tag.
```
<script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
<script src="assets/packages/flutter_recorder/web/init_recorder_module.dart.js" defer></script>
```
The plugin is **WASM** compatible and your app can be compiled and run locally with something like:
```
flutter run -d chrome --web-renderer canvaskit --web-browser-flag '--disable-web-security' -t lib/main.dart --release
```

#### Linux
- [`GStreamer`](https://gstreamer.freedesktop.org/documentation/installing/index.html?gi-language=c) is installed by default on most distributions, but if not, please [install it](https://gstreamer.freedesktop.org/documentation/installing/on-linux.html?gi-language=c) through your distribution's package manager.
- Installing Flutter using `snap` could cause compilation problems with native plugins. The only solution is to uninstall it with `sudo snap remove flutter` and install it the [official way](https://flutter-ko.dev/get-started/install/linux).

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

/// Initialize the capture device and start it:
try {
    Recorder.instance.init();
    Recorder.instance.start();
} on Exception catch (e) {
    debugPrint('init() error: $e\n');
}
/// On Web platform it is better to initialize and wait the user to give
/// mic permission. Then use `start()` when it's needed.

//Start recording:
Recorder.instance.startRecording(completeFilePath: 'audioCompleteFilenameWithPath.wav`);

/// Stop recording:
Recorder.instance.stopRecording();
```
**Tip**: Use `Recorder.instance.listCaptureDevices()` to see available devices and pass an optional `deviceID` to `init()`.
**Tip2**: Use the `format`, `sampleRate` and `channels` with the `init()` method to define recorder parameters.
**Tip3**: When recording with silence detection and want to record a little bit before the threshold db is reached, use the `setSecondsOfAudioToWriteBefore()` method.


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

***NOTE: this is only available when initializing the recorder with `PCMFormat.f32le` format.***

### 📢 Audio data stream 


```dart
/// Listen to audio data stream. The data is received in Uint8List.
Recorder.instance.uint8ListStream.listen((data) {
    /// the [data] is of type `AudioDataContainer` and, whatever format is passed to
    /// the `init()` method, it is available with [data.rawData] which is of `Uint8List`
    /// type. This is useful if we want to write into a file.
    /// It is possible to convert audio data to the desired format using one of the
    /// `data.to[*]List` methods. Be aware that the conversion is compute expensive and
    /// should be avoided if possible initializing the recorder with the format
    /// desired.
});

/// Start streaming:
Recorder.instance.startStreamingData();
/// Stop streaming:
Recorder.instance.stopStreamingData();
```
> [!CAUTION]
> Audio data must be processed as it is received. To optimize performance, the same memory is used to store data for all incoming streams, meaning the data will be overwritten. Therefore, you must copy the data if you need to populate a buffer while it arrives.
> For example, when using **RxDart.bufferTime**, it will fill a **List** of `AudioDataContainer` objects, but when you attempt to read them, you will find that all the items contain the same data.

### 🎚️ Auto Gain Filter

> [!WARNING]
> This is an experimental feature, may change in the future.

```
final Recorder recorder = Recorder.instance;
// Please look at the [Recorder.instance.autoGainFilter] doc to have a parameters overview.
final AutoGain autoGain = recorder.filters.autoGainFilter;

// You can now query or set parameters:
// For example with [autoGain.queryTargetRms] you can query the "human" name, `min`, `max` and `def` values.

// Set a new parameter value:
autoGain.targetRms.value = newValue;

// Get a new parameter value:
final value = autoGain.targetRms.value;
```
Available parameters: `targetRMS`, `attackTime`, `releaseTime`, `gainSmoothing`, `maxGain`, `minGain`.