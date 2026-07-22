// ignore_for_file: sort_constructors_first, public_member_api_docs

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
  failedToWriteWav(6),

  /// Filter not found
  filterNotFound(7),

  /// The filter has already been added.
  filterAlreadyAdded(8),

  /// Error getting filter parameter.
  filterParameterGetError(9);

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
        7 => filterNotFound,
        8 => filterAlreadyAdded,
        9 => filterParameterGetError,
        _ => throw ArgumentError('Unknown value for CaptureErrors: $value'),
      };
}

/// The channels to be used while initializing the player.
enum RecorderChannels {
  /// One channel.
  mono(1),

  /// Two channels.
  stereo(2);

  const RecorderChannels(this.count);

  /// The channels count.
  final int count;
}

/// The PCM format
enum PCMFormat {
  /// 8-bit unsigned.
  u8(0),

  /// 16-bit signed, little-endian.
  s16le(1),

  /// 24-bit signed, little-endian.
  s24le(2),

  /// 32-bit signed, little-endian.
  s32le(3),

  /// 32-bit float, little-endian.
  f32le(4);

  final int value;

  const PCMFormat(this.value);

  static PCMFormat fromValue(int value) => switch (value) {
        0 => u8,
        1 => s16le,
        2 => s24le,
        3 => s32le,
        4 => f32le,
        _ => throw ArgumentError('Unknown value for PCMFormat: $value'),
      };
}

/// Android capture input presets.
///
/// This is only applied on Android. Other platforms accept the value but
/// ignore it.
enum AndroidInputPreset {
  /// Android generic capture preset.
  generic(1),

  /// Android camcorder capture preset.
  camcorder(2),

  /// Android voice recognition capture preset.
  voiceRecognition(3),

  /// Android voice communication capture preset.
  voiceCommunication(4),

  /// Android unprocessed capture preset.
  unprocessed(5);

  const AndroidInputPreset(this.value);

  /// Internal value passed to the native recorder.
  final int value;
}

/// The format used when recording to a file.
enum RecordingFormat {
  /// WAV PCM file.
  wav(0),

  /// Ogg Opus file.
  opusOgg(1);

  const RecordingFormat(this.value);

  /// Internal value passed to the native recorder.
  final int value;

  static RecordingFormat fromValue(int value) => switch (value) {
        0 => wav,
        1 => opusOgg,
        _ => throw ArgumentError('Unknown value for RecordingFormat: $value'),
      };
}

/// The format used when streaming audio data.
enum StreamingFormat {
  /// Raw PCM data.
  pcm(0),

  /// Opus packets. Each packet is length-prefixed with a 4-byte
  /// little-endian integer.
  opus(1);

  const StreamingFormat(this.value);

  /// Internal value passed to the native recorder.
  final int value;

  static StreamingFormat fromValue(int value) => switch (value) {
        0 => pcm,
        1 => opus,
        _ => throw ArgumentError('Unknown value for StreamingFormat: $value'),
      };
}
