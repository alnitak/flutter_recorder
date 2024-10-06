# flutter_recorder

A low-level audio recorder plugin which uses miniaudio as backend and supporting all the platforms. It can detect silence and save to WAV audio format.

## Setup permissions
After setting up permission for you Android, MacOS or iOS, in your app, you will need to ask for permission to use the microphonem maybe using [permission_handler](https://pub.dev/packages/permission_handler) plugin.
https://pub.dev/packages/permission_handler

#### Android
Add the permission in the `AndroidManifest.xml`.
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### MacOS, iOS
Add the permission in `Runner/Info.plist`.
```
<key>NSMicrophoneUsageDescription</key>
<string>Some message to describe why you need this permission</string>
```

#### Web
Add this in `web/index.html` under the `<head>` tag.
```
<script src="assets/packages/flutter_recorder/web/libflutter_recorder_plugin.js" defer></script>
```

## Usage
1. if you are running on Android, MacOS or iOS, ask the permission to use the microphone:
```
import 'package:permission_handler/permission_handler.dart';
[...]
if (defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS) {
    Permission.microphone.request().isGranted.then((value) async {
    if (!value) {
        await [Permission.microphone].request();
    }
});
```
2. Initialize the capture device and start listening to it:
```
try {
    Recorder.instance.init();
    Recorder.instance.startListen();
} on Exception catch (e) {
    debugPrint('init() error: $e\n');
}
```

## TODOs
add package:log