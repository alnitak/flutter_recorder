import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:flutter_recorder_example/ui/bars.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';


/// Loopback example which uses `flutter_soloud` to play audio back to the
/// device from the microphone data stream. Please try it with headset to
/// prevent audio feedback.
///
/// If you want to try other formats than `f32le`, you must comment out
/// the `Bars()` widget.
///
/// The `Echo Cancellation` code is not yet ready and don't know if it will be!
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
          title: Text('loopback and filter example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LoopBack(),
        ),
      ),
    ),
  );
}

class LoopBack extends StatefulWidget {
  const LoopBack({super.key});

  @override
  State<LoopBack> createState() => _LoopBackState();
}

class _LoopBackState extends State<LoopBack> {
  final audioStreamChannels = Channels.mono;
  final audioStreamFormat = BufferPcmType.f32le;

  final recorderChannels = RecorderChannels.mono;
  final recorderFormat = PCMFormat.f32le;

  final sampleRate = 22050;

  final soloud = SoLoud.instance;
  final recorder = Recorder.instance;
  AudioSource? audioSource;

  bool autoGain = false;
  // bool echoCancellation = false;

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

    /// Listen for microphne data.
    recorder.uint8ListStream.listen((chunks) {
      if (audioSource != null) {
        soloud.addAudioDataStream(
          audioSource!,
          chunks.toF32List(from: PCMFormat.f32le).buffer.asUint8List(),
        );
      } else {
        initAudioSource();
        soloud
          ..addAudioDataStream(
            audioSource!,
            chunks.toF32List(from: PCMFormat.f32le).buffer.asUint8List(),
          )
          ..play(audioSource!, volume: 4);
      }
    });
  }

  /// Initialize the audio source
  void initAudioSource() {
    if (audioSource != null) disposeAudioSource();

    audioSource = soloud.setBufferStream(
      channels: audioStreamChannels,
      pcmFormat: audioStreamFormat,
      sampleRate: sampleRate,
      bufferingTimeNeeds: 0.2,
    );

    audioSource!.allInstancesFinished.listen((data) async {
      await soloud.disposeSource(audioSource!);
      audioSource = null;
    });
  }

  /// Dispose the audio source if it exists
  Future<void> disposeAudioSource() async {
    if (audioSource == null) return;

    await soloud.disposeSource(audioSource!);
    audioSource = null;
  }

  @override
  void dispose() {
    soloud.deinit();
    recorder.deinit();
    super.dispose();
  }

  Future<void> init() async {
    /// Initialize the player and the recorder.
    await disposeAudioSource();
    await soloud.init(channels: Channels.mono, sampleRate: sampleRate);
    // soloud.filters.echoFilter.activate();
    // soloud.filters.echoFilter.delay.value = 0.1;
    // soloud.filters.echoFilter.decay.value = 0.2;

    await recorder.init(
      format: recorderFormat,
      sampleRate: sampleRate,
      channels: recorderChannels,
    );

    recorder
      ..start()
      ..startStreamingData();

    if (context.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        // Start / Stop
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () {
                init();
              },
              child: const Text('Init loopback'),
            ),
            OutlinedButton(
              onPressed: () {
                soloud.deinit();
                recorder
                  ..stopStreamingData()
                  ..deinit();
                audioSource = null;
              },
              child: const Text('Stop'),
            ),
          ],
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Text('Auto gain'),
            Checkbox(
              value: autoGain,
              onChanged: (v) {
                if (v!) {
                  recorder.filters.autoGainFilter.activate();
                } else {
                  recorder.filters.autoGainFilter.deactivate();
                }
                setState(() {
                  autoGain = v;
                });
              },
            ),
            // Text('Echo Cancellation'),
            // Checkbox(
            //   value: echoCancellation,
            //   onChanged: (v) {
            //     if (v!) {
            //       recorder.filters.echoCancellationFilter.activate();
            //     } else {
            //       recorder.filters.echoCancellationFilter.deactivate();
            //     }
            //     setState(() {
            //       echoCancellation = v;
            //     });
            //   },
            // ),
          ],
        ),

        if (autoGain) AutoGainSliders(),

        // if (echoCancellation) EchoCancellationSliders(),

        // const Bars(),
      ],
    );
  }
}

// class EchoCancellationSliders extends StatefulWidget {
//   const EchoCancellationSliders({super.key});

//   @override
//   State<EchoCancellationSliders> createState() =>
//       _EchoCancellationSlidersState();
// }

// class _EchoCancellationSlidersState extends State<EchoCancellationSliders> {
//   late final Recorder recorder;
//   late final EchoCancellation echoCancellation;

//   @override
//   void initState() {
//     super.initState();
//     recorder = Recorder.instance;
//     echoCancellation = recorder.filters.echoCancellationFilter;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               '${echoCancellation.queryEchoDelayMs}: '
//               '${echoCancellation.echoDelayMs.value.toStringAsFixed(2)}',
//             ),
//             Expanded(
//               child: Slider(
//                 value: echoCancellation.echoDelayMs.value,
//                 min: echoCancellation.queryEchoDelayMs.min,
//                 max: echoCancellation.queryEchoDelayMs.max,
//                 onChanged: (v) {
//                   setState(() {
//                     echoCancellation.echoDelayMs.value = v;
//                   });
//                 },
//               ),
//             ),
//           ],
//         ),
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               '${echoCancellation.queryEchoAttenuation}: '
//               '${echoCancellation.echoAttenuation.value.toStringAsFixed(2)}',
//             ),
//             Expanded(
//               child: Slider(
//                 value: echoCancellation.echoAttenuation.value,
//                 min: echoCancellation.queryEchoAttenuation.min,
//                 max: echoCancellation.queryEchoAttenuation.max,
//                 onChanged: (v) {
//                   setState(() {
//                     echoCancellation.echoAttenuation.value = v;
//                   });
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

class AutoGainSliders extends StatefulWidget {
  const AutoGainSliders({super.key});

  @override
  State<AutoGainSliders> createState() => _AutoGainSlidersState();
}

class _AutoGainSlidersState extends State<AutoGainSliders> {
  late final Recorder recorder;
  late final AutoGain autoGain;

  @override
  void initState() {
    super.initState();
    recorder = Recorder.instance;
    autoGain = recorder.filters.autoGainFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${autoGain.queryTargetRms}: '
              '${autoGain.targetRms.value.toStringAsFixed(2)}',
            ),
            Expanded(
              child: Slider(
                value: autoGain.targetRms.value,
                min: autoGain.queryTargetRms.min,
                max: autoGain.queryTargetRms.max,
                onChanged: (v) {
                  setState(() {
                    autoGain.targetRms.value = v;
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${autoGain.queryAttackTime}: '
              '${autoGain.attackTime.value.toStringAsFixed(2)}',
            ),
            Expanded(
              child: Slider(
                value: autoGain.attackTime.value,
                min: autoGain.queryAttackTime.min,
                max: autoGain.queryAttackTime.max,
                onChanged: (v) {
                  setState(() {
                    autoGain.attackTime.value = v;
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${autoGain.queryReleaseTime}: '
              '${autoGain.releaseTime.value.toStringAsFixed(2)}',
            ),
            Expanded(
              child: Slider(
                value: autoGain.releaseTime.value,
                min: autoGain.queryReleaseTime.min,
                max: autoGain.queryReleaseTime.max,
                onChanged: (v) {
                  setState(() {
                    autoGain.releaseTime.value = v;
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${autoGain.queryGainSmoothing}: '
              '${autoGain.gainSmoothing.value.toStringAsFixed(2)}',
            ),
            Expanded(
              child: Slider(
                value: autoGain.gainSmoothing.value,
                min: autoGain.queryGainSmoothing.min,
                max: autoGain.queryGainSmoothing.max,
                onChanged: (v) {
                  setState(() {
                    autoGain.gainSmoothing.value = v;
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${autoGain.queryMaxGain}: '
              '${autoGain.maxGain.value.toStringAsFixed(2)}',
            ),
            Expanded(
              child: Slider(
                value: autoGain.maxGain.value,
                min: autoGain.queryMaxGain.min,
                max: autoGain.queryMaxGain.max,
                onChanged: (v) {
                  setState(() {
                    autoGain.maxGain.value = v;
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${autoGain.queryMinGain}: '
              '${autoGain.minGain.value.toStringAsFixed(2)}',
            ),
            Expanded(
              child: Slider(
                value: autoGain.minGain.value,
                min: autoGain.queryMinGain.min,
                max: autoGain.queryMinGain.max,
                onChanged: (v) {
                  setState(() {
                    autoGain.minGain.value = v;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
