import 'dart:async';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecorderDeviceNotification tests', () {
    test('enum values map correctly to miniaudio native integers', () {
      expect(RecorderDeviceNotification.started.value, 0);
      expect(RecorderDeviceNotification.stopped.value, 1);
      expect(RecorderDeviceNotification.rerouted.value, 2);
      expect(RecorderDeviceNotification.interruptionBegan.value, 3);
      expect(RecorderDeviceNotification.interruptionEnded.value, 4);
      expect(RecorderDeviceNotification.unlocked.value, 5);
    });

    test('fromValue resolves correct enum variants', () {
      expect(
        RecorderDeviceNotification.fromValue(0),
        RecorderDeviceNotification.started,
      );
      expect(
        RecorderDeviceNotification.fromValue(1),
        RecorderDeviceNotification.stopped,
      );
      expect(
        RecorderDeviceNotification.fromValue(2),
        RecorderDeviceNotification.rerouted,
      );
      expect(
        RecorderDeviceNotification.fromValue(3),
        RecorderDeviceNotification.interruptionBegan,
      );
      expect(
        RecorderDeviceNotification.fromValue(4),
        RecorderDeviceNotification.interruptionEnded,
      );
      expect(
        RecorderDeviceNotification.fromValue(5),
        RecorderDeviceNotification.unlocked,
      );
    });

    test('fromValue throws ArgumentError on unknown index', () {
      expect(
        () => RecorderDeviceNotification.fromValue(-1),
        throwsArgumentError,
      );
      expect(
        () => RecorderDeviceNotification.fromValue(99),
        throwsArgumentError,
      );
    });

    test(
      'deviceNotificationEvents broadcast stream delivers emitted events',
      () async {
        final controller =
            StreamController<RecorderDeviceNotification>.broadcast();
        final events = <RecorderDeviceNotification>[];

        final sub = controller.stream.listen(events.add);

        controller
          ..add(RecorderDeviceNotification.started)
          ..add(RecorderDeviceNotification.rerouted)
          ..add(RecorderDeviceNotification.interruptionBegan)
          ..add(RecorderDeviceNotification.interruptionEnded)
          ..add(RecorderDeviceNotification.stopped);

        await pumpEventQueue();

        expect(events, [
          RecorderDeviceNotification.started,
          RecorderDeviceNotification.rerouted,
          RecorderDeviceNotification.interruptionBegan,
          RecorderDeviceNotification.interruptionEnded,
          RecorderDeviceNotification.stopped,
        ]);

        await sub.cancel();
        await controller.close();
      },
    );
  });
}
