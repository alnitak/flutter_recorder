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
external int wasmInit(int deviceID, int format, int sampleRate, int channels);

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
external void wasmStartStreamingData();

@JS('RecorderModule._flutter_recorder_stopStreamingData')
external void wasmStopStreamingData();

@JS('RecorderModule._flutter_recorder_startRecording')
external int wasmStartRecording(int pathPtr);

@JS('RecorderModule._flutter_recorder_setPauseRecording')
external void wasmSetPauseRecording(bool pause);

@JS('RecorderModule._flutter_recorder_stopRecording')
external void wasmStopRecording();

@JS('RecorderModule._flutter_recorder_setFftSmoothing')
external void wasmSetFftSmoothing(double smooth);

@JS('RecorderModule._flutter_recorder_getFft')
external void wasmGetFft(int samplesPtr);

@JS('RecorderModule._flutter_recorder_getWave')
external void wasmGetWave(int samplesPtr);

@JS('RecorderModule._flutter_recorder_getTexture')
external void wasmGetTexture(int samplesPtr);

@JS('RecorderModule._flutter_recorder_getTexture2D')
external void wasmGetTexture2D(int samplesPtr);

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
