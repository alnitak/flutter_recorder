// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

import 'package:flutter_recorder/src/enums.dart';

/// Bindings for `src/flutter_recorder.h`.
///
/// Regenerate bindings with
/// `dart run ffigen --config ffigen.yaml`
/// or
/// `export CPATH="$(clang -v 2>&1 | grep "Selected GCC installation" | rev | cut -d' ' -f1 | rev)/include";  dart run ffigen --config ffigen.yaml`
///
class FlutterRecorderBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  FlutterRecorderBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  FlutterRecorderBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void createWorkerInWasm() {
    return _createWorkerInWasm();
  }

  late final _createWorkerInWasmPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('createWorkerInWasm');
  late final _createWorkerInWasm =
      _createWorkerInWasmPtr.asFunction<void Function()>();

  void setDartEventCallback(
    dartSilenceChangedCallback_t silence_changed_callback,
  ) {
    return _setDartEventCallback(
      silence_changed_callback,
    );
  }

  late final _setDartEventCallbackPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(dartSilenceChangedCallback_t)>>(
      'setDartEventCallback');
  late final _setDartEventCallback = _setDartEventCallbackPtr
      .asFunction<void Function(dartSilenceChangedCallback_t)>();

  void nativeFree(
    ffi.Pointer<ffi.Void> pointer,
  ) {
    return _nativeFree(
      pointer,
    );
  }

  late final _nativeFreePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'nativeFree');
  late final _nativeFree =
      _nativeFreePtr.asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void listCaptureDevices(
    ffi.Pointer<ffi.Pointer<ffi.Char>> devicesName,
    ffi.Pointer<ffi.Pointer<ffi.Int>> deviceId,
    ffi.Pointer<ffi.Pointer<ffi.Int>> isDefault,
    ffi.Pointer<ffi.Int> n_devices,
  ) {
    return _listCaptureDevices(
      devicesName,
      deviceId,
      isDefault,
      n_devices,
    );
  }

  late final _listCaptureDevicesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Pointer<ffi.Char>>,
              ffi.Pointer<ffi.Pointer<ffi.Int>>,
              ffi.Pointer<ffi.Pointer<ffi.Int>>,
              ffi.Pointer<ffi.Int>)>>('listCaptureDevices');
  late final _listCaptureDevices = _listCaptureDevicesPtr.asFunction<
      void Function(
          ffi.Pointer<ffi.Pointer<ffi.Char>>,
          ffi.Pointer<ffi.Pointer<ffi.Int>>,
          ffi.Pointer<ffi.Pointer<ffi.Int>>,
          ffi.Pointer<ffi.Int>)>();

  void freeListCaptureDevices(
    ffi.Pointer<ffi.Pointer<ffi.Char>> devicesName,
    ffi.Pointer<ffi.Pointer<ffi.Int>> deviceId,
    ffi.Pointer<ffi.Pointer<ffi.Int>> isDefault,
    int n_devices,
  ) {
    return _freeListCaptureDevices(
      devicesName,
      deviceId,
      isDefault,
      n_devices,
    );
  }

  late final _freeListCaptureDevicesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Pointer<ffi.Char>>,
              ffi.Pointer<ffi.Pointer<ffi.Int>>,
              ffi.Pointer<ffi.Pointer<ffi.Int>>,
              ffi.Int)>>('freeListCaptureDevices');
  late final _freeListCaptureDevices = _freeListCaptureDevicesPtr.asFunction<
      void Function(
          ffi.Pointer<ffi.Pointer<ffi.Char>>,
          ffi.Pointer<ffi.Pointer<ffi.Int>>,
          ffi.Pointer<ffi.Pointer<ffi.Int>>,
          int)>();

  CaptureErrors init(
    int deviceID,
    int sampleRate,
    int channels,
  ) {
    return CaptureErrors.fromValue(_init(
      deviceID,
      sampleRate,
      channels,
    ));
  }

  late final _initPtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              ffi.Int, ffi.UnsignedInt, ffi.UnsignedInt)>>('init');
  late final _init = _initPtr.asFunction<int Function(int, int, int)>();

  void deinit() {
    return _deinit();
  }

  late final _deinitPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('deinit');
  late final _deinit = _deinitPtr.asFunction<void Function()>();

  int isInited() {
    return _isInited();
  }

  late final _isInitedPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('isInited');
  late final _isInited = _isInitedPtr.asFunction<int Function()>();

  int isDeviceStartedListen() {
    return _isDeviceStartedListen();
  }

  late final _isDeviceStartedListenPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('isDeviceStartedListen');
  late final _isDeviceStartedListen =
      _isDeviceStartedListenPtr.asFunction<int Function()>();

  CaptureErrors startListen() {
    return CaptureErrors.fromValue(_startListen());
  }

  late final _startListenPtr =
      _lookup<ffi.NativeFunction<ffi.UnsignedInt Function()>>('startListen');
  late final _startListen = _startListenPtr.asFunction<int Function()>();

  void stopListen() {
    return _stopListen();
  }

  late final _stopListenPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('stopListen');
  late final _stopListen = _stopListenPtr.asFunction<void Function()>();

  void setSilenceDetection(
    bool enable,
  ) {
    return _setSilenceDetection(
      enable,
    );
  }

  late final _setSilenceDetectionPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Bool)>>(
          'setSilenceDetection');
  late final _setSilenceDetection =
      _setSilenceDetectionPtr.asFunction<void Function(bool)>();

  void setSilenceThresholdDb(
    double silenceThresholdDb,
  ) {
    return _setSilenceThresholdDb(
      silenceThresholdDb,
    );
  }

  late final _setSilenceThresholdDbPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Float)>>(
          'setSilenceThresholdDb');
  late final _setSilenceThresholdDb =
      _setSilenceThresholdDbPtr.asFunction<void Function(double)>();

  void setSilenceDuration(
    double silenceDuration,
  ) {
    return _setSilenceDuration(
      silenceDuration,
    );
  }

  late final _setSilenceDurationPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Float)>>(
          'setSilenceDuration');
  late final _setSilenceDuration =
      _setSilenceDurationPtr.asFunction<void Function(double)>();

  void setSecondsOfAudioToWriteBefore(
    double secondsOfAudioToWriteBefore,
  ) {
    return _setSecondsOfAudioToWriteBefore(
      secondsOfAudioToWriteBefore,
    );
  }

  late final _setSecondsOfAudioToWriteBeforePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Float)>>(
          'setSecondsOfAudioToWriteBefore');
  late final _setSecondsOfAudioToWriteBefore =
      _setSecondsOfAudioToWriteBeforePtr.asFunction<void Function(double)>();

  CaptureErrors startRecording(
    ffi.Pointer<ffi.Char> path,
  ) {
    return CaptureErrors.fromValue(_startRecording(
      path,
    ));
  }

  late final _startRecordingPtr = _lookup<
          ffi.NativeFunction<ffi.UnsignedInt Function(ffi.Pointer<ffi.Char>)>>(
      'startRecording');
  late final _startRecording =
      _startRecordingPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  void setPauseRecording(
    bool pause,
  ) {
    return _setPauseRecording(
      pause,
    );
  }

  late final _setPauseRecordingPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Bool)>>(
          'setPauseRecording');
  late final _setPauseRecording =
      _setPauseRecordingPtr.asFunction<void Function(bool)>();

  void stopRecording() {
    return _stopRecording();
  }

  late final _stopRecordingPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('stopRecording');
  late final _stopRecording = _stopRecordingPtr.asFunction<void Function()>();

  void getVolumeDb(
    ffi.Pointer<ffi.Float> volumeDb,
  ) {
    return _getVolumeDb(
      volumeDb,
    );
  }

  late final _getVolumeDbPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Float>)>>(
          'getVolumeDb');
  late final _getVolumeDb =
      _getVolumeDbPtr.asFunction<void Function(ffi.Pointer<ffi.Float>)>();

  void getFft(
    ffi.Pointer<ffi.Pointer<ffi.Float>> fft,
  ) {
    return _getFft(
      fft,
    );
  }

  late final _getFftPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Pointer<ffi.Float>>)>>('getFft');
  late final _getFft = _getFftPtr
      .asFunction<void Function(ffi.Pointer<ffi.Pointer<ffi.Float>>)>();

  void getWave(
    ffi.Pointer<ffi.Pointer<ffi.Float>> wave,
  ) {
    return _getWave(
      wave,
    );
  }

  late final _getWavePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Pointer<ffi.Float>>)>>('getWave');
  late final _getWave = _getWavePtr
      .asFunction<void Function(ffi.Pointer<ffi.Pointer<ffi.Float>>)>();

  void getTexture(
    ffi.Pointer<ffi.Float> samples,
  ) {
    return _getTexture(
      samples,
    );
  }

  late final _getTexturePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Float>)>>(
          'getTexture');
  late final _getTexture =
      _getTexturePtr.asFunction<void Function(ffi.Pointer<ffi.Float>)>();

  void getTexture2D(
    ffi.Pointer<ffi.Pointer<ffi.Float>> samples,
  ) {
    return _getTexture2D(
      samples,
    );
  }

  late final _getTexture2DPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Pointer<ffi.Float>>)>>('getTexture2D');
  late final _getTexture2D = _getTexture2DPtr
      .asFunction<void Function(ffi.Pointer<ffi.Pointer<ffi.Float>>)>();

  double getTextureValue(
    int row,
    int column,
  ) {
    return _getTextureValue(
      row,
      column,
    );
  }

  late final _getTextureValuePtr =
      _lookup<ffi.NativeFunction<ffi.Float Function(ffi.Int, ffi.Int)>>(
          'getTextureValue');
  late final _getTextureValue =
      _getTextureValuePtr.asFunction<double Function(int, int)>();

  void setFftSmoothing(
    double smooth,
  ) {
    return _setFftSmoothing(
      smooth,
    );
  }

  late final _setFftSmoothingPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Float)>>(
          'setFftSmoothing');
  late final _setFftSmoothing =
      _setFftSmoothingPtr.asFunction<void Function(double)>();
}

typedef dartSilenceChangedCallback_t
    = ffi.Pointer<ffi.NativeFunction<dartSilenceChangedCallback_tFunction>>;
typedef dartSilenceChangedCallback_tFunction = ffi.Void Function(
    ffi.Pointer<ffi.Bool>, ffi.Pointer<ffi.Float>);
typedef DartdartSilenceChangedCallback_tFunction = void Function(
    ffi.Pointer<ffi.Bool>, ffi.Pointer<ffi.Float>);
