@TestOn('windows')
library;

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the recorder and its bundled Windows dependencies', () {
    // Calls flutter_recorder_isInited through the generated @Native binding.
    // No capture device or microphone permission is needed for this check.
    expect(Recorder.instance.isDeviceInitialized(), isFalse);
  });
}
