#ifndef CAPTURE_WAVEFORM_BUFFER_H
#define CAPTURE_WAVEFORM_BUFFER_H

#include "miniaudio.h"

#include <algorithm>
#include <cstddef>
#include <cstring>

inline std::size_t copyCaptureWaveformBuffer(
    float *destination,
    std::size_t destinationCapacity,
    const void *input,
    ma_format inputFormat,
    ma_uint32 frameCount,
    ma_uint32 channels)
{
    if (destination == nullptr || destinationCapacity == 0 || input == nullptr ||
        inputFormat != ma_format_f32 || frameCount == 0 || channels == 0)
    {
        return 0;
    }

    const ma_uint64 sampleCount =
        static_cast<ma_uint64>(frameCount) * static_cast<ma_uint64>(channels);
    const std::size_t boundedSampleCount = static_cast<std::size_t>(
        std::min<ma_uint64>(sampleCount, destinationCapacity));

    std::memcpy(
        destination,
        input,
        boundedSampleCount * sizeof(float));
    return boundedSampleCount;
}

#endif // CAPTURE_WAVEFORM_BUFFER_H
