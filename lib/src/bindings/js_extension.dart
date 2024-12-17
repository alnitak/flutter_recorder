// ignore_for_file: public_member_api_docs, avoid_positional_boolean_parameters

import 'dart:js_interop';
import 'package:web/web.dart' as web;

// //////////////////////////
// common
// //////////////////////////
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

@JS('RecorderModule._createWorkerInWasm')
external void wasmCreateWorkerInWasm();

@JS('RecorderModule._setDartEventCallback')
external void wasmSetDartEventCallback(int callbackPtr, int callbackPtr2);

@JS('RecorderModule._sendToWorker')
external void wasmSendToWorker(int message, int value);

@JS('RecorderModule.wasmWorker')
external web.Worker wasmWorker;

// //////////////////////////
// bindings
// //////////////////////////

@JS('RecorderModule._setSilenceDetection')
external void wasmSetSilenceDetection(bool enable);

@JS('RecorderModule._setSilenceThresholdDb')
external void wasmSetSilenceThresholdDb(double silenceThresholdDb);

@JS('RecorderModule._setSilenceDuration')
external void wasmSetSilenceDuration(double silenceDuration);

@JS('RecorderModule._setSecondsOfAudioToWriteBefore')
external void wasmSetSecondsOfAudioToWriteBefore(
  double secondsOfAudioToWriteBefore,
);

@JS('RecorderModule._listCaptureDevices')
external void wasmListCaptureDevices(
  int namesPtr,
  int deviceIdPtr,
  int isDefaultPtr,
  int nDevicePtr,
);

@JS('RecorderModule._freeListCaptureDevices')
external void wasmFreeListCaptureDevices(
  int namesPtr,
  int deviceIdPtr,
  int isDefaultPtr,
  int nDevicePtr,
);

@JS('RecorderModule._init')
external int wasmInit(int deviceID, int format, int sampleRate, int channels);

@JS('RecorderModule._deinit')
external void wasmDeinit();

@JS('RecorderModule._isInited')
external int wasmIsDeviceInitialized();

@JS('RecorderModule._isDeviceStarted')
external int wasmIsDeviceStarted();

@JS('RecorderModule._start')
external int wasmStart();

@JS('RecorderModule._stop')
external void wasmStop();

@JS('RecorderModule._startStreamingData')
external void wasmStartStreamingData();

@JS('RecorderModule._stopStreamingData')
external void wasmStopStreamingData();

@JS('RecorderModule._startRecording')
external int wasmStartRecording(int pathPtr);

@JS('RecorderModule._setPauseRecording')
external void wasmSetPauseRecording(bool pause);

@JS('RecorderModule._stopRecording')
external void wasmStopRecording();

@JS('RecorderModule._setFftSmoothing')
external void wasmSetFftSmoothing(double smooth);

@JS('RecorderModule._getFft')
external void wasmGetFft(int samplesPtr);

@JS('RecorderModule._getWave')
external void wasmGetWave(int samplesPtr);

@JS('RecorderModule._getTexture')
external void wasmGetTexture(int samplesPtr);

@JS('RecorderModule._getTexture2D')
external void wasmGetTexture2D(int samplesPtr);

@JS('RecorderModule._getVolumeDb')
external void wasmGetVolumeDb(int volumeDbPtr);

@JS('RecorderModule._isFilterActive')
external int wasmIsFilterActive(int filterTypeId);

@JS('RecorderModule._addFilter')
external int wasmAddFilter(int filterTypeId);

@JS('RecorderModule._removeFilter')
external int wasmRemoveFilter(int filterTypeId);

@JS('RecorderModule._getFilterParamNames')
external int wasmGetFilterParamNames(
  int filterTypeId,
  int namesPtr,
  int paramsCountPtr,
);

@JS('RecorderModule._setFilterParams')
external void wasmSetFilterParamValue(
  int filterTypeId,
  int attributeId,
  double value,
);

@JS('RecorderModule._getFilterParams')
external double wasmGetFilterParamValue(int filterTypeId, int attributeId);
