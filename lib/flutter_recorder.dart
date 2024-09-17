// ignore_for_file: omit_local_variable_types, avoid_positional_boolean_parameters

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/enums.dart';
import 'package:flutter_recorder/exceptions/exceptions.dart';
import 'package:flutter_recorder/flutter_recorder_bindings_generated.dart';

/// Callback when silence state is changed.
typedef SilenceCallback = void Function(bool isSilent, double decibel);

/// Silence state.
typedef SilenceState = ({bool isSilent, double decibel});

/// Use this class to _capture_ audio (such as from a microphone).
class Recorder {
  /// The private constructor of [Recorder]. This prevents developers from
  /// instantiating new instances.
  Recorder._();

  /// The singleton instance of [Recorder]. Only one Recorder instance
  /// can exist in C++ land, so – for consistency and to avoid confusion
  /// – only one instance can exist in Dart land.
  ///
  /// Using this static field, you can get a hold of the single instance
  /// of this class from anywhere. This ability to access global state
  /// from anywhere can lead to hard-to-debug bugs, though, so it is
  /// preferable to encapsulate this and provide it through a facade.
  /// For example:
  ///
  /// ```dart
  /// final recordingController = MyRecordingController(Recorder.instance);
  ///
  /// // Now provide the recording controller to parts of the app that need it.
  /// // No other part of the codebase need import `package:flutter_recorder`.
  /// ```
  ///
  /// Alternatively, at least create a field with the single instance
  /// of [Recorder], and provide that (without the facade, but also without
  /// accessing [Recorder.instance] from different places of the app).
  /// For example:
  ///
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> {
  ///   Recorder? _recorder;
  ///
  ///   void _initializeRecording() async {
  ///     // The only place in the codebase that accesses Recorder.instance
  ///     // directly.
  ///     final recorder = Recorder.instance;
  ///     await recorder.initialize();
  ///
  ///     setState(() {
  ///       _recorder = recorder;
  ///     });
  ///   }
  ///
  ///   // ...
  /// }
  /// ```
  static final Recorder instance = Recorder._();

  SilenceCallback? _silenceCallback;

  /// Controller to listen to silence changed event.
  late final StreamController<SilenceState> silenceChangedEventController =
      StreamController.broadcast();

  /// Listener for silence changed.
  Stream<SilenceState> get silenceChangedEvents =>
      silenceChangedEventController.stream;

  static const String _libName = 'flutter_recorder';

  /// The dynamic library in which the symbols for [FlutterRecorderBindings]
  /// can be found.
  static final ffi.DynamicLibrary _dylib = () {
    if (Platform.isMacOS || Platform.isIOS) {
      return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return ffi.DynamicLibrary.open('lib$_libName.so');
    }
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('$_libName.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }();

  /// The bindings to the native functions in [_dylib].
  final FlutterRecorderBindings _bindings = FlutterRecorderBindings(_dylib);

  void _silenceChangedCallback(
    ffi.Pointer<ffi.Bool> silence,
    ffi.Pointer<ffi.Float> db,
  ) {
    // voiceEndedEventController.add(handle.value);
    // print('SILENCE CHANGED: ${silence.value}, ${db.value}');
    _silenceCallback?.call(silence.value, db.value);
    silenceChangedEventController.add(
      (isSilent: silence.value, decibel: db.value),
    );
  }

  /// Enable or disable silence detection.
  ///
  /// [enable] wheter to enable or disable silence detection. Default to false.
  /// [onSilenceChanged] callback when silence state is changed.
  void setSilenceDetection({
    required bool enable,
    SilenceCallback? onSilenceChanged,
  }) {
    final nativeSilenceChangedCallable =
        ffi.NativeCallable<dartSilenceChangedCallback_tFunction>.listener(
      _silenceChangedCallback,
    );

    _bindings
      ..setDartEventCallback(nativeSilenceChangedCallable.nativeFunction)
      ..setSilenceDetection(enable);

    if (onSilenceChanged != null) {
      _silenceCallback = onSilenceChanged;
    }
    if (!enable) {
      _silenceCallback = null;
    }
  }

  /// Set silence threshold in dB.
  ///
  /// [silenceThresholdDb] the silence threshold in dB. A volume under this
  /// value is considered to be silence. Default to -40.
  ///
  /// Note on dB value:
  /// - Decibels (dB) are a relative measure. In digital audio, there is
  /// no 'absolute 0 dB level' that corresponds to absolute silence.
  /// - The 0 dB level is usually defined as the maximum possible signal level,
  /// i.e., the maximum amplitude of the signal that the system can handle
  /// without distortion.
  /// - Negative dB values indicate that the signal's energy is lower compared
  /// to this maximum.
  void setSilenceThresholdDb(double silenceThresholdDb) {
    assert(silenceThresholdDb < 0, 'silenceThresholdDb must be < 0');
    _bindings.setSilenceThresholdDb(silenceThresholdDb);
  }

  /// Set silence duration in seconds.
  ///
  /// [silenceDuration] the duration of silence in seconds. If the volume
  /// remains silent for this duration, the callback will be triggered. Default
  /// to 2 seconds.
  void setSilenceDuration(double silenceDuration) {
    assert(silenceDuration >= 0, 'silenceDuration must be >= 0');
    _bindings.setSilenceDuration(silenceDuration);
  }

  /// Set seconds of audio to write before starting recording again after
  /// silence.
  ///
  /// [secondsOfAudioToWriteBefore] seconds of audio to write occurred before
  /// starting recording againg after silence. Default to 0 seconds.
  /// ```text
  /// |*** silence ***|******** recording *********|
  ///                 ^ start of recording
  ///             ^ secondsOfAudioToWriteBefore (write some before silence ends)
  /// ```
  void setSecondsOfAudioToWriteBefore(double secondsOfAudioToWriteBefore) {
    assert(
      secondsOfAudioToWriteBefore >= 0,
      'secondsOfAudioToWriteBefore must be >= 0',
    );
    _bindings.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
  }

  /// List available input devices. Useful on desktop to choose
  /// which input device to use.
  List<CaptureDevice> listCaptureDevices() {
    final ret = <CaptureDevice>[];
    final ffi.Pointer<ffi.Pointer<ffi.Char>> deviceNames =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Char>>>() * 255);
    final ffi.Pointer<ffi.Pointer<ffi.Int>> deviceIds =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Int>>>() * 50);
    final ffi.Pointer<ffi.Pointer<ffi.Int>> deviceIsDefault =
        calloc(ffi.sizeOf<ffi.Pointer<ffi.Pointer<ffi.Int>>>() * 50);
    final ffi.Pointer<ffi.Int> nDevices = calloc();

    _bindings.listCaptureDevices(
      deviceNames,
      deviceIds,
      deviceIsDefault,
      nDevices,
    );

    final ndev = nDevices.value;
    for (var i = 0; i < ndev; i++) {
      final s1 = (deviceNames + i).value;
      final s = s1.cast<Utf8>().toDartString();
      final id1 = (deviceIds + i).value;
      final id = id1.value;
      final n1 = (deviceIsDefault + i).value;
      final n = n1.value;
      ret.add(CaptureDevice(s, n == 1, id));
    }

    /// Free allocated memory done in C.
    /// This work on all platforms but not on win.
    // for (int i = 0; i < ndev; i++) {
    //   calloc.free(devices.elementAt(i).value.ref.name);
    //   calloc.free(devices.elementAt(i).value);
    // }
    _bindings.freeListCaptureDevices(
      deviceNames,
      deviceIds,
      deviceIsDefault,
      ndev,
    );

    calloc
      ..free(deviceNames)
      ..free(deviceIds)
      ..free(nDevices);
    return ret;
  }

  /// Initialize input device with [deviceID].
  ///
  /// Thows [RecorderInitializeFailedException] if something goes wrong, ie. no
  /// device found with [deviceID] id.
  void init({int deviceID = -1}) {
    final error = _bindings.init(deviceID);
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromPlayerError(error);
    }
  }

  /// Dispose capture device.
  void deinit() {
    _silenceCallback = null;
    _bindings.deinit();
  }

  /// Whether the device is initialized.
  bool isDeviceInitialized() {
    return _bindings.isInited() == 1;
  }

  /// Whether listen to the device is started.
  bool isDeviceStartedListen() {
    return _bindings.isDeviceStartedListen() == 1;
  }

  /// Start listening to the device.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToStartDeviceException].
  void startListen() {
    final error = _bindings.startListen();
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromPlayerError(error);
    }
  }

  /// Stop listening to the device.
  void stopListen() {
    _bindings.stopListen();
  }

  /// Start recording.
  ///
  /// Throws [RecorderCaptureNotInitializedException].
  /// Throws [RecorderFailedToInitializeRecordingException].
  void startRecording(String path) {
    final error = _bindings.startRecording(path.toNativeUtf8().cast());
    if (error != CaptureErrors.captureNoError) {
      throw RecorderCppException.fromPlayerError(error);
    }
  }

  /// Pause recording.
  void setPauseRecording({required bool pause}) {
    _bindings.setPauseRecording(pause);
  }

  /// Stop recording.
  void stopRecording() {
    _bindings.stopRecording();
  }

  /// Smooth FFT data.
  ///
  /// When new data is read and the values are decreasing, the new value will be
  /// decreased with an amplitude between the old and the new value.
  /// This will resul on a less shaky visualization.
  /// [smooth] must be in the [0.0 ~ 1.0] range.
  /// 0 = no smooth, values istantly get their new value.
  /// 1 = values don't get down when they reach their max value.
  /// the new value is calculated with:
  /// newFreq = smooth * oldFreq + (1 - smooth) * newFreq
  void setFftSmoothing(double smooth) {
    _bindings.setFftSmoothing(smooth);
  }

  /// Return a 256 float array containing FFT data in the range [-1.0, 1.0]
  /// not clamped.
  Float32List getFft() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> fft = calloc(256 * 4);
    _bindings.getFft(fft);

    final val = ffi.Pointer<ffi.Float>.fromAddress(fft.value.address);
    if (val == ffi.nullptr) return Float32List(256);

    final fftList = val.cast<ffi.Float>().asTypedList(256);
    calloc.free(fft);
    return fftList;
  }

  /// Return a 256 float array containing wave data in the range [-1.0, 1.0].
  Float32List getWave() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> wave = calloc(256 * 4);
    _bindings.getWave(wave);

    final val = ffi.Pointer<ffi.Float>.fromAddress(wave.value.address);
    if (val == ffi.nullptr) return Float32List(256);

    final waveList = val.cast<ffi.Float>().asTypedList(256);
    calloc.free(wave);
    return waveList;
  }

  /// Get the audio data representing an array of 256 floats FFT data and
  /// 256 float of wave data.
  Float32List getTexture2D() {
    final ffi.Pointer<ffi.Pointer<ffi.Float>> data = calloc(512 * 256 * 4);
    _bindings.getTexture2D(data);

    final val = ffi.Pointer<ffi.Float>.fromAddress(data.value.address);
    if (val == ffi.nullptr) return Float32List(512 * 256);

    calloc.free(data);
    final textureList = val.cast<ffi.Float>().asTypedList(512 * 256);

    return textureList;
  }

  /// Get the current volume in dB. Returns -90 if the capture is not inited.
  double getVolumeDb() {
    final ffi.Pointer<ffi.Float> volume = calloc(4);
    _bindings.getVolumeDb(volume);
    final v = volume.value;
    calloc.free(volume);
    return v;
  }
}
