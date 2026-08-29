import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EchoCancellationEnum', () {
    test('uses stable native parameter indices', () {
      expect(EchoCancellationEnum.filterLengthMs.index, 0);
      expect(EchoCancellationEnum.denoiseEnabled.index, 1);
      expect(EchoCancellationEnum.denoiseLevelDb.index, 2);
    });

    test('matches the filter parameter count', () {
      expect(
        RecorderFilterType.echoCancellation.numParameters,
        EchoCancellationEnum.values.length,
      );
    });

    test('validates parameter range bounds', () {
      expect(EchoCancellationEnum.filterLengthMs.min, 10);
      expect(EchoCancellationEnum.filterLengthMs.max, 500);
      expect(EchoCancellationEnum.filterLengthMs.def, 150);

      expect(EchoCancellationEnum.denoiseEnabled.min, 0);
      expect(EchoCancellationEnum.denoiseEnabled.max, 1);
      expect(EchoCancellationEnum.denoiseEnabled.def, 1);

      expect(EchoCancellationEnum.denoiseLevelDb.min, -60);
      expect(EchoCancellationEnum.denoiseLevelDb.max, 0);
      expect(EchoCancellationEnum.denoiseLevelDb.def, -30);
    });
  });
}
