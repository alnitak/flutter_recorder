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

  group('IosInputPreset', () {
    test('uses stable native values', () {
      expect(IosInputPreset.generic.value, 1);
      expect(IosInputPreset.voiceCommunication.value, 2);
      expect(IosInputPreset.videoChat.value, 3);
      expect(IosInputPreset.speechRecognition.value, 4);
      expect(IosInputPreset.unprocessed.value, 5);
    });

    test('maps null to the native default value', () {
      const IosInputPreset? iosInputPreset = null;

      expect(iosInputPreset?.value ?? 0, 0);
    });
  });

  group('WebInputPreset', () {
    test('uses stable values', () {
      expect(WebInputPreset.unprocessed.value, 0);
      expect(WebInputPreset.voiceCommunication.value, 1);
      expect(WebInputPreset.voiceRecognition.value, 2);
      expect(WebInputPreset.noiseSuppression.value, 3);
      expect(WebInputPreset.echoCancellation.value, 4);
    });
  });
}
