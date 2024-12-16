// ignore_for_file: avoid_print

import 'dart:js_interop';
import 'dart:js_util';

@JS('RecorderModule')
external JSObject getRecorderModule();

@JS('RecorderModule')
external JSObject recorderModuleConstructor(); // Represents the IIFE

@JS('self.RecorderModule') // Attach RecorderModule to the global scope
external set globalRecorderModule(JSObject module);

Future<JSObject> initializeRecorderModule() async {
  try {
    // Convert JavaScript Promise to Dart Future
    final promise = recorderModuleConstructor();
    final module = await promiseToFuture<JSObject>(promise);
    globalRecorderModule = module; // Make it globally accessible
    print('RecorderModule initialized and set globally.');
    return module; // Return the initialized module
  } catch (e) {
    print('Failed to initialize RecorderModule: $e');
    rethrow;
  }
}

/// The main Web Worker
void main() async {
  await initializeRecorderModule();
}
