---
name: flutter-recorder-silence-detection
version: 1
description: Teaches how to configure automated silence detection, voice activity detection (VAD), silence thresholds in dB, duration triggers, pre-roll buffer retention, and silence event streams. Use when the user asks to detect silence, pause recording when silent, auto-resume recording when speaking, or skip silent sections in audio.
---

# flutter_recorder silence detection

`flutter_recorder` includes built-in real-time silence detection and voice activity monitoring. It can notify your app via callbacks or reactive Streams whenever silence starts or ends, allowing automatic pausing of file recording or UI state updates.

## Minimal example

```dart
import 'package:flutter_recorder/flutter_recorder.dart';

Future<void> setupSilenceDetection() async {
  final recorder = Recorder.instance;

  // IMPORTANT: PCMFormat.f32le is required for silence detection!
  await recorder.init(
    format: PCMFormat.f32le,
    sampleRate: 22050,
    channels: RecorderChannels.mono,
  );
  recorder.start();

  // 1. Configure detection parameters
  recorder.setSilenceThresholdDb(-27.0);       // Volume below -27 dB is silence
  recorder.setSilenceDuration(0.5);            // Must stay below threshold for 0.5s
  recorder.setSecondsOfAudioToWriteBefore(0.2); // Pre-roll buffer to keep word starts

  // 2. Option A: Using the callback handler
  recorder.setSilenceDetection(
    enable: true,
    onSilenceChanged: (bool isSilent, double decibel) {
      if (isSilent) {
        print('Silence detected! Current volume: $decibel dB');
        // Optionally pause recording:
        // recorder.setPauseRecording(pause: true);
      } else {
        print('Speech resumed! Current volume: $decibel dB');
        // recorder.setPauseRecording(pause: false);
      }
    },
  );

  // 3. Option B: Using the Stream
  recorder.silenceChangedEvents.listen((SilenceState state) {
    print('isSilent: ${state.isSilent}, dB: ${state.decibel}');
  });
}
```

## How It Works

1. **RMS Decibel Calculation**: The native backend continuously measures the RMS energy of incoming audio frames in dBFS (decibels relative to full scale, ranging from -100 dB up to 0 dB).
2. **Threshold Comparison**: If the energy falls below `silenceThresholdDb` for continuous `silenceDuration` seconds, the state changes to `isSilent: true`.
3. **Voice Resumption**: The instant energy exceeds `silenceThresholdDb`, the state flips to `isSilent: false`.
4. **Pre-roll Ring Buffer**: With `setSecondsOfAudioToWriteBefore`, the recorder maintains an internal ring buffer. When recording unpauses upon voice onset, it prepends the specified seconds of audio so speech plosives/consonants are never truncated.

## The API Shape

All methods are available on `Recorder.instance`:

- `void setSilenceDetection({required bool enable, SilenceCallback? onSilenceChanged})`: Enables or disables silence detection and registers an optional callback `void Function(bool isSilent, double decibel)`. Requires `PCMFormat.f32le`.
- `Stream<SilenceState> get silenceChangedEvents`: Broadcast stream emitting `SilenceState ({bool isSilent, double decibel})`.
- `void setSilenceThresholdDb(double silenceThresholdDb)`: Sets the cutoff volume in dB (default `-40.0 dB`). Values typically range from `-60.0 dB` (very quiet room) to `-20.0 dB` (noisy environment).
- `void setSilenceDuration(double silenceDuration)`: Sets the duration in seconds that volume must remain below the threshold before triggering silence (default `2.0` seconds).
- `void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore)`: Configures the pre-roll duration in seconds (default `0.0` seconds) prepended when recording resumes.

## Recipe: Smart Auto-Pause Voice Recorder

```dart
import 'dart:io';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';

class SmartVoiceRecorder {
  final Recorder _recorder = Recorder.instance;
  bool _isAutoPauseEnabled = true;

  Future<void> initAndStart(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename.wav';

    // Must use PCMFormat.f32le
    await _recorder.init(
      format: PCMFormat.f32le,
      sampleRate: 44100,
      channels: RecorderChannels.mono,
    );
    _recorder.start();

    // Configure silence detection
    _recorder.setSilenceThresholdDb(-30.0);
    _recorder.setSilenceDuration(1.0);
    _recorder.setSecondsOfAudioToWriteBefore(0.3); // retain 300ms before speech

    _recorder.setSilenceDetection(
      enable: true,
      onSilenceChanged: (isSilent, db) {
        if (_isAutoPauseEnabled) {
          _recorder.setPauseRecording(pause: isSilent);
        }
      },
    );

    _recorder.startRecording(
      completeFilePath: path,
      format: RecordingFormat.wav,
    );
  }

  void stop() {
    _recorder.stopRecording();
    _recorder.stop();
    _recorder.deinit();
  }
}
```

## Traps & Gotchas

- **Requires `PCMFormat.f32le`**: Initializing `init()` with any format other than `PCMFormat.f32le` will prevent silence detection from operating and log a warning.
- **Decibel Scales**: 0 dB is the digital clipping maximum. Typical background room noise is between -60 dB and -45 dB. Normal speech is between -25 dB and -10 dB.
- **Threshold Too High vs Too Low**:
  - Setting threshold too high (e.g. -15 dB) may flag quiet spoken words as silence.
  - Setting threshold too low (e.g. -70 dB) may prevent background HVAC/fan hum from ever triggering silence.
- **Pre-Roll Memory**: `secondsOfAudioToWriteBefore` allocates a small native ring buffer. Recommended values are between 0.1s and 1.0s.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
