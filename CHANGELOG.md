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
- detailed exception when passing an invalind file name to `startRecording` #23
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
