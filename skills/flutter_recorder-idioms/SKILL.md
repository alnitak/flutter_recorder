---
name: flutter_recorder-idioms
version: 1
description: Teaches robust architecture and design patterns for flutter_recorder, including service facades, ChangeNotifier/Riverpod state controllers, widget lifecycle management with AppLifecycleListener, audio session coordination with package:audio_session, and exception handling. Use when the user asks how to structure recording state, handle app backgrounding/lifecycle, integrate with state management, or write clean, bug-free audio recording code.
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
      );

      // 3. Start hardware capture
      _recorder.start();

      // 4. Enable visualization & volume tracking
      _recorder.setVisualizationEnabled(true, windowSize: 256);
      _visSub = _recorder.audioVisualizationEvents.listen((data) {
        _volumeDb = _recorder.getVolumeDb();
        notifyListeners();
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

## Coordinating Audio Sessions (`audio_session`)

When using multiple audio plugins (e.g. `flutter_recorder` with `flutter_soloud` or speech synthesis), coordinate the system audio session using `package:audio_session` to avoid audio interruptions on iOS and Android:

```dart
import 'package:audio_session/audio_session.dart';

Future<void> configureSystemAudioSession() async {
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
