import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidInputPreset', () {
    test('uses stable native values', () {
      expect(AndroidInputPreset.generic.value, 1);
      expect(AndroidInputPreset.camcorder.value, 2);
      expect(AndroidInputPreset.voiceRecognition.value, 3);
      expect(AndroidInputPreset.voiceCommunication.value, 4);
      expect(AndroidInputPreset.unprocessed.value, 5);
    });

    test('maps null to the native default value', () {
      const AndroidInputPreset? androidInputPreset = null;

      expect(androidInputPreset?.value ?? 0, 0);
    });
  });
}
