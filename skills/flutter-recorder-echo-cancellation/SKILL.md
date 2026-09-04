---
name: flutter-recorder-echo-cancellation
version: 1
description: Teaches how to use SpeexDSP Acoustic Echo Cancellation (AEC) and native duplex loopback in flutter_recorder, tune filter length and denoise suppression, configure low-latency sidetone/karaoke monitoring, coordinate system audio sessions with package:audio_session, and feed far-end speaker reference audio from flutter_soloud or VoIP streams. Use when the user asks to eliminate speaker echo, cancel acoustic feedback, implement mic loopback/sidetone, build karaoke apps, or implement voice chat/VoIP.
---

# flutter_recorder Acoustic Echo Cancellation (AEC) & loopback

`flutter_recorder` integrates real-time Acoustic Echo Cancellation powered by [SpeexDSP](https://github.com/xiph/speexdsp). AEC removes loudspeaker acoustic feedback and room reverberation picked up by the microphone, ensuring clear voice capture without echoing or howling.

## Minimal example

```dart
import 'package:flutter_recorder/flutter_recorder.dart';

Future<void> setupEchoCancellation() async {
  final recorder = Recorder.instance;

  await recorder.init(
    format: PCMFormat.f32le,
    sampleRate: 22050,
    channels: RecorderChannels.mono,
  );
  recorder.start();

  // 1. Activate AEC filter
  final aec = recorder.filters.echoCancellationFilter;
  aec.activate();

  // 2. Tune AEC parameters
  aec.filterLengthMs.value = 150; // Echo tail length in ms (10..500 ms)
  aec.denoiseEnabled.value = 1;   // 1 = enable residual noise suppression, 0 = disable
  aec.denoiseLevelDb.value = -30; // Max suppression level in dB (-60..0 dB)
}
```

## Choosing Your Reference Mode

Acoustic echo cancellation requires knowledge of what is being played through the device's loudspeakers (the "far-end reference") so it can subtract that signal from what the microphone hears. `flutter_recorder` supports two modes:

---

### Mode A: Native Duplex Loopback (Karaoke / Sidetone)

When mic audio should be routed directly to the headphones or speakers with near-zero hardware latency (< 15ms):

```dart
// Enable native miniaudio duplex loopback
Recorder.instance.setLoopback(enable: true);
```

#### Use Cases:
- **Karaoke & In-Ear Monitoring**: The singer hears their voice in real time through headphones with imperceptible latency, while AEC prevents acoustic feedback loops.
- **Live Microphone Sidetone**: Confidence monitoring for podcasters, streamers, and broadcasters.

---

### Mode B: External Playback Reference (VoIP / Gaming / Smart Assistants)

When external audio (e.g. game music, sound effects, remote caller speech) is playing through the device speakers:

1. **Keep native loopback disabled**:
   ```dart
   Recorder.instance.setLoopback(enable: false);
   ```
2. **Feed loudspeaker audio frames to AEC**:
   ```dart
   Recorder.instance.feedPlaybackData(
     playbackPcmBytes,
     format: PCMFormat.f32le,
     channels: RecorderChannels.mono,
   );
   ```

#### Full Integration Recipe with `flutter_soloud` & `audio_session`:

When building games with voice chat or karaoke applications using `flutter_soloud` for playback and `flutter_recorder` for voice capture:

```dart
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

Future<void> initializeDuplexAudio() async {
  const sampleRate = 22050;

  // 1. Configure audio_session so iOS/Android route to speaker + allow simultaneous mic/playback
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

  // 2. Initialize SoLoud audio engine
  final soloud = SoLoud.instance;
  await soloud.init(
    channels: Channels.mono,
    sampleRate: sampleRate,
  );

  // 3. Initialize Recorder (matching sample rate and format)
  final recorder = Recorder.instance;
  await recorder.init(
    format: PCMFormat.f32le,
    sampleRate: sampleRate,
    channels: RecorderChannels.mono,
    // Note: leave iosInputPreset as null when audio_session is managing the session
  );
  recorder.start();

  // 4. Activate AEC filter in recorder
  recorder.filters.echoCancellationFilter.activate();
  recorder.filters.echoCancellationFilter.filterLengthMs.value = 150;
  recorder.filters.echoCancellationFilter.denoiseEnabled.value = 1;

  // 5. Pipe SoLoud master output stream into Recorder's AEC playback reference
  soloud.startMixerOutputStream(
    format: MixerOutputFormat.pcmF32le,
    channels: 1, // mono
  ).listen((Uint8List mixerBytes) {
    if (recorder.isInitialized && recorder.filters.echoCancellationFilter.isActive) {
      recorder.feedPlaybackData(
        mixerBytes,
        format: PCMFormat.f32le,
        channels: RecorderChannels.mono,
      );
    }
  });
}
```

#### Use Cases:
- **VoIP & Video Conferencing**: Eliminates remote caller echo when loudspeaker is active without requiring headphones.
- **Gaming Voice Chat**: Cancels background game music and SFX played via `flutter_soloud` from the team voice chat mic.
- **Smart Voice Assistants (Barge-In)**: Allows devices to recognize user wake words while actively playing speech or music through loudspeakers.

## Parameters & Tuning Guide

Access parameters via `recorder.filters.echoCancellationFilter.<param>`:

| Parameter | Range | Default | Guidance |
|---|---|---|---|
| `filterLengthMs` | 10 – 500 ms | 150 ms | Tail length (room acoustic memory). Headsets: `10–50 ms`. Small rooms: `100–200 ms`. Large or reverberant rooms: `200–400 ms`. |
| `denoiseEnabled` | 0 or 1 | 1 | Enables SpeexDSP residual echo suppression and stationary noise suppression. |
| `denoiseLevelDb` | -60 – 0 dB | -30 dB | Maximum attenuation of residual echo in dB. `-30 dB` to `-45 dB` provides strong suppression without distorting voice. |

## Hardware AEC vs Software AEC

- **Hardware AEC**: Configured via `IosInputPreset.voiceCommunication` on iOS or `AndroidInputPreset.voiceCommunication` on Android. This uses device DSP chips directly at the driver level.
- **Software AEC (`echoCancellationFilter`)**: Uses the SpeexDSP software engine. Ideal when cross-platform consistency is needed, when feeding custom playback references like `flutter_soloud` mixer streams, or on desktop platforms (macOS/Linux/Windows).

## The API Shape

- `Recorder.instance.filters.echoCancellationFilter`: Singleton accessor for the AEC filter.
- `void aec.activate()` / `void aec.deactivate()`: Enables or disables AEC filtering.
- `bool get aec.isActive`: Checks whether AEC is active.
- `void Recorder.instance.setLoopback({required bool enable})`: Toggles native C++ duplex loopback.
- `bool Recorder.instance.isLoopbackEnabled()`: Checks whether native loopback is active.
- `void Recorder.instance.feedPlaybackData(Uint8List data, {PCMFormat format = PCMFormat.f32le, RecorderChannels channels = RecorderChannels.mono})`: Feeds far-end reference PCM samples to the AEC filter.

## Traps & Gotchas

- **Do not enable loopback AND play back mic audio manually**: If `setLoopback(enable: true)` is active, miniaudio automatically outputs mic audio. Adding manual playback through another audio engine will cause doubled, flanged audio.
- **Sample Rate & Alignment**: `feedPlaybackData` works best when the playback stream sample rate matches the recorder sample rate (e.g. 22050 Hz or 44100 Hz).
- **Headsets vs Speakerphones**: When users wear headphones, AEC can be safely deactivated or given a short tail (`filterLengthMs = 20`) to minimize CPU usage.
- **Audio Session Setup**: When building duplex audio on mobile, always use `package:audio_session` or `IosInputPreset.voiceCommunication` / `AndroidInputPreset.voiceCommunication` so the OS routes audio properly to the loudspeaker instead of the telephone receiver earpiece.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
