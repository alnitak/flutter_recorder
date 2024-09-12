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
                        final e = _recorder.init();
                        debugPrint('-------------- init() $e\n');
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
                        final e = _recorder.startListen();
                        debugPrint('-------------- startListen() $e\n');
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
                        _recorder.setSilenceDetection(
                          enable: true,
                          silenceThresholdDb: -20,
                        );
                      },
                      child: const Text('setSilenceDetection ON'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _recorder.setSilenceDetection(enable: true);
                      },
                      child: const Text('setSilenceDetection OFF'),
                    ),
                  ],
                ),
                spacerSmall,
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
