// ignore_for_file: public_member_api_docs, avoid_positional_boolean_parameters

import 'dart:js_interop';
import 'package:web/web.dart' as web;

// //////////////////////////
// common
// //////////////////////////
@JS('Module._malloc')
external int wasmMalloc(int bytesCount);

@JS('Module._free')
external void wasmFree(int ptrAddress);

@JS('Module.getValue')
external int wasmGetI32Value(int ptrAddress, String type);

@JS('Module.getValue')
external double wasmGetF32Value(int ptrAddress, String type);

@JS('Module.UTF8ToString')
external String wasmUtf8ToString(int ptrAddress);

@JS('Module.setValue')
external void wasmSetValue(int ptrAddress, int value, String type);

@JS('Module.cwrap')
external JSFunction wasmCwrap(
  JSString fName,
  JSString returnType,
  JSArray<JSString> argTypes,
);

@JS('Module.ccall')
external JSFunction wasmCccall(
  JSString fName,
  JSString returnType,
  JSArray<JSString> argTypes,
  JSArray<JSAny> args,
);

@JS('Module._createWorkerInWasm')
external void wasmCreateWorkerInWasm();

@JS('Module._setDartEventCallback')
external void wasmSetDartEventCallback(int callbackPtr);

@JS('Module._sendToWorker')
external void wasmSendToWorker(int message, int value);

@JS('Module.wasmWorker')
external web.Worker wasmWorker;

// //////////////////////////
// bindings
// //////////////////////////

@JS('Module._setSilenceDetection')
external void wasmSetSilenceDetection(bool enable);

@JS('Module._setSilenceThresholdDb')
external void wasmSetSilenceThresholdDb(double silenceThresholdDb);

@JS('Module._setSilenceDuration')
external void wasmSetSilenceDuration(double silenceDuration);

@JS('Module._setSecondsOfAudioToWriteBefore')
external void wasmSetSecondsOfAudioToWriteBefore(
  double secondsOfAudioToWriteBefore,
);

@JS('Module._listCaptureDevices')
external void wasmListCaptureDevices(
  int namesPtr,
  int deviceIdPtr,
  int isDefaultPtr,
  int nDevicePtr,
  );

@JS('Module._freeListCaptureDevices')
external void wasmFreeListCaptureDevices(
  int namesPtr,
  int deviceIdPtr,
  int isDefaultPtr,
  int nDevicePtr,
  );

@JS('Module._init')
external int wasmInit(int deviceID);

@JS('Module._deinit')
external void wasmDeinit();

@JS('Module._isInited')
external int wasmIsDeviceInitialized();

@JS('Module._isDeviceStartedListen')
external int wasmIsDeviceStartedListen();

@JS('Module._startListen')
external int wasmStartListen();

@JS('Module._stopListen')
external void wasmStopListen();

@JS('Module._startRecording')
external int wasmStartRecording(int pathPtr);

@JS('Module._setPauseRecording')
external void wasmSetPauseRecording(bool pause);

@JS('Module._stopRecording')
external void wasmStopRecording();

@JS('Module._setFftSmoothing')
external void wasmSetFftSmoothing(double smooth);

@JS('Module._getFft')
external void wasmGetFft(int samplesPtr);

@JS('Module._getWave')
external void wasmGetWave(int samplesPtr);

@JS('Module._getTexture2D')
external void wasmGetTexture2D(int samplesPtr);

@JS('Module._getVolumeDb')
external void wasmGetVolumeDb(int volumeDbPtr);
