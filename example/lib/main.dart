import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_recorder_example/ui/bars.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  runApp(
    const MaterialApp(home: MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _recorder = Recorder.instance;
  String? filePath;
  var thresholdDb = -20.0;
  var silenceDuration = 2.0;
  var secondsOfAudioToWriteBefore = 0.0;

  @override
  void initState() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      Permission.microphone.request().isGranted.then((value) async {
        if (!value) {
          await [Permission.microphone].request();
        }
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Packages'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Wrap(
                runSpacing: 6,
                spacing: 6,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      showDeviceListDialog();
                    },
                    child: const Text('listCaptureDevices'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      try {
                        _recorder.init(
                          sampleRate: 44100,
                          channels: RecorderChannels.stereo,
                        );
                      } on Exception catch (e) {
                        debugPrint('-------------- init() error: $e\n');
                      }
                    },
                    child: const Text('init'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      try {
                        _recorder.startListen();
                      } on Exception catch (e) {
                        debugPrint('-------------- startListen() error: $e\n');
                      }
                    },
                    child: const Text('start listen'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _recorder.deinit();
                    },
                    child: const Text('deinit'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _recorder.setSilenceDetection(
                        enable: true,
                        onSilenceChanged: (isSilent, decibel) {
                          /// Here you can check if silence is changed.
                          /// Or you can do the same thing with the Stream
                          /// [Recorder.instance.silenceChangedEvents]
                          // debugPrint('SILENCE CHANGED: $isSilent, $decibel');
                        },
                      );
                      _recorder.setSilenceThresholdDb(-27);
                      _recorder.setSilenceDuration(0.5);
                      _recorder.setSecondsOfAudioToWriteBefore(0.0);
                      setState(() {
                        thresholdDb = -27;
                        silenceDuration = 0.5;
                        secondsOfAudioToWriteBefore = 0;
                      });
                    },
                    child: const Text('setSilenceDetection ON -27, 0.5, 0.0'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _recorder.setSilenceDetection(enable: false);
                    },
                    child: const Text('setSilenceDetection OFF'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                runSpacing: 6,
                spacing: 6,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        /// Asking for file path to store the audio file.
                        /// On web platform, it will be asked internally
                        /// from the browser.
                        if (!kIsWeb) {
                          final downloadsDir = await getDownloadsDirectory();
                          filePath =
                              '${downloadsDir!.path}/flutter_recorder.wav';
                          _recorder.startRecording(completeFilePath: filePath!);
                        } else {
                          _recorder.startRecording();
                        }
                      } on Exception catch (e) {
                        debugPrint('-------------- startRecording() $e\n');
                      }
                    },
                    child: const Text('Start recording'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _recorder.setPauseRecording(pause: true);
                    },
                    child: const Text('Pause recording'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _recorder.setPauseRecording(pause: false);
                    },
                    child: const Text('UN-Pause recording'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _recorder.stopRecording();
                      if (!kIsWeb) {
                        debugPrint('Audio recorded to "$filePath"');
                        showFileRecordedDialog(filePath!);
                      }
                    },
                    child: const Text('Stop recording'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder(
                stream: _recorder.silenceChangedEvents,
                builder: (context, snapshot) {
                  return ColoredBox(
                    color: snapshot.hasData && snapshot.data!.isSilent
                        ? Colors.green
                        : Colors.red,
                    child: SizedBox(
                      width: 70,
                      height: 50,
                      child: Center(
                        child: Text(_recorder.getVolumeDb().toStringAsFixed(1)),
                      ),
                    ),
                  );
                },
              ),
              Column(
                children: [
                  // Threshold dB slider
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text('Threshold: ${thresholdDb.toStringAsFixed(1)}dB'),
                      Expanded(
                        child: Slider(
                          value: thresholdDb,
                          min: -100,
                          max: 0,
                          label: thresholdDb.toStringAsFixed(1),
                          onChanged: (value) {
                            _recorder.setSilenceThresholdDb(value);
                            setState(() {
                              thresholdDb = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Silence duration slider
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text('Silence duration: '
                          '${silenceDuration.toStringAsFixed(1)}'),
                      Expanded(
                        child: Slider(
                          value: silenceDuration,
                          min: 0,
                          max: 10,
                          label: silenceDuration.toStringAsFixed(1),
                          onChanged: (value) {
                            _recorder.setSilenceDuration(value);
                            setState(() {
                              silenceDuration = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Silence duration slider
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text('Write before: '
                          '${secondsOfAudioToWriteBefore.toStringAsFixed(1)}'),
                      Expanded(
                        child: Slider(
                          value: secondsOfAudioToWriteBefore,
                          min: 0,
                          max: 5,
                          label: silenceDuration.toStringAsFixed(1),
                          onChanged: (value) {
                            _recorder.setSecondsOfAudioToWriteBefore(value);
                            setState(() {
                              secondsOfAudioToWriteBefore = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Bars(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showFileRecordedDialog(String filePath) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recording saved!'),
          content: Text('Audio saved to:\n$filePath'),
          actions: <Widget>[
            TextButton(
              child: const Text('open'),
              onPressed: () async {
                OpenFilex.open(
                  filePath,
                  type: 'audio/wav',
                );
              },
            ),
            TextButton(
              child: const Text('close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeviceListDialog() async {
    final devices = _recorder.listCaptureDevices();
    String devicesString = devices.asMap().entries.map((entry) {
      return '${entry.value.id} ${entry.value.isDefault ? 'DEFAULT' : ''} - '
          ' ${entry.value.name}';
    }).join('\n\n');

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recording saved!'),
          content: Text(devicesString),
          actions: <Widget>[
            const Text(''),
            TextButton(
              child: const Text('close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
