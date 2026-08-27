import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native capture callback respects the configured PCM sample width', () {
    final source = File('src/capture.cpp').readAsStringSync();
    final callbackStart = source.indexOf('void data_callback(');
    final callbackEnd = source.indexOf(
      '// /////////////////////////////',
      callbackStart,
    );

    expect(callbackStart, greaterThanOrEqualTo(0));
    expect(callbackEnd, greaterThan(callbackStart));

    final callback = source.substring(callbackStart, callbackEnd);
    expect(callback, contains('void *captured = const_cast<void *>(pInput);'));
    expect(callback, contains('copyCaptureWaveformBuffer('));
    expect(
      callback,
      isNot(contains('sizeof(float) * frameCount')),
      reason: 'Non-float PCM input must never be copied with float width.',
    );
  });

  test('guarded non-float input is not read as float waveform data', () async {
    if (Platform.isWindows) {
      return;
    }

    final tempDirectory = await Directory.systemTemp.createTemp(
      'flutter_recorder_capture_input_format_',
    );
    final executable = File('${tempDirectory.path}/capture_input_format_test');
    try {
      final compile = await Process.run('c++', [
        '-std=c++17',
        '-Wall',
        '-Wextra',
        '-Werror',
        '-Isrc',
        'test/cpp/capture_waveform_buffer_test.cpp',
        '-o',
        executable.path,
      ]);
      expect(
        compile.exitCode,
        0,
        reason: '${compile.stdout}\n${compile.stderr}',
      );

      final run = await Process.run(executable.path, const []);
      expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  });
}
