// ignore_for_file: avoid_positional_boolean_parameters, public_member_api_docs

import 'dart:typed_data';

import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:meta/meta.dart';

export 'package:flutter_recorder/src/bindings/recorder_io.dart'
    if (dart.library.js_interop) 'package:flutter_recorder/src/bindings/recorder_web.dart';

abstract class RecorderImpl {
  /// Set Dart functions to call when an event occurs.
  ///
  /// On the web, only the `voiceEndedCallback` is supported. On the other
  /// platform there are also `fileLoadedCallback` and `stateChangedCallback`.
  @mustBeOverridden
  void setDartEventCallbacks();

  @mustBeOverridden
  Stream<SilenceState> get silenceChangedEvents;

  @mustBeOverridden
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  });

  @mustBeOverridden
  void setSilenceThresholdDb(double silenceThresholdDb);

  @mustBeOverridden
  void setSilenceDuration(double silenceDuration);

  @mustBeOverridden
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore);

  @mustBeOverridden
  List<CaptureDevice> listCaptureDevices();

  @mustBeOverridden
  void init({int deviceID = -1});

  @mustBeOverridden
  void deinit();

  @mustBeOverridden
  bool isDeviceInitialized();

  @mustBeOverridden
  bool isDeviceStartedListen();

  @mustBeOverridden
  void startListen();

  @mustBeOverridden
  void stopListen();

  @mustBeOverridden
  void startRecording(String path);

  @mustBeOverridden
  void setPauseRecording({required bool pause});

  @mustBeOverridden
  void stopRecording();

  @mustBeOverridden
  void setFftSmoothing(double smooth);

  @mustBeOverridden
  Float32List getFft();

  @mustBeOverridden
  Float32List getWave();

  @mustBeOverridden
  Float32List getTexture2D();

  @mustBeOverridden
  double getVolumeDb();
}
