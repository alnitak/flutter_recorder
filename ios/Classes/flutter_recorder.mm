// Relative import to be able to reuse the C sources.
// See the comment in ../flutter_recorder.podspec for more information.
#include "../../src/flutter_recorder.cpp"

#include "../../src/analyzer.cpp"
#include "../../src/capture.cpp"
#include "../../src/opus_encoder_pipeline.cpp"
#include "../../src/opus_ogg_writer.cpp"
#include "../../src/fft/soloud_fft.cpp"
#include "../../src/filters/filters.cpp"
#include "../../src/filters/autogain.cpp"
#include "../../src/filters/echo_cancellation.cpp"
