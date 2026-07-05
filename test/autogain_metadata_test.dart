import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoGainEnum', () {
    test('uses stable native parameter indices', () {
      expect(AutoGainEnum.targetRms.index, 0);
      expect(AutoGainEnum.attackTime.index, 1);
      expect(AutoGainEnum.releaseTime.index, 2);
      expect(AutoGainEnum.gainSmoothing.index, 3);
      expect(AutoGainEnum.maxGain.index, 4);
      expect(AutoGainEnum.minGain.index, 5);
      expect(AutoGainEnum.noiseFloorDb.index, 6);
      expect(AutoGainEnum.headroomDb.index, 7);
      expect(AutoGainEnum.currentGain.index, 8);
      expect(AutoGainEnum.inputRms.index, 9);
      expect(AutoGainEnum.outputPeak.index, 10);
      expect(AutoGainEnum.limiterClipCount.index, 11);
      expect(AutoGainEnum.totalLimiterClipCount.index, 12);
      expect(AutoGainEnum.lastFrameCount.index, 13);
    });

    test('matches the filter parameter count', () {
      expect(
        RecorderFilterType.autogain.numParameters,
        AutoGainEnum.values.length,
      );
    });

    test('separates writable parameters from runtime metrics', () {
      expect(AutoGainEnum.noiseFloorDb.isWritable, isTrue);
      expect(AutoGainEnum.headroomDb.isWritable, isTrue);
      expect(AutoGainEnum.currentGain.isWritable, isFalse);
      expect(AutoGainEnum.inputRms.isWritable, isFalse);
      expect(AutoGainEnum.outputPeak.isWritable, isFalse);
      expect(AutoGainEnum.limiterClipCount.isWritable, isFalse);
      expect(AutoGainEnum.totalLimiterClipCount.isWritable, isFalse);
      expect(AutoGainEnum.lastFrameCount.isWritable, isFalse);
    });
  });
}
