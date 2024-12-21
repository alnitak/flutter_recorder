#include "autogain.h"

#include <cmath>
#include <cstdint>
#include <vector>
#include <algorithm>

AutoGain::AutoGain(unsigned int sampleRate)
    : mSampleRate(sampleRate), mCurrentGain(1.0f),
      mParams{ // def min max
          {TargetRMS,       {0.1f,   0.01f,   1.f}},
          {AttackTime,      {0.1f,   0.01f,  0.5f}},
          {ReleaseTime,     {0.2f,   0.01f,   0.5f}},
          {GainSmoothing,   {0.05f,  0.001f,  1.f}},
          {MaxGain,         {6.0f,   1.0f,    6.0f}},
          {MinGain,         {0.2f,   0.1f,    1.f}}
      }
{
    mValues.resize(ParamCount);
    // Initialize values with defaults
    for (const auto &[param, range] : mParams)
    {
        mValues[param] = range.defaultVal;
    }
    mSmoothedRMS = mValues[TargetRMS]; // Initialize with Target RMS
}

// Override parameter management methods
int AutoGain::getParamCount() const
{
    return ParamCount;
}

float AutoGain::getParamMax(int param) const
{
    validateParam(param);
    return mParams.at(static_cast<Params>(param)).maxVal;
}

float AutoGain::getParamMin(int param) const
{
    validateParam(param);
    return mParams.at(static_cast<Params>(param)).minVal;
}

float AutoGain::getParamDef(int param) const
{
    validateParam(param);
    return mParams.at(static_cast<Params>(param)).defaultVal;
}

std::string AutoGain::getParamName(int param) const
{
    validateParam(param);
    switch (static_cast<Params>(param))
    {
    case TargetRMS:
        return "Target RMS";
    case AttackTime:
        return "Attack Time";
    case ReleaseTime:
        return "Release Time";
    case GainSmoothing:
        return "Gain Smoothing";
    case MaxGain:
        return "Max Gain";
    case MinGain:
        return "Min Gain";
    default:
        return "Unknown";
    }
}

void AutoGain::setParamValue(int param, float value)
{
    validateParam(param);
    const auto &range = mParams.at(static_cast<Params>(param));
    if (value < range.minVal || value > range.maxVal)
    {
        // Parameter value out of range
        return;
    }
    mValues[param] = value;
}

float AutoGain::getParamValue(int param) const
{
    validateParam(param);
    return mValues[param];
}

void AutoGain::process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    // Calculate the current frame's RMS
    float currentRMS = calculateRMS(pInput, frameCount, channels, format);

    // Smooth RMS over time using exponential smoothing
    mSmoothedRMS += (currentRMS - mSmoothedRMS) * rmsSmoothingFactor();

    // Calculate the target gain based on smoothed RMS
    float targetGain = getParamValue(TargetRMS) / (mSmoothedRMS + 1e-6f);
    targetGain = std::min(targetGain, getParamValue(MaxGain));
    targetGain = std::clamp(targetGain, getParamValue(MinGain), getParamValue(MaxGain));
    // if (mSmoothedRMS < 0.01f) {
    //     targetGain = getParamValue(MaxGain);  // Boost gain to reach MinRMS.
    // } else if (mSmoothedRMS > .1f) {
    //     targetGain = getParamValue(MinGain);  // Lower gain to stay below MaxRMS.
    // } else {
    //     targetGain = getParamValue(TargetRMS) / mSmoothedRMS;
    // }

    // Smoothly adjust gain
    float smoothing = targetGain > mCurrentGain ? getParamValue(AttackTime) : getParamValue(ReleaseTime);
    mCurrentGain += (targetGain - mCurrentGain) * (1.0f - std::exp(-smoothing * getParamValue(GainSmoothing)));
    mCurrentGain += (targetGain - mCurrentGain) * getParamValue(GainSmoothing);
    // float delta = targetGain - mCurrentGain;
    // if (std::abs(delta) > 0.001f) { // Adjust threshold as needed
    //     mCurrentGain += delta * getParamValue(GainSmoothing);
    // }

    // printf("currentRMS: %f smoothedRMS: %f targetGain: %f currentGain: %f\n",
    //    currentRMS, mSmoothedRMS, targetGain, mCurrentGain);
    
    // Apply the gain to the input buffer
    applyGain((void *)pInput, frameCount, channels, format);
}

// Calculate RMS for the current frame
float AutoGain::calculateRMS(const void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    double rmsSum = 0.0;
    ma_uint32 sampleCount = frameCount * channels;

    switch (format)
    {
    case ma_format_u8:
        for (ma_uint32 i = 0; i < sampleCount; ++i)
        {
            float sample = (static_cast<const uint8_t *>(pInput)[i] - 128) / 128.0f;
            rmsSum += sample * sample;
        }
        break;
    case ma_format_s16:
        for (ma_uint32 i = 0; i < sampleCount; ++i)
        {
            float sample = static_cast<const int16_t *>(pInput)[i] / 32768.0f;
            rmsSum += sample * sample;
        }
        break;
    case ma_format_s24:
        for (ma_uint32 i = 0; i < sampleCount; ++i)
        {
            int32_t sample = (static_cast<const uint8_t *>(pInput)[i * 3] << 16) |
                             (static_cast<const uint8_t *>(pInput)[i * 3 + 1] << 8) |
                             static_cast<const uint8_t *>(pInput)[i * 3 + 2];
            sample = sample << 8 >> 8; // Sign extend
            rmsSum += (sample / 8388608.0f) * (sample / 8388608.0f);
        }
        break;
    case ma_format_s32:
        for (ma_uint32 i = 0; i < sampleCount; ++i)
        {
            float sample = static_cast<const int32_t *>(pInput)[i] / 2147483648.0f;
            rmsSum += sample * sample;
        }
        break;
    case ma_format_f32:
        for (ma_uint32 i = 0; i < sampleCount; ++i)
        {
            float sample = static_cast<const float *>(pInput)[i];
            rmsSum += sample * sample;
        }
        break;
    default:
        return 0.0f; // Unknown format
    }

    return std::sqrt(rmsSum / sampleCount);
}

// Exponential smoothing factor for RMS calculation
float AutoGain::rmsSmoothingFactor() const
{
    float windowSizeSeconds = 0.5f; // Adjust smoothing window as needed
    return 1.0f - std::exp(-1.0f / (windowSizeSeconds * mSampleRate));
}

// Apply gain to the audio data
void AutoGain::applyGain(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    ma_uint32 sampleCount = frameCount * channels;

    switch (format)
    {
        case ma_format_u8:
            for (ma_uint32 i = 0; i < sampleCount; ++i)
            {
                float sample = (static_cast<uint8_t *>(pInput)[i] - 128) / 128.0f * mCurrentGain;
                sample = std::clamp(sample, -1.0f, 1.0f);
                static_cast<uint8_t *>(pInput)[i] = static_cast<uint8_t>((sample * 128.0f) + 128);
            }
            break;
        case ma_format_s16:
            for (ma_uint32 i = 0; i < sampleCount; ++i)
            {
                float sample = static_cast<int16_t *>(pInput)[i] / 32768.0f * mCurrentGain;
                sample = std::clamp(sample, -1.0f, 1.0f);
                static_cast<int16_t *>(pInput)[i] = static_cast<int16_t>(sample * 32768.0f);
            }
            break;
        case ma_format_s24:
            for (ma_uint32 i = 0; i < sampleCount; ++i)
            {
                // Read the 24-bit signed sample (3 bytes per sample)
                uint8_t *samplePtr = static_cast<uint8_t *>(pInput) + i * 3;
                int32_t sample = (samplePtr[0] << 8) | (samplePtr[1] << 16) | (samplePtr[2] << 24); // Reassemble to 32-bit signed
                sample >>= 8;                                                                       // Shift to make it a signed 24-bit value

                // Scale and apply gain
                float normalizedSample = sample / 8388608.0f; // Scale to -1.0 to +1.0 range
                normalizedSample *= mCurrentGain;
                normalizedSample = std::clamp(normalizedSample, -1.0f, 1.0f);

                // Convert back to signed 24-bit
                int32_t processedSample = static_cast<int32_t>(normalizedSample * 8388608.0f);
                processedSample = std::clamp(processedSample, -8388608, 8388607);

                // Write back the processed sample into 3 bytes
                samplePtr[0] = (processedSample & 0xFF0000) >> 16;
                samplePtr[1] = (processedSample & 0x00FF00) >> 8;
                samplePtr[2] = (processedSample & 0x0000FF);
            }
            break;
        case ma_format_s32:
            for (ma_uint32 i = 0; i < sampleCount; ++i)
            {
                float sample = static_cast<int32_t *>(pInput)[i] / 2147483648.0f * mCurrentGain;
                sample = std::clamp(sample, -1.0f, 1.0f);
                static_cast<int32_t *>(pInput)[i] = static_cast<int32_t>(sample * 2147483648.0f);
            }
            break;
        case ma_format_f32:
            for (ma_uint32 i = 0; i < sampleCount; ++i)
            {
                static_cast<float *>(pInput)[i] *= mCurrentGain;
            }
            break;
        case ma_format_unknown:
            break;
        case ma_format_count:
            break;
    }
}

void AutoGain::validateParam(int param) const
{
    if (param < 0 || param >= ParamCount)
    {
        // Invalid parameter index
        return;
    }
} 
