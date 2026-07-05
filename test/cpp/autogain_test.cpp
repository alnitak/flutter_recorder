#include "filters/autogain.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

namespace
{
constexpr unsigned int kSampleRate = 48000;
constexpr unsigned int kChannels = 1;

void require(bool condition, const std::string &message)
{
    if (condition)
        return;

    std::cerr << "autogain_test failed: " << message << std::endl;
    std::exit(1);
}

void setParam(AutoGain &autoGain, AutoGain::Params param, float value)
{
    autoGain.setParamValue(param, value);
}

float metric(const AutoGain &autoGain, AutoGain::Params param)
{
    return autoGain.getParamValue(param);
}

void processConstant(AutoGain &autoGain, float amplitude, ma_uint32 totalFrames, ma_uint32 blockFrames)
{
    std::vector<float> buffer(blockFrames * kChannels);
    ma_uint32 remaining = totalFrames;

    while (remaining > 0)
    {
        const ma_uint32 frames = std::min(remaining, blockFrames);
        std::fill(buffer.begin(), buffer.begin() + frames * kChannels, amplitude);
        autoGain.process(buffer.data(), frames, kChannels, ma_format_f32);
        remaining -= frames;
    }
}

void configureSpeechAgc(AutoGain &autoGain)
{
    setParam(autoGain, AutoGain::TargetRMS, 0.1f);
    setParam(autoGain, AutoGain::AttackTime, 0.05f);
    setParam(autoGain, AutoGain::ReleaseTime, 0.2f);
    setParam(autoGain, AutoGain::GainSmoothing, 0.05f);
    setParam(autoGain, AutoGain::MaxGain, 6.0f);
    setParam(autoGain, AutoGain::MinGain, 0.2f);
    setParam(autoGain, AutoGain::NoiseFloorDb, -90.0f);
    setParam(autoGain, AutoGain::HeadroomDb, 1.0f);
}

void testCallbackSizeInvariantGain()
{
    AutoGain smallBlock(kSampleRate);
    AutoGain largeBlock(kSampleRate);
    configureSpeechAgc(smallBlock);
    configureSpeechAgc(largeBlock);

    processConstant(smallBlock, 0.02f, kSampleRate, 64);
    processConstant(largeBlock, 0.02f, kSampleRate, 512);

    const float smallGain = metric(smallBlock, AutoGain::CurrentGain);
    const float largeGain = metric(largeBlock, AutoGain::CurrentGain);
    const float relativeDifference = std::fabs(smallGain - largeGain) / std::max(smallGain, largeGain);

    require(relativeDifference < 0.03f, "gain should be callback-size invariant");
}

void testSilenceDoesNotGetBoosted()
{
    AutoGain autoGain(kSampleRate);
    configureSpeechAgc(autoGain);
    setParam(autoGain, AutoGain::NoiseFloorDb, -50.0f);

    processConstant(autoGain, 0.02f, kSampleRate, 128);
    require(metric(autoGain, AutoGain::CurrentGain) > 1.0f, "quiet speech should be amplified before silence");

    processConstant(autoGain, 0.0f, 128, 128);
    require(metric(autoGain, AutoGain::InputRMS) == 0.0f, "silence RMS should be zero");
    require(metric(autoGain, AutoGain::CurrentGain) <= 1.0f, "silence should not be boosted above unity");
}

void testLimiterProtectsFloatOutput()
{
    AutoGain autoGain(kSampleRate);
    configureSpeechAgc(autoGain);
    setParam(autoGain, AutoGain::TargetRMS, 0.5f);
    setParam(autoGain, AutoGain::AttackTime, 0.001f);
    setParam(autoGain, AutoGain::GainSmoothing, 0.001f);
    setParam(autoGain, AutoGain::MaxGain, 12.0f);

    processConstant(autoGain, 0.01f, kSampleRate / 4, 128);

    std::vector<float> impulse(256, 1.0f);
    autoGain.process(impulse.data(), static_cast<ma_uint32>(impulse.size()), kChannels, ma_format_f32);

    const float ceiling = std::pow(10.0f, -metric(autoGain, AutoGain::HeadroomDb) / 20.0f);
    const float peak = *std::max_element(
        impulse.begin(),
        impulse.end(),
        [](float lhs, float rhs) { return std::fabs(lhs) < std::fabs(rhs); });

    require(std::fabs(peak) <= ceiling + 1.0e-5f, "limiter should keep float samples below headroom");
    require(metric(autoGain, AutoGain::LimiterClipCount) > 0.0f, "limiter should report clipped samples");
    require(metric(autoGain, AutoGain::OutputPeak) <= ceiling + 1.0e-5f, "output peak should report limited peak");
}

void testS16PositiveFullScaleDoesNotOverflow()
{
    AutoGain autoGain(kSampleRate);
    configureSpeechAgc(autoGain);
    setParam(autoGain, AutoGain::TargetRMS, 0.5f);
    setParam(autoGain, AutoGain::AttackTime, 0.001f);
    setParam(autoGain, AutoGain::GainSmoothing, 0.001f);
    setParam(autoGain, AutoGain::MaxGain, 12.0f);

    processConstant(autoGain, 0.01f, kSampleRate / 4, 128);

    std::vector<int16_t> samples(256, 32767);
    autoGain.process(samples.data(), static_cast<ma_uint32>(samples.size()), kChannels, ma_format_s16);

    for (const int16_t sample : samples)
    {
        const int value = sample;
        require(value >= 0, "positive s16 full-scale samples should not wrap negative");
        require(value <= 32767, "s16 output should stay within positive full scale");
    }
}

void testReadOnlyMetricsIgnoreSetters()
{
    AutoGain autoGain(kSampleRate);
    autoGain.setParamValue(AutoGain::CurrentGain, 6.0f);
    autoGain.setParamValue(AutoGain::InputRMS, 0.5f);

    require(metric(autoGain, AutoGain::CurrentGain) == 1.0f, "current gain metric should be read-only");
    require(metric(autoGain, AutoGain::InputRMS) == 0.0f, "input RMS metric should be read-only");
}
} // namespace

int main()
{
    testCallbackSizeInvariantGain();
    testSilenceDoesNotGetBoosted();
    testLimiterProtectsFloatOutput();
    testS16PositiveFullScaleDoesNotOverflow();
    testReadOnlyMetricsIgnoreSetters();

    return 0;
}
