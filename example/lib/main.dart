import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_recorder_example/ui/bars.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _recorder = Recorder.instance;
  var thresholdDb = -20.0;
  var silenceDuration = 2.0;
  var secondsOfAudioToWriteBefore = 0.0;

  @override
  void initState() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
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
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
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
                        final devices = _recorder.listCaptureDevices();
                        debugPrint('\n-------- LIST DEVICES ---------');
                        for (final d in devices) {
                          debugPrint(
                            '${d.id} - ${d.isDefault ? "DEFAULT " : ""}  '
                            '${d.name}',
                          );
                        }
                        debugPrint('-------------------------------\n');
                      },
                      child: const Text('listCaptureDevices'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        try {
                        _recorder.init();
                        } on Exception catch (e) {
                          debugPrint('-------------- init() $e\n');
                        }
                      },
                      child: const Text('init'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _recorder.deinit();
                        debugPrint('-------------- deinit()\n');
                      },
                      child: const Text('deinit'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final e = _recorder.isDeviceInitialized();
                        debugPrint('-------------- isDeviceInitialized() $e\n');
                      },
                      child: const Text('isDeviceInitialized'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        try {
                        _recorder.startListen();
                        } on Exception catch (e) {
                          debugPrint('-------------- startListen() $e\n');
                        }
                      },
                      child: const Text('startListen'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final e = _recorder.isDeviceStartedListen();
                        debugPrint(
                            '-------------- isDeviceStartedListen() $e\n');
                      },
                      child: const Text('isDeviceStartedListen'),
                    ),
                    spacerSmall,
                    OutlinedButton(
                      onPressed: () {
                        final wave = _recorder.getWave();
                        debugData(wave, 256);
                      },
                      child: const Text('getWave'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final wave = _recorder.getFft();
                        debugData(wave, 256);
                      },
                      child: const Text('getFft'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        final wave = _recorder.getTexture2D();
                        debugData(wave, 256, startIndex: 0);
                        debugData(wave, 256, startIndex: 256);
                      },
                      child: const Text('getTexture'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _recorder.setSilenceDetection(enable: true,onSilenceChanged: (isSilent, decibel) {
                                  // print('SILENCE CHANGED: $isSilent, $decibel');
                                },);
                        _recorder.setSilenceThresholdDb(-27);
                        _recorder.setSilenceDuration(0.1);
                        _recorder.setSecondsOfAudioToWriteBefore(0.0);
                      },
                      child: const Text('setSilenceDetection ON -27 0.1'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _recorder.setSilenceDetection(enable: false);
                      },
                      child: const Text('setSilenceDetection OFF'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        try {
                        _recorder.startRecording('/home/deimos/my_file.wav');
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
                      child: const Text('UNPause recording'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _recorder.stopRecording();
                      },
                      child: const Text('Stop recording'),
                    ),
                  ],
                ),
                spacerSmall,
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
                          child:
                              Text(_recorder.getVolumeDb().toStringAsFixed(1)),
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
                            min: -60,
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
                        Text('write before: '
                        '${secondsOfAudioToWriteBefore.toStringAsFixed(1)}'),
                        Expanded(
                          child: Slider(
                            value: secondsOfAudioToWriteBefore,
                            min: 0,
                            max: 10,
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
      ),
    );
  }

  void debugData(Float32List data, int width, {int startIndex = 0}) {
    final buf = StringBuffer();
    buf.write('DART from $startIndex: ');
    for (var i = startIndex; i < width + startIndex; i++) {
      buf
        ..write(data[i].toStringAsFixed(3))
        ..write(' ');
    }
    buf.writeln();
    debugPrint(buf.toString());
  }
}
