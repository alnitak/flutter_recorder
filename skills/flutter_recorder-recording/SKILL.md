---
name: flutter_recorder-recording
version: 1
description: Teaches how to record audio to WAV and Ogg Opus files on disk, pause and resume recording, stop recordings, manage output directories across platforms, and handle Web file downloads. Use when a user asks to record microphone audio to a file, save WAV or Opus audio, implement pause/resume recording, or retrieve recorded audio files.
---

# flutter_recorder file recording

`flutter_recorder` can record captured microphone audio directly into WAV (uncompressed PCM) or Ogg Opus (compressed, high quality, low bitrate) audio files. Recording supports live pause and resume without breaking or splitting the output file.

## Minimal example

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';

Future<void> recordAudio() async {
  final recorder = Recorder.instance;

  // 1. Initialize and start the capture engine
  await recorder.init(
    format: PCMFormat.f32le,
    sampleRate: 44100,
    channels: RecorderChannels.mono,
  );
  recorder.start();

  // 2. Determine target path (Desktop/Mobile vs Web)
  String filePath = '';
  if (!kIsWeb) {
    final dir = await getApplicationDocumentsDirectory();
    filePath = '${dir.path}/my_recording.wav';
  }

  // 3. Start recording to file (WAV default)
  recorder.startRecording(
    completeFilePath: filePath,
    format: RecordingFormat.wav,
  );

  // 4. Optional: Pause and resume recording
  recorder.setPauseRecording(pause: true);
  // ... silence or user paused ...
  recorder.setPauseRecording(pause: false);

  // 5. Stop recording and finalize file header
  recorder.stopRecording();

  // 6. Stop and deinit capture
  recorder.stop();
  recorder.deinit();
}
```

## Formats: WAV vs Ogg Opus

Select the output format via the `format` parameter in `startRecording`:

```dart
// Uncompressed WAV
recorder.startRecording(
  completeFilePath: '/path/to/recording.wav',
  format: RecordingFormat.wav,
);

// High-efficiency Ogg Opus
recorder.startRecording(
  completeFilePath: '/path/to/recording.opus',
  format: RecordingFormat.opusOgg,
);
```

| Format | Enum Value | File Extension | Characteristics | Best For |
|---|---|---|---|---|
| WAV | `RecordingFormat.wav` | `.wav` | Uncompressed PCM, lossless, instant writing | Audio editing, DSP analysis, short clips |
| Ogg Opus | `RecordingFormat.opusOgg` | `.opus` or `.ogg` | High-efficiency compression (Opus), compact size | Long recordings, voice notes, streaming storage |

## The API Shape

All recording methods are called on `Recorder.instance`:

- `void startRecording({String completeFilePath = '', RecordingFormat format = RecordingFormat.wav})`: Starts writing captured audio into the specified file.
  - On non-web platforms, `completeFilePath` is mandatory.
  - On Web, `completeFilePath` is ignored; audio is held in memory and downloaded upon stopping.
  - Throws `RecorderNotInitializedException` if `init()` was not called.
  - Throws `RecorderCaptureNotStartededException` if `start()` was not called.
  - Throws `RecorderInvalidFileNameException` if the destination path is invalid.
- `void setPauseRecording({required bool pause})`: Pauses (`pause: true`) or unpauses (`pause: false`) writing into the recording file without interrupting the microphone capture stream.
- `void stopRecording()`: Finalizes the audio file, writes header metadata (such as WAV riff size and sample counts), closes the file descriptor, and flushes to disk.

## Cross-Platform File Paths

Use `package:path_provider` to ensure safe, writable directories:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getRecordingPath({String fileName = 'recording.wav'}) async {
  if (kIsWeb) return ''; // Ignored on Web

  final Directory saveDir;
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    // Mobile: Sandboxed documents directory
    saveDir = await getApplicationDocumentsDirectory();
  } else {
    // Desktop (macOS, Windows, Linux): Downloads or Application Documents
    final downloads = await getDownloadsDirectory();
    saveDir = downloads ?? await getApplicationDocumentsDirectory();
  }

  if (!saveDir.existsSync()) {
    saveDir.createSync(recursive: true);
  }
  return '${saveDir.path}/$fileName';
}
```

## Silence Detection Pre-Roll Buffering

When recording with silence detection enabled, you can write audio that occurred immediately *before* voice triggered recording, ensuring words are never clipped at the start of a sentence:

```dart
// Retain 0.5 seconds of audio prior to speech detection
Recorder.instance.setSecondsOfAudioToWriteBefore(0.5);
```

## Traps & Gotchas

- **`start()` must be called before `startRecording()`**: Calling `startRecording()` when `isStarted` is `false` throws `RecorderCaptureNotStartededException`.
- **`completeFilePath` is required on mobile and desktop**: Omitting or passing an empty string on non-web platforms causes an assertion failure or `RecorderInvalidFileNameException`.
- **Always call `stopRecording()` before `stop()` / `deinit()`**: Stopping the engine without stopping the recording may leave the file header incomplete or corrupt.
- **On Web, `stopRecording()` triggers a browser download**: No local file system path is used on the web.
- **File Overwrites**: If `completeFilePath` points to an existing file, the recorder will overwrite it. Clean up existing files if you want to verify new creation.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
