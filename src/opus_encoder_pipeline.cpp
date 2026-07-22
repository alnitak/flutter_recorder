#include "opus_encoder_pipeline.h"

#include <algorithm>
#include <cstring>

OpusEncoderPipeline::OpusEncoderPipeline()
    : inputFormat_(ma_format_unknown), channels_(0), inputSampleRate_(0),
      encoder_(nullptr), resamplerInitialized_(false), needResample_(false) {}

OpusEncoderPipeline::~OpusEncoderPipeline() { reset(); }

void OpusEncoderPipeline::reset() {
  if (encoder_ != nullptr) {
    opus_encoder_destroy(encoder_);
    encoder_ = nullptr;
  }
  if (resamplerInitialized_) {
    ma_resampler_uninit(&resampler_, nullptr);
    resamplerInitialized_ = false;
  }
}

CaptureErrors OpusEncoderPipeline::init(ma_format inputFormat,
                                          ma_uint32 inputChannels,
                                          ma_uint32 inputSampleRate) {
  reset();

  inputFormat_ = inputFormat;
  channels_ = inputChannels;
  inputSampleRate_ = inputSampleRate;

  int opusErr = OPUS_OK;
  encoder_ = opus_encoder_create(
      static_cast<opus_int32>(OUTPUT_SAMPLE_RATE), static_cast<int>(channels_),
      OPUS_APPLICATION_AUDIO, &opusErr);
  if (encoder_ == nullptr || opusErr != OPUS_OK) {
    reset();
    return captureInitFailed;
  }

  opus_encoder_ctl(encoder_, OPUS_SET_BITRATE(64000));

  needResample_ = (inputSampleRate_ != OUTPUT_SAMPLE_RATE);
  if (needResample_) {
    ma_resampler_config config = ma_resampler_config_init(
        ma_format_s16, channels_, inputSampleRate_, OUTPUT_SAMPLE_RATE,
        ma_resample_algorithm_linear);
    ma_result result = ma_resampler_init(&config, nullptr, &resampler_);
    if (result != MA_SUCCESS) {
      reset();
      return captureInitFailed;
    }
    resamplerInitialized_ = true;
  }

  packetBuffer_.resize(4000);
  return captureNoError;
}

void OpusEncoderPipeline::push(const void *input, ma_uint32 frameCount) {
  if (encoder_ == nullptr || frameCount == 0) {
    return;
  }

  const ma_uint64 sampleCount =
      static_cast<ma_uint64>(frameCount) * static_cast<ma_uint64>(channels_);
  formatBuffer_.resize(sampleCount);
  ma_pcm_convert(formatBuffer_.data(), ma_format_s16, input, inputFormat_,
                 sampleCount, ma_dither_mode_none);

  if (!needResample_) {
    opusBuffer_.insert(opusBuffer_.end(), formatBuffer_.begin(),
                       formatBuffer_.end());
  } else {
    ma_uint64 inputFrames = frameCount;
    ma_uint64 outputFrames = 0;
    ma_resampler_get_expected_output_frame_count(&resampler_, inputFrames,
                                                 &outputFrames);
    resampleBuffer_.resize(outputFrames * channels_);
    ma_resampler_process_pcm_frames(&resampler_, formatBuffer_.data(),
                                    &inputFrames, resampleBuffer_.data(),
                                    &outputFrames);
    resampleBuffer_.resize(outputFrames * channels_);
    opusBuffer_.insert(opusBuffer_.end(), resampleBuffer_.begin(),
                       resampleBuffer_.end());
  }

  encodeAvailableFrames();
}

void OpusEncoderPipeline::encodeAvailableFrames() {
  const int frameSize = opusFrameSize();
  const int frameSamples = frameSize * static_cast<int>(channels_);

  while (opusBuffer_.size() >= frameSamples) {
    const int packetSize = opus_encode(
        encoder_, opusBuffer_.data(), frameSize, packetBuffer_.data(),
        static_cast<opus_int32>(packetBuffer_.size()));
    if (packetSize > 0 && onPacket) {
      onPacket(packetBuffer_.data(), packetSize);
    }
    opusBuffer_.erase(opusBuffer_.begin(),
                      opusBuffer_.begin() + frameSamples);
  }
}

void OpusEncoderPipeline::flush() {
  if (encoder_ == nullptr) {
    return;
  }

  const int frameSize = opusFrameSize();
  const int frameSamples = frameSize * static_cast<int>(channels_);

  if (!opusBuffer_.empty()) {
    opusBuffer_.resize(frameSamples, 0);
    const int packetSize = opus_encode(
        encoder_, opusBuffer_.data(), frameSize, packetBuffer_.data(),
        static_cast<opus_int32>(packetBuffer_.size()));
    if (packetSize > 0 && onPacket) {
      onPacket(packetBuffer_.data(), packetSize);
    }
    opusBuffer_.clear();
  }
}
