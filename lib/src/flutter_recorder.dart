// ignore_for_file: omit_local_variable_types, avoid_positional_boolean_parameters

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';

/// Callback when silence state is changed.
typedef SilenceCallback = void Function(bool isSilent, double decibel);

/// Silence state.
typedef SilenceState = ({bool isSilent, double decibel});

/// Use this class to _capture_ audio (such as from a microphone).
interface class Recorder {
  /// The private constructor of [Recorder]. This prevents developers from
  /// instantiating new instances.
  Recorder._();

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

  final _recoreder = RecorderController();

  /// Listening to silence state changes.
  Stream<SilenceState> get silenceChangedEvents =>
      _recoreder.impl.silenceChangedEvents;

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

  /// Set silence duration in seconds.
  ///
  /// [silenceDuration] the duration of silence in seconds. If the volume
  /// remains silent for this duration, the callback will be triggered. Default
  /// to 2 seconds.
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
    final ret = <CaptureDevice>[];
    _recoreder.impl.listCaptureDevices();

    return ret;
  }

  /// Initialize input device with [deviceID].
  ///
  /// Thows [RecorderInitializeFailedException] if something goes wrong, ie. no
  /// device found with [deviceID] id.
  void init({int deviceID = -1}) {
    _recoreder.impl.init(deviceID: deviceID);
    _recoreder.impl.setDartEventCallbacks();
  }

  /// Dispose capture device.
  void deinit() {
    _recoreder.impl.deinit();
  }

  /// Whether the device is initialized.
  bool isDeviceInitialized() {
    return _recoreder.impl.isDeviceInitialized();
  }

  /// Whether listen to the device is started.
  bool isDeviceStartedListen() {
    return _recoreder.impl.isDeviceStartedListen();
  }

  /// Start listening to the device.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  void startListen() {
    _recoreder.impl.startListen();
  }

  /// Stop listening to the device.
  void stopListen() {
    _recoreder.impl.stopListen();
  }

  /// Ask for file name to save recording only for web. After calling this
  /// method, the file name is set and [startRecording] can be called.
  void webAskFileName() {
    _recoreder.impl.webAskFileName();
  }

  /// Start recording.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToInitializeRecordingException].
  void startRecording(String path) {
    _recoreder.impl.startRecording(path);
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
  Float32List getFft() {
    return _recoreder.impl.getFft();
  }

  /// Return a 256 float array containing wave data in the range [-1.0, 1.0].
  Float32List getWave() {
    return _recoreder.impl.getWave();
  }

  /// Get the audio data representing an array of 256 floats FFT data and
  /// 256 float of wave data.
  Float32List getTexture2D() {
    return _recoreder.impl.getTexture2D();
  }

  /// Get the current volume in dB. Returns -100 if the capture is not inited.
  double getVolumeDb() {
    return _recoreder.impl.getVolumeDb();
  }
}
