// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/audio_visualization_data.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// Callback when silence state is changed.
typedef SilenceCallback = void Function(bool isSilent, double decibel);

/// Silence state.
typedef SilenceState = ({bool isSilent, double decibel});

/// Use this class to _capture_ audio (such as from a microphone).
interface class Recorder {
  /// The private constructor of [Recorder]. This prevents developers from
  /// instantiating new instances.
  Recorder._();

  static final Logger _log = Logger('flutter_recorder.Recorder');

  /// The singleton instance of [Recorder]. Only one Recorder instance
  /// can exist in C++ land, so – for consistency and to avoid confusion
  /// – only one instance can exist in Dart land.
  ///
  /// Using this static field, you can get a hold of the single instance
  /// of this class from anywhere. This ability to access global state
  /// from anywhere can lead to hard-to-debug bugs, though, so it is
  /// preferable to encapsulate this and provide it through a facade.
  /// For example:
  ///
  /// ```dart
  /// final recordingController = MyRecordingController(Recorder.instance);
  ///
  /// // Now provide the recording controller to parts of the app that need it.
  /// // No other part of the codebase need import `package:flutter_recorder`.
  /// ```
  ///
  /// Alternatively, at least create a field with the single instance
  /// of [Recorder], and provide that (without the facade, but also without
  /// accessing [Recorder.instance] from different places of the app).
  /// For example:
  ///
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> {
  ///   Recorder? _recorder;
  ///
  ///   void _initializeRecording() async {
  ///     // The only place in the codebase that accesses Recorder.instance
  ///     // directly.
  ///     final recorder = Recorder.instance;
  ///     await recorder.initialize();
  ///
  ///     setState(() {
  ///       _recorder = recorder;
  ///     });
  ///   }
  ///
  ///   // ...
  /// }
  /// ```
  static final Recorder instance = Recorder._();

  /// This can be used to access all the available filter functionalities.
  ///
  /// ```dart
  /// final recorder = await Recorder.instance.init();
  /// ...
  /// /// activate the filter.
  ///recorder.filters.autoGainFilter.activate();
  ///
  /// /// Later on, deactivate it.
  /// recorder.filters.autoGainFilter.deactivate();
  /// ```
  ///
  /// It's possible to get and set filter parameters:
  /// ```dart
  /// /// Set
  /// recorder.filters.autoGainFilter.targetRms.value = 0.6;
  /// /// Get
  /// final targetRmsValue = recorder.filters.autoGainFilter.targetRms.value;
  /// ```
  ///
  /// It's possible to query filter parameters:
  /// ```dart
  /// final targetRms = recorder.filters.autoGainFilter.queryTargetRms;
  /// ```
  ///
  /// Now with `targetRms` you have access to:
  /// - `toString()` gives the "human readable" parameter name.
  /// - `min` which represent the minimum accepted value.
  /// - `max` which represent the maximum accepted value.
  /// - `def` which represent the default value.
  @experimental
  final filters = const Filters();

  final _recorder = RecorderController();

  /// Whether the device is initialized.
  bool _isInitialized = false;

  /// Whether the device is started.
  bool _isStarted = false;

  /// Currently used recorder configuration.
  PCMFormat _recorderFormat = PCMFormat.s16le;

  /// The PCM format currently used by the recorder.
  PCMFormat get recorderFormat => _recorderFormat;

  /// Listening to silence state changes.
  Stream<SilenceState> get silenceChangedEvents =>
      _recorder.impl.silenceChangedEvents;

  /// Listening to real-time audio visualization events (waveform & FFT data).
  Stream<AudioVisualizationData> get audioVisualizationEvents =>
      _recorder.impl.audioVisualizationEvents;

  /// Listening to native audio capture device notifications and lifecycle
  /// state events (e.g. device started, stopped, rerouted to another input,
  /// or interrupted by an incoming phone call on iOS).
  Stream<RecorderDeviceNotification> get deviceNotificationEvents =>
      _recorder.impl.deviceNotificationEvents;

  /// Listen to audio data.
  ///
  /// The streaming must be enabled calling [startStreamingData].
  ///
  /// **NOTE**: Audio data must be processed as it is received. To optimize
  /// performance, the same memory is used to store data for all incoming
  /// streams, meaning the data will be overwritten. Therefore, you must copy
  /// the data if you need to populate a buffer. For example, when using
  /// **RxDart.bufferTime**, it will fill a **List** of `AudioDataContainer`
  /// objects, but when you attempt to read them, you will find that all
  /// the items contain the same data.
  Stream<AudioDataContainer> get uint8ListStream =>
      _recorder.impl.uint8ListStream;

  /// Enable or disable silence detection.
  ///
  /// [enable] wheter to enable or disable silence detection. Default to false.
  /// [onSilenceChanged] callback when silence state is changed.
  ///
  /// **NOTE**: this is only available when initializing the recorder
  /// with [PCMFormat.f32le] format.
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    _recorder.impl.setSilenceDetection(
      enable: enable,
      onSilenceChanged: onSilenceChanged,
    );
  }

  /// Set silence threshold in dB.
  ///
  /// [silenceThresholdDb] the silence threshold in dB. A volume under this
  /// value is considered to be silence. Default to -40.
  ///
  /// Note on dB value:
  /// - Decibels (dB) are a relative measure. In digital audio, there is
  /// no 'absolute 0 dB level' that corresponds to absolute silence.
  /// - The 0 dB level is usually defined as the maximum possible signal level,
  /// i.e., the maximum amplitude of the signal that the system can handle
  /// without distortion.
  /// - Negative dB values indicate that the signal's energy is lower compared
  /// to this maximum.
  ///
  /// **NOTE**: this is only available when initializing the recorder
  /// with [PCMFormat.f32le] format.
  void setSilenceThresholdDb(double silenceThresholdDb) {
    _recorder.impl.setSilenceThresholdDb(silenceThresholdDb);
  }

  /// Set the value in seconds of silence after which silence is considered
  /// as such.
  ///
  /// [silenceDuration] the duration of silence in seconds. If the volume
  /// remains silent for this duration, the [SilenceCallback] callback will be
  /// triggered or the Stream [silenceChangedEvents] will emit silence state.
  /// Default to 2 seconds.
  ///
  /// **NOTE**: this is only available when initializing the recorder
  /// with [PCMFormat.f32le] format.
  void setSilenceDuration(double silenceDuration) {
    _recorder.impl.setSilenceDuration(silenceDuration);
  }

  /// Set seconds of audio to write before starting recording again after
  /// silence.
  ///
  /// [secondsOfAudioToWriteBefore] seconds of audio to write occurred before
  /// starting recording againg after silence. Default to 0 seconds.
  /// ```text
  /// |*** silence ***|******** recording *********|
  ///                 ^ start of recording
  ///             ^ secondsOfAudioToWriteBefore (write some before silence ends)
  /// ```
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    _recorder.impl.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
  }

  /// List available input devices. Useful on desktop to choose
  /// which input device to use.
  List<CaptureDevice> listCaptureDevices() {
    final ret = _recorder.impl.listCaptureDevices();

    return ret;
  }

  /// Initialize input device with [deviceID].
  ///
  /// [deviceID] the id of the input device. If -1, the default OS input
  /// device is used.
  /// [format] PCM format. Default to [PCMFormat.s16le].
  /// [sampleRate] sample rate in Hz. Default to 22050.
  /// [channels] number of channels. Default to [RecorderChannels.mono].
  /// [androidInputPreset] Android hardware capture preset. Configures device
  /// DSP and hardware filters (e.g. [AndroidInputPreset.voiceCommunication] for
  /// hardware AEC/AGC, [AndroidInputPreset.unprocessed] for raw audio). If
  /// null, the platform default is used. Ignored on non-Android platforms.
  /// [iosInputPreset] iOS system `AVAudioSession` preset. Configures Apple
  /// hardware voice processing (e.g. [IosInputPreset.voiceCommunication] for
  /// hardware AEC/AGC, [IosInputPreset.unprocessed] for clean raw audio). If
  /// null, the active `AVAudioSession` configuration is left untouched. Ignored
  /// on non-iOS platforms.
  /// [webInputPreset] Web Audio preprocessing constraints (`echoCancellation`,
  /// `autoGainControl`, `noiseSuppression`) configured on `getUserMedia`.
  /// Defaults to [WebInputPreset.unprocessed] (raw audio without browser AGC
  /// pumping). Ignored on non-Web platforms.
  ///
  /// > **Note on macOS:**
  /// > On macOS, CoreAudio HAL captures raw, unprocessed audio from the
  /// > selected input device by default. System-wide "Voice Isolation" and
  /// > "Wide Spectrum" Mic Modes in macOS Sonoma/Sequoia can be selected by
  /// > the user in the macOS menu bar / Control Center.
  ///
  /// Throws [RecorderInitializeFailedException] if something goes wrong, ie. no
  /// device found with [deviceID] id.
  Future<void> init({
    int deviceID = -1,
    PCMFormat format = PCMFormat.s16le,
    int sampleRate = 22050,
    RecorderChannels channels = RecorderChannels.mono,
    AndroidInputPreset? androidInputPreset,
    IosInputPreset? iosInputPreset,
    WebInputPreset? webInputPreset,
  }) async {
    // Sets the [_isInitialized].
    // Useful when the consumer uses hot restart and that flag
    // has been reset.
    isDeviceInitialized();

    if (_isInitialized) {
      _log.warning(
        'init() called when the native device is already '
        'initialized. This is expected after a hot restart but not '
        "otherwise. If you see this in production logs, there's probably "
        'a bug in your code. You may have neglected to deinit() Recorder '
        'during the current lifetime of the app.',
      );
      _recorder.impl.clearDartCallbackRegistrations();
      deinit();
    }

    await _recorder.impl.init(
      deviceID: deviceID,
      format: format,
      sampleRate: sampleRate,
      channels: channels,
      androidInputPreset: androidInputPreset,
      iosInputPreset: iosInputPreset,
      webInputPreset: webInputPreset,
    );

    await _recorder.impl.setDartEventCallbacks();

    _recorderFormat = format;
    _isInitialized = true;
  }

  /// Dispose capture device.
  void deinit() {
    stop();
    _isInitialized = false;
    _recorder.impl.deinit();
  }

  /// Whether the device is initialized.
  bool isDeviceInitialized() {
    // ignore: join_return_with_assignment
    _isInitialized = _recorder.impl.isDeviceInitialized();
    return _isInitialized;
  }

  /// Whether the device is initialized.
  bool get isInitialized => isDeviceInitialized();

  /// Whether the device is started.
  bool isDeviceStarted() {
    // ignore: join_return_with_assignment
    _isStarted = _recorder.impl.isDeviceStarted();
    return _isStarted;
  }

  /// Whether the device is started.
  bool get isStarted => isDeviceStarted();

  /// Start the device.
  ///
  /// WEB NOTE: it's preferable to call this method after the user accepted
  /// the recording permission.
  ///
  /// Throws [RecorderNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  void start() {
    if (!_isInitialized) {
      _log.warning(() => 'start(): recorder is not initialized.');
      throw const RecorderNotInitializedException();
    }
    _recorder.impl.start();
    _isStarted = true;
  }

  /// Stop the device.
  void stop() {
    if (!_isInitialized) {
      _log.warning(() => 'stop(): recorder is not initialized.');
      return;
    }
    _isStarted = false;
    _recorder.impl.stop();
  }

  /// Start streaming data.
  ///
  /// [format] selects whether the stream should contain raw PCM samples or
  /// Opus packets. Opus packets are length-prefixed with a 4-byte
  /// little-endian integer.
  ///
  /// Throws [RecorderNotInitializedException].
  void startStreamingData({StreamingFormat format = StreamingFormat.pcm}) {
    if (!_isInitialized) {
      _log.warning(() => 'startStreamingData(): recorder is not initialized.');
      throw const RecorderNotInitializedException();
    }
    _recorder.impl.startStreamingData(format: format);
  }

  /// Stop streaming data.
  void stopStreamingData() {
    if (!_isInitialized) {
      _log.warning(() => 'stopStreamingData(): recorder is not initialized.');
      return;
    }
    _recorder.impl.stopStreamingData();
  }

  /// Start recording.
  ///
  /// [completeFilePath] complete file path to save the recording.
  /// This is mandatory on all platforms but on the Web.
  /// [format] selects the output format. The default is WAV. When Opus is
  /// selected the file is written as Ogg Opus.
  /// NOTE: when running on the  Web, [completeFilePath] is ignored:
  /// when stopping the recording the browser will ask to save the file.
  ///
  /// Throws [RecorderNotInitializedException].
  /// Throws [RecorderCaptureNotStartededException].
  /// Throws [RecorderInvalidFileNameException] if the given file name is
  /// invalid.
  void startRecording({
    String completeFilePath = '',
    RecordingFormat format = RecordingFormat.wav,
  }) {
    assert(
      () {
        if (!kIsWeb && completeFilePath.isEmpty) {
          return false;
        }
        return true;
      }.call(),
      'completeFilePath is required on all platforms but on the Web.',
    );
    if (!_isInitialized) {
      _log.warning(() => 'startRecording(): recorder is not initialized.');
      throw const RecorderNotInitializedException();
    }
    if (!_isStarted) {
      _log.warning(() => 'startRecording(): recorder is not started.');
      throw const RecorderCaptureNotStartededException();
    }
    _recorder.impl.startRecording(completeFilePath, format: format);
  }

  /// Pause recording.
  void setPauseRecording({required bool pause}) {
    if (!_isStarted) return;
    _recorder.impl.setPauseRecording(pause: pause);
  }

  /// Stop recording.
  void stopRecording() {
    if (!_isStarted) return;
    _recorder.impl.stopRecording();
  }

  /// Smooth FFT data.
  ///
  /// When new data is read and the values are decreasing, the new value will be
  /// decreased with an amplitude between the old and the new value.
  /// This will resul on a less shaky visualization.
  /// [smooth] must be in the [0.0 ~ 1.0] range.
  /// 0 = no smooth, values istantly get their new value.
  /// 1 = values don't get down when they reach their max value.
  /// the new value is calculated with:
  /// newFreq = smooth * oldFreq + (1 - smooth) * newFreq
  void setFftSmoothing(double smooth) {
    if (!_isInitialized) {
      _log.warning(() => 'setFftSmoothing: recorder is not initialized.');
      return;
    }
    _recorder.impl.setFftSmoothing(smooth);
  }

  /// Enable or disable real-time audio visualization.
  ///
  /// When enabled, audio data will be analyzed and emitted via
  /// [audioVisualizationEvents].
  ///
  /// [enabled] whether to start or stop visual analysis.
  /// [windowSize] FFT window size, must be a power of 2 between 128 and 8192
  /// (default 256).
  /// [kind] type of visualization data to compute: [VisualizationKind.wave],
  /// [VisualizationKind.fft], or [VisualizationKind.waveAndFft] (default).
  /// [channel] channel selection: [VisualizationChannel.merged] (mono downmix),
  /// [VisualizationChannel.all] (all channels), or an explicit zero-based
  /// channel index.
  void setVisualizationEnabled(
    bool enabled, {
    int windowSize = 256,
    VisualizationKind kind = VisualizationKind.waveAndFft,
    int channel = VisualizationChannel.merged,
  }) {
    if (!_isInitialized) {
      _log.warning(
        () => 'setVisualizationEnabled: recorder is not initialized.',
      );
      return;
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () =>
            'setVisualizationEnabled: visualization requires PCMFormat.f32le '
            'format.',
      );
      return;
    }
    _recorder.impl.setVisualizationEnabled(
      enabled,
      windowSize: windowSize,
      kind: kind,
      channel: channel,
    );
  }

  /// Returns `true` if real-time audio visualization is currently enabled.
  bool getVisualizationEnabled() {
    if (!_isInitialized) {
      return false;
    }
    return _recorder.impl.getVisualizationEnabled();
  }

  /// Sets an explicit direct callback handler for incoming audio visualization
  /// events.
  ///
  /// Setting this is an alternative or complement to listening to
  /// [audioVisualizationEvents].
  void setVisualizationCallback(
    void Function(AudioVisualizationData data)? callback,
  ) {
    _recorder.impl.setVisualizationCallback(callback);
  }

  /// Get the current volume in dB. Returns -100 if the capture is not inited.
  /// 0 is the max volume the capture device can handle.
  ///
  /// **NOTE**: this is only available when initializing the recorder
  /// with [PCMFormat.f32le] format.
  double getVolumeDb() {
    if (!_isInitialized) {
      _log.warning(() => 'getVolumeDb: recorder is not initialized.');
      return -100;
    }
    if (!_isStarted) {
      _log.warning(() => 'getVolumeDb: recorder is not started.');
      return -100;
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getVolumeDb: volume can be get only using f32le format.',
      );
      return -100;
    }
    return _recorder.impl.getVolumeDb();
  }

  /// Enable or disable native duplex loopback.
  ///
  /// When enabled on duplex-capable devices, microphone audio is automatically
  /// output through the default speaker/headphones with minimal latency, and
  /// used as the far-end reference signal for acoustic echo cancellation.
  ///
  /// ### Use Cases:
  /// - **Karaoke & Live Mic Monitoring (Sidetone)**: Singers or presenters
  ///   wearing headphones can hear their own voice in real-time with near-zero
  ///   latency.
  /// - **In-Ear Monitoring / Hearing Assist**: Near-zero latency mic-to-ear
  ///   pass-through where audio buffering delay must remain imperceptible
  ///   (< 15ms).
  ///
  /// > [!NOTE]
  /// > If your app plays external audio (such as remote participant speech in
  /// > a VoIP call or game music via `flutter_soloud`) instead of just looping
  /// > the microphone, leave native loopback disabled and use
  /// > [feedPlaybackData] to supply the far-end speaker reference to AEC.
  void setLoopback({required bool enable}) {
    if (!_isInitialized) {
      _log.warning(() => 'setLoopback: recorder is not initialized.');
      return;
    }
    _recorder.impl.setLoopback(enable: enable);
  }

  /// Check whether native duplex loopback is currently enabled.
  bool isLoopbackEnabled() {
    if (!_isInitialized) {
      return false;
    }
    return _recorder.impl.isLoopbackEnabled();
  }

  // ///////////////////////
  //   FILTERS
  // ///////////////////////

  /// Check if a filter is active.
  /// Return -1 if the filter is not active or its index.
  int isFilterActive(RecorderFilterType filterType) {
    return _recorder.impl.isFilterActive(filterType);
  }

  /// Add a filter.
  ///
  /// Throws [RecorderFilterAlreadyAddedException] if the filter has already
  /// been added.
  /// Throws [RecorderFilterNotFoundException] if the filter could not be found.
  void addFilter(RecorderFilterType filterType) {
    _recorder.impl.addFilter(filterType);
  }

  /// Remove a filter.
  ///
  /// Throws [RecorderFilterNotFoundException] if trying to remove a non active
  /// filter.
  void removeFilter(RecorderFilterType filterType) {
    _recorder.impl.removeFilter(filterType);
  }

  /// Get filter param names.
  List<String> getFilterParamNames(RecorderFilterType filterType) {
    return _recorder.impl.getFilterParamNames(filterType);
  }

  /// Set filter param value.
  void setFilterParamValue(
    RecorderFilterType filterType,
    int attributeId,
    double value,
  ) {
    _recorder.impl.setFilterParamValue(filterType, attributeId, value);
  }

  /// Get filter param value.
  double getFilterParamValue(RecorderFilterType filterType, int attributeId) {
    return _recorder.impl.getFilterParamValue(filterType, attributeId);
  }

  /// Feed far-end playback audio data to the echo cancellation filter.
  ///
  /// Supplies external loudspeaker playback frames (e.g. from `flutter_soloud`
  /// or a VoIP decoder) to the SpeexDSP Acoustic Echo Cancellation (AEC)
  /// filter. AEC uses this reference signal to subtract speaker sound picked
  /// up by the microphone.
  ///
  /// ### Use Cases:
  /// - **Voice Calls & VoIP Conferencing**: When remote participants' voices
  ///   are played through the device speaker, feeding the decoded playback
  ///   frames prevents the remote caller from hearing their own voice echoing
  ///   back.
  /// - **Gaming with Voice Chat**: Game SFX and music played via
  ///   `flutter_soloud` are captured using `soloud.startMixerOutputStream()`
  ///   and fed here so teammates only hear your voice, not the game audio.
  /// - **Voice Assistants / Smart Devices (Barge-In)**: The device can play
  ///   spoken responses or music while listening for user wake words and
  ///   commands without being triggered by its own speaker output.
  ///
  /// [data] raw PCM bytes of the playback stream.
  /// [format] PCM format of the playback data (default [PCMFormat.f32le]).
  /// [channels] number of channels in the playback data (default
  /// [RecorderChannels.mono]). Stereo streams are automatically downmixed to
  /// match the recorder channels.
  void feedPlaybackData(
    Uint8List data, {
    PCMFormat format = PCMFormat.f32le,
    RecorderChannels channels = RecorderChannels.mono,
  }) {
    if (!_isInitialized) {
      _log.warning(() => 'feedPlaybackData: recorder is not initialized.');
      return;
    }
    _recorder.impl.feedPlaybackData(data, format: format, channels: channels);
  }
}
