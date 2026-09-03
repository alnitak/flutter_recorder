// ignore_for_file: omit_local_variable_types
// ignore_for_file: avoid_positional_boolean_parameters, public_member_api_docs

import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/audio_visualization_data.dart';
import 'package:flutter_recorder/src/bindings/darwin_engine_lifecycle.dart';
import 'package:flutter_recorder/src/bindings/flutter_recorder_bindings_generated.dart'
    as bindings;
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:meta/meta.dart';

final class _IsolateLifecycleToken implements ffi.Finalizable {}

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
  SilenceCallback? _silenceCallback;
  void Function(AudioVisualizationData data)? _visualizationCallback;

  late final ffi.NativeFinalizer _isolateFinalizer = ffi.NativeFinalizer(
    ffi.Native.addressOf(
      bindings.flutter_recorder_retireDartCallbacksFinalizer,
    ),
  );
  _IsolateLifecycleToken? _lifecycleToken;

  /// The engine ID of the current FlutterEngine, or -1 if unavailable.
  int get currentEngineId {
    try {
      return PlatformDispatcher.instance.engineId ?? -1;
    } on Object {
      return -1;
    }
  }

  void _silenceChangedCallback(
    ffi.Pointer<ffi.Bool> silence,
    ffi.Pointer<ffi.Float> db,
  ) {
    _silenceCallback?.call(silence.value, db.value);
    silenceChangedEventController.add((
      isSilent: silence.value,
      decibel: db.value,
    ));
  }

  void _streamDataCallback(ffi.Pointer<ffi.UnsignedChar> data, int dataLength) {
    try {
      // Direct copy from native buffer into Dart Uint8List without
      // intermediate List<int>.
      final audioData = Uint8List.fromList(
        data.cast<ffi.Uint8>().asTypedList(dataLength),
      );
      uint8ListController.add(AudioDataContainer(audioData));
    } finally {
      // Free the memory allocated in C++
      bindings.flutter_recorder_nativeFree(data.cast<ffi.Void>());
    }
  }

  void _visualizationDataCallback(
    int channelCount,
    ffi.Pointer<ffi.Pointer<ffi.Float>> waveDataPerChannel,
    int waveSamples,
    ffi.Pointer<ffi.Pointer<ffi.Float>> fftDataPerChannel,
    int fftSamples,
  ) {
    final waveList = <Float32List>[];
    if (waveSamples > 0 && waveDataPerChannel != ffi.nullptr) {
      for (var c = 0; c < channelCount; c++) {
        final ptr = waveDataPerChannel[c];
        if (ptr != ffi.nullptr) {
          waveList.add(Float32List.fromList(ptr.asTypedList(waveSamples)));
        }
      }
    }

    final fftList = <Float32List>[];
    if (fftSamples > 0 && fftDataPerChannel != ffi.nullptr) {
      for (var c = 0; c < channelCount; c++) {
        final ptr = fftDataPerChannel[c];
        if (ptr != ffi.nullptr) {
          fftList.add(Float32List.fromList(ptr.asTypedList(fftSamples)));
        }
      }
    }

    final packet = AudioVisualizationData(
      channelCount: channelCount,
      wave: waveList,
      fft: fftList,
    );

    _visualizationCallback?.call(packet);
    if (audioVisualizationEventsController.hasListener) {
      audioVisualizationEventsController.add(packet);
    }
  }

  void _deviceNotificationCallback(int eventType) {
    try {
      final notif = RecorderDeviceNotification.fromValue(eventType);
      if (deviceNotificationEventsController.hasListener) {
        deviceNotificationEventsController.add(notif);
      }
    } catch (_) {
      // Ignore unknown event type safely
    }
  }

  ffi.NativeCallable<bindings.dartSilenceChangedCallback_tFunction>?
  nativeSilenceChangedCallable;
  ffi.NativeCallable<bindings.dartStreamDataCallback_tFunction>?
  nativeStreamDataCallable;
  ffi.NativeCallable<bindings.dartVisualizationCallback_tFunction>?
  nativeVisualizationCallable;
  ffi.NativeCallable<bindings.dartDeviceNotificationCallback_tFunction>?
  nativeDeviceNotificationCallable;

  @override
  void disposeNativeCallables() {
    if (_lifecycleToken != null) {
      _isolateFinalizer.detach(_lifecycleToken!);
      _lifecycleToken = null;
    }
    nativeSilenceChangedCallable?.close();
    nativeSilenceChangedCallable = null;
    nativeStreamDataCallable?.close();
    nativeStreamDataCallable = null;
    nativeVisualizationCallable?.close();
    nativeVisualizationCallable = null;
    nativeDeviceNotificationCallable?.close();
    nativeDeviceNotificationCallable = null;
  }

  @override
  void clearDartCallbackRegistrations() {
    bindings.flutter_recorder_clearDartCallbackRegistrations();
  }

  @override
  Future<void> setDartEventCallbacks() async {
    disposeNativeCallables();

    nativeSilenceChangedCallable =
        ffi.NativeCallable<
          bindings.dartSilenceChangedCallback_tFunction
        >.listener(_silenceChangedCallback);

    nativeStreamDataCallable =
        ffi.NativeCallable<bindings.dartStreamDataCallback_tFunction>.listener(
          _streamDataCallback,
        );

    nativeVisualizationCallable =
        ffi.NativeCallable<
          bindings.dartVisualizationCallback_tFunction
        >.listener(_visualizationDataCallback);

    nativeDeviceNotificationCallable =
        ffi.NativeCallable<
          bindings.dartDeviceNotificationCallback_tFunction
        >.listener(_deviceNotificationCallback);

    bindings.flutter_recorder_setDartEventCallbackForEngine(
      nativeSilenceChangedCallable!.nativeFunction,
      nativeStreamDataCallable!.nativeFunction,
      currentEngineId,
    );
    bindings.flutter_recorder_setDartVisualizationCallbackForEngine(
      nativeVisualizationCallable!.nativeFunction,
      currentEngineId,
    );
    bindings.flutter_recorder_setDartDeviceNotificationCallbackForEngine(
      nativeDeviceNotificationCallable!.nativeFunction,
      currentEngineId,
    );

    _lifecycleToken = _IsolateLifecycleToken();
    _isolateFinalizer.attach(
      _lifecycleToken!,
      ffi.Pointer.fromAddress(currentEngineId),
      detach: _lifecycleToken,
    );
  }

  @override
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    bindings.flutter_recorder_setSilenceDetection(enable);

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
    bindings.flutter_recorder_setSilenceThresholdDb(silenceThresholdDb);
  }

  @override
  void setSilenceDuration(double silenceDuration) {
    assert(silenceDuration >= 0, 'silenceDuration must be >= 0');
    bindings.flutter_recorder_setSilenceDuration(silenceDuration);
  }

  @override
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    assert(
      secondsOfAudioToWriteBefore >= 0,
      'secondsOfAudioToWriteBefore must be >= 0',
    );
    bindings.flutter_recorder_setSecondsOfAudioToWriteBefore(
      secondsOfAudioToWriteBefore,
    );
  }

  @override
  List<CaptureDevice> listCaptureDevices() {
    final ret = <CaptureDevice>[];
    final ffi.Pointer<ffi.Pointer<ffi.Char>> deviceNames = calloc(
      ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Char>>>() * 255,
    );
    final ffi.Pointer<ffi.Pointer<ffi.Int>> deviceIds = calloc(
      ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Int>>>() * 50,
    );
    final ffi.Pointer<ffi.Pointer<ffi.Int>> deviceIsDefault = calloc(
      ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Int>>>() * 50,
    );
    final ffi.Pointer<ffi.Int> nDevices = calloc();

    bindings.flutter_recorder_listCaptureDevices(
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
    bindings.flutter_recorder_freeListCaptureDevices(
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
  Future<void> init({
    required int deviceID,
    required PCMFormat format,
    required int sampleRate,
    required RecorderChannels channels,
    required AndroidInputPreset? androidInputPreset,
    required IosInputPreset? iosInputPreset,
    required WebInputPreset? webInputPreset,
  }) async {
    if (DarwinEngineLifecycle.isSupported) {
      final shutdownEpoch = bindings
          .flutter_recorder_currentEngineShutdownEpoch();
      const darwinLifecycle = DarwinEngineLifecycle();
      final result = await darwinLifecycle.prepareEngineInit(
        currentEngineId,
        shutdownEpoch,
      );
      if (result == DarwinEnginePrepareResult.unavailable) {
        bindings.flutter_recorder_prepareEngineInit(currentEngineId);
      }
    } else {
      bindings.flutter_recorder_prepareEngineInit(currentEngineId);
    }

    final error = bindings.flutter_recorder_init(
      deviceID,
      format.value,
      sampleRate,
      channels.count,
      androidInputPreset?.value ?? 0,
      iosInputPreset?.value ?? 0,
    );
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
    super.init(
      deviceID: deviceID,
      format: format,
      sampleRate: sampleRate,
      channels: channels,
      androidInputPreset: androidInputPreset,
      iosInputPreset: iosInputPreset,
      webInputPreset: webInputPreset,
    );
  }

  @override
  void deinit() {
    disposeNativeCallables();
    bindings.flutter_recorder_stopRecording();
    bindings.flutter_recorder_stopStreamingData();
    bindings.flutter_recorder_stop();
    bindings.flutter_recorder_deinit();

    _silenceCallback = null;
    _visualizationCallback = null;
    super.deinit();
  }

  @override
  bool isDeviceInitialized() {
    return bindings.flutter_recorder_isInited() == 1;
  }

  @override
  bool isDeviceStarted() {
    return bindings.flutter_recorder_isDeviceStarted() == 1;
  }

  @override
  void start() {
    final error = bindings.flutter_recorder_start();
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  void stop() {
    bindings.flutter_recorder_stop();
  }

  @override
  void startStreamingData({required StreamingFormat format}) {
    bindings.flutter_recorder_startStreamingData(format.value);
  }

  @override
  void stopStreamingData() {
    bindings.flutter_recorder_stopStreamingData();
  }

  @override
  void startRecording(String path, {required RecordingFormat format}) {
    var errorDescription = '';
    // Check the file name is valid for the different platforms.
    bool isValidPathName() {
      // Reserved Windows filenames - these apply to any part of the path
      const reservedNames = {
        'CON', 'PRN', 'AUX', 'NUL',
        'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
        'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
        // ignore: require_trailing_commas
      };

      switch (defaultTargetPlatform) {
        case TargetPlatform.windows:
          bool isValidDriveChar(int value) {
            return ((value | 0x20) - 'a'.codeUnitAt(0)) <=
                ('z'.codeUnitAt(0) - 'a'.codeUnitAt(0));
          }

          bool isDriveCharWithVolumeSeparatorChar(String path) {
            return path.length >= 2 &&
                isValidDriveChar(path.codeUnitAt(0)) &&
                path[1] == ':';
          }

          // Split path into components
          final pathParts = path.split(RegExp(r'[/\\]'));

          var needSkipCheckFirst = isDriveCharWithVolumeSeparatorChar(path);

          // Check each component
          for (final part in pathParts) {
            // Skip empty parts
            if (part.isEmpty) continue;

            if (needSkipCheckFirst) {
              needSkipCheckFirst = false;
              continue;
            }

            if (part.length == 1 && part == '.') continue;

            // Check for invalid characters in each part
            if (part.contains(RegExp('[:*?"<>|]')) ||
                reservedNames.contains(part.toUpperCase().split('.').first) ||
                part.endsWith(' ') ||
                part.endsWith('.')) {
              errorDescription =
                  'Invalid path component "$part". Path '
                  'components must not '
                  'contain any of these characters: :*?"<>| '
                  'or be a reserved name, or end with space/period.';
              return false;
            }
          }

          // Check total path length (Windows MAX_PATH is 260)
          if (path.length > 259) {
            errorDescription =
                'Path is too long. Windows paths must be '
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
            errorDescription =
                'Path contains invalid characters. '
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

    final error = bindings.flutter_recorder_startRecording(
      path.toNativeUtf8().cast(),
      format.value,
    );
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  void setPauseRecording({required bool pause}) {
    bindings.flutter_recorder_setPauseRecording(pause);
  }

  @override
  void stopRecording() {
    bindings.flutter_recorder_stopRecording();
  }

  @override
  void setFftSmoothing(double smooth) {
    bindings.flutter_recorder_setFftSmoothing(smooth);
  }

  @override
  void setVisualizationEnabled(
    bool enabled, {
    int windowSize = 256,
    VisualizationKind kind = VisualizationKind.waveAndFft,
    int channel = VisualizationChannel.merged,
  }) {
    final error = bindings.flutter_recorder_setVisualizationEnabled(
      enabled,
      windowSize,
      kind.value,
      channel,
    );
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  bool getVisualizationEnabled() {
    return bindings.flutter_recorder_isVisualizationEnabled() == 1;
  }

  @override
  void setVisualizationCallback(
    void Function(AudioVisualizationData data)? callback,
  ) {
    _visualizationCallback = callback;
  }

  @override
  double getVolumeDb() {
    final ffi.Pointer<ffi.Float> volume = calloc(4);
    bindings.flutter_recorder_getVolumeDb(volume);
    final v = volume.value;
    calloc.free(volume);
    return v;
  }

  @override
  int isFilterActive(RecorderFilterType filterType) {
    return bindings.flutter_recorder_isFilterActive(filterType.value);
  }

  @override
  void addFilter(RecorderFilterType filterType) {
    final error = bindings.flutter_recorder_addFilter(filterType.value);
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  CaptureErrors removeFilter(RecorderFilterType filterType) {
    final error = bindings.flutter_recorder_removeFilter(filterType.value);
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
    return CaptureErrors.fromValue(error);
  }

  @override
  List<String> getFilterParamNames(RecorderFilterType filterType) {
    final ffi.Pointer<ffi.Pointer<ffi.Char>> names = calloc(
      ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Char>>>() * 30,
    );
    final ffi.Pointer<ffi.Int> paramsCount = calloc(ffi.sizeOf<ffi.Int>());
    bindings.flutter_recorder_getFilterParamNames(
      filterType.value,
      names,
      paramsCount,
    );
    final List<String> ret = [];
    for (var i = 0; i < paramsCount.value; i++) {
      final s1 = (names + i).value;
      final s = s1.cast<Utf8>().toDartString();
      ret.add(s);
      bindings.flutter_recorder_nativeFree(s1.cast<ffi.Void>());
    }
    calloc
      ..free(names)
      ..free(paramsCount);
    return ret;
  }

  @override
  void setLoopback({required bool enable}) {
    bindings.flutter_recorder_setLoopback(enable);
  }

  @override
  bool isLoopbackEnabled() {
    return bindings.flutter_recorder_isLoopbackEnabled() == 1;
  }

  @override
  void setFilterParamValue(
    RecorderFilterType filterType,
    int attributeId,
    double value,
  ) {
    bindings.flutter_recorder_setFilterParams(
      filterType.value,
      attributeId,
      value,
    );
  }

  @override
  double getFilterParamValue(RecorderFilterType filterType, int attributeId) {
    return bindings.flutter_recorder_getFilterParams(
      filterType.value,
      attributeId,
    );
  }

  @override
  void feedPlaybackData(
    Uint8List data, {
    required PCMFormat format,
    required RecorderChannels channels,
  }) {
    if (data.isEmpty) return;
    final bytesPerSample = format.sampleSize;
    final totalSamples = data.lengthInBytes ~/ bytesPerSample;
    final frameCount = totalSamples ~/ channels.count;
    if (frameCount == 0) return;

    using((Arena arena) {
      final ptr = arena<ffi.Uint8>(data.lengthInBytes);
      ptr.asTypedList(data.lengthInBytes).setAll(0, data);
      bindings.flutter_recorder_feedPlaybackData(
        ptr.cast<ffi.Void>(),
        frameCount,
        channels.count,
        format.value,
      );
    });
  }
}
