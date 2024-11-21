#include "echo_cancellation.h"

#include <iostream>
#include <cmath>
#include <cstring>
#include <algorithm>
#include <stdint.h>

EchoCancellation::EchoCancellation(unsigned int sampleRate)
    : mWriteIndex(0),
      mParams{
          {EchoDelayMs, {50.0f, 0.0f, 1000.0f}}, // Delay in ms (default, min, max)
          {EchoAttenuation, {0.7f, 0.0f, 1.0f}}  // Attenuation (default, min, max)
      },
      mValues(ParamCount, 0.0f)
{
    // Initialize values with defaults
    for (const auto &[param, range] : mParams)
    {
        mValues[param] = range.defaultVal;
    }
    mDelaySamples = static_cast<unsigned int>((getParamDef(EchoDelayMs) / 1000.0f) * sampleRate);
    // Allocate twice the delay size to handle circular buffer
    mBuffer = std::vector<float>(mDelaySamples * 2, 0.0f);
}

// Override parameter management methods
int EchoCancellation::getParamCount() const
{
    return ParamCount;
}

float EchoCancellation::getParamMax(int param) const
{
    validateParam(param);
    return mParams.at(static_cast<Params>(param)).maxVal;
}

float EchoCancellation::getParamMin(int param) const
{
    validateParam(param);
    return mParams.at(static_cast<Params>(param)).minVal;
}

float EchoCancellation::getParamDef(int param) const
{
    validateParam(param);
    return mParams.at(static_cast<Params>(param)).defaultVal;
}

std::string EchoCancellation::getParamName(int param) const
{
    validateParam(param);
    switch (static_cast<Params>(param))
    {
    case EchoDelayMs:
        return "Echo Delay (ms)";
    case EchoAttenuation:
        return "Echo Attenuation";
    default:
        return "Unknown";
    }
}

void EchoCancellation::setParamValue(int param, float value)
{
    validateParam(param);
    const auto &range = mParams.at(static_cast<Params>(param));
    if (value < range.minVal || value > range.maxVal)
    {
        throw std::out_of_range("Parameter value out of range");
    }
    mValues[param] = value;
}

float EchoCancellation::getParamValue(int param) const
{
    validateParam(param);
    return mValues[param];
}

void EchoCancellation::process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    switch (format)
    {
    case ma_format_u8:
        processAudio<unsigned char>(pInput, frameCount, channels);
        break;
    case ma_format_s16:
        processAudio<int16_t>(pInput, frameCount, channels);
        break;
    case ma_format_s24:
        processAudioS24(pInput, frameCount, channels);
        break;
    case ma_format_s32:
        processAudio<int32_t>(pInput, frameCount, channels);
        break;
    case ma_format_f32:
        processAudio<float>(pInput, frameCount, channels);
        break;
    default:
        std::cerr << "Unsupported format\n";
        break;
    }
}

template <typename T>
void EchoCancellation::processAudio(void *pInput, ma_uint32 frameCount, unsigned int channels)
{
    T *input = static_cast<T *>(pInput);

    for (ma_uint32 i = 0; i < frameCount * channels; ++i)
    {
        // Normalize sample to float [-1, 1]
        float currentSample = normalizeSample(input[i]);
        float delayedSample = mBuffer[mWriteIndex];

        // Apply echo cancellation
        float processedSample = currentSample - getParamValue(EchoAttenuation) * delayedSample;

        // Store result back to circular buffer
        mBuffer[mWriteIndex] = currentSample;

        // Write processed sample back to input
        input[i] = denormalizeSample<T>(processedSample);

        // Increment and wrap write index
        mWriteIndex = (mWriteIndex + 1) % mBuffer.size();
    }
}

void EchoCancellation::processAudioS24(void *pInput, ma_uint32 frameCount, unsigned int channels)
{
    uint8_t *input = static_cast<uint8_t *>(pInput);

    for (ma_uint32 i = 0; i < frameCount * channels; ++i)
    {
        // Extract 24-bit signed integer from the 3 bytes
        int32_t sample = (input[i * 3 + 0] << 8) | (input[i * 3 + 1] << 16) | (input[i * 3 + 2] << 24);
        sample >>= 8; // Convert to signed 32-bit integer

        // Normalize sample to float [-1, 1]
        float currentSample = sample / 8388608.0f; // 2^23

        float delayedSample = mBuffer[mWriteIndex];

        // Apply echo cancellation
        float processedSample = currentSample - getParamValue(EchoAttenuation) * delayedSample;

        // Store result back to circular buffer
        mBuffer[mWriteIndex] = currentSample;

        // Write processed sample back to input
        int32_t processedInt = static_cast<int32_t>(std::clamp(processedSample * 8388608.0f, -8388608.0f, 8388607.0f));
        input[i * 3 + 0] = static_cast<uint8_t>((processedInt >> 8) & 0xFF);
        input[i * 3 + 1] = static_cast<uint8_t>((processedInt >> 16) & 0xFF);
        input[i * 3 + 2] = static_cast<uint8_t>((processedInt >> 24) & 0xFF);

        // Increment and wrap write index
        mWriteIndex = (mWriteIndex + 1) % mBuffer.size();
    }
}

float EchoCancellation::normalizeSample(unsigned char sample)
{
    return (sample - 128) / 128.0f;
}

float EchoCancellation::normalizeSample(int16_t sample)
{
    return sample / 32768.0f;
}

float EchoCancellation::normalizeSample(int32_t sample)
{
    return sample / 2147483648.0f;
}

float EchoCancellation::normalizeSample(float sample)
{
    return sample; // Already normalized
}

template <typename T>
T EchoCancellation::denormalizeSample(float sample)
{
    if (std::is_same<T, unsigned char>::value)
    {
        return static_cast<unsigned char>(std::clamp(sample * 128.0f + 128, 0.0f, 255.0f));
    }
    else if (std::is_same<T, int16_t>::value)
    {
        return static_cast<int16_t>(std::clamp(sample * 32768.0f, -32768.0f, 32767.0f));
    }
    else if (std::is_same<T, int32_t>::value)
    {
        return static_cast<int32_t>(std::clamp(sample * 2147483648.0f, -2147483648.0f, 2147483647.0f));
    }
    else if (std::is_same<T, float>::value)
    {
        return sample;
    }
    return 0;
}

void EchoCancellation::validateParam(int param) const
{
    if (param < 0 || param >= ParamCount)
    {
        throw std::invalid_argument("Invalid parameter index");
    }
}
