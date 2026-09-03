#ifndef ECHO_CANCELLATION_H
#define ECHO_CANCELLATION_H

#include "generic_filter.h"
#include <speex/speex_echo.h>
#include <speex/speex_preprocess.h>

#include "../fast_mutex.h"
#include <vector>
#include <unordered_map>
#include <string>

class EchoCancellation : public GenericFilter
{
public:
    // Enum for filter parameters
    enum Params
    {
        FilterLengthMs,
        DenoiseEnabled,
        DenoiseLevelDb,
        ParamCount // Always keep this last; indicates the number of parameters
    };

    EchoCancellation();
    EchoCancellation(unsigned int sampleRate);
    ~EchoCancellation();

    int getParamCount() const override;
    float getParamMax(int param) const override;
    float getParamMin(int param) const override;
    float getParamDef(int param) const override;
    std::string getParamName(int param) const override;
    void setParamValue(int param, float value) override;
    float getParamValue(int param) const override;

    void process(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format) override;
    void processDuplex(void *pInput, void *pOutput, ma_uint32 frameCount, unsigned int channels, ma_format format) override;
    void feedPlaybackData(const void *pData, ma_uint32 frameCount, unsigned int channels, ma_format format);

private:
    struct ParamInfo
    {
        float defaultVal;
        float minVal;
        float maxVal;
    };

    void initSpeex(unsigned int channels);
    void destroySpeex();

    unsigned int mSampleRate;
    unsigned int mChannels;
    int mFrameSize;
    int mFilterLength;

    SpeexEchoState *mEchoState;
    std::vector<SpeexPreprocessState *> mPreprocessStates;

    std::unordered_map<Params, ParamInfo> mParams;
    std::vector<float> mValues;

    FastMutex mMutex;

    std::vector<spx_int16_t> mMicFifo;
    std::vector<spx_int16_t> mRefFifo;
    std::vector<spx_int16_t> mOutFifo;

    void validateParam(int param) const;
};

#endif // ECHO_CANCELLATION_H