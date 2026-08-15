import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OpenSL capture stops before queued input buffers are discarded', () {
    final source = File('src/miniaudio.h').readAsStringSync();
    final stopFunctionStart = source.indexOf(
      'static ma_result ma_device_stop__opensl(ma_device* pDevice)',
    );
    final stopFunctionEnd = source.indexOf(
      'static ma_result ma_context_uninit__opensl',
      stopFunctionStart,
    );

    expect(stopFunctionStart, greaterThanOrEqualTo(0));
    expect(stopFunctionEnd, greaterThan(stopFunctionStart));

    final stopFunction = source.substring(stopFunctionStart, stopFunctionEnd);
    final playbackBranchStart = stopFunction.indexOf(
      'if (pDevice->type == ma_device_type_playback',
    );
    expect(playbackBranchStart, greaterThanOrEqualTo(0));

    final captureBranch = stopFunction.substring(0, playbackBranchStart);
    final stopCapture = captureBranch.indexOf('SL_RECORDSTATE_STOPPED');
    final clearCapture = captureBranch.indexOf('pBufferQueueCapture)->Clear');

    expect(
      captureBranch,
      isNot(contains('ma_device_drain__opensl')),
      reason: 'A stalled capture queue must not block device shutdown.',
    );
    expect(stopCapture, greaterThanOrEqualTo(0));
    expect(clearCapture, greaterThan(stopCapture));

    final playbackBranch = stopFunction.substring(playbackBranchStart);
    expect(
      playbackBranch,
      contains('ma_device_drain__opensl(pDevice, ma_device_type_playback)'),
      reason: 'Playback data must retain its existing drain behavior.',
    );
  });
}
