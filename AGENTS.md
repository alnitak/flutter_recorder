# flutter_recorder - AI Agent Documentation

## Project Overview

`flutter_recorder` is a **Flutter audio recording plugin** that provides low-level audio capture capabilities across all Flutter-supported platforms. It uses the [miniaudio](https://github.com/mackron/miniaudio) C library as the backend and exposes functionality via Dart FFI (Foreign Function Interface).

### Key Features
- Cross-platform audio recording (Android, iOS, Linux, macOS, Windows, Web)
- WAV file recording with pause/resume functionality
- Real-time audio visualization (waveform and FFT data)
- Silence detection with configurable thresholds
- Audio data streaming
- Experimental audio filters (Auto Gain, Echo Cancellation)
- WebAssembly (WASM) support for web platform

## Technology Stack

### Core Technologies
| Component | Technology |
|-----------|------------|
| Language | Dart (SDK ^3.5.1) |
| Native Backend | C++ (C++17) |
| Audio Library | miniaudio (single-header C library) |
| FFI Bindings | `dart:ffi` for IO platforms |
| Web Implementation | WebAssembly via Emscripten |
| Build System | CMake (native), Gradle (Android) |

### Dependencies
```yaml
# Production dependencies
ffi: ^2.1.3
logging: ^1.3.0
meta: ^1.12.0
plugin_platform_interface: ^2.0.2
web: ^1.1.0

# Development dependencies
ffigen: ^13.0.0
flutter_lints: ^4.0.0
very_good_analysis: ^6.0.0
```

## Project Structure

```
flutter_recorder/
├── lib/                          # Dart source code
│   ├── flutter_recorder.dart     # Main library export
│   └── src/
│       ├── flutter_recorder.dart # Main Recorder singleton class
│       ├── enums.dart            # Enums (PCMFormat, RecorderChannels, CaptureErrors)
│       ├── audio_data_container.dart  # Audio data wrapper
│       ├── bindings/             # Platform-specific bindings
│       │   ├── recorder.dart     # Abstract recorder interface
│       │   ├── recorder_io.dart  # FFI implementation for IO platforms
│       │   ├── recorder_web.dart # WASM implementation for web
│       │   ├── js_extension.dart # JavaScript interop helpers
│       │   └── flutter_recorder_bindings_generated.dart  # Auto-generated FFI bindings
│       ├── exceptions/           # Custom exceptions
│       ├── filters/              # Audio filter implementations
│       └── worker/               # Web worker for WASM
│
├── src/                          # C++ native source
│   ├── flutter_recorder.cpp      # Main C++ implementation
│   ├── flutter_recorder.h        # C header for FFI bindings
│   ├── capture.cpp/h             # Audio capture logic
│   ├── analyzer.cpp/h            # FFT analysis
│   ├── common.h                  # Shared definitions
│   ├── enums.h                   # C++ enums
│   ├── circular_buffer.h         # Circular buffer implementation
│   ├── miniaudio.h               # miniaudio library (single header)
│   ├── wav.h                     # WAV file handling
│   ├── fft/                      # FFT implementation (SoLoud)
│   └── filters/                  # C++ audio filters
│       ├── filters.cpp/h
│       ├── autogain.cpp/h
│       ├── echo_cancellation.cpp/h
│       └── generic_filter.h
│
├── web/                          # Web platform assets
│   ├── compile_wasm.sh           # WASM compilation script
│   ├── compile_worker.sh         # Worker compilation script
│   ├── worker.dart               # Web worker Dart code
│   ├── init_recorder_module.dart # WASM module initialization
│   ├── libflutter_recorder_plugin.js    # Generated JS glue
│   └── libflutter_recorder_plugin.wasm  # Generated WASM binary
│
├── example/                      # Example application
│   ├── lib/
│   │   ├── main.dart             # Demo app with UI
│   │   └── ui/                   # Visualization widgets
│   ├── android/                  # Android-specific config
│   ├── ios/                      # iOS-specific config
│   ├── macos/                    # macOS-specific config
│   ├── linux/                    # Linux-specific config
│   └── windows/                  # Windows-specific config
│
├── android/                      # Android plugin config
├── ios/                          # iOS plugin config
├── macos/                        # macOS plugin config
├── linux/                        # Linux plugin config
├── windows/                      # Windows plugin config
│
├── pubspec.yaml                  # Package manifest
├── ffigen.yaml                   # FFI bindings generator config
├── analysis_options.yaml         # Dart linting rules
└── src/CMakeLists.txt            # Native build configuration
```

## Architecture

### Platform Abstraction
The plugin uses a platform abstraction pattern:

1. **Main Interface** (`lib/src/flutter_recorder.dart`): `Recorder` singleton class
2. **Abstract Implementation** (`lib/src/bindings/recorder.dart`): `RecorderImpl` abstract class
3. **IO Implementation** (`lib/src/bindings/recorder_io.dart`): Uses `dart:ffi` to call native code
4. **Web Implementation** (`lib/src/bindings/recorder_web.dart`): Uses WASM and JS interop

### Native Layer
- C++ code compiled as a shared library (`.so`, `.dll`, `.dylib`, `.framework`)
- FFI bindings auto-generated using `ffigen` from `src/flutter_recorder.h`
- Native code manages audio capture via miniaudio, FFT analysis, and audio filters

### Web Layer
- C++ code compiled to WebAssembly using Emscripten
- Web Worker handles audio processing to avoid blocking the main thread
- JS interop bridges Dart and WASM

## Build Commands

### Development Setup
```bash
# Install dependencies
dart pub get

# Generate FFI bindings (after modifying C headers)
dart run ffigen --config ffigen.yaml

# Format code
dart format .

# Apply automatic fixes
dart fix --apply

# Analyze code
dart analyze
```

### Running the Example
```bash
cd example

# Android
flutter run -d android

# iOS
flutter run -d ios

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Windows
flutter run -d windows

# Web (WASM)
flutter run -d chrome --web-renderer canvaskit \
  --web-browser-flag '--disable-web-security' \
  -t lib/main.dart --release
```

### Web Build (WASM)
```bash
# Compile WASM module
./wasm.sh
# or
cd web && sh ./compile_wasm.sh

# Compile web worker
./web.sh
# or
cd web && sh ./compile_worker.sh
```

**Note**: Web builds require Emscripten SDK installed.

### FFI Binding Regeneration
If you modify `src/flutter_recorder.h`, regenerate the Dart bindings:

```bash
# Standard method
dart run ffigen --config ffigen.yaml

# With custom GCC path (if needed)
export CPATH="$(clang -v 2>&1 | grep "Selected GCC installation" | rev | cut -d' ' -f1 | rev)/include"
dart run ffigen --config ffigen.yaml
```

## Code Style Guidelines

### Dart
- **Linter**: Uses `very_good_analysis` (strict Flutter/Dart linting rules)
- Configuration: `analysis_options.yaml` includes `package:very_good_analysis/analysis_options.yaml`
- Key rules:
  - `always_specify_types`: Types must be explicit
  - `camel_case_types`: Classes use UpperCamelCase
  - `public_member_api_docs`: Public APIs require documentation
  - `avoid_positional_boolean_parameters`: Use named parameters for booleans
  - `sort_constructors_first`: Constructors before other members

### C++
- Standard: C++17
- Use `FFI_PLUGIN_EXPORT` for all exported functions
- Header guards required (e.g., `#ifndef FLUTTER_RECORDER_H`)
- Prefer `std::unique_ptr` for memory management
- Use `nullptr` instead of `NULL`

### Documentation
- All public Dart APIs must have doc comments (`///`)
- C++ headers document the C API surface
- README.md contains setup and usage examples

## Testing

**Note**: This project currently has **no automated tests**. Testing is done manually via the example application in `example/`.

### Manual Testing Checklist
1. Device enumeration (`listCaptureDevices`)
2. Initialization with different formats (`PCMFormat.f32le` recommended for visualization)
3. Start/stop audio capture
4. WAV recording with pause/resume
5. Real-time FFT and waveform visualization
6. Silence detection functionality
7. Audio streaming
8. Filter activation/deactivation (Auto Gain, Echo Cancellation)
9. Cross-platform verification

## Platform-Specific Notes

### Android
- Requires `RECORD_AUDIO` permission in `AndroidManifest.xml`
- Supports Android 15 16k page size (configured in CMake)

### iOS / macOS
- Requires `NSMicrophoneUsageDescription` in `Info.plist`
- macOS: Enable "Audio input" capability in entitlements

### Linux
- Requires GStreamer installed
- Avoid Flutter snap installation (use official installer)

### Web
- Add to `web/index.html`:
```html
<script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
<script src="assets/packages/flutter_recorder/web/init_recorder_module.dart.js" defer></script>
```
- WASM assets are conditionally included (waiting for Flutter conditional asset support)

## Common Patterns

### Using the Recorder (Singleton)
```dart
// Initialize
await Recorder.instance.init(
  format: PCMFormat.f32le,  // Required for visualization
  sampleRate: 22050,
  channels: RecorderChannels.mono,
);

// Start capture
Recorder.instance.start();

// Start recording to file
Recorder.instance.startRecording(completeFilePath: '/path/to/file.wav');

// Get real-time data
final volume = Recorder.instance.getVolumeDb();
final fft = Recorder.instance.getFft();
final wave = Recorder.instance.getWave();

// Stop
Recorder.instance.stopRecording();
Recorder.instance.stop();
Recorder.instance.deinit();
```

### Silence Detection
```dart
Recorder.instance.setSilenceDetection(
  enable: true,
  onSilenceChanged: (isSilent, decibel) {
    print('Silence: $isSilent, dB: $decibel');
  },
);
Recorder.instance.setSilenceThresholdDb(-27);
Recorder.instance.setSilenceDuration(0.5);
```

### Audio Filters
```dart
// Activate filter
Recorder.instance.filters.autoGainFilter.activate();

// Set parameter
Recorder.instance.filters.autoGainFilter.targetRms.value = 0.6;

// Deactivate
Recorder.instance.filters.autoGainFilter.deactivate();
```

## Security Considerations

1. **Microphone Permissions**: Always request permission before initializing on mobile platforms
2. **File Path Validation**: The plugin validates file paths platform-specifically (Windows reserved names, invalid characters, etc.)
3. **Web Security**: Use `--disable-web-security` only for local development with web platform
4. **Memory Safety**: Native code uses proper allocation/deallocation patterns; FFI bindings handle pointer management

## Release Process

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md` with changes
3. Run `dart analyze` to ensure no issues
4. Run `dart format .` to ensure consistent formatting
5. Test on all target platforms using the example app
6. Tag release and publish to pub.dev

## Resources

- **Repository**: https://github.com/alnitak/flutter_recorder
- **Pub Package**: https://pub.dev/packages/flutter_recorder
- **miniaudio**: https://github.com/mackron/miniaudio
- **Web Example**: https://marcobavagnoli.com/flutter_recorder/

## Maintainer

- Marco Bavagnoli (@lildeimos)

---

*This documentation is intended for AI agents working on the flutter_recorder project. For user-facing documentation, see README.md.*
