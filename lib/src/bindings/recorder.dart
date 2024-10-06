// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:typed_data';

import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:meta/meta.dart';

export 'package:flutter_recorder/src/bindings/recorder_io.dart'
    if (dart.library.js_interop) 'package:flutter_recorder/src/bindings/recorder_web.dart';

/// Use this class to _capture_ audio (such as from a microphone).
abstract class RecorderImpl {
  /// Set Dart functions to call when an event occurs.
  ///
  /// On the web, only the `voiceEndedCallback` is supported. On the other
  /// platform there are also `fileLoadedCallback` and `stateChangedCallback`.
  @mustBeOverridden
  void setDartEventCallbacks();

  /// Stream of silence state changes.
  @mustBeOverridden
  Stream<SilenceState> get silenceChangedEvents;

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
  void init({int deviceID = -1});

  /// Dispose capture device.
  @mustBeOverridden
  void deinit();

  /// Whether the device is initialized.
  @mustBeOverridden
  bool isDeviceInitialized();

  /// Whether listen to the device is started.
  @mustBeOverridden
  bool isDeviceStartedListen();

  /// Start listening to the device.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  @mustBeOverridden
  void startListen();

  /// Stop listening to the device.
  @mustBeOverridden
  void stopListen();

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
}
