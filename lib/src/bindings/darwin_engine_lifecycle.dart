import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// What came of asking the iOS or macOS plugin to claim the native engine.
enum DarwinEnginePrepareResult {
  /// The plugin took the native lifecycle claim.
  claimed,

  /// The channel could not be used at all, so nothing was claimed.
  unavailable,

  /// The plugin refused or the outcome is unknown.
  refused,
}

/// Hands the iOS or macOS plugin the engine id it cannot obtain for itself.
class DarwinEngineLifecycle {
  /// Creates a bridge over the plugin's engine-local lifecycle channel.
  const DarwinEngineLifecycle();

  static final Logger _log = Logger('flutter_recorder.DarwinEngineLifecycle');

  /// The plugin's engine-local channel name.
  @visibleForTesting
  static const String channelName = 'flutter_recorder/engine_lifecycle';

  /// Whether this platform runs the Darwin lifecycle plugin.
  static bool get isSupported =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Asks the plugin to adopt [engineId] and claim the native engine, valid
  /// only while the native shutdown epoch is still [shutdownEpoch].
  Future<DarwinEnginePrepareResult> prepareEngineInit(
    int engineId,
    int shutdownEpoch,
  ) async {
    if (!isSupported) return DarwinEnginePrepareResult.unavailable;

    final BinaryMessenger messenger;
    try {
      messenger = ServicesBinding.instance.defaultBinaryMessenger;
    } on Object catch (error) {
      _log.warning(
        'Flutter messaging is not available, so automatic FlutterEngine '
        'teardown cannot be armed; initializing directly instead.',
        error,
      );
      return DarwinEnginePrepareResult.unavailable;
    }

    final channel = MethodChannel(
      channelName,
      const StandardMethodCodec(),
      messenger,
    );

    try {
      final claimed = await channel.invokeMethod<bool>('prepareEngineInit', {
        'engineId': engineId,
        'shutdownEpoch': shutdownEpoch,
      });
      if (claimed ?? false) return DarwinEnginePrepareResult.claimed;

      _log.warning('The lifecycle plugin did not claim engine $engineId.');
      return DarwinEnginePrepareResult.refused;
    } on MissingPluginException catch (error) {
      _log.warning(
        'The lifecycle plugin is not registered, so automatic '
        'FlutterEngine teardown cannot be armed; initializing directly '
        'instead.',
        error,
      );
      return DarwinEnginePrepareResult.unavailable;
    } on Object catch (error, stackTrace) {
      _log.warning(
        'The lifecycle handshake for engine $engineId failed after the '
        'request was sent; abandoning this initialization rather than risking '
        'a duplicate native claim.',
        error,
        stackTrace,
      );
      return DarwinEnginePrepareResult.refused;
    }
  }
}
