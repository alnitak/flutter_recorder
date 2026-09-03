---
name: flutter-recorder-visualization
version: 1
description: Teaches how to capture real-time audio visualization data (time-domain waveforms, frequency-domain FFT spectrum bins, and volume in dB), configure PFFFT window sizes, apply FFT smoothing, and render waveform, spectrum bar, and VU meter CustomPainters. Use when the user asks to build an audio visualizer, frequency spectrum analyzer, oscilloscope waveform, or VU volume meter.
---

# flutter_recorder audio visualization

`flutter_recorder` features a high-performance, SIMD-accelerated (via PFFFT) audio analysis engine with Blackman windowing and exponential frequency smoothing. It delivers time-domain waveform samples and frequency-domain FFT magnitude bins in real time.

## Minimal example

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

Future<void> setupVisualization() async {
  final recorder = Recorder.instance;

  // 1. MUST initialize with PCMFormat.f32le
  await recorder.init(
    format: PCMFormat.f32le,
    sampleRate: 44100,
    channels: RecorderChannels.mono,
  );
  recorder.start();

  // 2. Configure visualization engine
  recorder.setVisualizationEnabled(
    true,
    windowSize: 512,                     // Power of 2 (128..8192)
    kind: VisualizationKind.waveAndFft,  // wave, fft, or waveAndFft
    channel: VisualizationChannel.merged,// mono downmix or channel index
  );

  // 3. Optional: Configure FFT smoothing for calmer animations
  recorder.setFftSmoothing(0.6); // 0.0 = instant, 1.0 = frozen

  // 4. Listen to visualization events
  recorder.audioVisualizationEvents.listen((AudioVisualizationData data) {
    // Waveform samples: values in range [-1.0, 1.0]
    final Float32List? wave = data.waveData;

    // FFT frequency bins: values in range [0.0, 1.0] (length: windowSize / 2)
    final Float32List? fft = data.fftData;

    // Volume level in dB: [-100, 0]
    final double volumeDb = recorder.getVolumeDb();
  });
}
```

## The API Shape

All visualization APIs live on `Recorder.instance`:

- `void setVisualizationEnabled(bool enabled, {int windowSize = 256, VisualizationKind kind = VisualizationKind.waveAndFft, int channel = VisualizationChannel.merged})`: Starts or stops visual analysis.
  - `windowSize`: Power of 2 between 128 and 8192 (128, 256, 512, 1024, 2048, 4096, 8192).
  - `kind`: `VisualizationKind.wave`, `VisualizationKind.fft`, or `VisualizationKind.waveAndFft`.
  - `channel`: `VisualizationChannel.merged` (-1 mono downmix), `VisualizationChannel.all` (-2), or 0-indexed channel.
- `bool getVisualizationEnabled()`: Checks whether visual analysis is active.
- `Stream<AudioVisualizationData> get audioVisualizationEvents`: Emits analysis packets containing waveform and FFT data.
- `void setVisualizationCallback(void Function(AudioVisualizationData data)? callback)`: Direct callback alternative to `audioVisualizationEvents`.
- `void setFftSmoothing(double smooth)`: Smooths decreasing FFT values (0.0 to 1.0). `0.0` means immediate response; `0.6` provides natural bar decay.
- `double getVolumeDb()`: Computes instantaneous RMS volume in dB `[-100, 0]`.

### Data Object: `AudioVisualizationData`
- `int channelCount`: Number of audio channels in this packet.
- `List<Float32List> wave`: Waveform buffers per channel (`[-1.0, 1.0]`).
- `List<Float32List> fft`: FFT magnitude buffers per channel (`[0.0, 1.0]`, length `windowSize / 2`).
- `Float32List? get waveData`: First/merged channel waveform.
- `Float32List? get fftData`: First/merged channel FFT bins.

## UI Recipe: Frequency Spectrum Painter (CustomPainter)

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

class SpectrumVisualizer extends StatelessWidget {
  const SpectrumVisualizer({super.key, required this.data});

  final AudioVisualizationData? data;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: FftBarsPainter(data?.fftData),
    );
  }
}

class FftBarsPainter extends CustomPainter {
  FftBarsPainter(this.fft);

  final Float32List? fft;

  @override
  void paint(Canvas canvas, Size size) {
    if (fft == null || fft!.isEmpty) return;

    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    const barCount = 32; // Aggregate bins into 32 visible bars
    final binStep = fft!.length ~/ barCount;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      double maxMagnitude = 0.0;
      for (int b = 0; b < binStep; b++) {
        final binIdx = i * binStep + b;
        if (binIdx < fft!.length && fft![binIdx] > maxMagnitude) {
          maxMagnitude = fft![binIdx];
        }
      }

      final barHeight = (maxMagnitude * size.height).clamp(2.0, size.height);
      final left = i * barWidth;
      final top = size.height - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left + 1, top, barWidth - 2, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FftBarsPainter oldDelegate) => true;
}
```

## UI Recipe: Oscilloscope Waveform Painter

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter(this.wave);

  final Float32List? wave;

  @override
  void paint(Canvas canvas, Size size) {
    if (wave == null || wave!.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = size.width / wave!.length;
    final centerY = size.height / 2;

    for (int i = 0; i < wave!.length; i++) {
      final x = i * step;
      final y = centerY + (wave![i] * centerY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
```

## UI Recipe: VU Volume Meter

```dart
import 'package:flutter/material.dart';

class VuMeterWidget extends StatelessWidget {
  const VuMeterWidget({super.key, required this.volumeDb});

  final double volumeDb; // e.g. -100 to 0 dB

  @override
  Widget build(BuildContext context) {
    // Normalize -60 dB .. 0 dB into 0.0 .. 1.0
    final normalized = ((volumeDb + 60) / 60).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: normalized,
          backgroundColor: Colors.grey.shade800,
          color: normalized > 0.85
              ? Colors.red
              : (normalized > 0.6 ? Colors.amber : Colors.green),
          minHeight: 12,
        ),
        Text('${volumeDb.toStringAsFixed(1)} dB'),
      ],
    );
  }
}
```

## Traps & Gotchas

- **Requires `PCMFormat.f32le`**: Setting visualization with any format other than `PCMFormat.f32le` is ignored with a warning.
- **Window sizes must be powers of 2**: `windowSize` must be in `[128, 256, 512, 1024, 2048, 4096, 8192]`. 256 or 512 is recommended for 60fps UI visualizers.
- **`audioVisualizationEvents` frequency**: Events are emitted periodically as new FFT windows fill. Use `RepaintBoundary` around CustomPainters to avoid repainting surrounding UI trees.
- **Decibel range**: `getVolumeDb()` returns `-100.0` when capture is inactive or silent.

## Keeping this skill current

This skill ships inside the flutter_recorder package. To check for updates, run:

```sh
dart run flutter_recorder:skills --check
```
