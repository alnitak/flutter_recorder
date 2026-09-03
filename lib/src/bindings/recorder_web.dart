import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data' show Float32List, Uint8List;

import 'package:flutter_recorder/src/audio_data_container.dart';
import 'package:flutter_recorder/src/audio_visualization_data.dart';
import 'package:flutter_recorder/src/bindings/js_extension.dart';
import 'package:flutter_recorder/src/bindings/recorder.dart';
import 'package:flutter_recorder/src/enums.dart';
import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/filters.dart';
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
  RecorderWeb() {
    _hookGetUserMedia();
  }

  SilenceCallback? _silenceCallback;
  void Function(AudioVisualizationData data)? _visualizationCallback;
  bool _wasmVisualizationCallbackSetUp = false;

  /// Calls `flutter_recorder_init`. In the multi-threaded (AudioWorklet)
  /// build this can reach `emscripten_sleep` (miniaudio spin-waits while the
  /// worklet thread starts up), and the ASYNCIFY build requires them to be
  /// called with `{async: true}`. The single-threaded build has no ASYNCIFY,
  /// so there it is a plain synchronous call.
  Future<int> _callEngineAsync(String fn, List<int> args) async {
    await _ensureModuleReady();
    if (flutterRecorderHasAsyncify != true) {
      if (fn == 'flutter_recorder_init') {
        return wasmInit(
          args[0],
          args[1],
          args[2],
          args[3],
          args.length > 4 ? args[4] : 0,
          args.length > 5 ? args[5] : 0,
        );
      }
      throw UnimplementedError('Unknown async function: $fn');
    }
    final promise = wasmCcallAsync(
      fn.toJS,
      'number'.toJS,
      List.filled(args.length, 'number'.toJS).toJS,
      args.map((a) => a.toJS).toList().toJS,
      <String, Object>{'async': true}.jsify()! as JSObject,
    );
    final ret = (await promise.toDart).toDartInt;
    return ret;
  }

  bool _getUserMediaHooked = false;

  void _hookGetUserMedia() {
    if (_getUserMediaHooked) return;
    _getUserMediaHooked = true;
    try {
      final nav = globalContext.getProperty<JSObject?>('navigator'.toJS);
      final mediaDevices = nav?.getProperty<JSObject?>('mediaDevices'.toJS);
      if (mediaDevices == null) return;

      final origGetUserMedia = mediaDevices.getProperty<JSFunction?>(
        'getUserMedia'.toJS,
      );
      if (origGetUserMedia == null) return;

      JSPromise customGetUserMedia(JSObject? rawConstraints) {
        final constraints = rawConstraints ?? JSObject();
        final stored = globalContext.getProperty<JSObject?>(
          '_flutterRecorderWebAudioConstraints'.toJS,
        );

        if (stored != null) {
          final audioProp = constraints.getProperty<JSAny?>('audio'.toJS);
          if (audioProp != null && audioProp.isA<JSBoolean>()) {
            constraints.setProperty('audio'.toJS, stored);
          } else if (audioProp != null && audioProp.isA<JSObject>()) {
            final audioObj = audioProp as JSObject;
            final echo = stored.getProperty<JSBoolean?>(
              'echoCancellation'.toJS,
            );
            final agc = stored.getProperty<JSBoolean?>('autoGainControl'.toJS);
            final noise = stored.getProperty<JSBoolean?>(
              'noiseSuppression'.toJS,
            );
            if (echo != null) {
              audioObj.setProperty('echoCancellation'.toJS, echo);
            }
            if (agc != null) {
              audioObj.setProperty('autoGainControl'.toJS, agc);
            }
            if (noise != null) {
              audioObj.setProperty('noiseSuppression'.toJS, noise);
            }
          } else if (audioProp == null) {
            constraints.setProperty('audio'.toJS, stored);
          }
        }

        final promise =
            (origGetUserMedia.callAsFunction(mediaDevices, constraints)
                as JSPromise?)!;

        return promise.toDart.then((stream) {
          if (stream != null) {
            globalContext.setProperty(
              '_flutterRecorderActiveMediaStream'.toJS,
              stream as JSObject,
            );
          }
          return stream;
        }).toJS;
      }

      mediaDevices.setProperty('getUserMedia'.toJS, customGetUserMedia.toJS);
    } catch (_) {
      // Ignore if navigator.mediaDevices is not available or restricted
    }
  }

  /// Waits for the WASM module to finish loading. `Recorder.init()` can be
  /// called by the app while `init_recorder_module.dart.js` is still
  /// instantiating the module; without this the first bindings call would hit
  /// a not-yet-defined `RecorderModule`.
  Future<void> _ensureModuleReady() async {
    _hookGetUserMedia();
    if (_isModuleInstantiated()) return;
    final ready = flutterRecorderReady;
    if (ready != null) {
      await ready.toDart.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'flutter_recorder: the WASM module did not finish initializing in '
          '15 seconds. If you serve the app with COOP/COEP headers, make '
          'sure they are not duplicated or conflicting, which blocks the '
          'worker threads the module needs.',
        ),
      );
      return;
    }
    for (var i = 0; i < 100 && !_isModuleInstantiated(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final r = flutterRecorderReady;
      if (r != null) {
        await r.toDart;
        return;
      }
    }
  }

  /// Whether `self.RecorderModule` is the fully instantiated WASM module.
  bool _isModuleInstantiated() {
    final instance = moduleRecorderInstance;
    return instance != null && !instance.isA<JSFunction>();
  }

  void _setupWasmVisualizationCallback() {
    if (_wasmVisualizationCallbackSetUp) return;
    _wasmVisualizationCallbackSetUp = true;

    void webVisualizationCallback(
      JSNumber channelCount,
      JSNumber waveDataPerChannelPtr,
      JSNumber waveSamples,
      JSNumber fftDataPerChannelPtr,
      JSNumber fftSamples,
    ) {
      final cCount = channelCount.toDartInt;
      final wavePtr = waveDataPerChannelPtr.toDartInt;
      final wSamples = waveSamples.toDartInt;
      final fftPtr = fftDataPerChannelPtr.toDartInt;
      final fSamples = fftSamples.toDartInt;

      try {
        final heap = wasmHeapF32.toDart;
        final heapLen = heap.length;

        final waveList = <Float32List>[];
        if (wSamples > 0 && wavePtr != 0) {
          for (var c = 0; c < cCount; c++) {
            final channelPtr = wasmGetI32Value(wavePtr + (c * 4), 'i32');
            if (channelPtr != 0) {
              final startIndex = channelPtr >> 2;
              final endIndex = startIndex + wSamples;
              if (startIndex >= 0 && endIndex <= heapLen) {
                waveList.add(heap.sublist(startIndex, endIndex));
              }
            }
          }
        }

        final fftList = <Float32List>[];
        if (fSamples > 0 && fftPtr != 0) {
          for (var c = 0; c < cCount; c++) {
            final channelPtr = wasmGetI32Value(fftPtr + (c * 4), 'i32');
            if (channelPtr != 0) {
              final startIndex = channelPtr >> 2;
              final endIndex = startIndex + fSamples;
              if (startIndex >= 0 && endIndex <= heapLen) {
                fftList.add(heap.sublist(startIndex, endIndex));
              }
            }
          }
        }

        final packet = AudioVisualizationData(
          channelCount: cCount,
          wave: waveList,
          fft: fftList,
        );

        _visualizationCallback?.call(packet);
        if (audioVisualizationEventsController.hasListener) {
          audioVisualizationEventsController.add(packet);
        }
      } catch (_) {
        // Ignore stale frames during WASM heap growth or reinitialization
      }
    }

    globalContext.setProperty(
      '_wasmRecorderVisualizationCallback'.toJS,
      webVisualizationCallback.toJS,
    );
  }

  /// Create the worker in the WASM Module and listen for events coming
  /// from `web/worker.dart.js`
  @override
  Future<void> setDartEventCallbacks() async {
    await _ensureModuleReady();

    // This calls the native WASM `createWorkerInWasm()` in `bindings.cpp`.
    // The latter creates a web Worker using `EM_ASM` inlining JS code to
    // create the worker in the WASM `Module`.
    wasmCreateWorkerInWasm();

    wasmSetDartEventCallback(0, 0);

    // Here the `RecorderModule.wasmModule` binded to a local [WorkerController]
    // is used in the main isolate to listen for events coming from native.
    // From native the events can be sent from the main thread and even from
    // other threads like the audio thread.
    final workerController = WorkerController()..setWasmWorker(wasmWorker);
    workerController.onReceive().listen((event) {
      /// The [event] coming from `web/worker.dart.js` is of Map type.
      switch (event) {
        case Map():
          if (event['message'] == 'silenceChangedCallback') {
            final silence = (event['isSilent'] as int) == 1;
            final db = event['energyDb'] as double;
            _silenceCallback?.call(silence, db);
            silenceChangedEventController.add((isSilent: silence, decibel: db));
          }

          if (event['message'] == 'streamDataCallback') {
            final audioData = event['data'] as Uint8List;
            uint8ListController.add(AudioDataContainer(audioData));
          }
      }
    });
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

    wasmListCaptureDevices(namesPtr, deviceIdPtr, isDefaultPtr, nDevicesPtr);

    final nDevices = wasmGetI32Value(nDevicesPtr, '*');
    final devices = <CaptureDevice>[];
    for (var i = 0; i < nDevices; i++) {
      final namePtr = wasmGetI32Value(namesPtr + i * 4, '*');
      final name = wasmUtf8ToString(namePtr);
      final deviceId = wasmGetI32Value(
        wasmGetI32Value(deviceIdPtr + i * 4, '*'),
        '*',
      );
      final isDefault = wasmGetI32Value(
        wasmGetI32Value(isDefaultPtr + i * 4, '*'),
        '*',
      );

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
  Future<void> init({
    required int deviceID,
    required PCMFormat format,
    required int sampleRate,
    required RecorderChannels channels,
    required AndroidInputPreset? androidInputPreset,
    required IosInputPreset? iosInputPreset,
    required WebInputPreset? webInputPreset,
  }) async {
    _applyWebInputPreset(webInputPreset ?? WebInputPreset.unprocessed);
    await _ensureModuleReady();
    final error = await _callEngineAsync('flutter_recorder_init', [
      deviceID,
      format.value,
      sampleRate,
      channels.count,
      androidInputPreset?.value ?? 0,
      iosInputPreset?.value ?? 0,
    ]);
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
    _silenceCallback = null;
    final activeStream = globalContext.getProperty<JSObject?>(
      '_flutterRecorderActiveMediaStream'.toJS,
    );
    if (activeStream != null) {
      try {
        final getTracks = activeStream.getProperty<JSFunction>(
          'getTracks'.toJS,
        );
        final tracks =
            getTracks.callAsFunction(activeStream)! as JSArray<JSObject>;
        for (var i = 0; i < tracks.length; i++) {
          final track = tracks[i];
          track.getProperty<JSFunction>('stop'.toJS).callAsFunction(track);
        }
      } catch (_) {}
      globalContext.setProperty('_flutterRecorderActiveMediaStream'.toJS, null);
    }
    wasmDeinit();
    super.deinit();
  }

  @override
  bool isDeviceInitialized() {
    return wasmIsDeviceInitialized() == 1;
  }

  @override
  bool isDeviceStarted() {
    return wasmIsDeviceStarted() == 1;
  }

  @override
  void start() {
    final error = wasmStart();
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  void stop() {
    wasmStop();
  }

  @override
  void startStreamingData({required StreamingFormat format}) {
    wasmStartStreamingData(format.value);
  }

  @override
  void stopStreamingData() {
    wasmStopStreamingData();
  }

  @override
  void startRecording(String path, {required RecordingFormat format}) {
    final pathPtr = wasmMalloc(path.length);
    for (var i = 0; i < path.length; i++) {
      wasmSetValue(pathPtr + i, path.codeUnits[i], 'i8');
    }
    final error = wasmStartRecording(pathPtr, format.value);
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
  void setVisualizationEnabled(
    bool enabled, {
    int windowSize = 256,
    VisualizationKind kind = VisualizationKind.waveAndFft,
    int channel = VisualizationChannel.merged,
  }) {
    if (enabled) {
      _setupWasmVisualizationCallback();
    }
    final error = wasmSetVisualizationEnabled(
      enabled ? 1 : 0,
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
    return wasmIsVisualizationEnabled() == 1;
  }

  @override
  void setVisualizationCallback(
    void Function(AudioVisualizationData data)? callback,
  ) {
    _visualizationCallback = callback;
    if (callback != null) {
      _setupWasmVisualizationCallback();
    }
  }

  @override
  double getVolumeDb() {
    final volumeDbPtr = wasmMalloc(4);
    wasmGetVolumeDb(volumeDbPtr);
    final volumeDb = wasmGetF32Value(volumeDbPtr, 'float');
    wasmFree(volumeDbPtr);
    return volumeDb;
  }

  @override
  int isFilterActive(RecorderFilterType filterType) {
    return wasmIsFilterActive(filterType.value);
  }

  @override
  void addFilter(RecorderFilterType filterType) {
    final error = wasmAddFilter(filterType.value);
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
  }

  @override
  CaptureErrors removeFilter(RecorderFilterType filterType) {
    final error = wasmRemoveFilter(filterType.value);
    if (CaptureErrors.fromValue(error) != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromRecorderError(
        CaptureErrors.fromValue(error),
      );
    }
    return CaptureErrors.fromValue(error);
  }

  @override
  List<String> getFilterParamNames(RecorderFilterType filterType) {
    final namesPtr = wasmMalloc(4);
    final paramsCountPtr = wasmMalloc(4);
    wasmGetFilterParamNames(filterType.value, namesPtr, paramsCountPtr);
    final namesPtr2 = wasmGetI32Value(namesPtr, '*');
    final paramsCount = wasmGetI32Value(paramsCountPtr, '*');
    final names = <String>[];
    for (var i = 0; i < paramsCount; i++) {
      final namePtr = wasmGetI32Value(namesPtr2 + i * 4, '*');
      final name = wasmUtf8ToString(namePtr);
      names.add(name);
    }
    wasmFree(namesPtr);
    wasmFree(paramsCountPtr);
    return names;
  }

  @override
  void setLoopback({required bool enable}) {
    wasmSetLoopback(enable);
  }

  @override
  bool isLoopbackEnabled() {
    return wasmIsLoopbackEnabled() == 1;
  }

  @override
  void setFilterParamValue(
    RecorderFilterType filterType,
    int attributeId,
    double value,
  ) {
    wasmSetFilterParamValue(filterType.value, attributeId, value);
  }

  @override
  double getFilterParamValue(RecorderFilterType filterType, int attributeId) {
    final value = wasmGetFilterParamValue(filterType.value, attributeId);
    return value;
  }

  @override
  void feedPlaybackData(
    Uint8List data, {
    required PCMFormat format,
    required RecorderChannels channels,
  }) {
    // Web implementation
  }

  void _applyWebInputPreset(WebInputPreset preset) {
    _hookGetUserMedia();

    final bool echoCancellation;
    final bool autoGainControl;
    final bool noiseSuppression;

    switch (preset) {
      case WebInputPreset.unprocessed:
        echoCancellation = false;
        autoGainControl = false;
        noiseSuppression = false;
      case WebInputPreset.voiceCommunication:
        echoCancellation = true;
        autoGainControl = true;
        noiseSuppression = true;
      case WebInputPreset.voiceRecognition:
        echoCancellation = false;
        autoGainControl = true;
        noiseSuppression = true;
      case WebInputPreset.noiseSuppression:
        echoCancellation = false;
        autoGainControl = false;
        noiseSuppression = true;
      case WebInputPreset.echoCancellation:
        echoCancellation = true;
        autoGainControl = false;
        noiseSuppression = false;
    }

    final constraints =
        <String, Object>{
              'echoCancellation': echoCancellation,
              'autoGainControl': autoGainControl,
              'noiseSuppression': noiseSuppression,
            }.jsify()!
            as JSObject;

    globalContext.setProperty(
      '_flutterRecorderWebAudioConstraints'.toJS,
      constraints,
    );
  }
}
