import 'dart:io';

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
  final format = PCMFormat.u8;
  final sampleRate = 22050;
  final channels = RecorderChannels.mono;
  final _recorder = Recorder.instance;
  String? filePath;
  var thresholdDb = -20.0;
  var silenceDuration = 2.0;
  var secondsOfAudioToWriteBefore = 0.0;

  File? file;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      Permission.microphone.request().isGranted.then((value) async {
        if (!value) {
          await [Permission.microphone].request();
        }
      });
    }

    /// Listen to audio data stream. The data is received in Uint8List.
    _recorder.uint8ListStream.listen((data) {
      /// Write the PCM data to file. It can then be imported with the correct
      /// parameters with for example Audacity.
      file?.writeAsBytesSync(
        // If you want a conversion, call one of the `to*List` methods.
        // data.toF32List(from: format).buffer.asUint8List(),
        data.rawData,
        mode: FileMode.writeOnlyAppend,
      );
      debugPrint('uint8List: ${data.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Recorder'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              /// List capture devices, init, start, deinit
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
                          format: format,
                          sampleRate: sampleRate,
                          channels: channels,
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
                        _recorder.start();
                      } on Exception catch (e) {
                        debugPrint('-------------- start() error: $e\n');
                      }
                    },
                    child: const Text('start'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _recorder.deinit();
                    },
                    child: const Text('deinit'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// Recording
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

              /// Streaming
              Wrap(
                runSpacing: 6,
                spacing: 6,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _recorder.startStreamingData();
                      file = File(
                          '/home/deimos/fr_${sampleRate}_${format.name}_${channels.count}.pcm');
                      try {
                        file?.deleteSync();
                      } catch (e) {}
                    },
                    child: const Text('start stream'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _recorder.stopStreamingData();
                    },
                    child: const Text('stop stream'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              /// The silence detection is available only with f32 format and
              /// the visualization is adapted only with that format.
              if (format == PCMFormat.f32le)
                Column(
                  children: [
                    Column(
                      children: [
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
                                  child: Text(_recorder
                                      .getVolumeDb()
                                      .toStringAsFixed(1)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          runSpacing: 6,
                          spacing: 6,
                          children: [
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
                              child: const Text(
                                  'setSilenceDetection ON -27, 0.5, 0.0'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                _recorder.setSilenceDetection(enable: false);
                              },
                              child: const Text('setSilenceDetection OFF'),
                            ),
                          ],
                        ),
                        // Threshold dB slider
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                                'Threshold: ${thresholdDb.toStringAsFixed(1)}dB'),
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
                                  _recorder
                                      .setSecondsOfAudioToWriteBefore(value);
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
