// ignore_for_file: avoid_print

import 'dart:js_interop';
import 'dart:js_util';

/// Module to initialized the WASM RecorderModule before the app starts.
/// It must be compiled with
/// `dart compile js -O3 -o init_recorder_module.dart.js ./init_recorder_module.dart`
/// and the resulting `init_recorder_module.dart.js` must be added as a script
/// in the `index.html` with also `libflutter_recorder_plugin.js`:
/// ```hmtl
/// <script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
/// <script src="assets/packages/flutter_recorder/web/init_recorder_module.dart.js" defer></script>
/// ```

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
