#include "autogain.h"

#include <algorithm>
#include <cmath>
#include <limits>

namespace
{
constexpr float kDefaultSampleRate = 48000.0f;
constexpr float kMinTimeSeconds = 0.001f;
constexpr float kFloatEpsilon = 1.0e-6f;

float clampFinite(float value, float minValue, float maxValue)
{
    if (!std::isfinite(value))
        return minValue;
    return std::clamp(value, minValue, maxValue);
}

float dbToLinear(float db)
{
    return std::pow(10.0f, db / 20.0f);
}

float safeAbs(float value)
{
    return std::fabs(std::isfinite(value) ? value : 0.0f);
}

int32_t signExtend24(uint32_t value)
{
    if ((value & 0x00800000u) != 0)
        value |= 0xFF000000u;
    return static_cast<int32_t>(value);
}
} // namespace

const std::array<AutoGain::ParamInfo, AutoGain::ParamCount> AutoGain::kParamInfo = {{
    {"Target RMS", 0.1f, 0.001f, 0.95f, true},
    {"Attack Time", 0.1f, 0.001f, 2.0f, true},
    {"Release Time", 0.2f, 0.001f, 5.0f, true},
    {"Gain Smoothing", 0.05f, 0.001f, 1.0f, true},
    {"Max Gain", 6.0f, 1.0f, 12.0f, true},
    {"Min Gain", 0.2f, 0.0f, 1.0f, true},
    {"Noise Floor dB", -55.0f, -100.0f, -10.0f, true},
    {"Headroom dB", 1.0f, 0.0f, 24.0f, true},
    {"Current Gain", 1.0f, 0.0f, 12.0f, false},
    {"Input RMS", 0.0f, 0.0f, 1.0f, false},
    {"Output Peak", 0.0f, 0.0f, 1.0f, false},
    {"Limiter Clip Count", 0.0f, 0.0f, std::numeric_limits<float>::max(), false},
    {"Total Limiter Clip Count", 0.0f, 0.0f, std::numeric_limits<float>::max(), false},
    {"Last Frame Count", 0.0f, 0.0f, std::numeric_limits<float>::max(), false},
}};

AutoGain::AutoGain() : AutoGain(0) {}

AutoGain::AutoGain(unsigned int sampleRate)
    : mSampleRate(sampleRate > 0 ? static_cast<float>(sampleRate) : kDefaultSampleRate),
      mCurrentGain(kParamInfo[CurrentGain].defaultVal),
      mSmoothedRMS(kParamInfo[TargetRMS].defaultVal),
      mTotalLimiterClipCount(0)
{
    for (int i = 0; i < ParamCount; ++i)
        mValues[i].store(kParamInfo[i].defaultVal, std::memory_order_relaxed);
}

int AutoGain::getParamCount() const
{
    return ParamCount;
}

float AutoGain::getParamMax(int param) const
{
    if (!isValidParam(param))
        return 0.0f;
    return kParamInfo[param].maxVal;
}

float AutoGain::getParamMin(int param) const
{
    if (!isValidParam(param))
        return 0.0f;
    return kParamInfo[param].minVal;
}

float AutoGain::getParamDef(int param) const
{
    if (!isValidParam(param))
        return 0.0f;
    return kParamInfo[param].defaultVal;
}

std::string AutoGain::getParamName(int param) const
{
    if (!isValidParam(param))
        return "Unknown";
    return kParamInfo[param].name;
}

void AutoGain::setParamValue(int param, float value)
{
    if (!isWritableParam(param))
        return;

    const ParamInfo &info = kParamInfo[param];
    if (value < info.minVal || value > info.maxVal || !std::isfinite(value))
        return;

    mValues[param].store(value, std::memory_order_relaxed);
}

float AutoGain::getParamValue(int param) const
{
    if (!isValidParam(param))
        return 0.0f;
    return mValues[param].load(std::memory_order_relaxed);
}

void AutoGain::process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    if (pInput == nullptr || frameCount == 0 || channels == 0)
        return;

    const ma_uint64 sampleCount64 = static_cast<ma_uint64>(frameCount) * channels;
    if (sampleCount64 > std::numeric_limits<ma_uint32>::max())
        return;

    const ma_uint32 sampleCount = static_cast<ma_uint32>(sampleCount64);
    const LevelStats input = analyzeInput(pInput, sampleCount, format);

    const float levelAlpha = smoothingFactor(readParam(GainSmoothing), frameCount);
    mSmoothedRMS += (input.rms - mSmoothedRMS) * levelAlpha;
    mSmoothedRMS = std::max(mSmoothedRMS, 0.0f);

    float targetGain = calculateTargetGain(input.rms, input.peak);
    const float gainTime = targetGain > mCurrentGain
                               ? readParam(AttackTime)
                               : readParam(ReleaseTime);
    const float gainAlpha = smoothingFactor(gainTime, frameCount);

    float startGain = mCurrentGain;
    float endGain = mCurrentGain + (targetGain - mCurrentGain) * gainAlpha;

    const float noiseFloor = dbToLinear(readParam(NoiseFloorDb));
    if (input.rms < noiseFloor)
    {
        startGain = std::min(startGain, 1.0f);
        endGain = std::min(endGain, 1.0f);
    }

    const float maxGain = readParam(MaxGain);
    endGain = clampFinite(endGain, 0.0f, maxGain);

    const ProcessStats output = applyGain(
        pInput,
        frameCount,
        channels,
        format,
        startGain,
        endGain);

    mCurrentGain = endGain;
    mTotalLimiterClipCount += output.limiterClipCount;

    writeMetric(CurrentGain, mCurrentGain);
    writeMetric(InputRMS, input.rms);
    writeMetric(OutputPeak, output.outputPeak);
    writeMetric(LimiterClipCount, static_cast<float>(output.limiterClipCount));
    writeMetric(TotalLimiterClipCount, static_cast<float>(mTotalLimiterClipCount));
    writeMetric(LastFrameCount, static_cast<float>(frameCount));
}

AutoGain::LevelStats AutoGain::analyzeInput(const void *pInput, ma_uint32 sampleCount, ma_format format) const
{
    if (sampleCount == 0)
        return {0.0f, 0.0f};

    double squareSum = 0.0;
    float peak = 0.0f;

    for (ma_uint32 i = 0; i < sampleCount; ++i)
    {
        const float sample = readSample(pInput, i, format);
        squareSum += static_cast<double>(sample) * sample;
        peak = std::max(peak, safeAbs(sample));
    }

    return {
        static_cast<float>(std::sqrt(squareSum / sampleCount)),
        peak,
    };
}

float AutoGain::readSample(const void *pInput, ma_uint32 sampleIndex, ma_format format) const
{
    switch (format)
    {
    case ma_format_u8:
        return (static_cast<const uint8_t *>(pInput)[sampleIndex] - 128) / 128.0f;
    case ma_format_s16:
        return static_cast<const int16_t *>(pInput)[sampleIndex] / 32768.0f;
    case ma_format_s24:
    {
        const uint8_t *sample = static_cast<const uint8_t *>(pInput) + sampleIndex * 3;
        const uint32_t packed = static_cast<uint32_t>(sample[0]) |
                                (static_cast<uint32_t>(sample[1]) << 8) |
                                (static_cast<uint32_t>(sample[2]) << 16);
        return signExtend24(packed) / 8388608.0f;
    }
    case ma_format_s32:
        return static_cast<const int32_t *>(pInput)[sampleIndex] / 2147483648.0f;
    case ma_format_f32:
        return std::isfinite(static_cast<const float *>(pInput)[sampleIndex])
                   ? static_cast<const float *>(pInput)[sampleIndex]
                   : 0.0f;
    default:
        return 0.0f;
    }
}

void AutoGain::writeSample(void *pInput, ma_uint32 sampleIndex, ma_format format, float sample) const
{
    switch (format)
    {
    case ma_format_u8:
    {
        const float clamped = clampFinite(sample, -1.0f, 1.0f);
        const int32_t converted = static_cast<int32_t>(std::lrint(clamped * 128.0f + 128.0f));
        static_cast<uint8_t *>(pInput)[sampleIndex] = static_cast<uint8_t>(std::clamp(converted, 0, 255));
        break;
    }
    case ma_format_s16:
    {
        const float maxSample = 32767.0f / 32768.0f;
        const float clamped = clampFinite(sample, -1.0f, maxSample);
        const int32_t converted = static_cast<int32_t>(std::lrint(clamped * 32768.0f));
        static_cast<int16_t *>(pInput)[sampleIndex] = static_cast<int16_t>(std::clamp(converted, -32768, 32767));
        break;
    }
    case ma_format_s24:
    {
        const float maxSample = 8388607.0f / 8388608.0f;
        const float clamped = clampFinite(sample, -1.0f, maxSample);
        const int32_t converted = std::clamp(
            static_cast<int32_t>(std::lrint(clamped * 8388608.0f)),
            -8388608,
            8388607);
        uint8_t *destination = static_cast<uint8_t *>(pInput) + sampleIndex * 3;
        destination[0] = static_cast<uint8_t>(converted & 0xFF);
        destination[1] = static_cast<uint8_t>((converted >> 8) & 0xFF);
        destination[2] = static_cast<uint8_t>((converted >> 16) & 0xFF);
        break;
    }
    case ma_format_s32:
    {
        const double maxSample = 2147483647.0 / 2147483648.0;
        const double clamped = static_cast<double>(clampFinite(sample, -1.0f, static_cast<float>(maxSample)));
        const int64_t converted = static_cast<int64_t>(std::llrint(clamped * 2147483648.0));
        static_cast<int32_t *>(pInput)[sampleIndex] = static_cast<int32_t>(
            std::clamp<int64_t>(converted, std::numeric_limits<int32_t>::min(), std::numeric_limits<int32_t>::max()));
        break;
    }
    case ma_format_f32:
        static_cast<float *>(pInput)[sampleIndex] = clampFinite(sample, -1.0f, 1.0f);
        break;
    default:
        break;
    }
}

float AutoGain::calculateTargetGain(float inputRMS, float inputPeak) const
{
    const float noiseFloor = dbToLinear(readParam(NoiseFloorDb));
    if (inputRMS < noiseFloor || mSmoothedRMS < noiseFloor)
        return std::min(mCurrentGain, 1.0f);

    const float minGain = readParam(MinGain);
    const float maxGain = readParam(MaxGain);
    const float targetRMS = readParam(TargetRMS);
    float targetGain = targetRMS / std::max(mSmoothedRMS, kFloatEpsilon);
    targetGain = std::clamp(targetGain, minGain, maxGain);

    const float ceiling = dbToLinear(-readParam(HeadroomDb));
    if (inputPeak > kFloatEpsilon)
        targetGain = std::min(targetGain, ceiling / inputPeak);

    return clampFinite(targetGain, 0.0f, maxGain);
}

float AutoGain::smoothingFactor(float timeSeconds, ma_uint32 frameCount) const
{
    const float safeTime = std::max(timeSeconds, kMinTimeSeconds);
    const float safeSampleRate = std::max(mSampleRate, 1.0f);
    return 1.0f - std::exp(-static_cast<float>(frameCount) / (safeTime * safeSampleRate));
}

AutoGain::ProcessStats AutoGain::applyGain(
    void *pInput,
    ma_uint32 frameCount,
    unsigned int channels,
    ma_format format,
    float startGain,
    float endGain) const
{
    const float ceiling = dbToLinear(-readParam(HeadroomDb));
    const float gainDelta = endGain - startGain;
    float outputPeak = 0.0f;
    uint64_t limiterClipCount = 0;

    for (ma_uint32 frame = 0; frame < frameCount; ++frame)
    {
        const float progress = static_cast<float>(frame + 1) / frameCount;
        const float frameGain = startGain + gainDelta * progress;

        for (unsigned int channel = 0; channel < channels; ++channel)
        {
            const ma_uint32 sampleIndex = frame * channels + channel;
            float sample = readSample(pInput, sampleIndex, format) * frameGain;

            if (!std::isfinite(sample))
                sample = 0.0f;

            if (safeAbs(sample) > ceiling)
            {
                sample = std::copysign(ceiling, sample);
                ++limiterClipCount;
            }

            outputPeak = std::max(outputPeak, safeAbs(sample));
            writeSample(pInput, sampleIndex, format, sample);
        }
    }

    return {outputPeak, limiterClipCount};
}

float AutoGain::readParam(Params param) const
{
    return mValues[param].load(std::memory_order_relaxed);
}

void AutoGain::writeMetric(Params param, float value)
{
    if (!isValidParam(param))
        return;
    mValues[param].store(value, std::memory_order_relaxed);
}

bool AutoGain::isValidParam(int param) const
{
    return param >= 0 && param < ParamCount;
}

bool AutoGain::isWritableParam(int param) const
{
    return isValidParam(param) && kParamInfo[param].writable;
}
