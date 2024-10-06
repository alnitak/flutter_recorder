// ignore_for_file: omit_local_variable_types, avoid_positional_boolean_parameters, public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/src/bindings/js_extension.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:flutter_recorder/src/worker/worker.dart';
import 'package:meta/meta.dart';

@internal
class RecorderController {
  factory RecorderController() => _instance ??= RecorderController._();

  RecorderController._() {
    impl = RecorderWeb();
  }
  static RecorderController? _instance;

  late final RecorderImpl impl;
}

/// Use this class to _capture_ audio (such as from a microphone).
@internal
class RecorderWeb extends RecorderImpl {
  /// Controller to listen to silence changed event.
  late final StreamController<SilenceState> silenceChangedEventController =
      StreamController.broadcast();

  /// Listener for silence changed.
  @override
  Stream<SilenceState> get silenceChangedEvents =>
      silenceChangedEventController.stream;

  SilenceCallback? _silenceCallback;

  /// Create the worker in the WASM Module and listen for events coming
  /// from `web/worker.dart.js`
  @override
  void setDartEventCallbacks() {
    // This calls the native WASM `createWorkerInWasm()` in `bindings.cpp`.
    // The latter creates a web Worker using `EM_ASM` inlining JS code to
    // create the worker in the WASM `Module`.
    wasmCreateWorkerInWasm();

    wasmSetDartEventCallback(0);

    // Here the `Module.wasmModule` binded to a local [WorkerController]
    // is used in the main isolate to listen for events coming from native.
    // From native the events can be sent from the main thread and even from
    // other threads like the audio thread.
    final workerController = WorkerController()..setWasmWorker(wasmWorker);
    workerController.onReceive().listen(
      (event) {
        /// The [event] coming from `web/worker.dart.js` is of String type.
        /// Only `voiceEndedCallback` event in web for now.
        // print('recorder_web: Received $event\n');
        switch (event) {
          case String():
            final decodedMap = jsonDecode(event) as Map;
            if (decodedMap['message'] == 'silenceChangedCallback') {
              final silence = (decodedMap['isSilent'] as int) == 1;
              final db = decodedMap['energyDb'] as double;
              _silenceCallback?.call(silence, db);
              silenceChangedEventController.add(
                (isSilent: silence, decibel: db),
              );
            }
        }
      },
    );
  }

  @override
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    wasmSetSilenceDetection(enable);

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
    wasmSetSilenceThresholdDb(silenceThresholdDb);
  }

  @override
  void setSilenceDuration(double silenceDuration) {
    assert(silenceDuration >= 0, 'silenceDuration must be >= 0');
    wasmSetSilenceDuration(silenceDuration);
  }

  @override
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    assert(
      secondsOfAudioToWriteBefore >= 0,
      'secondsOfAudioToWriteBefore must be >= 0',
    );
    wasmSetSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
  }

  @override
  List<CaptureDevice> listCaptureDevices() {
    /// allocate 50 device strings
    final namesPtr = wasmMalloc(50 * 255);
    final deviceIdPtr = wasmMalloc(50 * 4);
    final isDefaultPtr = wasmMalloc(50 * 4);
    final nDevicesPtr = wasmMalloc(4); // 4 bytes for an int

    wasmListCaptureDevices(
      namesPtr,
      deviceIdPtr,
      isDefaultPtr,
      nDevicesPtr,
    );

    final nDevices = wasmGetI32Value(nDevicesPtr, '*');
    final devices = <CaptureDevice>[];
    for (var i = 0; i < nDevices; i++) {
      final namePtr = wasmGetI32Value(namesPtr + i * 4, '*');
      final name = wasmUtf8ToString(namePtr);
      final deviceId =
          wasmGetI32Value(wasmGetI32Value(deviceIdPtr + i * 4, '*'), '*');
      final isDefault =
          wasmGetI32Value(wasmGetI32Value(isDefaultPtr + i * 4, '*'), '*');

      devices.add(CaptureDevice(name, isDefault == 1, deviceId));
    }

    wasmFreeListCaptureDevices(namesPtr, deviceIdPtr, isDefaultPtr, nDevices);

    wasmFree(nDevicesPtr);
    wasmFree(deviceIdPtr);
    wasmFree(isDefaultPtr);
    wasmFree(namesPtr);

    return devices;
  }

  @override
  void init({int deviceID = -1}) {
    final error = wasmInit(deviceID);
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  void deinit() {
    _silenceCallback = null;
    wasmDeinit();
  }

  @override
  bool isDeviceInitialized() {
    return wasmIsDeviceInitialized() == 1;
  }

  @override
  bool isDeviceStartedListen() {
    return wasmIsDeviceStartedListen() == 1;
  }

  @override
  void startListen() {
    final error = wasmStartListen();
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  void stopListen() {
    wasmStopListen();
  }

  @override
  void startRecording(String path) {
    final pathPtr = wasmMalloc(path.length);
    for (var i = 0; i < path.length; i++) {
      wasmSetValue(pathPtr + i, path.codeUnits[i], 'i8');
    }
    final error = wasmStartRecording(pathPtr);
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  void setPauseRecording({required bool pause}) {
    wasmSetPauseRecording(pause);
  }

  @override
  void stopRecording() {
    wasmStopRecording();
  }

  @override
  void setFftSmoothing(double smooth) {
    wasmSetFftSmoothing(smooth);
  }

  @override
  Float32List getFft() {
    final samplesPtr = wasmMalloc(4);
    wasmGetFft(samplesPtr);
    final samplesPtr2 = wasmGetI32Value(samplesPtr, '*');
    final samples = Float32List(256);
    for (var i = 0; i < 256; i++) {
      samples[i] = wasmGetF32Value(samplesPtr2 + i * 4, 'float');
    }
    wasmFree(samplesPtr);
    return samples;
  }

  @override
  Float32List getWave() {
    final samplesPtr = wasmMalloc(4);
    wasmGetWave(samplesPtr);
    final samplesPtr2 = wasmGetI32Value(samplesPtr, '*');
    final samples = Float32List(256);
    for (var i = 0; i < 256; i++) {
      samples[i] = wasmGetF32Value(samplesPtr2 + i * 4, 'float');
    }
    wasmFree(samplesPtr);
    return samples;
  }

  @override
  Float32List getTexture2D() {
    final samplesPtr = wasmMalloc(4);
    wasmGetTexture2D(samplesPtr);
    final samplesPtr2 = wasmGetI32Value(samplesPtr, '*');
    final samples = Float32List(512 * 256);
    for (var i = 0; i < 512 * 256; i++) {
      samples[i] = wasmGetF32Value(samplesPtr2 + i * 4, 'float');
    }
    wasmFree(samplesPtr);
    return samples;
  }

  @override
  double getVolumeDb() {
    final volumeDbPtr = wasmMalloc(4);
    wasmGetVolumeDb(volumeDbPtr);
    final volumeDb = wasmGetF32Value(volumeDbPtr, 'float');
    wasmFree(volumeDbPtr);
    return volumeDb;
  }
}
