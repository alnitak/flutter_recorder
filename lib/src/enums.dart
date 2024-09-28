/// CaptureDevice exposed to Dart
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
