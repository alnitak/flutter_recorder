// ignore_for_file: public_member_api_docs, avoid_positional_boolean_parameters

import 'dart:js_interop';
import 'package:web/web.dart' as web;

// //////////////////////////
// common
// //////////////////////////

@JS('globalThis.crossOriginIsolated')
external bool? get isCrossOriginIsolated;

@JS('globalThis.SharedArrayBuffer')
external JSObject? get sharedArrayBuffer;

/// The WASM module instance. Null until `init_recorder_module.dart.js` has
/// finished instantiating it (or if the glue failed to load).
@JS('self.RecorderModule')
external JSObject? get moduleRecorderInstance;

/// Promise exposed by `init_recorder_module.dart.js` that resolves when the
/// WASM module is ready. Used to wait out the startup race instead of crashing
/// when the recorder is initialized while the module is still loading.
@JS('self.flutter_recorder_ready')
external JSPromise? get flutterRecorderReady;

/// Whether the loaded WASM build was compiled with ASYNCIFY (only the
/// multi-threaded AudioWorklet build is). Set by
/// `init_recorder_module.dart.js`. Used to decide whether
/// `flutter_recorder_init` must go through `ccall({async: true})`.
@JS('self.flutter_recorder_has_asyncify')
external bool? get flutterRecorderHasAsyncify;

/// The WASM build flavor in use, set by `init_recorder_module.dart.js`:
/// `mt` (multi-threaded, requires cross-origin isolation),
/// `st` (single-threaded) or `manual` (glue script loaded by the page).
@JS('self.flutter_recorder_build')
external String? get flutterRecorderBuild;

@JS('self.flutter_recorder_force_single_threaded')
external bool? get forceSingleThreaded;

@JS('RecorderModule._malloc')
external int wasmMalloc(int bytesCount);

@JS('RecorderModule._free')
external void wasmFree(int ptrAddress);

@JS('RecorderModule.getValue')
external int wasmGetI32Value(int ptrAddress, String type);

@JS('RecorderModule.getValue')
external double wasmGetF32Value(int ptrAddress, String type);

@JS('RecorderModule.UTF8ToString')
external String wasmUtf8ToString(int ptrAddress);

@JS('RecorderModule.setValue')
external void wasmSetValue(int ptrAddress, int value, String type);

@JS('RecorderModule.cwrap')
external JSFunction wasmCwrap(
  JSString fName,
  JSString returnType,
  JSArray<JSString> argTypes,
);

@JS('RecorderModule.ccall')
external JSFunction wasmCccall(
  JSString fName,
  JSString returnType,
  JSArray<JSString> argTypes,
  JSArray<JSAny> args,
);

/// Calls a WASM export asynchronously (Emscripten `ccall` with
/// `{async: true}`).
///
/// Needed in the multi-threaded (AudioWorklet) build, which is compiled
/// with ASYNCIFY: exports that can reach `emscripten_sleep` (`init`,
/// via `ma_device_init`) unwind the WASM stack while the worklet thread
/// starts up. A synchronous call would return early with a garbage value;
/// the returned promise instead resolves with the actual return value once
/// the call completes.
@JS('RecorderModule.ccall')
external JSPromise<JSNumber> wasmCcallAsync(
  JSString fName,
  JSString returnType,
  JSArray<JSString> argTypes,
  JSArray<JSAny?> args,
  JSObject options,
);

@JS('RecorderModule._flutter_recorder_createWorkerInWasm')
external void wasmCreateWorkerInWasm();

@JS('RecorderModule._flutter_recorder_setDartEventCallback')
external void wasmSetDartEventCallback(int callbackPtr, int callbackPtr2);

@JS('RecorderModule.wasmWorker')
external web.Worker wasmWorker;

// //////////////////////////
// bindings
// //////////////////////////

@JS('RecorderModule._flutter_recorder_setSilenceDetection')
external void wasmSetSilenceDetection(bool enable);

@JS('RecorderModule._flutter_recorder_setSilenceThresholdDb')
external void wasmSetSilenceThresholdDb(double silenceThresholdDb);

@JS('RecorderModule._flutter_recorder_setSilenceDuration')
external void wasmSetSilenceDuration(double silenceDuration);

@JS('RecorderModule._flutter_recorder_setSecondsOfAudioToWriteBefore')
external void wasmSetSecondsOfAudioToWriteBefore(
  double secondsOfAudioToWriteBefore,
);

@JS('RecorderModule._flutter_recorder_listCaptureDevices')
external void wasmListCaptureDevices(
  int namesPtr,
  int deviceIdPtr,
  int isDefaultPtr,
  int nDevicePtr,
);

@JS('RecorderModule._flutter_recorder_freeListCaptureDevices')
external void wasmFreeListCaptureDevices(
  int namesPtr,
  int deviceIdPtr,
  int isDefaultPtr,
  int nDevicePtr,
);

@JS('RecorderModule._flutter_recorder_init')
external int wasmInit(
  int deviceID,
  int format,
  int sampleRate,
  int channels,
  int androidInputPreset,
);

@JS('RecorderModule._flutter_recorder_deinit')
external void wasmDeinit();

@JS('RecorderModule._flutter_recorder_isInited')
external int wasmIsDeviceInitialized();

@JS('RecorderModule._flutter_recorder_isDeviceStarted')
external int wasmIsDeviceStarted();

@JS('RecorderModule._flutter_recorder_start')
external int wasmStart();

@JS('RecorderModule._flutter_recorder_stop')
external void wasmStop();

@JS('RecorderModule._flutter_recorder_startStreamingData')
external void wasmStartStreamingData(int format);

@JS('RecorderModule._flutter_recorder_stopStreamingData')
external void wasmStopStreamingData();

@JS('RecorderModule._flutter_recorder_startRecording')
external int wasmStartRecording(int pathPtr, int format);

@JS('RecorderModule._flutter_recorder_setPauseRecording')
external void wasmSetPauseRecording(bool pause);

@JS('RecorderModule._flutter_recorder_stopRecording')
external void wasmStopRecording();

@JS('RecorderModule._flutter_recorder_setFftSmoothing')
external void wasmSetFftSmoothing(double smooth);

@JS('RecorderModule._flutter_recorder_setLoopback')
external void wasmSetLoopback(bool enable);

@JS('RecorderModule._flutter_recorder_isLoopbackEnabled')
external int wasmIsLoopbackEnabled();

@JS('RecorderModule.HEAPF32')
external JSFloat32Array get wasmHeapF32;

@JS('RecorderModule.HEAPU8')
external JSUint8Array get wasmHeapU8;

@JS('RecorderModule._flutter_recorder_setVisualizationEnabled')
external int wasmSetVisualizationEnabled(
  int enabled,
  int windowSize,
  int kind,
  int channel,
);

@JS('RecorderModule._flutter_recorder_isVisualizationEnabled')
external int wasmIsVisualizationEnabled();

@JS('RecorderModule._flutter_recorder_setDartVisualizationCallback')
external void wasmSetDartVisualizationCallback(int callbackPtr);

@JS('RecorderModule._flutter_recorder_getVolumeDb')
external void wasmGetVolumeDb(int volumeDbPtr);

@JS('RecorderModule._flutter_recorder_isFilterActive')
external int wasmIsFilterActive(int filterTypeId);

@JS('RecorderModule._flutter_recorder_addFilter')
external int wasmAddFilter(int filterTypeId);

@JS('RecorderModule._flutter_recorder_removeFilter')
external int wasmRemoveFilter(int filterTypeId);

@JS('RecorderModule._flutter_recorder_getFilterParamNames')
external int wasmGetFilterParamNames(
  int filterTypeId,
  int namesPtr,
  int paramsCountPtr,
);

@JS('RecorderModule._flutter_recorder_setFilterParams')
external void wasmSetFilterParamValue(
  int filterTypeId,
  int attributeId,
  double value,
);

@JS('RecorderModule._flutter_recorder_getFilterParams')
external double wasmGetFilterParamValue(int filterTypeId, int attributeId);
