---
name: flutter-recorder-autogain
version: 1
description: Teaches how to use flutter_recorder's AutoGain DSP audio filter, tune target RMS loudness, attack and release times, gain limits, noise floor threshold, and headroom, and inspect live metrics like limiter clips and current gain. Use when the user asks to normalize microphone volume, add automatic gain control (AGC), prevent audio clipping, or boost quiet voices.
---

# flutter_recorder AutoGain filter

`flutter_recorder` includes an experimental native `AutoGain` DSP audio filter that performs real-time automatic loudness normalization and dynamic range compression. It boosts quiet speech, attenuates excessive loud bursts, suppresses background noise floors, and protects against digital clipping with an internal brickwall limiter.

## Minimal example

```dart
import 'package:flutter_recorder/flutter_recorder.dart';

Future<void> setupAutoGain() async {
  final recorder = Recorder.instance;

  await recorder.init(
    format: PCMFormat.f32le,
    sampleRate: 44100,
    channels: RecorderChannels.mono,
  );
  recorder.start();

  // 1. Obtain filter instance
  final autoGain = recorder.filters.autoGainFilter;

  // 2. Activate the filter
  autoGain.activate();

  // 3. Adjust parameters for speech
  autoGain.targetRms.value = 0.15;       // Target loudness level
  autoGain.attackTime.value = 0.02;      // Fast reaction to quiet audio (20ms)
  autoGain.releaseTime.value = 0.20;     // Smooth gain recovery (200ms)
  autoGain.maxGain.value = 5.0;          // Max 5x gain boost
  autoGain.noiseFloorDb.value = -50.0;   // Don't amplify signals below -50 dB
  autoGain.headroomDb.value = 2.0;       // 2 dB headroom before limiter

  // 4. Read live metrics during recording:
  final double gain = autoGain.currentGain.value;
  final double peak = autoGain.outputPeak.value;
  final double clips = autoGain.totalLimiterClipCount.value;

  // 5. Deactivate when finished:
  // autoGain.deactivate();
}
```

## Parameters & Tuning Guide

Access writable parameters via `recorder.filters.autoGainFilter.<param>.value = ...`:

| Parameter | Range | Default | Purpose & Tuning Advice |
|---|---|---|---|
| `targetRms` | 0.001 – 0.95 | 0.10 | Desired target loudness. Speech: `0.05–0.20`. Music: `0.10–0.30`. |
| `attackTime` | 0.001 – 2.0s | 0.10s | How quickly gain increases when signal drops. Speech: `0.01–0.05s`. Slower attack avoids breathing artifacts. |
| `releaseTime` | 0.001 – 5.0s | 0.20s | How quickly gain drops when a loud sound occurs. `0.10–0.40s` creates smooth transitions. |
| `gainSmoothing`| 0.001 – 1.0s | 0.05s | RMS detector time constant. Higher values reduce gain pumping. |
| `maxGain` | 1.0 – 12.0 | 6.00 | Maximum amplification multiplier. Restrict to `3.0–6.0` to avoid boosting room noise. |
| `minGain` | 0.0 – 1.0 | 0.20 | Minimum gain multiplier. Prevents excessive attenuation. |
| `noiseFloorDb` | -100 – -10 dB | -55 dB | Input threshold below which gain boost is disabled to keep silence quiet. |
| `headroomDb` | 0.0 – 24 dB | 1.0 dB | Safety margin below digital full scale (0 dBFS) before limiter engages. |

## Querying Parameter Metadata

You can query parameter boundaries without hardcoding values:

```dart
final autoGain = Recorder.instance.filters.autoGainFilter;

// Metadata getters
final query = autoGain.queryTargetRms;
print(query.toString()); // "Target RMS"
print(query.min);        // 0.001
print(query.max);        // 0.95
print(query.def);        // 0.1
print(query.isWritable); // true
```

## Read-Only Runtime Metrics

The filter exposes live runtime DSP statistics through `FilterMetric` accessors:

- `autoGain.currentGain.value`: Current linear gain multiplier being applied.
- `autoGain.inputRms.value`: Current input signal RMS energy `[0.0, 1.0]`.
- `autoGain.outputPeak.value`: Peak amplitude of the output audio frame `[0.0, 1.0]`.
- `autoGain.limiterClipCount.value`: Number of samples clamped by the brickwall limiter in the latest frame.
- `autoGain.totalLimiterClipCount.value`: Cumulative number of clipped samples since activation.
- `autoGain.lastFrameCount.value`: Frame size processed in the latest audio callback.

## Recommended Presets

### Speech in a Noisy Room
```dart
autoGain.targetRms.value = 0.10;
autoGain.attackTime.value = 0.02;
autoGain.releaseTime.value = 0.20;
autoGain.gainSmoothing.value = 0.01;
autoGain.maxGain.value = 4.0;
autoGain.minGain.value = 0.2;
autoGain.noiseFloorDb.value = -45.0; // Higher noise floor ignores background noise
autoGain.headroomDb.value = 2.0;
```

### High-Quality Podcast Recording
```dart
autoGain.targetRms.value = 0.15;
autoGain.attackTime.value = 0.03;
autoGain.releaseTime.value = 0.25;
autoGain.gainSmoothing.value = 0.03;
autoGain.maxGain.value = 5.0;
autoGain.minGain.value = 0.1;
autoGain.noiseFloorDb.value = -55.0;
autoGain.headroomDb.value = 1.5;
```

### Music Recording / Singing
```dart
autoGain.targetRms.value = 0.20;
autoGain.attackTime.value = 0.01;
autoGain.releaseTime.value = 0.35;
autoGain.gainSmoothing.value = 0.05;
autoGain.maxGain.value = 3.0;
autoGain.minGain.value = 0.1;
autoGain.noiseFloorDb.value = -60.0;
autoGain.headroomDb.value = 3.0;
```

## Traps & Gotchas

- **Out-of-range sets are silently clamped**: Parameter values set outside `[min, max]` are rejected without throwing exceptions. Check `query<Param>.min/max` bounds.
- **Metrics are read-only**: Calling setter on a `FilterMetric` is not supported.
- **Deinitialization resets filters**: Re-initializing the recorder with `deinit()` + `init()` resets active filters. Re-activate with `autoGain.activate()` after re-initialization.
- **Experimental Feature**: The filter API is marked `@experimental` and may be refined in future releases.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
