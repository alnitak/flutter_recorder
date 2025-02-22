// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_positional_boolean_parameters, public_member_api_docs

import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/bindings/flutter_recorder_bindings_generated.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
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
    _silenceCallback?.call(silence.value, db.value);
    silenceChangedEventController.add(
      (isSilent: silence.value, decibel: db.value),
    );
  }

  void _streamDataCallback(
    ffi.Pointer<ffi.UnsignedChar> data,
    int dataLength,
  ) {
    try {
      // Create a copy of the data
      final audioData = data.cast<ffi.Uint8>().asTypedList(dataLength).toList();
      uint8ListController.add(
        AudioDataContainer(Uint8List.fromList(audioData)),
      );
    } finally {
      // Free the memory allocated in C++
      _bindings.flutter_recorder_nativeFree(data.cast<ffi.Void>());
    }
  }

  ffi.NativeCallable<dartStreamDataCallback_tFunction>?
      nativeStreamDataCallable;
  @override
  Future<void> setDartEventCallbacks() async {
    // Create a NativeCallable for the Dart functions
    final nativeSilenceChangedCallable =
        ffi.NativeCallable<dartSilenceChangedCallback_tFunction>.listener(
      _silenceChangedCallback,
    );

    final nativeStreamDataCallable =
        ffi.NativeCallable<dartStreamDataCallback_tFunction>.listener(
      _streamDataCallback,
    );

    _bindings.flutter_recorder_setDartEventCallback(
      nativeSilenceChangedCallable.nativeFunction,
      nativeStreamDataCallable.nativeFunction,
    );
  }

  @override
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    _bindings.flutter_recorder_setSilenceDetection(enable);

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
    _bindings.flutter_recorder_setSilenceThresholdDb(silenceThresholdDb);
  }

  @override
  void setSilenceDuration(double silenceDuration) {
    assert(silenceDuration >= 0, 'silenceDuration must be >= 0');
    _bindings.flutter_recorder_setSilenceDuration(silenceDuration);
  }

  @override
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    assert(
      secondsOfAudioToWriteBefore >= 0,
      'secondsOfAudioToWriteBefore must be >= 0',
    );
    _bindings.flutter_recorder_setSecondsOfAudioToWriteBefore(
      secondsOfAudioToWriteBefore,
    );
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

    _bindings.flutter_recorder_listCaptureDevices(
      deviceNames,
      deviceIds,
      deviceIsDefault,
      nDevices,
    );

    final ndev = nDevices.value;
    for (var i = 0; i < ndev; i++) {
      var s = 'no name';
      final s1 = (deviceNames + i).value;
      if (s1 != ffi.nullptr) {
        s = s1.cast<Utf8>().toDartString();
      }
      final id1 = (deviceIds + i).value;
      final id = id1.value;
      final n1 = (deviceIsDefault + i).value;
      final n = n1.value;
      ret.add(CaptureDevice(s, n == 1, id));
    }

    // Free allocated memory is done in C.
    // This work on all platforms but not on win.
    // for (int i = 0; i < ndev; i++) {
    //   calloc.free(devices.elementAt(i).value.ref.name);
    //   calloc.free(devices.elementAt(i).value);
    // }
    _bindings.flutter_recorder_freeListCaptureDevices(
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
  void init({
    required int deviceID,
    required PCMFormat format,
    required int sampleRate,
    required RecorderChannels channels,
  }) {
    final error = _bindings.flutter_recorder_init(
      deviceID,
      format.value,
      sampleRate,
      channels.count,
    );
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
    super.init(
      deviceID: deviceID,
      format: format,
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  @override
  void deinit() {
    _silenceCallback = null;
    _bindings.flutter_recorder_deinit();
    super.deinit();
  }

  @override
  bool isDeviceInitialized() {
    return _bindings.flutter_recorder_isInited() == 1;
  }

  @override
  bool isDeviceStarted() {
    return _bindings.flutter_recorder_isDeviceStarted() == 1;
  }

  @override
  void start() {
    final error = _bindings.flutter_recorder_start();
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
  }

  @override
  void stop() {
    _bindings.flutter_recorder_stop();
  }

  @override
  void startStreamingData() {
    _bindings.flutter_recorder_startStreamingData();
  }

  @override
  void stopStreamingData() {
    _bindings.flutter_recorder_stopStreamingData();
  }

  @override
  void startRecording(String path) {
    var errorDescription = '';
    // Check the file name is valid for the different platforms.
    bool isValidPathName() {
      // Reserved Windows filenames - these apply to any part of the path
      const reservedNames = {
        'CON', 'PRN', 'AUX', 'NUL',
        'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
        'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
        // ignore: require_trailing_commas
      };

      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          // Split path into components
          final pathParts = path.split(RegExp(r'[/\\]'));

          // Check each component
          for (final part in pathParts) {
            // Skip empty parts
            if (part.isEmpty) continue;

            // Check for invalid characters in each part
            if (part.contains(RegExp('[:*?"<>|]')) ||
                reservedNames.contains(part.toUpperCase().split('.').first) ||
                part.endsWith(' ') ||
                part.endsWith('.')) {
              errorDescription = 'Invalid path component "$part". Path '
                  'components must not '
                  'contain any of these characters: :*?"<>| '
                  'or be a reserved name, or end with space/period.';
              return false;
            }
          }

          // Check total path length (Windows MAX_PATH is 260)
          if (path.length > 259) {
            errorDescription = 'Path is too long. Windows paths must be '
                'less than 260 characters.';
            return false;
          }

        case TargetPlatform.linux:
        case TargetPlatform.android:
          // Check for null bytes and control characters
          if (path.contains(RegExp(r'[\x00-\x1F]'))) {
            errorDescription = 'Path contains invalid control characters.';
            return false;
          }

        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          // Check for invalid characters on macOS/iOS
          if (path.contains(RegExp('[:<>]'))) {
            errorDescription = 'Path contains invalid characters. '
                'The following characters are not allowed: :<>';
            return false;
          }
          // Check for ._ at start (reserved for resource forks)
          if (path.split('/').any((part) => part.startsWith('._'))) {
            errorDescription =
                'File names cannot start with "._" on macOS/iOS.';
            return false;
          }

        case TargetPlatform.fuchsia:
          throw UnimplementedError();
      }

      return true;
    }

    if (!isValidPathName()) {
      throw RecorderInvalidFileNameException(errorDescription);
    }

    final error =
        _bindings.flutter_recorder_startRecording(path.toNativeUtf8().cast());
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
  }

  @override
  void setPauseRecording({required bool pause}) {
    _bindings.flutter_recorder_setPauseRecording(pause);
  }

  @override
  void stopRecording() {
    _bindings.flutter_recorder_stopRecording();
  }

  @override
  void setFftSmoothing(double smooth) {
    _bindings.flutter_recorder_setFftSmoothing(smooth);
  }

  @override
  Float32List getFft() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> fft = calloc(256 * 4);
    _bindings.flutter_recorder_getFft(fft);

    final val = ffi.Pointer<ffi.Float>.fromAddress(fft.value.address);
    if (val == ffi.nullptr) return Float32List(256);

    final fftList = val.cast<ffi.Float>().asTypedList(256);
    calloc.free(fft);
    return fftList;
  }

  @override
  Float32List getWave() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> wave = calloc(256 * 4);
    _bindings.flutter_recorder_getWave(wave);

    final val = ffi.Pointer<ffi.Float>.fromAddress(wave.value.address);
    if (val == ffi.nullptr) return Float32List(256);

    final waveList = val.cast<ffi.Float>().asTypedList(256);
    calloc.free(wave);
    return waveList;
  }

  @override
  Float32List getTexture2D() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> data = calloc(512 * 256 * 4);
    _bindings.flutter_recorder_getTexture2D(data);

    final val = ffi.Pointer<ffi.Float>.fromAddress(data.value.address);
    if (val == ffi.nullptr) return Float32List(512 * 256);

    calloc.free(data);
    final textureList = val.cast<ffi.Float>().asTypedList(512 * 256);

    return textureList;
  }

  @override
  double getVolumeDb() {
    final ffi.Pointer<ffi.Float> volume = calloc(4);
    _bindings.flutter_recorder_getVolumeDb(volume);
    final v = volume.value;
    calloc.free(volume);
    return v;
  }

  @override
  int isFilterActive(RecorderFilterType filterType) {
    return _bindings.flutter_recorder_isFilterActive(filterType);
  }

  @override
  void addFilter(RecorderFilterType filterType) {
    final error = _bindings.flutter_recorder_addFilter(filterType);
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
  }

  @override
  CaptureErrors removeFilter(RecorderFilterType filterType) {
    final error = _bindings.flutter_recorder_removeFilter(filterType);
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(error);
    }
    return error;
  }

  @override
  List<String> getFilterParamNames(RecorderFilterType filterType) {
    final ffi.Pointer<ffi.Pointer<ffi.Char>> names =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Char>>>() * 30);
    final ffi.Pointer<ffi.Int> paramsCount = calloc(ffi.sizeOf<ffi.Int>());
    _bindings.flutter_recorder_getFilterParamNames(
      filterType,
      names,
      paramsCount,
    );
    final List<String> ret = [];
    for (var i = 0; i < paramsCount.value; i++) {
      final s1 = (names + i).value;
      final s = s1.cast<Utf8>().toDartString();
      ret.add(s);
      _bindings.flutter_recorder_nativeFree(s1.cast<ffi.Void>());
    }
    calloc
      ..free(names)
      ..free(paramsCount);
    return ret;
  }

  @override
  void setFilterParamValue(
    RecorderFilterType filterType,
    int attributeId,
    double value,
  ) {
    _bindings.flutter_recorder_setFilterParams(filterType, attributeId, value);
  }

  @override
  double getFilterParamValue(RecorderFilterType filterType, int attributeId) {
    return _bindings.flutter_recorder_getFilterParams(filterType, attributeId);
  }
}
