import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AEC, loopback, and device enumeration contracts', () {
    late String captureCpp;
    late String captureH;
    late String flutterRecorderCpp;

    setUpAll(() {
      captureCpp = File('src/capture.cpp').readAsStringSync();
      captureH = File('src/capture.h').readAsStringSync();
      flutterRecorderCpp = File('src/flutter_recorder.cpp').readAsStringSync();
    });

    test('Capture::init opens duplex only when native loopback is enabled', () {
      expect(captureCpp, contains('bool isDuplex = isLoopbackEnabled;'));
      expect(
        captureCpp,
        isNot(
          contains(
            'filters->isFilterActive(RecorderFilterType::echoCancellation)',
          ),
        ),
      );
      expect(captureCpp, contains('isLoopbackEnabled(false)'));
      expect(captureCpp, contains('mEnumContextInited(false)'));
    });

    test('setLoopback reinitializes open device; add/removeFilter do not', () {
      final setLoopbackStart = flutterRecorderCpp.indexOf(
        'flutter_recorder_setLoopback(bool enable)',
      );
      final setLoopbackEnd = flutterRecorderCpp.indexOf('}', setLoopbackStart);
      final setLoopbackBody = flutterRecorderCpp.substring(
        setLoopbackStart,
        setLoopbackEnd,
      );
      expect(setLoopbackBody, contains('if (capture.isLoopback() == enable)'));
      expect(setLoopbackBody, contains('if (capture.isInited())'));
      expect(setLoopbackBody, contains('capture.reinitDevice();'));

      final addFilterStart = flutterRecorderCpp.indexOf(
        'flutter_recorder_addFilter(enum RecorderFilterType filterType)',
      );
      final addFilterEnd = flutterRecorderCpp.indexOf('}', addFilterStart);
      expect(
        flutterRecorderCpp.substring(addFilterStart, addFilterEnd),
        isNot(contains('reinitDevice')),
      );

      final removeFilterStart = flutterRecorderCpp.indexOf(
        'flutter_recorder_removeFilter(enum RecorderFilterType filterType)',
      );
      final removeFilterEnd = flutterRecorderCpp.indexOf(
        '}',
        removeFilterStart,
      );
      expect(
        flutterRecorderCpp.substring(removeFilterStart, removeFilterEnd),
        isNot(contains('reinitDevice')),
      );
    });

    test(
      'listCaptureDevices reuses mEnumContext and avoids AVAudioSession',
      () {
        expect(captureH, contains('ma_context mEnumContext;'));
        expect(captureH, contains('bool mEnumContextInited;'));
        expect(captureH, contains('ma_device_id mCaptureDeviceId;'));

        expect(captureCpp, contains('if (!mEnumContextInited)'));
        expect(
          captureCpp,
          contains('ma_context_init(NULL, 0, &contextConfig, &mEnumContext)'),
        );
        expect(captureCpp, contains('ma_context_get_devices(&mEnumContext,'));
        expect(
          captureCpp,
          contains('contextConfig.coreaudio.noAudioSessionActivate = true;'),
        );
        expect(
          captureCpp,
          contains('contextConfig.coreaudio.noAudioSessionDeactivate = true;'),
        );
      },
    );

    test(
      'init copies mCaptureDeviceId, validates negative IDs, and frees names',
      () {
        expect(
          captureCpp,
          contains(
            'bool found = deviceID >= 0 && deviceID < (int)devices.size();',
          ),
        );
        expect(
          captureCpp,
          contains('mCaptureDeviceId = pCaptureInfos[deviceID].id;'),
        );
        expect(
          captureCpp,
          contains('deviceConfig.capture.pDeviceID = &mCaptureDeviceId;'),
        );
      },
    );

    test(
      'flutter_recorder_listCaptureDevices checks length first and frees names',
      () {
        final fnStart = flutterRecorderCpp.indexOf(
          'flutter_recorder_listCaptureDevices(',
        );
        final fnEnd = flutterRecorderCpp.indexOf(
          'flutter_recorder_freeListCaptureDevices(',
          fnStart,
        );
        final fnBody = flutterRecorderCpp.substring(fnStart, fnEnd);

        final lenCheckIdx = fnBody.indexOf('if (strlen(d[i].name) <= 5)');
        final charLoopIdx = fnBody.indexOf('for (int n = 0; n < 5; n++)');
        expect(lenCheckIdx, greaterThanOrEqualTo(0));
        expect(charLoopIdx, greaterThan(lenCheckIdx));
        expect(fnBody, contains('free(device.name);'));
      },
    );

    test(
      'Recorder Dart API handles loopback & feedPlaybackData safely pre-init',
      () {
        final recorder = Recorder.instance;
        expect(recorder.isLoopbackEnabled(), isFalse);
        expect(() => recorder.setLoopback(enable: true), returnsNormally);
        expect(() => recorder.feedPlaybackData(Uint8List(16)), returnsNormally);
      },
    );
  });
}
