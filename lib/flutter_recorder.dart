/// Flutter low level audio recorder plugin using miniaudio library and FFI
library flutter_recorder;

export 'src/audio_data_container.dart';
export 'src/enums.dart' show PCMFormat, RecorderChannels;
export 'src/filters/autogain.dart';
export 'src/filters/echo_cancellation.dart';
export 'src/flutter_recorder.dart';
