#include "echo_cancellation.h"

#include <iostream>
#include <cmath>
#include <cstring>
#include <algorithm>
#include <stdexcept>

EchoCancellation::EchoCancellation()
    : mSampleRate(44100),
      mChannels(1),
      mFrameSize(441),
      mFilterLength(6615),
      mEchoState(nullptr),
      mParams{
          {FilterLengthMs, {150.0f, 10.0f, 500.0f}}, // Tail length in ms (default, min, max)
          {DenoiseEnabled, {1.0f, 0.0f, 1.0f}},       // Residual / background denoiser (1 = on, 0 = off)
          {DenoiseLevelDb, {-30.0f, -60.0f, 0.0f}}    // Denoise attenuation in dB
      },
      mValues(ParamCount, 0.0f)
{
    for (const auto &[param, range] : mParams)
    {
        mValues[param] = range.defaultVal;
    }
}

EchoCancellation::EchoCancellation(unsigned int sampleRate)
    : mSampleRate(sampleRate > 0 ? sampleRate : 44100),
      mChannels(1),
      mFrameSize((mSampleRate * 10) / 1000), // 10 ms frame size
      mFilterLength((mSampleRate * 150) / 1000),
      mEchoState(nullptr),
      mParams{
          {FilterLengthMs, {150.0f, 10.0f, 500.0f}},
          {DenoiseEnabled, {1.0f, 0.0f, 1.0f}},
          {DenoiseLevelDb, {-30.0f, -60.0f, 0.0f}}
      },
      mValues(ParamCount, 0.0f)
{
    if (mFrameSize < 64)
        mFrameSize = 64;

    for (const auto &[param, range] : mParams)
    {
        mValues[param] = range.defaultVal;
    }
}

EchoCancellation::~EchoCancellation()
{
    std::lock_guard<FastMutex> lock(mMutex);
    destroySpeex();
}

void EchoCancellation::initSpeex(unsigned int channels)
{
    destroySpeex();

    mChannels = channels > 0 ? channels : 1;
    mFrameSize = (mSampleRate * 10) / 1000;
    if (mFrameSize < 64)
        mFrameSize = 64;

    mFilterLength = (mSampleRate * static_cast<int>(mValues[FilterLengthMs])) / 1000;
    if (mFilterLength < mFrameSize)
        mFilterLength = mFrameSize * 2;

    if (mChannels == 1)
    {
        mEchoState = speex_echo_state_init(mFrameSize, mFilterLength);
    }
    else
    {
        mEchoState = speex_echo_state_init_mc(mFrameSize, mFilterLength, mChannels, mChannels);
    }

    int denoise = mValues[DenoiseEnabled] > 0.5f ? 1 : 0;
    int noiseSuppress = static_cast<int>(mValues[DenoiseLevelDb]);
    int echoSuppress = static_cast<int>(mValues[DenoiseLevelDb]);
    int echoSuppressActive = echoSuppress / 2;

    mPreprocessStates.resize(mChannels, nullptr);
    for (unsigned int c = 0; c < mChannels; ++c)
    {
        mPreprocessStates[c] = speex_preprocess_state_init(mFrameSize, mSampleRate);
        if (mEchoState != nullptr)
        {
            speex_preprocess_ctl(mPreprocessStates[c], SPEEX_PREPROCESS_SET_ECHO_STATE, mEchoState);
            speex_preprocess_ctl(mPreprocessStates[c], SPEEX_PREPROCESS_SET_ECHO_SUPPRESS, &echoSuppress);
            speex_preprocess_ctl(mPreprocessStates[c], SPEEX_PREPROCESS_SET_ECHO_SUPPRESS_ACTIVE, &echoSuppressActive);
        }
        speex_preprocess_ctl(mPreprocessStates[c], SPEEX_PREPROCESS_SET_DENOISE, &denoise);
        speex_preprocess_ctl(mPreprocessStates[c], SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);
    }
}

void EchoCancellation::destroySpeex()
{
    for (auto *state : mPreprocessStates)
    {
        if (state != nullptr)
        {
            speex_preprocess_state_destroy(state);
        }
    }
    mPreprocessStates.clear();

    if (mEchoState != nullptr)
    {
        speex_echo_state_destroy(mEchoState);
        mEchoState = nullptr;
    }

    mMicFifo.clear();
    mRefFifo.clear();
    mOutFifo.clear();
}

int EchoCancellation::getParamCount() const
{
    return ParamCount;
}

float EchoCancellation::getParamMax(int param) const
{
    if (param < 0 || param >= ParamCount)
        return 0.0f;
    return mParams.at(static_cast<Params>(param)).maxVal;
}

float EchoCancellation::getParamMin(int param) const
{
    if (param < 0 || param >= ParamCount)
        return 0.0f;
    return mParams.at(static_cast<Params>(param)).minVal;
}

float EchoCancellation::getParamDef(int param) const
{
    if (param < 0 || param >= ParamCount)
        return 0.0f;
    return mParams.at(static_cast<Params>(param)).defaultVal;
}

std::string EchoCancellation::getParamName(int param) const
{
    if (param < 0 || param >= ParamCount)
        return "Unknown";
    switch (static_cast<Params>(param))
    {
    case FilterLengthMs:
        return "Filter Length (ms)";
    case DenoiseEnabled:
        return "Denoise Enabled";
    case DenoiseLevelDb:
        return "Denoise Level (dB)";
    default:
        return "Unknown";
    }
}

void EchoCancellation::setParamValue(int param, float value)
{
    if (param < 0 || param >= ParamCount)
        return;
    const auto &range = mParams.at(static_cast<Params>(param));
    value = std::clamp(value, range.minVal, range.maxVal);

    std::lock_guard<FastMutex> lock(mMutex);
    mValues[param] = value;

    if (param == FilterLengthMs)
    {
        int newFilterLength = (mSampleRate * static_cast<int>(value)) / 1000;
        if (newFilterLength < mFrameSize)
            newFilterLength = mFrameSize * 2;
        if (mEchoState != nullptr && newFilterLength != mFilterLength)
        {
            initSpeex(mChannels);
        }
    }
    else if (param == DenoiseEnabled)
    {
        int denoise = value > 0.5f ? 1 : 0;
        for (auto *state : mPreprocessStates)
        {
            if (state != nullptr)
            {
                speex_preprocess_ctl(state, SPEEX_PREPROCESS_SET_DENOISE, &denoise);
            }
        }
    }
    else if (param == DenoiseLevelDb)
    {
        int noiseSuppress = static_cast<int>(value);
        int echoSuppress = static_cast<int>(value);
        int echoSuppressActive = echoSuppress / 2;
        for (auto *state : mPreprocessStates)
        {
            if (state != nullptr)
            {
                speex_preprocess_ctl(state, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);
                if (mEchoState != nullptr)
                {
                    speex_preprocess_ctl(state, SPEEX_PREPROCESS_SET_ECHO_SUPPRESS, &echoSuppress);
                    speex_preprocess_ctl(state, SPEEX_PREPROCESS_SET_ECHO_SUPPRESS_ACTIVE, &echoSuppressActive);
                }
            }
        }
    }
}

float EchoCancellation::getParamValue(int param) const
{
    if (param < 0 || param >= ParamCount)
        return 0.0f;
    return mValues[param];
}

void EchoCancellation::feedPlaybackData(const void *pData, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    if (pData == nullptr || frameCount == 0 || channels == 0)
        return;

    std::lock_guard<FastMutex> lock(mMutex);

    if (mEchoState == nullptr)
    {
        initSpeex(mChannels == 0 ? channels : mChannels);
    }

    const size_t totalInputSamples = frameCount * channels;
    std::vector<spx_int16_t> inputS16(totalInputSamples);
    ma_pcm_convert(inputS16.data(), ma_format_s16, pData, format, totalInputSamples, ma_dither_mode_none);

    if (channels == mChannels)
    {
        mRefFifo.insert(mRefFifo.end(), inputS16.begin(), inputS16.end());
    }
    else if (channels == 2 && mChannels == 1)
    {
        // Downmix stereo to mono
        for (ma_uint32 i = 0; i < frameCount; i++)
        {
            int32_t mixed = (static_cast<int32_t>(inputS16[i * 2]) + static_cast<int32_t>(inputS16[i * 2 + 1])) / 2;
            mRefFifo.push_back(static_cast<spx_int16_t>(mixed));
        }
    }
    else if (channels == 1 && mChannels == 2)
    {
        // Upmix mono to stereo
        for (ma_uint32 i = 0; i < frameCount; i++)
        {
            mRefFifo.push_back(inputS16[i]);
            mRefFifo.push_back(inputS16[i]);
        }
    }
    else
    {
        mRefFifo.insert(mRefFifo.end(), inputS16.begin(), inputS16.end());
    }

    const size_t maxRefSamples = static_cast<size_t>(mSampleRate * mChannels * 2);
    if (mRefFifo.size() > maxRefSamples)
    {
        mRefFifo.erase(mRefFifo.begin(), mRefFifo.begin() + (mRefFifo.size() - maxRefSamples));
    }
}

void EchoCancellation::process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    processDuplex(pInput, nullptr, frameCount, channels, format);
}

void EchoCancellation::processDuplex(void *pInput, void *pOutput, ma_uint32 frameCount, unsigned int channels, ma_format format)
{
    if (pInput == nullptr || frameCount == 0 || channels == 0)
        return;

    std::lock_guard<FastMutex> lock(mMutex);

    if (mEchoState == nullptr || mChannels != channels)
    {
        initSpeex(channels);
    }

    const size_t totalSamples = frameCount * channels;

    // Convert near-end (mic) input to 16-bit PCM
    std::vector<spx_int16_t> micConverted(totalSamples);
    ma_pcm_convert(micConverted.data(), ma_format_s16, pInput, format, totalSamples, ma_dither_mode_none);

    mMicFifo.insert(mMicFifo.end(), micConverted.begin(), micConverted.end());

    // If pOutput is provided (native duplex loopback), append to mRefFifo
    if (pOutput != nullptr)
    {
        std::vector<spx_int16_t> refConverted(totalSamples);
        ma_pcm_convert(refConverted.data(), ma_format_s16, pOutput, format, totalSamples, ma_dither_mode_none);
        mRefFifo.insert(mRefFifo.end(), refConverted.begin(), refConverted.end());
    }

    // If mRefFifo is smaller than mMicFifo (e.g. silence or no external feed), pad with silence
    if (mRefFifo.size() < mMicFifo.size())
    {
        mRefFifo.resize(mMicFifo.size(), 0);
    }

    const size_t chunkSize = static_cast<size_t>(mFrameSize * mChannels);
    std::vector<spx_int16_t> chunkOut(chunkSize);

    while (mMicFifo.size() >= chunkSize && mRefFifo.size() >= chunkSize)
    {
        speex_echo_cancellation(mEchoState, mMicFifo.data(), mRefFifo.data(), chunkOut.data());

        if (mChannels == 1)
        {
            if (!mPreprocessStates.empty() && mPreprocessStates[0] != nullptr)
            {
                speex_preprocess_run(mPreprocessStates[0], chunkOut.data());
            }
        }
        else
        {
            for (unsigned int c = 0; c < mChannels; ++c)
            {
                if (c < mPreprocessStates.size() && mPreprocessStates[c] != nullptr)
                {
                    std::vector<spx_int16_t> chanBuf(mFrameSize);
                    for (int i = 0; i < mFrameSize; ++i)
                    {
                        chanBuf[i] = chunkOut[i * mChannels + c];
                    }
                    speex_preprocess_run(mPreprocessStates[c], chanBuf.data());
                    for (int i = 0; i < mFrameSize; ++i)
                    {
                        chunkOut[i * mChannels + c] = chanBuf[i];
                    }
                }
            }
        }

        mOutFifo.insert(mOutFifo.end(), chunkOut.begin(), chunkOut.end());
        mMicFifo.erase(mMicFifo.begin(), mMicFifo.begin() + chunkSize);
        mRefFifo.erase(mRefFifo.begin(), mRefFifo.begin() + chunkSize);
    }

    // Prepare output buffer back in target format
    std::vector<spx_int16_t> outSamples(totalSamples, 0);
    size_t available = std::min(totalSamples, mOutFifo.size());
    if (available > 0)
    {
        std::copy(mOutFifo.begin(), mOutFifo.begin() + available, outSamples.begin());
        mOutFifo.erase(mOutFifo.begin(), mOutFifo.begin() + available);
    }
    if (available < totalSamples)
    {
        std::copy(micConverted.begin() + available, micConverted.end(), outSamples.begin() + available);
    }

    ma_pcm_convert(pInput, format, outSamples.data(), ma_format_s16, totalSamples, ma_dither_mode_none);
}

void EchoCancellation::validateParam(int param) const
{
}
