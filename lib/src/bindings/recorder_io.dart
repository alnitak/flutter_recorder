// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_positional_boolean_parameters, public_member_api_docs

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/bindings/flutter_recorder_bindings_generated.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:meta/meta.dart';

@internal
class RecorderController {
  factory RecorderController() => _instance ??= RecorderController._();

  RecorderController._() {
    impl = RecorderFfi();
  }
  static RecorderController? _instance;

  late final RecorderImpl impl;
}

@internal
class RecorderFfi extends RecorderImpl {

  /// Controller to listen to silence changed event.
  late final StreamController<SilenceState> silenceChangedEventController =
      StreamController.broadcast();

  /// Listener for silence changed.
  @override
  Stream<SilenceState> get silenceChangedEvents =>
      silenceChangedEventController.stream;

  static const String _libName = 'flutter_recorder';

  /// The dynamic library in which the symbols for [FlutterRecorderBindings]
  /// can be found.
  static final ffi.DynamicLibrary _dylib = () {
    if (Platform.isMacOS || Platform.isIOS) {
      return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return ffi.DynamicLibrary.open('lib$_libName.so');
    }
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('$_libName.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }();

  /// The bindings to the native functions in [_dylib].
  final FlutterRecorderBindings _bindings = FlutterRecorderBindings(_dylib);

  SilenceCallback? _silenceCallback;

  void _silenceChangedCallback(
    ffi.Pointer<ffi.Bool> silence,
    ffi.Pointer<ffi.Float> db,
  ) {
    // print('SILENCE CHANGED: ${silence.value}, ${db.value}');
    _silenceCallback?.call(silence.value, db.value);
    silenceChangedEventController.add(
      (isSilent: silence.value, decibel: db.value),
    );
  }

  @override
  void setDartEventCallbacks() {
    // Create a NativeCallable for the Dart functions
    final nativeSilenceChangedCallable =
        ffi.NativeCallable<dartSilenceChangedCallback_tFunction>.listener(
      _silenceChangedCallback,
    );

    _bindings.setDartEventCallback(nativeSilenceChangedCallable.nativeFunction);
  }

  @override
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    _bindings.setSilenceDetection(enable);

    if (onSilenceChanged != null) {
      _silenceCallback = onSilenceChanged;
    }
    if (!enable) {
      _silenceCallback = null;
    }
  }

  @override
  void setSilenceThresholdDb(double silenceThresholdDb) {
    assert(silenceThresholdDb < 0, 'silenceThresholdDb must be < 0');
    _bindings.setSilenceThresholdDb(silenceThresholdDb);
  }

  @override
  void setSilenceDuration(double silenceDuration) {
    assert(silenceDuration >= 0, 'silenceDuration must be >= 0');
    _bindings.setSilenceDuration(silenceDuration);
  }

  @override
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    assert(
      secondsOfAudioToWriteBefore >= 0,
      'secondsOfAudioToWriteBefore must be >= 0',
    );
    _bindings.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
  }

  @override
  List<CaptureDevice> listCaptureDevices() {
    final ret = <CaptureDevice>[];
    final ffi.Pointer<ffi.Pointer<ffi.Char>> deviceNames =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Char>>>() * 255);
    final ffi.Pointer<ffi.Pointer<ffi.Int>> deviceIds =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Int>>>() * 50);
    final ffi.Pointer<ffi.Pointer<ffi.Int>> deviceIsDefault =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Int>>>() * 50);
    final ffi.Pointer<ffi.Int> nDevices = calloc();

    _bindings.listCaptureDevices(
      deviceNames,
      deviceIds,
      deviceIsDefault,
      nDevices,
    );

    final ndev = nDevices.value;
    for (var i = 0; i < ndev; i++) {
      final s1 = (deviceNames + i).value;
      final s = s1.cast<Utf8>().toDartString();
      final id1 = (deviceIds + i).value;
      final id = id1.value;
      final n1 = (deviceIsDefault + i).value;
      final n = n1.value;
      ret.add(CaptureDevice(s, n == 1, id));
    }

    /// Free allocated memory done in C.
    /// This work on all platforms but not on win.
    // for (int i = 0; i < ndev; i++) {
    //   calloc.free(devices.elementAt(i).value.ref.name);
    //   calloc.free(devices.elementAt(i).value);
    // }
    _bindings.freeListCaptureDevices(
      deviceNames,
      deviceIds,
      deviceIsDefault,
      ndev,
    );

    calloc
      ..free(deviceNames)
      ..free(deviceIds)
      ..free(nDevices);
    return ret;
  }

  @override
  void init({int deviceID = -1}) {
    final error = _bindings.init(deviceID);
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
  }

  @override
  void deinit() {
    _silenceCallback = null;
    _bindings.deinit();
  }

  @override
  bool isDeviceInitialized() {
    return _bindings.isInited() == 1;
  }

  @override
  bool isDeviceStartedListen() {
    return _bindings.isDeviceStartedListen() == 1;
  }

  @override
  void startListen() {
    final error = _bindings.startListen();
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
  }

  @override
  void stopListen() {
    _bindings.stopListen();
  }

  @override
  void startRecording(String path) {
    final error = _bindings.startRecording(path.toNativeUtf8().cast());
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
  }

  @override
  void setPauseRecording({required bool pause}) {
    _bindings.setPauseRecording(pause);
  }

  @override
  void stopRecording() {
    _bindings.stopRecording();
  }

  @override
  void setFftSmoothing(double smooth) {
    _bindings.setFftSmoothing(smooth);
  }

  @override
  Float32List getFft() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> fft = calloc(256 * 4);
    _bindings.getFft(fft);

    final val = ffi.Pointer<ffi.Float>.fromAddress(fft.value.address);
    if (val == ffi.nullptr) return Float32List(256);

    final fftList = val.cast<ffi.Float>().asTypedList(256);
    calloc.free(fft);
    return fftList;
  }

  @override
  Float32List getWave() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> wave = calloc(256 * 4);
    _bindings.getWave(wave);

    final val = ffi.Pointer<ffi.Float>.fromAddress(wave.value.address);
    if (val == ffi.nullptr) return Float32List(256);

    final waveList = val.cast<ffi.Float>().asTypedList(256);
    calloc.free(wave);
    return waveList;
  }

  @override
  Float32List getTexture2D() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> data = calloc(512 * 256 * 4);
    _bindings.getTexture2D(data);

    final val = ffi.Pointer<ffi.Float>.fromAddress(data.value.address);
    if (val == ffi.nullptr) return Float32List(512 * 256);

    calloc.free(data);
    final textureList = val.cast<ffi.Float>().asTypedList(512 * 256);

    return textureList;
  }

  @override
  double getVolumeDb() {
    final ffi.Pointer<ffi.Float> volume = calloc(4);
    _bindings.getVolumeDb(volume);
    final v = volume.value;
    calloc.free(volume);
    return v;
  }
}
