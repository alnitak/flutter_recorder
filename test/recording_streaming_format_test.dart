import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordingFormat', () {
    test('uses stable native values', () {
      expect(RecordingFormat.wav.value, 0);
      expect(RecordingFormat.opusOgg.value, 1);
    });

    test('maps values correctly', () {
      expect(RecordingFormat.fromValue(0), RecordingFormat.wav);
      expect(RecordingFormat.fromValue(1), RecordingFormat.opusOgg);
    });
  });

  group('StreamingFormat', () {
    test('uses stable native values', () {
      expect(StreamingFormat.pcm.value, 0);
      expect(StreamingFormat.opus.value, 1);
    });

    test('maps values correctly', () {
      expect(StreamingFormat.fromValue(0), StreamingFormat.pcm);
      expect(StreamingFormat.fromValue(1), StreamingFormat.opus);
    });
  });
}
