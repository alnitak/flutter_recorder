---
name: flutter-recorder-idioms
version: 1
description: Teaches robust architecture and design patterns for flutter_recorder, including service facades, ChangeNotifier/Riverpod state controllers, widget lifecycle management with AppLifecycleListener, audio session coordination with package:audio_session, and integration with flutter_soloud. Use when the user asks how to structure recording state, handle app backgrounding/lifecycle, integrate with flutter_soloud, coordinate audio_session, or write clean, bug-free audio recording code.
---

# flutter_recorder idioms & best practices

`flutter_recorder` is a singleton FFI/WASM audio capture engine (`Recorder.instance`). Because it manages low-level hardware streams and native memory, adhering to correct architecture and lifecycle patterns prevents memory leaks, dangling file handles, and crashes across platforms.

## Architectural Pattern: Service Facade / Controller

Avoid accessing `Recorder.instance` directly from multiple unrelated UI widgets. Instead, encapsulate the recorder inside a service or controller class (ChangeNotifier, Riverpod notifier, or Bloc) that coordinates permissions, recording state, and file storage.

### Example: ChangeNotifier Controller

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecordingState { uninitialized, ready, recording, paused }

class RecordingController extends ChangeNotifier {
  final Recorder _recorder = Recorder.instance;

  RecordingState _state = RecordingState.uninitialized;
  RecordingState get state => _state;

  String? _lastRecordedFilePath;
  String? get lastRecordedFilePath => _lastRecordedFilePath;

  double _volumeDb = -100.0;
  double get volumeDb => _volumeDb;

  StreamSubscription<AudioVisualizationData>? _visSub;
  StreamSubscription<RecorderDeviceNotification>? _deviceNotifSub;

  Future<bool> initialize() async {
    if (_recorder.isInitialized) return true;

    // 1. Request microphone permission
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        return false;
      }
    }

    try {
      // 2. Initialize engine
      await _recorder.init(
        format: PCMFormat.f32le,
        sampleRate: 44100,
        channels: RecorderChannels.mono,
        androidInputPreset: AndroidInputPreset.voiceCommunication,
        iosInputPreset: IosInputPreset.voiceCommunication,
        webInputPreset: WebInputPreset.unprocessed,
      );

      // 3. Start hardware capture
      _recorder.start();

      // 4. Enable visualization & volume tracking
      _recorder.setVisualizationEnabled(true, windowSize: 256);
      _visSub = _recorder.audioVisualizationEvents.listen((data) {
        _volumeDb = _recorder.getVolumeDb();
        notifyListeners();
      });

      // 5. Listen to native device lifecycle & interruption events
      _deviceNotifSub = _recorder.deviceNotificationEvents.listen((event) {
        switch (event) {
          case RecorderDeviceNotification.stopped:
            if (_state == RecordingState.recording) {
              _state = RecordingState.ready;
              notifyListeners();
            }
          case RecorderDeviceNotification.interruptionBegan:
            if (_state == RecordingState.recording) {
              pauseRecording();
            }
          case RecorderDeviceNotification.interruptionEnded:
            // Interruption ended; optionally resume or stay paused
            break;
          case RecorderDeviceNotification.rerouted:
          case RecorderDeviceNotification.started:
          case RecorderDeviceNotification.unlocked:
            break;
        }
      });

      _state = RecordingState.ready;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to initialize recorder: $e');
      return false;
    }
  }

  Future<void> startRecording({String filename = 'audio_note.wav'}) async {
    if (_state != RecordingState.ready && _state != RecordingState.paused) return;

    String filePath = '';
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      filePath = '${dir.path}/$filename';
      _lastRecordedFilePath = filePath;
    }

    _recorder.startRecording(
      completeFilePath: filePath,
      format: RecordingFormat.wav,
    );

    _state = RecordingState.recording;
    notifyListeners();
  }

  void pauseRecording() {
    if (_state != RecordingState.recording) return;
    _recorder.setPauseRecording(pause: true);
    _state = RecordingState.paused;
    notifyListeners();
  }

  void resumeRecording() {
    if (_state != RecordingState.paused) return;
    _recorder.setPauseRecording(pause: false);
    _state = RecordingState.recording;
    notifyListeners();
  }

  void stopRecording() {
    if (_state != RecordingState.recording && _state != RecordingState.paused) return;
    _recorder.stopRecording();
    _state = RecordingState.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    _visSub?.cancel();
    _deviceNotifSub?.cancel();
    if (_recorder.isInitialized) {
      if (_state == RecordingState.recording || _state == RecordingState.paused) {
        _recorder.stopRecording();
      }
      _recorder.deinit();
    }
    super.dispose();
  }
}
```

## Flutter Widget Lifecycle with `AppLifecycleListener`

Always register an `AppLifecycleListener` to safely clean up native audio resources when the app is detached:

```dart
class _RecordingScreenState extends State<RecordingScreen> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: () {
        Recorder.instance.deinit();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    Recorder.instance.deinit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## Integrating `flutter_recorder` with `flutter_soloud` & `audio_session`

When building applications that simultaneously play audio (games, music, sound effects via `flutter_soloud`) and capture microphone audio (voice chat, speech recognition, karaoke via `flutter_recorder`), use `package:audio_session` to prevent audio interruptions, speakerphone dropouts, or OS ducking:

### Choosing Presets vs `audio_session`:

- **Option A: Built-in Input Presets** (`IosInputPreset` / `AndroidInputPreset` / `WebInputPreset`):
  Use when you want a standalone, zero-dependency configuration for microphone recording without manually managing audio sessions.
- **Option B: `package:audio_session` Coordination**:
  Use when orchestrating multiple audio packages (e.g. `flutter_recorder` + `flutter_soloud`). Set `iosInputPreset: null` so `flutter_recorder` preserves the `AVAudioSession` configuration set by `audio_session`.

### Complete Integration Recipe:

```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class DuplexAudioService {
  final SoLoud _soloud = SoLoud.instance;
  final Recorder _recorder = Recorder.instance;
  StreamSubscription<Uint8List>? _soloudMixerSub;

  Future<void> initialize({int sampleRate = 22050}) async {
    // 1. Configure audio_session for simultaneous PlayAndRecord
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          usage: AndroidAudioUsage.voiceCommunication,
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
        ),
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);

    // 2. Initialize SoLoud playback engine
    await _soloud.init(
      channels: Channels.mono,
      sampleRate: sampleRate,
    );

    // 3. Initialize Recorder capture engine (keep iosInputPreset null to preserve audio_session)
    await _recorder.init(
      format: PCMFormat.f32le,
      sampleRate: sampleRate,
      channels: RecorderChannels.mono,
      androidInputPreset: AndroidInputPreset.voiceCommunication,
      webInputPreset: WebInputPreset.unprocessed,
    );
    _recorder.start();

    // 4. Activate AEC and bridge SoLoud mixer output to Recorder
    _recorder.filters.echoCancellationFilter.activate();
    _soloudMixerSub = _soloud.startMixerOutputStream(
      format: MixerOutputFormat.pcmF32le,
      channels: 1,
    ).listen((Uint8List mixerBytes) {
      if (_recorder.isInitialized &&
          _recorder.filters.echoCancellationFilter.isActive) {
        _recorder.feedPlaybackData(
          mixerBytes,
          format: PCMFormat.f32le,
          channels: RecorderChannels.mono,
        );
      }
    });
  }

  Future<void> dispose() async {
    await _soloudMixerSub?.cancel();
    if (_recorder.isInitialized) {
      _recorder.deinit();
    }
    if (_soloud.isInitialized) {
      await _soloud.deinitAsync();
    }
  }
}
```

## Exception Handling Matrix

Always catch specific `flutter_recorder` exceptions when performing audio operations:

```dart
try {
  Recorder.instance.startRecording(completeFilePath: path);
} on RecorderNotInitializedException {
  // init() was not called or failed
} on RecorderCaptureNotStartededException {
  // start() was not called
} on RecorderInvalidFileNameException catch (e) {
  // Invalid or inaccessible path
} on Exception catch (e) {
  // Other unexpected errors
}
```

## Traps & Checklist

- [ ] **Always use `PCMFormat.f32le`** if you plan to use `audioVisualizationEvents`, `getVolumeDb()`, or `setSilenceDetection()`.
- [ ] **Never ignore buffer memory reuse** in `uint8ListStream` — clone incoming bytes with `Uint8List.fromList(data.rawData)` when holding or buffering.
- [ ] **Always call `stopRecording()`** before calling `stop()` or `deinit()`.
- [ ] **Never pass a hardcoded file path on Web** — Web ignores `completeFilePath` and triggers a browser download on `stopRecording()`.
- [ ] **Dispose listeners and streams** (`StreamSubscription.cancel()`) in widget `dispose()` methods.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
