import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_session/audio_session.dart';
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
  final audioStreamFormat = BufferType.f32le;

  final recorderChannels = RecorderChannels.mono;
  final recorderFormat = PCMFormat.f32le;

  final sampleRate = 22050;

  final soloud = SoLoud.instance;
  final recorder = Recorder.instance;
  AudioSource? audioSource;

  bool autoGain = false;
  // bool echoCancellation = false;

  /// Current audio devices
  String _currentInput = 'None';
  String _currentOutput = 'None';

  /// Subscription to recorder stream (need to cancel on dispose)
  StreamSubscription<AudioDataContainer>? _recorderSubscription;

  /// Update the current audio devices display
  Future<void> _updateAudioDevices() async {
    final session = await AudioSession.instance;
    final devices = await session.getDevices();
    
    // Log all devices for debugging
    final allInputs = devices.where((d) => d.isInput).map((d) => d.name).toList();
    final allOutputs = devices.where((d) => d.isOutput).map((d) => d.name).toList();
    dev.log(
      'All devices: input=$allInputs, output=$allOutputs',
      name: 'AudioSession',
    );
    
    // On Android, getDevices() returns all available devices, not just active ones.
    // Try to find a headset/Bluetooth device first, otherwise use the first one.
    String findBestDevice(List<AudioDevice> deviceList) {
      if (deviceList.isEmpty) return 'None';
      
      // Look for Bluetooth or wired headset first
      for (final device in deviceList) {
        final name = device.name.toLowerCase();
        if (name.contains('bluetooth') || 
            name.contains('headset') || 
            name.contains('headphone') ||
            name.contains('btr') ||  // FiiO BTR3K
            name.contains('fiio')) {
          return device.name;
        }
      }
      
      // Fall back to first device
      return deviceList.first.name;
    }
    
    final input = findBestDevice(devices.where((d) => d.isInput).toList());
    final output = findBestDevice(devices.where((d) => d.isOutput).toList());
    
    if (mounted && (input != _currentInput || output != _currentOutput)) {
      setState(() {
        _currentInput = input;
        _currentOutput = output;
      });
    }
  }

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

    /// Listen for audio route changes and update UI.
    AudioSession.instance.then((session) {
      // Initial update
      _updateAudioDevices();

      // Listen to stream changes
      session.devicesStream.listen((devices) {
        final input =
            devices.where((d) => d.isInput).map((d) => d.name).join(', ');
        final output =
            devices.where((d) => d.isOutput).map((d) => d.name).join(', ');
        dev.log(
          'Audio devices changed: input=$input, output=$output',
          name: 'AudioSession',
        );
        _updateAudioDevices();
      });
    });

    /// Listen for microphne data.
    _recorderSubscription = recorder.uint8ListStream.listen((chunks) {
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
      maxBufferSizeBytes: 1024 * 1024 * 50,
      channels: audioStreamChannels,
      format: audioStreamFormat,
      sampleRate: sampleRate,
      bufferingTimeNeeds: 0.2,
      bufferingType: BufferingType.released,
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
    if (audioSource != null) {
      soloud.setDataIsEnded(audioSource!);
    }
    _recorderSubscription?.cancel();
    recorder.deinit();
    soloud.deinit();

    /// Deactivate the audio session when done.
    AudioSession.instance.then((session) => session.setActive(false));
    super.dispose();
  }

  Future<void> init() async {
    /// Configure the audio session for play and record.
    /// This is important when using multiple audio plugins together.
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        // Android configuration
        androidAudioAttributes: const AndroidAudioAttributes(
          usage: AndroidAudioUsage.voiceCommunication,
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
        ),
        androidWillPauseWhenDucked: false,
      ),
    );

    /// Activate the audio session before initializing audio plugins.
    await session.setActive(true);

    /// Debug: Log current audio route
    final devices = await session.getDevices();
    dev.log(
      'Audio route before init: input=${devices.where((d) => d.isInput).map((d) => d.name).join(', ')}, '
      'output=${devices.where((d) => d.isOutput).map((d) => d.name).join(', ')}',
      name: 'AudioSession',
    );

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

    /// Debug: Log audio route after init
    final devicesAfter = await session.getDevices();
    dev.log(
      'Audio route after init: input=${devicesAfter.where((d) => d.isInput).map((d) => d.name).join(', ')}, '
      'output=${devicesAfter.where((d) => d.isOutput).map((d) => d.name).join(', ')}',
      name: 'AudioSession',
    );

    // Update the device display
    await _updateAudioDevices();

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
        const Text('Please, use headset to prevent audio feedback'),
        // Audio route info
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Text('Input: $_currentInput',
                    style: const TextStyle(fontSize: 12)),
                Text('Output: $_currentOutput',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: _updateAudioDevices,
              tooltip: 'Refresh devices',
            ),
          ],
        ),
        // Start / Stop
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () async {
                await init();
              },
              child: const Text('Init loopback'),
            ),
            OutlinedButton(
              onPressed: () {
                // First deinit the recorder and then the player
                recorder
                  ..stopStreamingData()
                  ..deinit();
                soloud.deinit();
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

        const Bars(),
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
                  if (v <= autoGain.queryTargetRms.min) return;
                  if (v >= autoGain.queryTargetRms.max) return;
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
                  if (v <= autoGain.queryAttackTime.min) return;
                  if (v >= autoGain.queryAttackTime.max) return;
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
                  if (v <= autoGain.queryReleaseTime.min) return;
                  if (v >= autoGain.queryReleaseTime.max) return;
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
                  if (v <= autoGain.queryGainSmoothing.min) return;
                  if (v >= autoGain.queryGainSmoothing.max) return;
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
                  if (v <= autoGain.queryMaxGain.min) return;
                  if (v >= autoGain.queryMaxGain.max) return;
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
                  if (v <= autoGain.queryMinGain.min) return;
                  if (v >= autoGain.queryMinGain.max) return;
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
