// ignore_for_file: public_member_api_docs

import 'dart:js_interop';
import 'package:web/web.dart' as web;

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

@JS('Module._sendToWorker')
external void wasmSendToWorker(int message, int value);

@JS('Module.wasmWorker')
external web.Worker wasmWorker;
