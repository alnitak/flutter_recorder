// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:meta/meta.dart';

export 'package:flutter_recorder/src/bindings/recorder_io.dart'
    if (dart.library.js_interop) 'package:flutter_recorder/src/bindings/recorder_web.dart';

/// Use this class to _capture_ audio (such as from a microphone).
abstract class RecorderImpl {
  /// The device ID used to initialize the device.
  int? deviceID;

  ///  PCM format used to initialize the device.
  PCMFormat? format;

  /// Sample rate used to initialize the device.
  int? sampleRate;

  /// Channels used to initialize the device.
  RecorderChannels? channels;

  /// Controller to listen to silence changed event.
  late final StreamController<SilenceState> silenceChangedEventController =
      StreamController.broadcast();

  /// Stream of silence state changes.
  Stream<SilenceState> get silenceChangedEvents =>
      silenceChangedEventController.stream;

  /// Controller for audio data types.
  late final uint8ListController =
      StreamController<AudioDataContainer>.broadcast();

  /// Streams for audio data types.
  Stream<AudioDataContainer> get uint8ListStream => uint8ListController.stream;

  /// Set Dart functions to call when an event occurs.
  @mustBeOverridden
  void setDartEventCallbacks();

  /// Enable or disable silence detection.
  ///
  /// [enable] wheter to enable or disable silence detection. Default to false.
  /// [onSilenceChanged] callback when silence state is changed.
  @mustBeOverridden
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  });

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
  @mustBeOverridden
  void setSilenceThresholdDb(double silenceThresholdDb);

  /// Set silence duration in seconds.
  ///
  /// [silenceDuration] the duration of silence in seconds. If the volume
  /// remains silent for this duration, the callback will be triggered. Default
  /// to 2 seconds.
  @mustBeOverridden
  void setSilenceDuration(double silenceDuration);

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
  @mustBeOverridden
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore);

  /// List available input devices. Useful on desktop to choose
  /// which input device to use.
  @mustBeOverridden
  List<CaptureDevice> listCaptureDevices();

  /// Initialize input device with [deviceID].
  ///
  /// Thows [RecorderInitializeFailedException] if something goes wrong, ie. no
  /// device found with [deviceID] id.
  @mustBeOverridden
  @mustCallSuper
  void init({
    required int deviceID,
    required PCMFormat format,
    required int sampleRate,
    required RecorderChannels channels,
  }) {
    this.deviceID = deviceID;
    this.format = format;
    this.sampleRate = sampleRate;
    this.channels = channels;
  }

  /// Dispose capture device.
  @mustBeOverridden
  @mustCallSuper
  void deinit() {
    deviceID = null;
    format = null;
    sampleRate = null;
    channels = null;
  }

  /// Whether the device is initialized.
  @mustBeOverridden
  bool isDeviceInitialized();

  /// Whether the device is started.
  @mustBeOverridden
  bool isDeviceStarted();

  /// Start the device.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  @mustBeOverridden
  void start();

  /// Stop the device.
  @mustBeOverridden
  void stop();

  /// Start streaming data.
  @mustBeOverridden
  void startStreamingData();

  /// Stop streaming data.
  @mustBeOverridden
  void stopStreamingData();

  /// Start recording.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToInitializeRecordingException].
  @mustBeOverridden
  void startRecording(String path);

  /// Pause recording.
  @mustBeOverridden
  void setPauseRecording({required bool pause});

  /// Stop recording.
  @mustBeOverridden
  void stopRecording();

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
  @mustBeOverridden
  void setFftSmoothing(double smooth);

  /// Return a 256 float array containing FFT data in the range [-1.0, 1.0]
  /// not clamped.@mustBeOverridden
  Float32List getFft();

  /// Return a 256 float array containing wave data in the range [-1.0, 1.0].
  @mustBeOverridden
  Float32List getWave();

  /// Get the audio data representing an array of 256 floats FFT data and
  /// 256 float of wave data.
  @mustBeOverridden
  Float32List getTexture2D();

  /// Get the current volume in dB. Returns -100 if the capture is not inited.
  @mustBeOverridden
  double getVolumeDb();

  // ///////////////////////
  //   FILTERS
  // ///////////////////////

  /// Check if a filter is active.
  /// Return -1 if the filter is not active or its index.
  @mustBeOverridden
  int isFilterActive(FilterType filterType);

  /// Add a filter.
  ///
  /// Throws [RecorderFilterAlreadyAddedException] if the filter has already
  /// been added.
  /// Throws [RecorderFilterNotFoundException] if the filter could not be found.
  @mustBeOverridden
  void addFilter(FilterType filterType);

  /// Remove a filter.
  ///
  /// Throws [RecorderFilterNotFoundException] if trying to a non active
  /// filter.
  @mustBeOverridden
  CaptureErrors removeFilter(FilterType filterType);

  /// Get filter param names.
  @mustBeOverridden
  List<String> getFilterParamNames(FilterType filterType);

  /// Set filter param value.
  @mustBeOverridden
  void setFilterParamValue(
    FilterType filterType,
    int attributeId,
    double value,
  );

  /// Get filter param value.
  @mustBeOverridden
  double getFilterParamValue(FilterType filterType, int attributeId);
}
