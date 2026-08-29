# Web Setup & WASM Guide for flutter_recorder

`flutter_recorder` supports modern Web browsers by compiling the miniaudio C engine into WebAssembly (WASM) via Emscripten and executing real-time audio processing within a dedicated Web Worker (`web/worker.dart`).

## Required Script Tags

Add these script tags to `<head>` in `web/index.html`:

```html
<script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
<script src="assets/packages/flutter_recorder/web/init_recorder_module.dart.js" defer></script>
```

These scripts initialize the WASM runtime (`libflutter_recorder_plugin.wasm`), register the JS interop bridge, and spawn the audio worker.

## Web Browser Microphone Permissions

Unlike mobile apps where permissions are requested through OS dialogs beforehand, Web browsers require an explicit user gesture (e.g. clicking a button) to grant microphone access.

### Recommended Pattern on Web:
1. Initialize the recorder: `await Recorder.instance.init();`
2. Present a UI button (e.g. "Grant Microphone Access" or "Start Recording").
3. Call `Recorder.instance.start();` directly from the `onPressed` handler.
4. If permission is denied or dismissed, handle the resulting exception gracefully.

## Web File Download Behavior

On Web:
- `startRecording({String completeFilePath = ''})` ignores any filesystem path.
- When `stopRecording()` is called, the audio data recorded in memory is bundled as a Blob and automatically presented as a browser file download prompt.

## Local Web Testing

To run the web app in Chrome during development:

```sh
flutter run -d chrome \
  --web-renderer canvaskit \
  --web-browser-flag '--disable-web-security' \
  -t lib/main.dart \
  --release
```

The `--disable-web-security` flag helps bypass local localhost mic-access or cross-origin restrictions when testing in dev mode.
