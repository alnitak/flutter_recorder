#ifndef ECHO_CANCELLATION_H
#define ECHO_CANCELLATION_H

#include "generic_filter.h"

#include <vector>
#include <unordered_map>

class EchoCancellation : public GenericFilter
{
public:
    // Enum for filter parameters
    enum Params
    {
        EchoDelayMs,
        EchoAttenuation,
        ParamCount // Always keep this last; indicates the number of parameters
    };

    EchoCancellation() {};
    EchoCancellation(unsigned int sampleRate);

    int getParamCount() const override;
    float getParamMax(int param) const override;
    float getParamMin(int param) const override;
    float getParamDef(int param) const override;
    std::string getParamName(int param) const override;
    void setParamValue(int param, float value) override;
    float getParamValue(int param) const override;

    void process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format) override;

private:
    // Struct to hold parameter information
    struct ParamInfo
    {
        float defaultVal;
        float minVal;
        float maxVal;
    };

    unsigned int mDelaySamples;
    std::vector<float> mBuffer; // Circular buffer for storing past samples
    unsigned int mWriteIndex;

    // Parameter metadata
    std::unordered_map<Params, ParamInfo> mParams;

    // Parameter values
    std::vector<float> mValues;

    template <typename T>
    void processAudio(void *pInput, ma_uint32 frameCount, unsigned int channels);

    void processAudioS24(void *pInput, ma_uint32 frameCount, unsigned int channels);

    float normalizeSample(unsigned char sample);

    float normalizeSample(int16_t sample);

    float normalizeSample(int32_t sample);

    float normalizeSample(float sample);

    template <typename T>
    T denormalizeSample(float sample);

    // Validate parameter index
    void validateParam(int param) const;
};

#endif // ECHO_CANCELLATION_H