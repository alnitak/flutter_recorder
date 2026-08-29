// ignore_for_file: experimental_member_use

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
        appBar: AppBar(title: Text('loopback and filter example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(child: LoopBack()),
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
  bool echoCancellation = false;
  bool nativeLoopback = false;

  AndroidInputPreset androidInputPreset = AndroidInputPreset.voiceCommunication;
  IosInputPreset iosInputPreset = IosInputPreset.voiceCommunication;
  WebInputPreset webInputPreset = WebInputPreset.unprocessed;

  /// Subscription to recorder stream (need to cancel on dispose)
  StreamSubscription<AudioDataContainer>? _recorderSubscription;

  /// Subscription to SoLoud mixer capture output stream (feeds AEC playback reference)
  StreamSubscription<Uint8List>? _soloudMixerSubscription;

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
      // Listen to list of audio devices changes
      session.devicesStream.listen((devices) {
        final input = devices
            .where((d) => d.isInput)
            .map((d) => d.name)
            .join(', ');
        final output = devices
            .where((d) => d.isOutput)
            .map((d) => d.name)
            .join(', ');
        dev.log(
          'Audio devices changed: input=$input, output=$output',
          name: 'AudioSession',
        );
      });

      session.becomingNoisyEventStream.listen((_) {
        dev.log(
          'Audio route became noisy (e.g. unplugged headphones)',
          name: 'AudioSession',
        );
      });

      session.devicesChangedEventStream.listen((event) {
        dev.log('Devices added:   ${event.devicesAdded}');
        dev.log('Devices removed: ${event.devicesRemoved}');
      });
    });

    /// Listen for microphne data.
    _recorderSubscription = recorder.uint8ListStream.listen((chunks) {
      if (!recorder.isInitialized || !soloud.isInitialized) return;

      // If native loopback is enabled, audio plays natively through duplex output.
      // If disabled, route audio to SoLoud buffer stream for playback.
      if (!recorder.isLoopbackEnabled()) {
        final f32Data = chunks
            .toF32List(from: recorder.recorderFormat)
            .buffer
            .asUint8List();
        if (audioSource != null) {
          soloud.addAudioDataStream(audioSource!, f32Data);
        } else {
          initAudioSource();
          if (audioSource != null && soloud.isInitialized) {
            soloud
              ..addAudioDataStream(audioSource!, f32Data)
              ..play(audioSource!, volume: 1);
          }
        }
      }
    });
  }

  /// Updates loopback routing mode:
  /// - When enabled: miniaudio duplex loopback routes mic to speaker natively.
  /// - When disabled: SoLoud handles playback, and its mixer capture output
  ///   is fed to AEC as the far-end speaker reference.
  void _updateLoopbackMode(bool enabled) {
    if (!recorder.isInitialized) return;
    recorder.setLoopback(enable: enabled);

    if (enabled) {
      _soloudMixerSubscription?.cancel();
      _soloudMixerSubscription = null;
      if (soloud.isMixerOutputStreamRunning) {
        soloud.stopMixerOutputStream();
      }
      disposeAudioSource();
    } else {
      if (soloud.isInitialized) {
        _soloudMixerSubscription?.cancel();
        _soloudMixerSubscription = soloud
            .startMixerOutputStream(
              format: MixerOutputFormat.pcmF32le,
              channels: recorderChannels.count,
            )
            .listen((mixerData) {
              if (recorder.isInitialized &&
                  recorder.filters.echoCancellationFilter.isActive) {
                recorder.feedPlaybackData(
                  mixerData,
                  format: PCMFormat.f32le,
                  channels: recorderChannels,
                );
              }
            });
      }
    }
  }

  /// Initialize the audio source
  void initAudioSource() {
    if (!soloud.isInitialized) return;
    if (audioSource != null) disposeAudioSource();

    audioSource = soloud.setBufferStream(
      maxBufferSizeBytes: 1024 * 1024 * 50,
      channels: audioStreamChannels,
      format: audioStreamFormat,
      sampleRate: sampleRate,
      bufferingTimeNeeds: 0.0,
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

    if (soloud.isInitialized) {
      await soloud.disposeSource(audioSource!);
    }
    audioSource = null;
  }

  @override
  void dispose() {
    if (audioSource != null) {
      soloud.setDataIsEnded(audioSource!);
    }
    _soloudMixerSubscription?.cancel();
    _soloudMixerSubscription = null;
    if (soloud.isMixerOutputStreamRunning) {
      soloud.stopMixerOutputStream();
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
    if (soloud.isInitialized) {
      await soloud.deinitAsync();
    }
    await soloud.init(
      bufferSize: 1024,
      channels: Channels.mono,
      sampleRate: sampleRate,
    );

    await recorder.init(
      format: recorderFormat,
      sampleRate: sampleRate,
      channels: recorderChannels,
      androidInputPreset:
          androidInputPreset, // <-- prevales over audio session preset (if not null)
      iosInputPreset:
          iosInputPreset, // <-- prevales over audio session preset (if not null)
      webInputPreset: webInputPreset,
    );

    recorder
      ..start()
      ..startStreamingData();

    _updateLoopbackMode(nativeLoopback);

    /// Debug: Log audio route after init
    final devicesAfter = await session.getDevices();
    dev.log(
      'Audio route after init: input=${devicesAfter.where((d) => d.isInput).map((d) => d.name).join(', ')}, '
      'output=${devicesAfter.where((d) => d.isOutput).map((d) => d.name).join(', ')}',
      name: 'AudioSession',
    );

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
        // Start / Stop
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () async {
                await init();
              },
              child: const Text('Init recorder'),
            ),
            OutlinedButton(
              onPressed: () async {
                _soloudMixerSubscription?.cancel();
                _soloudMixerSubscription = null;
                if (soloud.isMixerOutputStreamRunning) {
                  soloud.stopMixerOutputStream();
                }
                // First deinit the recorder and then the player
                recorder
                  ..stopStreamingData()
                  ..deinit();
                await disposeAudioSource();
                await soloud.deinitAsync();
                if (context.mounted) {
                  setState(() {});
                }
              },
              child: const Text('Stop'),
            ),
          ],
        ),

        // Native Loopback Checkbox
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: nativeLoopback,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  nativeLoopback = v;
                });
                _updateLoopbackMode(v);
              },
            ),
            const Flexible(
              child: Text(
                'Native Duplex Loopback: When checked, uses miniaudio duplex loopback directly. '
                'When unchecked, uses flutter_soloud playback and feeds its mixer output capture to AEC.',
              ),
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
            Text('Echo Cancellation'),
            Checkbox(
              value: echoCancellation,
              onChanged: (v) {
                if (v!) {
                  recorder.filters.echoCancellationFilter.activate();
                } else {
                  recorder.filters.echoCancellationFilter.deactivate();
                }
                setState(() {
                  echoCancellation = v;
                });
              },
            ),
          ],
        ),

        if (kIsWeb) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Web preset (applied on init): ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<WebInputPreset>(
                  value: webInputPreset,
                  items: WebInputPreset.values
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => webInputPreset = v);
                  },
                ),
              ],
            ),
          ),
        ],

        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Android preset (applied on init): ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<AndroidInputPreset>(
                  value: androidInputPreset,
                  items: AndroidInputPreset.values
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => androidInputPreset = v);
                  },
                ),
              ],
            ),
          ),
        ],

        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'iOS preset (applied on init): ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<IosInputPreset>(
                  value: iosInputPreset,
                  items: IosInputPreset.values
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => iosInputPreset = v);
                  },
                ),
              ],
            ),
          ),
        ],

        if (autoGain) AutoGainSliders(),

        if (echoCancellation) EchoCancellationSliders(),
        if (recorderFormat == PCMFormat.f32le) const Bars(),
      ],
    );
  }
}

class EchoCancellationSliders extends StatefulWidget {
  const EchoCancellationSliders({super.key});

  @override
  State<EchoCancellationSliders> createState() =>
      _EchoCancellationSlidersState();
}

class _EchoCancellationSlidersState extends State<EchoCancellationSliders> {
  late final Recorder recorder;
  late final EchoCancellation echoCancellation;

  @override
  void initState() {
    super.initState();
    recorder = Recorder.instance;
    echoCancellation = recorder.filters.echoCancellationFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${echoCancellation.queryFilterLengthMs}: '
              '${echoCancellation.filterLengthMs.value.toStringAsFixed(0)} ms',
            ),
            Expanded(
              child: Slider(
                value: echoCancellation.filterLengthMs.value,
                min: echoCancellation.queryFilterLengthMs.min,
                max: echoCancellation.queryFilterLengthMs.max,
                onChanged: (v) {
                  if (v < echoCancellation.queryFilterLengthMs.min ||
                      v > echoCancellation.queryFilterLengthMs.max) {
                    return;
                  }
                  setState(() {
                    echoCancellation.filterLengthMs.value = v;
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
              '${echoCancellation.queryDenoiseLevelDb}: '
              '${echoCancellation.denoiseLevelDb.value.toStringAsFixed(1)} dB',
            ),
            Expanded(
              child: Slider(
                value: echoCancellation.denoiseLevelDb.value,
                min: echoCancellation.queryDenoiseLevelDb.min,
                max: echoCancellation.queryDenoiseLevelDb.max,
                onChanged: (v) {
                  if (v < echoCancellation.queryDenoiseLevelDb.min ||
                      v > echoCancellation.queryDenoiseLevelDb.max) {
                    return;
                  }
                  setState(() {
                    echoCancellation.denoiseLevelDb.value = v;
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(echoCancellation.queryDenoiseEnabled.toString()),
            Checkbox(
              value: echoCancellation.denoiseEnabled.value > 0.5,
              onChanged: (v) {
                setState(() {
                  echoCancellation.denoiseEnabled.value = (v ?? false)
                      ? 1.0
                      : 0.0;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

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
