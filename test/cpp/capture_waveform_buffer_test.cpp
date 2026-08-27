#include "capture_waveform_buffer.h"

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>

#if defined(__unix__) || defined(__APPLE__)
#include <sys/mman.h>
#include <unistd.h>
#endif

namespace
{
void require(bool condition, const std::string &message)
{
    if (condition)
        return;

    std::cerr << "capture_waveform_buffer_test failed: " << message << std::endl;
    std::exit(1);
}

void testNonFloatInputIsNotRead()
{
#if defined(__unix__) || defined(__APPLE__)
    const long pageSize = sysconf(_SC_PAGESIZE);
    require(pageSize > 0, "page size should be available");

    void *pages = mmap(
        nullptr,
        static_cast<std::size_t>(pageSize) * 2,
        PROT_READ | PROT_WRITE,
        MAP_PRIVATE | MAP_ANONYMOUS,
        -1,
        0);
    require(pages != MAP_FAILED, "guarded input allocation should succeed");

    auto *secondPage = static_cast<std::uint8_t *>(pages) + pageSize;
    require(
        mprotect(secondPage, static_cast<std::size_t>(pageSize), PROT_NONE) == 0,
        "guard page should be protected");

    struct NonFloatFormat
    {
        ma_format format;
        std::size_t bytesPerSample;
        const char *name;
    };
    const NonFloatFormat formats[] = {
        {ma_format_u8, 1, "u8"},
        {ma_format_s16, 2, "s16"},
        {ma_format_s24, 3, "s24"},
        {ma_format_s32, 4, "s32"},
    };

    for (const auto &format : formats)
    {
        auto *lastSample = secondPage - format.bytesPerSample;
        std::fill(lastSample, secondPage, static_cast<std::uint8_t>(0x5a));
        float destination[8] = {};

        const std::size_t copied = copyCaptureWaveformBuffer(
            destination,
            8,
            lastSample,
            format.format,
            8,
            1);
        require(
            copied == 0,
            std::string(format.name) +
                " capture must not be read as float waveform data");
    }
    require(munmap(pages, static_cast<std::size_t>(pageSize) * 2) == 0,
            "guarded input allocation should be released");
#endif
}

void testFloatInputIsCopiedWithinDestinationCapacity()
{
    const float input[] = {0.25f, -0.5f, 0.75f, -1.0f};
    float destination[] = {9.0f, 9.0f, 9.0f};

    const std::size_t copied = copyCaptureWaveformBuffer(
        destination,
        2,
        input,
        ma_format_f32,
        4,
        1);

    require(copied == 2, "float copy should be bounded by destination capacity");
    require(destination[0] == input[0] && destination[1] == input[1],
            "float samples should be preserved");
    require(destination[2] == 9.0f, "copy must not overwrite the destination guard");
}

void testInvalidInputDoesNotCopy()
{
    float destination[2] = {1.0f, 2.0f};
    require(
        copyCaptureWaveformBuffer(
            destination, 2, nullptr, ma_format_f32, 2, 1) == 0,
        "null input should not be copied");
    require(
        copyCaptureWaveformBuffer(
            destination, 2, destination, ma_format_f32, 0, 1) == 0,
        "empty callbacks should not be copied");
    require(
        destination[0] == 1.0f && destination[1] == 2.0f,
        "invalid input should leave destination unchanged");
}
} // namespace

int main()
{
    testNonFloatInputIsNotRead();
    testFloatInputIsCopiedWithinDestinationCapacity();
    testInvalidInputDoesNotCopy();
    return 0;
}
