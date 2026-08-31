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

  /// Number of bytes per sample for this format.
  int get sampleSize => switch (this) {
    u8 => 1,
    s16le => 2,
    s24le => 3,
    s32le || f32le => 4,
  };

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
/// Maps to Android `AAUDIO_INPUT_PRESET_*` / `OpenSL ES` hardware recording
/// presets to configure device DSP and hardware audio preprocessors.
///
/// This is only applied on Android. Other platforms accept the value but
/// ignore it.
enum AndroidInputPreset {
  /// Standard Android generic capture preset (`AAUDIO_INPUT_PRESET_GENERIC`).
  ///
  /// - **Hardware Filters:** Standard OEM audio processing.
  generic(1),

  /// Camcorder capture preset (`AAUDIO_INPUT_PRESET_CAMCORDER`).
  ///
  /// - **Hardware Filters:** Tuned for video recording directionality and
  ///   ambient sound balance.
  camcorder(2),

  /// Voice recognition preset (`AAUDIO_INPUT_PRESET_VOICE_RECOGNITION`).
  ///
  /// - **Hardware Filters:** Tuned for automatic speech recognition (ASR) with
  ///   minimal AGC and high-pass filtering.
  /// - **Best for:** Speech-to-text, voice assistants.
  voiceRecognition(3),

  /// Voice communication preset (`AAUDIO_INPUT_PRESET_VOICE_COMMUNICATION`).
  ///
  /// - **Hardware Filters:** Enables hardware **Acoustic Echo Cancellation
  ///   (AEC)**, **Automatic Gain Control (AGC)**, and **Noise Suppression
  ///   (NS)** handled by the device OEM audio HAL.
  /// - **Best for:** VoIP, voice calls, two-way communication.
  voiceCommunication(4),

  /// Unprocessed capture preset (`AAUDIO_INPUT_PRESET_UNPROCESSED`).
  ///
  /// - **Hardware Filters:** **Completely disables** all OEM DSP, noise
  ///   suppressors, and AGC to deliver clean, uncolored, raw PCM audio data.
  /// - **Best for:** Custom DSP filters (e.g. `AutoGainFilter`,
  ///   `EchoCancellationFilter`), audio measurement, music recording.
  unprocessed(5);

  const AndroidInputPreset(this.value);

  /// Internal value passed to the native recorder.
  final int value;
}

/// iOS capture input presets.
///
/// Configures the iOS system `AVAudioSession` category and mode to enable or
/// disable hardware-level audio processing (such as Apple's hardware Voice
/// Processing Acoustic Echo Cancellation, Automatic Gain Control, and
/// measurement mode) without requiring external audio session management.
///
/// This is only applied on iOS. Other platforms accept the value but ignore it.
enum IosInputPreset {
  /// Standard iOS capture preset (`AVAudioSessionModeDefault`).
  ///
  /// - **Hardware Filters:** Standard Apple system voice processing.
  generic(1),

  /// Voice communication preset (`AVAudioSessionModeVoiceChat`).
  ///
  /// - **Hardware Filters:** Enables Apple's hardware **Acoustic Echo
  ///   Cancellation (AEC)**, **Automatic Gain Control (AGC)**, and voice EQ
  ///   processing.
  /// - **Best for:** VoIP, video calls, two-way voice chat.
  voiceCommunication(2),

  /// Video chat preset (`AVAudioSessionModeVideoChat`).
  ///
  /// - **Hardware Filters:** Enables Apple's hardware **Acoustic Echo
  ///   Cancellation (AEC)** optimized for video chat and loudspeaker output.
  /// - **Best for:** Video conferencing, camera-based recording.
  videoChat(3),

  /// Speech recognition preset (`AVAudioSessionModeSpokenAudio`).
  ///
  /// - **Hardware Filters:** Tuned for speech recognition and spoken audio with
  ///   minimal aggressive filtering.
  /// - **Best for:** ASR, dictation, voice commands.
  speechRecognition(4),

  /// Unprocessed / measurement preset (`AVAudioSessionModeMeasurement`).
  ///
  /// - **Hardware Filters:** **Completely disables** AGC, high-pass filtering,
  ///   and preprocessing to provide clean, raw, uncolored audio data.
  /// - **Best for:** Custom DSP filters, acoustic measurement, audio analysis.
  unprocessed(5);

  const IosInputPreset(this.value);

  /// Internal value passed to the native recorder.
  final int value;
}

/// Web Audio capture input presets for browser-level audio preprocessing.
///
/// Configures browser `MediaTrackConstraints` (`echoCancellation`,
/// `autoGainControl`, `noiseSuppression`) at stream initialization time
/// (`getUserMedia`).
///
/// This is only applied on Web. Other platforms accept the value but ignore it.
enum WebInputPreset {
  /// Raw, unprocessed microphone capture.
  ///
  /// - **Browser Filters:**
  ///   - `echoCancellation: false`
  ///   - `autoGainControl: false`
  ///   - `noiseSuppression: false`
  /// - **Best for:** Custom software DSP filters (such as `flutter_recorder`'s
  ///   `AutoGainFilter` and `EchoCancellationFilter`), audio analysis,
  ///   music, and loopback setups where browser AGC pumping must be avoided.
  unprocessed(0),

  /// Full voice communication preset.
  ///
  /// - **Browser Filters:**
  ///   - `echoCancellation: true`
  ///   - `autoGainControl: true`
  ///   - `noiseSuppression: true`
  /// - **Best for:** Voice chat, VoIP, video conferencing.
  voiceCommunication(1),

  /// Speech recognition preset.
  ///
  /// - **Browser Filters:**
  ///   - `echoCancellation: false`
  ///   - `autoGainControl: true`
  ///   - `noiseSuppression: true`
  /// - **Best for:** Voice search, speech-to-text, dictation.
  voiceRecognition(2),

  /// Noise suppression only.
  ///
  /// - **Browser Filters:**
  ///   - `echoCancellation: false`
  ///   - `autoGainControl: false`
  ///   - `noiseSuppression: true`
  /// - **Best for:** Removing stationary fan/background noise without AGC.
  noiseSuppression(3),

  /// Acoustic echo cancellation only.
  ///
  /// - **Browser Filters:**
  ///   - `echoCancellation: true`
  ///   - `autoGainControl: false`
  ///   - `noiseSuppression: false`
  /// - **Best for:** Preventing speaker feedback loop without dynamic AGC.
  echoCancellation(4);

  const WebInputPreset(this.value);

  /// Internal value.
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

/// The kind of visualization data to compute and emit.
enum VisualizationKind {
  /// Time-domain waveform only.
  wave(0),

  /// Frequency-domain FFT only.
  fft(1),

  /// Both waveform and FFT data.
  waveAndFft(2);

  const VisualizationKind(this.value);

  /// The internal integer representation.
  final int value;
}

/// Constants for visualization channel selection.
abstract final class VisualizationChannel {
  /// Downmix all input channels into a single mono channel.
  static const int merged = -1;

  /// Output all input channels individually.
  static const int all = -2;
}

/// Device notification and microphone lifecycle events emitted by the native
/// audio engine.
enum RecorderDeviceNotification {
  /// The audio capture device has started running.
  started(0),

  /// The audio capture device has stopped running (either requested or due to
  /// hardware/OS changes).
  stopped(1),

  /// The audio stream was rerouted (e.g. headset plugged/unplugged, system
  /// audio routing change).
  rerouted(2),

  /// An OS-level audio interruption began (e.g. incoming phone call, alarm,
  /// Siri on iOS).
  interruptionBegan(3),

  /// An OS-level audio interruption ended.
  interruptionEnded(4),

  /// The audio device lock was released.
  unlocked(5);

  const RecorderDeviceNotification(this.value);

  /// The internal integer representation.
  final int value;

  /// Create a [RecorderDeviceNotification] from an internal value.
  static RecorderDeviceNotification fromValue(int value) => switch (value) {
    0 => started,
    1 => stopped,
    2 => rerouted,
    3 => interruptionBegan,
    4 => interruptionEnded,
    5 => unlocked,
    _ => throw ArgumentError(
      'Unknown value for RecorderDeviceNotification: $value',
    ),
  };
}
