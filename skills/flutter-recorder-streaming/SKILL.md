---
name: flutter-recorder-streaming
version: 1
description: Teaches how to stream real-time audio data (PCM samples or Opus packets), convert sample formats with AudioDataContainer, handle the zero-copy buffer reuse constraint, and stream audio to network backends or speech-to-text models. Use when the user asks to stream microphone data, send audio over WebSockets/WebRTC, process raw PCM bytes, encode live Opus packets, or convert audio formats.
---

# flutter_recorder audio streaming

`flutter_recorder` provides low-latency, real-time streaming of captured audio data via Dart streams. It supports streaming raw uncompressed PCM samples in any bit depth, as well as live-encoded Opus packets.

## Minimal example

```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_recorder/flutter_recorder.dart';

StreamSubscription<AudioDataContainer>? _audioSubscription;

Future<void> startStreaming() async {
  final recorder = Recorder.instance;

  await recorder.init(
    format: PCMFormat.s16le, // or f32le, s32le, etc.
    sampleRate: 16000,       // 16kHz common for Speech-to-Text
    channels: RecorderChannels.mono,
  );
  recorder.start();

  // 1. Listen to incoming audio data
  _audioSubscription = recorder.uint8ListStream.listen((AudioDataContainer data) {
    // IMPORTANT: Make a copy if buffering or processing asynchronously!
    final Uint8List frameCopy = Uint8List.fromList(data.rawData);

    // Send frameCopy over WebSocket or process it:
    // webSocket.add(frameCopy);
  });

  // 2. Start streaming PCM samples
  recorder.startStreamingData(format: StreamingFormat.pcm);
}

Future<void> stopStreaming() async {
  final recorder = Recorder.instance;
  recorder.stopStreamingData();
  await _audioSubscription?.cancel();
  recorder.stop();
}
```

## Formats: PCM vs Opus Streaming

Configure the streaming mode in `startStreamingData`:

```dart
// Stream raw PCM bytes
Recorder.instance.startStreamingData(format: StreamingFormat.pcm);

// Stream length-prefixed Opus packets
Recorder.instance.startStreamingData(format: StreamingFormat.opus);
```

### Opus Streaming Details
When streaming with `StreamingFormat.opus`:
- `data.rawData` contains length-prefixed Opus packets.
- Each packet begins with a **4-byte little-endian integer** indicating the byte size of the ensuing Opus frame, followed by the encoded Opus payload.

## Converting Sample Formats with `AudioDataContainer`

The emitted `AudioDataContainer` wraps the incoming byte buffer. You can access raw bytes via `data.rawData` or convert to specific Dart typed arrays:

```dart
recorder.uint8ListStream.listen((AudioDataContainer data) {
  // Access raw bytes (matches format passed to init()):
  final Uint8List raw = data.rawData;
  final int byteLength = data.length;

  // Convert to Float32 [-1.0, 1.0] (e.g. for ML models / visualizers):
  final Float32List floatSamples = data.toF32List(from: PCMFormat.s16le);

  // Convert to Int16 [-32768, 32767] (e.g. for standard PCM 16-bit encoders):
  final Int16List int16Samples = data.toS16List(from: PCMFormat.f32le);

  // Other available conversions:
  // data.toU8List(from: format);        // Uint8List (0..255)
  // data.toS8List(from: format);        // Int8List (-128..127)
  // data.toS24List(from: format);       // Int8List 3-byte aligned
  // data.toS24ListOnInt32(from: format);// Int32List 24-bit sign-extended
  // data.toS32List(from: format);       // Int32List (-2147483648..2147483647)
});
```

*Tip: For maximum performance, initialize `Recorder.instance.init(format: ...)` directly with your target format to avoid costly per-frame conversions in Dart.*

## CRITICAL: Buffer Memory Reuse Rule

> [!CAUTION]
> Audio data must be processed as it is received. To optimize performance and avoid high GC overhead, the native backend reuses the same memory buffer for successive stream events.
>
> If you store frames in a list, queue them, or use reactive operators like `RxDart.bufferTime()`, **all items in your list will point to the same overwritten buffer**.
>
> **Solution**: Always clone the buffer when retaining or delegating asynchronously:
> ```dart
> final safeCopy = Uint8List.fromList(data.rawData);
> ```

## Streaming to Speech-to-Text / AI APIs (e.g. Gemini Live, Whisper)

```dart
import 'dart:typed_data';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void setupSpeechStreaming(WebSocketChannel channel) {
  Recorder.instance.init(
    format: PCMFormat.s16le,
    sampleRate: 16000,
    channels: RecorderChannels.mono,
  );
  Recorder.instance.start();

  Recorder.instance.uint8ListStream.listen((data) {
    // Clone before sending to network sink
    final payload = Uint8List.fromList(data.rawData);
    channel.sink.add(payload);
  });

  Recorder.instance.startStreamingData(format: StreamingFormat.pcm);
}
```

## The API Shape

- `Stream<AudioDataContainer> get uint8ListStream`: Broadcast stream of audio data packets.
- `void startStreamingData({StreamingFormat format = StreamingFormat.pcm})`: Begins streaming captured microphone data to `uint8ListStream`.
- `void stopStreamingData()`: Pauses emission to `uint8ListStream`.

## Traps & Gotchas

- **Do not forget to call `startStreamingData()`**: Listening to `uint8ListStream` alone will not emit events until `startStreamingData()` is called.
- **`start()` must be called before streaming**: If the capture engine is not started, no audio packets will arrive.
- **Conversion overhead**: Performing software PCM conversion (`toF32List`, `toS16List`) on every 20ms audio frame on the main isolate can affect UI frames. Match the initialized `PCMFormat` to your required format whenever possible.
- **Opus packets are length-prefixed**: When parsing Opus streaming packets, read the 4-byte little-endian length prefix before parsing each payload.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
