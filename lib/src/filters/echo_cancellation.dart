import 'package:flutter_recorder/src/filters/filters.dart';

/// Parameters for the SpeexDSP [EchoCancellation] filter.
enum EchoCancellationEnum {
  /// Echo filter tail length in milliseconds (10 to 500 ms).
  filterLengthMs,

  /// Whether residual echo suppression and noise reduction are enabled
  /// (0 or 1).
  denoiseEnabled,

  /// Maximum suppression and denoise level in dB (-60 to 0 dB).
  denoiseLevelDb;

  final List<double> _defs = const [150, 1, -30];
  final List<double> _mins = const [10, 0, -60];
  final List<double> _maxs = const [500, 1, 0];

  /// Minimum value allowed for this parameter.
  double get min => _mins[index];

  /// Maximum value allowed for this parameter.
  double get max => _maxs[index];

  /// Default value for this parameter.
  double get def => _defs[index];

  @override
  String toString() => switch (this) {
    EchoCancellationEnum.filterLengthMs => 'Filter Length (ms)',
    EchoCancellationEnum.denoiseEnabled => 'Denoise Enabled',
    EchoCancellationEnum.denoiseLevelDb => 'Denoise Level (dB)',
  };
}

abstract class _EchoCancellationInternal extends FilterBase {
  const _EchoCancellationInternal()
    : super(RecorderFilterType.echoCancellation);

  EchoCancellationEnum get queryFilterLengthMs =>
      EchoCancellationEnum.filterLengthMs;
  EchoCancellationEnum get queryDenoiseEnabled =>
      EchoCancellationEnum.denoiseEnabled;
  EchoCancellationEnum get queryDenoiseLevelDb =>
      EchoCancellationEnum.denoiseLevelDb;
}

/// SpeexDSP Acoustic Echo Cancellation (AEC) filter.
///
/// Removes loudspeaker acoustic feedback and room reverberation picked up by
/// the microphone.
///
/// ### Operation Modes & Use Cases:
///
/// #### 1. Native Duplex Loopback (Karaoke / Sidetone)
/// Enable native loopback via `Recorder.instance.setLoopback(enable: true)`.
/// - **Karaoke & In-Ear Monitoring**: The singer's voice is routed directly to
///   headphones with minimum hardware latency (< 15ms), while AEC cancels
///   loudspeaker or headphone bleed from the recorded/streamed track.
/// - **Live Mic Sidetone**: Provides confidence monitoring for podcasters and
///   broadcasters.
///
/// #### 2. External Playback Reference (VoIP / Gaming / Smart Assistants)
/// Keep native loopback disabled and feed loudspeaker audio frames via
/// `Recorder.instance.feedPlaybackData(...)` (or `flutter_soloud` mixer output
/// capture):
/// - **VoIP & Video Conferencing**: Remote party voices played via the device
///   loudspeaker are subtracted from the local microphone, eliminating
///   annoying echoes on the remote end.
/// - **Gaming with Voice Chat**: Game sounds and music played via
///   `flutter_soloud` are captured using `soloud.startMixerOutputStream()` and
///   fed into AEC so teammates hear clear voice without background game noise.
/// - **Voice Assistants (Barge-In)**: The device can play spoken responses or
///   music while listening for user wake words without triggering itself.
class EchoCancellation extends _EchoCancellationInternal {
  /// Creates a new [EchoCancellation] filter instance.
  const EchoCancellation() : super();

  /// Echo filter tail length in milliseconds (10 to 500 ms, default 150 ms).
  ///
  /// Represents the acoustic memory of room reflections. Larger rooms or
  /// higher speaker volumes benefit from longer filter lengths (150–300 ms),
  /// while headsets require only 10–50 ms.
  FilterParam get filterLengthMs => FilterParam(
    filterType,
    EchoCancellationEnum.filterLengthMs.index,
    EchoCancellationEnum.filterLengthMs.min,
    EchoCancellationEnum.filterLengthMs.max,
  );

  /// Enables or disables residual echo suppression and noise reduction
  /// (0 = disabled, 1 = enabled, default 1).
  FilterParam get denoiseEnabled => FilterParam(
    filterType,
    EchoCancellationEnum.denoiseEnabled.index,
    EchoCancellationEnum.denoiseEnabled.min,
    EchoCancellationEnum.denoiseEnabled.max,
  );

  /// Maximum suppression and denoise level in dB (-60 to 0 dB, default -30 dB).
  ///
  /// More negative values provide stronger residual echo suppression.
  FilterParam get denoiseLevelDb => FilterParam(
    filterType,
    EchoCancellationEnum.denoiseLevelDb.index,
    EchoCancellationEnum.denoiseLevelDb.min,
    EchoCancellationEnum.denoiseLevelDb.max,
  );
}
