import 'dart:developer' as dev;

import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_recorder_example/ui/bars.dart';
import 'package:logging/logging.dart';

/// Demostrate how to use flutter_recorder.
///
/// The silence detection and the visualizer works when using [PCMFormat.f32].
/// Writing audio stream to file is not implemented on Web.

void main() async {
  // The `flutter_recorder` package logs everything
  // (from severe warnings to fine debug messages)
  // using the standard `package:logging`.
  // You can listen to the logs as shown below.

  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;

  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Recorder'),
        ),
        body: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final recorder = Recorder.instance;

  final _audioStream = getAudioStream();

  @override
  void initState() {
    super.initState();
  }

  Future<void> init() async {
    await recorder.init(
        format: PCMFormat.f32le,
        sampleRate: 44100,
        channels: RecorderChannels.mono);

    final devices = recorder.listCaptureDevices();
    dev.log('devices ${devices.length}');
    for (var i = 0; i < devices.length; i++) {
      dev.log(
          'device $i: ${devices[i].name} ${devices[i].id} ${devices[i].isDefault}');
    }

    recorder.start();

    _audioStream.init(
        waitingBufferMilliSec: 100,
        bufferMilliSec: 200,
        sampleRate: 44100,
        channels: 1);

    if (kIsWeb) {
      _audioStream.resume();
    }

    recorder.uint8ListStream.listen((data) {
      _audioStream.push(data.toF32List(from: PCMFormat.f32le));
    });

    recorder.startStreamingData();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          ElevatedButton(
            onPressed: init,
            child: const Text('start'),
          ),
          const Bars(),
        ],
      ),
    );
  }
}
