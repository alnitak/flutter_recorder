#ifndef OPUS_ENCODER_PIPELINE_H
#define OPUS_ENCODER_PIPELINE_H

#include "common.h"
#include "enums.h"
#include "miniaudio.h"

#include <opus/opus.h>
#include <functional>
#include <vector>

/// Encodes incoming audio to Opus packets.
///
/// The pipeline resamples the input to 48 kHz (if needed), converts it to
/// interleaved 16-bit PCM and feeds it to the Opus encoder in 20 ms frames.
/// Each produced packet is delivered through the [onPacket] callback.
class OpusEncoderPipeline {
public:
  OpusEncoderPipeline();
  ~OpusEncoderPipeline();

  /// Initialize the pipeline for the given capture format.
  CaptureErrors init(ma_format inputFormat, ma_uint32 inputChannels,
                       ma_uint32 inputSampleRate);

  /// Push a chunk of captured audio into the pipeline.
  void push(const void *input, ma_uint32 frameCount);

  /// Flush the remaining audio, padding with silence if necessary.
  void flush();

  /// Release the encoder and resampler.
  void reset();

  /// Called for every encoded Opus packet.
  std::function<void(const unsigned char *packet, int packetSize)> onPacket;

private:
  static constexpr ma_uint32 OUTPUT_SAMPLE_RATE = 48000;
  static constexpr int FRAME_SIZE_MS = 20;

  int opusFrameSize() const {
    return (OUTPUT_SAMPLE_RATE * FRAME_SIZE_MS) / 1000;
  }

  void encodeAvailableFrames();

  ma_format inputFormat_;
  ma_uint32 channels_;
  ma_uint32 inputSampleRate_;

  OpusEncoder *encoder_;
  ma_resampler resampler_;
  bool resamplerInitialized_;
  bool needResample_;

  std::vector<opus_int16> formatBuffer_;
  std::vector<opus_int16> resampleBuffer_;
  std::vector<opus_int16> opusBuffer_;
  std::vector<unsigned char> packetBuffer_;
};

#endif // OPUS_ENCODER_PIPELINE_H
