import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_recorder/src/bindings/darwin_engine_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bridge = DarwinEngineLifecycle();
  const engineId = 1234;
  const shutdownEpoch = 7;

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(DarwinEngineLifecycle.channelName),
          null,
        );
  });

  void handleWith(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(DarwinEngineLifecycle.channelName),
          (call) {
            calls.add(call);
            return handler(call);
          },
        );
  }

  test('a successful claim reports claimed and carries the epoch', () async {
    handleWith((call) async => true);

    final result = await bridge.prepareEngineInit(engineId, shutdownEpoch);

    expect(result, DarwinEnginePrepareResult.claimed);
    expect(calls.single.method, 'prepareEngineInit');
    expect(calls.single.arguments, <String, Object?>{
      'engineId': engineId,
      'shutdownEpoch': shutdownEpoch,
    });
  });

  test(
    'an explicit plugin refusal never falls back to a direct claim',
    () async {
      for (final code in <String>[
        'stale_prepare',
        'engine_detached',
        'invalid_engine_id',
        'invalid_arguments',
      ]) {
        calls.clear();
        handleWith((call) async => throw PlatformException(code: code));

        final result = await bridge.prepareEngineInit(engineId, shutdownEpoch);

        expect(
          result,
          DarwinEnginePrepareResult.refused,
          reason: '$code must not be mistaken for an unusable channel',
        );
      }
    },
  );

  test('a reply that is not true is a refusal, not a fallback', () async {
    handleWith((call) async => false);

    expect(
      await bridge.prepareEngineInit(engineId, shutdownEpoch),
      DarwinEnginePrepareResult.refused,
    );
  });

  test('an unknown failure after sending is refused, not retried', () async {
    handleWith((call) async => throw StateError('the reply went missing'));

    expect(
      await bridge.prepareEngineInit(engineId, shutdownEpoch),
      DarwinEnginePrepareResult.refused,
    );
  });

  test('an unregistered plugin is unavailable, so init still works', () async {
    expect(
      await bridge.prepareEngineInit(engineId, shutdownEpoch),
      DarwinEnginePrepareResult.unavailable,
    );
  });

  test('macOS uses the same handshake as iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    handleWith((call) async => true);

    expect(
      await bridge.prepareEngineInit(engineId, shutdownEpoch),
      DarwinEnginePrepareResult.claimed,
    );
    expect(calls.single.arguments, <String, Object?>{
      'engineId': engineId,
      'shutdownEpoch': shutdownEpoch,
    });
  });

  test('platforms without the plugin never touch the channel', () async {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      calls.clear();
      debugDefaultTargetPlatformOverride = platform;
      handleWith((call) async => true);

      expect(
        await bridge.prepareEngineInit(engineId, shutdownEpoch),
        DarwinEnginePrepareResult.unavailable,
        reason: '$platform has no lifecycle plugin to hand the engine id to',
      );
      expect(calls, isEmpty, reason: '$platform must not send anything');
    }
  });
}
