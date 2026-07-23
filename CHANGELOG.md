## 1.2.1
- android fix: opus lib not found #49

## 1.2.0
- add Opus encoding for `startRecording` (Ogg Opus) and `startStreamingData` (Opus packets) through the new `RecordingFormat` and `StreamingFormat` enums.
- build: vendored Ogg/Opus libraries renamed to `libfr_ogg`/`libfr_opus` on Android to avoid conflicts with other plugins such as `flutter_soloud`.
- build: macOS now uses project-specific vendored static libraries; iOS uses vendored XCFrameworks to avoid CocoaPods symbol collisions.
- build: updated WASM compile script to support Ogg/Opus sources and avoid picking up host macOS/iOS SDK headers.

## 1.1.6
- improve native Auto Gain with stateful RMS tracking, noise-floor gating, headroom limiting, PCM-safe clipping, and runtime telemetry #46. Thanks to @Avejack.
- add Auto Gain `noiseFloorDb` and `headroomDb` parameters plus read-only metrics for current gain, input RMS, output peak, limiter counts, and last callback frame count #46. Thanks to @Avejack.

## 1.1.5
- add Android input preset selection for recorder initialization #45. Thanks to @Avejack

## 1.1.4
- fix compilation issue on macOS #43

## 1.1.3
- fix issue when using together with flutter_soloud
- updated loopback example using audio_session
- miniaudio backend updated

## 1.1.2
- fix: macOS cross-compilation #39 by @Vild

## 1.1.1
- fix building issue with XCode 16.3 #32
- fix: `listPlaybackDevices` fails to retrieve devices when the device prefix contains Chinese characters #35 by @WHYBBE
- fix: some legitimate paths are unavailable on Windows #38 by @WHYBBE

## 1.1.0
- when calling AudioData.getAudioData is now possible to check if the audio data is the same as before. Useful to visualize waveforms. This is because AudioData.getAudioData returns the current data in the buffer and if it is called before the buffer has been updated, it will return the previous data.
- better FFT data for a better visualization.

## 1.0.4
- added getTexture and a check for all get* methods to know if the current data is the same audio data computed previously.
- better FFT data

## 1.0.3
- update WASM lib

## 1.0.2
- resolved conflicts with flutter_soloud #25

## 1.0.1
- detailed exception when passing an invalid file name to `startRecording` #23
- removed deprecated `dart:js_util`

## 1.0.0
- fixed choppy PCM playback on macOS #18.
- fix `startRecording` empty path on the web

## 0.9.4
- fixed mic permission iOS example
- fixed `listCaptureDevices` when there are not input devices
- update doc

## 0.9.3
- added `autoGain` filter
- breaking changes: 
  - the `init` method is now async
  - `FilterType` renamed to `RecorderFilterType`
  - an [additional script](https://github.com/alnitak/flutter_recorder#web) must be added for the web platform. Now it looks like:
  ```
  <script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
  <script src="assets/packages/flutter_recorder/web/init_recorder_module.dart.js" defer></script>
  ```

## 0.9.2
- fix: the stop was instead einit the device
- fix: removed dialog when stopping stream in the example

## 0.9.1
- breaking changes: 
  - renamed `startListen` to `start`
  - renamed `stopListen` to `stop`
  - renamed `isDeviceStartedListen` to `isDeviceStarted`
