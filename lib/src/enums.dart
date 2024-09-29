/// CaptureDevice exposed to Dart
// ignore_for_file: sort_constructors_first, public_member_api_docs

final class CaptureDevice {
  /// Constructs a new [CaptureDevice].
  // ignore: avoid_positional_boolean_parameters
  const CaptureDevice(this.name, this.isDefault, this.id);

  /// The name of the device.
  final String name;

  /// Whether this is the default capture device.
  final bool isDefault;

  /// The ID of the device.
  final int id;
}

/// Possible capture errors
enum CaptureErrors {
  /// No error
  captureNoError(0),

  /// The capture device has failed to initialize.
  captureInitFailed(1),

  /// The capture device has not yet been initialized.
  captureNotInited(2),

  /// Failed to start the device.
  failedToStartDevice(3),

  /// Failed to initialize wav recording.
  failedToInitializeRecording(4),

  /// Invalid arguments while initializing wav recording.
  invalidArgs(5),

  /// Failed to write wav file.
  failedToWriteWav(6);

  /// Internal value
  final int value;

  /// Create a [CaptureErrors] from an internal value
  const CaptureErrors(this.value);

  static CaptureErrors fromValue(int value) => switch (value) {
        0 => captureNoError,
        1 => captureInitFailed,
        2 => captureNotInited,
        3 => failedToStartDevice,
        4 => failedToInitializeRecording,
        5 => invalidArgs,
        6 => failedToWriteWav,
        _ => throw ArgumentError('Unknown value for CaptureErrors: $value'),
      };
}
