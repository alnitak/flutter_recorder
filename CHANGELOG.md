## 0.9.6
- choppy PCM playback on macOS

## 0.9.5
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
