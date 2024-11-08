// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';

File? file;
File? fileRaw;
PCMFormat fromFormat = PCMFormat.u8;
PCMFormat toFormat = PCMFormat.u8;
/// Wrte .raw file only on 1st loop
bool isFirstFormat = false;

Future<int> main() async {
  final recorder = Recorder.instance;
  const sampleRate = 22050;
  const channels = RecorderChannels.mono;

  var downloadsDir = await getDownloadsDirectory();
  if (downloadsDir == null) {
    print('Cannot get download directory!');
    exit(1);
  }
  downloadsDir = Directory('${downloadsDir.path}/flutter_recorder');
  downloadsDir.createSync();
  print('Saving results into ${downloadsDir.path}');

  recorder.uint8ListStream.listen((data) {
    /// Write the data to file. It can then be imported with the correct
    /// parameters with for example Audacity.
    write(data);
  });

  final List<(PCMFormat from, PCMFormat to)> fromTo = [
    // (PCMFormat.s16le, PCMFormat.f32le),
    // (PCMFormat.s16le, PCMFormat.u8),
    // (PCMFormat.s24le, PCMFormat.f32le),
    // (PCMFormat.s24le, PCMFormat.s16le),
    // (PCMFormat.s24le, PCMFormat.s32le),
    // (PCMFormat.s32le, PCMFormat.f32le),
    // (PCMFormat.s32le, PCMFormat.s16le),
  ];

  for (var from = 0; from < PCMFormat.values.length; from++) {
    for (var to = 0; to < PCMFormat.values.length; to++) {
      fromTo.add((PCMFormat.fromValue(from), PCMFormat.fromValue(to)));
    }
  }

  for (final n in fromTo) {

      // Wheter to write the .raw file in the listener.
      isFirstFormat = n.$2.name == 'u8';

      fromFormat = n.$1;
      toFormat = n.$2;

      file = File('${downloadsDir.path}/fr_${sampleRate}_'
          '${n.$1.name}_'
          '${channels.count}_'
          'to_${n.$2.name}'
          '.pcm');
      try {
        file?.deleteSync();
      } catch (e) {}

      fileRaw = File('${downloadsDir.path}/fr_${sampleRate}_'
          '${n.$1.name}_'
          '${channels.count}'
          '.raw');
      try {
        file?.deleteSync();
      } catch (e) {}

      recorder.init(
        format: fromFormat,
        sampleRate: sampleRate,
        channels: channels,
      );

      recorder.start();

      recorder.startStreamingData();

      await Future.delayed(const Duration(seconds: 3));

      recorder.stopStreamingData();

      recorder.stop();

      recorder.deinit();
      await Future.delayed(const Duration(seconds: 1));
    }


  exit(0);
}

void write(AudioDataContainer data) {
  if (isFirstFormat) {
    fileRaw?.writeAsBytesSync(
    data.rawData,
    mode: FileMode.writeOnlyAppend,
  );
  }
  file?.writeAsBytesSync(
    switch (toFormat) {
      PCMFormat.u8 => data.toU8List(from: fromFormat).buffer.asUint8List(),
      PCMFormat.s16le => data.toS16List(from: fromFormat).buffer.asUint8List(),
      PCMFormat.s24le => data.toS24List(from: fromFormat).buffer.asUint8List(),
      PCMFormat.s32le => data.toS32List(from: fromFormat).buffer.asUint8List(),
      PCMFormat.f32le => data.toF32List(from: fromFormat).buffer.asUint8List(),
    },
    mode: FileMode.writeOnlyAppend,
  );
}
