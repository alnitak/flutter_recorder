import 'dart:typed_data';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisualizationKind', () {
    test('uses stable native values', () {
      expect(VisualizationKind.wave.value, 0);
      expect(VisualizationKind.fft.value, 1);
      expect(VisualizationKind.waveAndFft.value, 2);
    });
  });

  group('VisualizationChannel', () {
    test('uses expected channel selection constants', () {
      expect(VisualizationChannel.merged, -1);
      expect(VisualizationChannel.all, -2);
    });
  });

  group('AudioVisualizationData', () {
    test('handles single channel visualization data', () {
      final waveSample = Float32List.fromList([0.1, -0.2, 0.3]);
      final fftSample = Float32List.fromList([0.8, 0.4]);

      final data = AudioVisualizationData(
        channelCount: 1,
        wave: [waveSample],
        fft: [fftSample],
      );

      expect(data.channelCount, 1);
      expect(data.wave.length, 1);
      expect(data.fft.length, 1);
      expect(data.waveData, waveSample);
      expect(data.fftData, fftSample);
    });

    test('handles multi-channel visualization data', () {
      final waveL = Float32List.fromList([0.1, -0.2]);
      final waveR = Float32List.fromList([0.3, -0.4]);
      final fftL = Float32List.fromList([0.9, 0.5]);
      final fftR = Float32List.fromList([0.7, 0.2]);

      final data = AudioVisualizationData(
        channelCount: 2,
        wave: [waveL, waveR],
        fft: [fftL, fftR],
      );

      expect(data.channelCount, 2);
      expect(data.wave.length, 2);
      expect(data.fft.length, 2);
      expect(data.waveData, waveL);
      expect(data.fftData, fftL);
    });

    test('handles empty channel data gracefully', () {
      const data = AudioVisualizationData(channelCount: 0, wave: [], fft: []);

      expect(data.channelCount, 0);
      expect(data.wave, isEmpty);
      expect(data.fft, isEmpty);
      expect(data.waveData, isNull);
      expect(data.fftData, isNull);
    });
  });
}
