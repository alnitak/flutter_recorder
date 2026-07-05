#ifndef AUTO_GAIN_H
#define AUTO_GAIN_H

#include "../miniaudio.h"
#include "generic_filter.h"

#include <array>
#include <atomic>
#include <cstdint>

/// Stateful automatic gain controller for capture audio.
class AutoGain : public GenericFilter
{
public:
    enum Params
    {
        TargetRMS,
        AttackTime,
        ReleaseTime,
        GainSmoothing,
        MaxGain,
        MinGain,
        NoiseFloorDb,
        HeadroomDb,
        CurrentGain,
        InputRMS,
        OutputPeak,
        LimiterClipCount,
        TotalLimiterClipCount,
        LastFrameCount,
        ParamCount
    };

    AutoGain();
    AutoGain(unsigned int sampleRate);

    int getParamCount() const override;
    float getParamMax(int param) const override;
    float getParamMin(int param) const override;
    float getParamDef(int param) const override;
    std::string getParamName(int param) const override;
    void setParamValue(int param, float value) override;
    float getParamValue(int param) const override;

    void process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format) override;

private:
    struct ParamInfo
    {
        const char *name;
        float defaultVal;
        float minVal;
        float maxVal;
        bool writable;
    };

    struct LevelStats
    {
        float rms;
        float peak;
    };

    struct ProcessStats
    {
        float outputPeak;
        uint64_t limiterClipCount;
    };

    static const std::array<ParamInfo, ParamCount> kParamInfo;

    float mSampleRate;
    float mCurrentGain;
    float mSmoothedRMS;
    uint64_t mTotalLimiterClipCount;

    std::array<std::atomic<float>, ParamCount> mValues;

    LevelStats analyzeInput(const void *pInput, ma_uint32 sampleCount, ma_format format) const;

    float readSample(const void *pInput, ma_uint32 sampleIndex, ma_format format) const;
    void writeSample(void *pInput, ma_uint32 sampleIndex, ma_format format, float sample) const;

    float calculateTargetGain(float inputRMS, float inputPeak) const;
    float smoothingFactor(float timeSeconds, ma_uint32 frameCount) const;
    ProcessStats applyGain(void *pInput,
                           ma_uint32 frameCount,
                           unsigned int channels,
                           ma_format format,
                           float startGain,
                           float endGain) const;

    float readParam(Params param) const;
    void writeMetric(Params param, float value);
    bool isValidParam(int param) const;
    bool isWritableParam(int param) const;
};

#endif // AUTO_GAIN_H
