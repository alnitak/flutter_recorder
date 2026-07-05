/// Flutter low level audio recorder plugin using miniaudio library and FFI
library flutter_recorder;

export 'src/audio_data_container.dart';
export 'src/enums.dart'
    show
        AndroidInputPreset,
        CaptureDevice,
        CaptureErrors,
        PCMFormat,
        RecorderChannels;
export 'src/filters/autogain.dart';
export 'src/filters/echo_cancellation.dart';
export 'src/filters/filters.dart'
    show FilterMetric, FilterParam, RecorderFilterType;
export 'src/flutter_recorder.dart';
