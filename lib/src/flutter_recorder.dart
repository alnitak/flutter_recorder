// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
import 'package:logging/logging.dart';

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
  final filters = const Filters();

  final _recoreder = RecorderController();

  /// Whether the device is initialized.
  bool _isInitialized = false;

  /// Whether the device is started.
  bool _isStarted = false;

  /// Currently used recorder configuration.
  PCMFormat _recorderFormat = PCMFormat.s16le;

  /// Listening to silence state changes.
  Stream<SilenceState> get silenceChangedEvents =>
      _recoreder.impl.silenceChangedEvents;

  /// Listen to audio data.
  ///
  /// The streaming must be enabled calling [startStreamingData].
  /// 
  /// *NOTE*: the audio data must be managed as the data is received. Since the
  /// memory used to store data is the same for all the received streams to
  /// have better performances, the data will be overwritten. Hence, you
  /// must copy the data if you want fill a buffer. This happens
  /// for example when using "RxDart.bufferTime" which will fill a "List" of
  /// [AudioDataContainer] but when you will try to read them, you will notice
  /// that all the items have the same data.
  Stream<AudioDataContainer> get uint8ListStream =>
      _recoreder.impl.uint8ListStream;

  /// Enable or disable silence detection.
  ///
  /// [enable] wheter to enable or disable silence detection. Default to false.
  /// [onSilenceChanged] callback when silence state is changed.
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    _recoreder.impl.setSilenceDetection(
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
  void setSilenceThresholdDb(double silenceThresholdDb) {
    _recoreder.impl.setSilenceThresholdDb(silenceThresholdDb);
  }

  /// Set the value in seconds of silence after which silence is considered
  /// as such.
  ///
  /// [silenceDuration] the duration of silence in seconds. If the volume
  /// remains silent for this duration, the [SilenceCallback] callback will be
  /// triggered or the Stream [silenceChangedEvents] will emit silence state.
  /// Default to 2 seconds.
  void setSilenceDuration(double silenceDuration) {
    _recoreder.impl.setSilenceDuration(silenceDuration);
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
    _recoreder.impl.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
  }

  /// List available input devices. Useful on desktop to choose
  /// which input device to use.
  List<CaptureDevice> listCaptureDevices() {
    final ret = _recoreder.impl.listCaptureDevices();

    return ret;
  }

  /// Initialize input device with [deviceID].
  ///
  /// [deviceID] the id of the input device. If -1, the default OS input
  /// device is used.
  /// [format] PCM format. Default to [PCMFormat.s16le].
  /// [sampleRate] sample rate in Hz. Default to 22050.
  /// [channels] number of channels. Default to [RecorderChannels.mono].
  ///
  /// Thows [RecorderInitializeFailedException] if something goes wrong, ie. no
  /// device found with [deviceID] id.
  Future<void> init({
    int deviceID = -1,
    PCMFormat format = PCMFormat.s16le,
    int sampleRate = 22050,
    RecorderChannels channels = RecorderChannels.mono,
  }) async {
    await _recoreder.impl.setDartEventCallbacks();
    if (_isInitialized) {
      _log.warning('init() called when the native device is already '
          'initialized. This is expected after a hot restart but not '
          "otherwise. If you see this in production logs, there's probably "
          'a bug in your code. You may have neglected to deinit() Recorder '
          'during the current lifetime of the app.');
      deinit();
    }

    _recoreder.impl.init(
      deviceID: deviceID,
      format: format,
      sampleRate: sampleRate,
      channels: channels,
    );
    _recorderFormat = format;
    _isInitialized = true;
  }

  /// Dispose capture device.
  void deinit() {
    _isInitialized = false;
    _isStarted = false;
    _recoreder.impl.deinit();
  }

  /// Whether the device is initialized.
  bool isDeviceInitialized() {
    // ignore: join_return_with_assignment
    _isInitialized = _recoreder.impl.isDeviceInitialized();
    return _isInitialized;
  }

  /// Whether the device is started.
  bool isDeviceStarted() {
    // ignore: join_return_with_assignment
    _isStarted = _recoreder.impl.isDeviceStarted();
    return _isStarted;
  }

  /// Start the device.
  ///
  /// WEB NOTE: it's preferable to call this method after the user accepted
  /// the recording permission.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  void start() {
    _recoreder.impl.start();
    _isStarted = true;
  }

  /// Stop the device.
  void stop() {
    _isStarted = false;
    _recoreder.impl.stop();
  }

  /// Start streaming data.
  void startStreamingData() {
    _recoreder.impl.startStreamingData();
  }

  /// Stop streaming data.
  void stopStreamingData() {
    _recoreder.impl.stopStreamingData();
  }

  /// Start recording.
  ///
  /// [completeFilePath] complete file path to save the recording.
  /// This is mandatory on all platforms but on the Web.
  /// NOTE: when running on the  Web, [completeFilePath] is ignored and
  /// just stopping the recording the browser will ask to save the file.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToInitializeRecordingException].
  void startRecording({String completeFilePath = ''}) {
    assert(
        !kIsWeb && completeFilePath.isNotEmpty,
        'completeFilePath is required '
        'on all platforms but on the Web.');
    _recoreder.impl.startRecording(completeFilePath);
  }

  /// Pause recording.
  void setPauseRecording({required bool pause}) {
    _recoreder.impl.setPauseRecording(pause: pause);
  }

  /// Stop recording.
  void stopRecording() {
    _recoreder.impl.stopRecording();
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
    _recoreder.impl.setFftSmoothing(smooth);
  }

  /// Return a 256 float array containing FFT data in the range [-1.0, 1.0]
  /// not clamped.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getFft() {
    if (!_isStarted) {
      _log.warning(() => 'Recorder is not started.');
      return Float32List(256);
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getFft: FFT data can be get only with f32le format.',
      );
      return Float32List(256);
    }
    return _recoreder.impl.getFft();
  }

  /// Return a 256 float array containing wave data in the range [-1.0, 1.0]
  /// not clamped.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getWave() {
    if (!_isStarted) {
      _log.warning(() => 'Recorder is not started.');
      return Float32List(256);
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getWave: wave data can be get only with f32le format.',
      );
      return Float32List(256);
    }
    return _recoreder.impl.getWave();
  }

  /// Get the audio data representing an array of 256 floats FFT data and
  /// 256 float of wave data.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  Float32List getTexture2D() {
    if (!_isStarted) {
      _log.warning(() => 'Recorder is not started.');
      return Float32List(256);
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getTexture2D: texture can be get only with f32le format.',
      );
      return Float32List(256);
    }
    return _recoreder.impl.getTexture2D();
  }

  /// Get the current volume in dB. Returns -100 if the capture is not inited.
  /// 0 is the max volume the capture device can handle.
  ///
  /// **NOTE**: use this only with format [PCMFormat.f32le].
  double getVolumeDb() {
    if (!_isStarted) {
      _log.warning(() => 'Recorder is not started.');
      return -100;
    }
    if (_recorderFormat != PCMFormat.f32le) {
      _log.warning(
        () => 'getVolumeDb: volume can be get only with f32le format.',
      );
      return -100;
    }
    return _recoreder.impl.getVolumeDb();
  }

  // ///////////////////////
  //   FILTERS
  // ///////////////////////

  /// Check if a filter is active.
  /// Return -1 if the filter is not active or its index.
  int isFilterActive(FilterType filterType) {
    return _recoreder.impl.isFilterActive(filterType);
  }

  /// Add a filter.
  ///
  /// Throws [RecorderFilterAlreadyAddedException] if the filter has already
  /// been added.
  /// Throws [RecorderFilterNotFoundException] if the filter could not be found.
  void addFilter(FilterType filterType) {
    _recoreder.impl.addFilter(filterType);
  }

  /// Remove a filter.
  ///
  /// Throws [RecorderFilterNotFoundException] if trying to a non active
  /// filter.
  CaptureErrors removeFilter(FilterType filterType) {
    return _recoreder.impl.removeFilter(filterType);
  }

  /// Get filter param names.
  List<String> getFilterParamNames(FilterType filterType) {
    return _recoreder.impl.getFilterParamNames(filterType);
  }

  /// Set filter param value.
  void setFilterParamValue(
    FilterType filterType,
    int attributeId,
    double value,
  ) {
    _recoreder.impl.setFilterParamValue(filterType, attributeId, value);
  }

  /// Get filter param value.
  double getFilterParamValue(FilterType filterType, int attributeId) {
    return _recoreder.impl.getFilterParamValue(filterType, attributeId);
  }
}
