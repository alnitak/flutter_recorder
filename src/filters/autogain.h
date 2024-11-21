#ifndef AUTO_GAIN_H
#define AUTO_GAIN_H

#include "../miniaudio.h"
#include "generic_filter.h"

#include <unordered_map>
#include <vector>

// 1. **Target RMS Level (g_targetRMS)**
//   - Purpose: Sets the desired loudness level.
//   - Typical Value:
//   - For speech: 0.05 to 0.2 (RMS values in the -1.0 to +1.0 range).
//   - For music: 0.1 to 0.3.
//   - Adjust to: Match the desired loudness without introducing excessive distortion or artifacts.
// 2. **Attack Time (g_attackTime)**
//   - Purpose: Determines how quickly the gain increases when the signal level is below the target.
//   - Typical Value: 0.005 to 0.05 seconds.
//   - Faster attack (e.g., 0.005) ensures quick response to sudden volume drops, but may sound unnatural.
//   - Slower attack (e.g., 0.02-0.05) smoothens gain changes.
// 3. **Release Time (g_releaseTime)**
//   - Purpose: Determines how quickly the gain decreases when the signal level is above the target.
//   - Typical Value: 0.05 to 0.5 seconds.
//   - Short release (e.g., 0.05-0.1) responds quickly to loud bursts but risks unnatural pumping effects.
//   - Long release (e.g., 0.2-0.5) creates smoother transitions for dynamic content like music.
// 4. **Gain Smoothing (g_gainSmoothing)**
//   - Purpose: Controls how quickly the gain changes overall, acting as a dampening factor.
//   - Typical Value: 0.01 to 0.1.
//   - Lower values (e.g., 0.01) result in slow gain adjustments, reducing artifacts but possibly underreacting to fast changes.
//   - Higher values (e.g., 0.05-0.1) provide faster responsiveness but may sound less smooth.
// 5. **Maximum Gain (g_maxGain)**
//   - Purpose: Caps the maximum amplification to avoid over-amplification or distortion.
//   - Typical Value: 4.0 to 10.0.
//   - Adjust to: Match the dynamic range of the input; keep lower for highly dynamic signals to prevent clipping.
// 6. **Minimum Gain (g_minGain)**
//   - Purpose: Prevents excessive attenuation of the signal.
//   - Typical Value: 0.1 to 0.5.
//   - Adjust to: Avoid muting low signals unless silence is acceptable.

// #### Recommended Settings for Common Scenarios
// **Speech in a Noisy Environment**
//   - targetRMS = 0.1f
//   - attackTime = 0.02f
//   - releaseTime = 0.2f
//   - gainSmoothing = 0.01f
//   - maxGain = 6.0f
//   - minGain = 0.2f
// **Music Playback**
//   - targetRMS = 0.2f
//   - attackTime = 0.01f
//   - releaseTime = 0.3f
//   - gainSmoothing = 0.05f
//   - maxGain = 4.0f
//   - minGain = 0.1f
// **Podcast Recording**
//   - targetRMS = 0.15f
//   - attackTime = 0.02f
//   - releaseTime = 0.2f
//   - gainSmoothing = 0.03f
//   - maxGain = 5.0f
//   - minGain = 0.1f

class AutoGain : public GenericFilter
{
public:
    // Enum for filter parameters
    enum Params
    {
        TargetRMS,      // Target RMS level
        AttackTime,     // Attack time in seconds
        ReleaseTime,    // Release time in seconds
        GainSmoothing,  // Smoothing factor for gain adjustment
        MaxGain,        // Maximum gain multiplier
        MinGain,        // Minimum gain multiplier
        ParamCount // Always keep this last; indicates the number of parameters
    };

    AutoGain() {};
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
    // Struct to hold parameter information
    struct ParamInfo
    {
        float defaultVal;
        float minVal;
        float maxVal;
    };

    float mSampleRate;
    float mCurrentGain;
    float mSmoothedRMS;

    // Parameter metadata
    std::unordered_map<Params, ParamInfo> mParams;

    // Parameter values
    std::vector<float> mValues;

    // Calculate RMS for the current frame
    float calculateRMS(const void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format);

    // Exponential smoothing factor for RMS calculation
    float rmsSmoothingFactor() const;

    // Apply gain to the audio data
    void applyGain(void *pInput, ma_uint32 frameCount, unsigned int channels, ma_format format);

    // Validate parameter index
    void validateParam(int param) const;
};

#endif // AUTO_GAIN_H