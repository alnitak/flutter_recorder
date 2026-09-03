#include "miniaudio.h"
#include "enums.h"

#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

namespace WriteAudio
{
    // Class to write the WAV audio file. It uses miniaudio when not on the web platform and
    // in-memory WAV encoding with Blob download when on the web platform.
    class Wav
    {
    public:
        Wav() : isRecording(false) {};

        ~Wav()
        {
            close();
        };

        bool isRecording;

        // Using miniaudio wav recorder when on non web platform.
#ifndef __EMSCRIPTEN__
        CaptureErrors init(const char *path, ma_device_config deviceConfig)
        {
            ma_encoder_config config = ma_encoder_config_init(
                ma_encoding_format_wav,
                deviceConfig.capture.format,
                deviceConfig.capture.channels,
                deviceConfig.sampleRate);
            ma_result result = ma_encoder_init_file(path, &config, &encoder);
            if (result != MA_SUCCESS)
            {
                printf("error %d. Failed to initialize output file.\n", result);
                if (result == MA_INVALID_ARGS)
                    return invalidArgs;
                return failedToInitializeRecording;
            }
            isRecording = true;
            return captureNoError;
        }

        CaptureErrors write(void *pFramesIn, ma_uint64 frameCount)
        {
            ma_uint64 framesWritten;
            ma_result result = ma_encoder_write_pcm_frames(&encoder, pFramesIn, frameCount, &framesWritten);
            if (result != MA_SUCCESS)
            {
                printf("error %d. Failed to write to output file.\n", result);
                if (result == MA_INVALID_ARGS)
                    return invalidArgs;
                return failedToWriteWav;
            }
            return captureNoError;
        }

        void close()
        {
            if (isRecording)
                ma_encoder_uninit(&encoder);
            isRecording = false;
        }

        ma_encoder encoder;
#else
        // Implementation for the web platform.
        CaptureErrors init(const char *path, ma_device_config deviceConfig)
        {
            mFileName = (path && strlen(path) > 0) ? path : "output.wav";
            mChannels = deviceConfig.capture.channels;
            mSampleRate = deviceConfig.sampleRate;
            mFormat = deviceConfig.capture.format;
            mBytesPerSample = ma_get_bytes_per_sample(deviceConfig.capture.format);
            mData.clear();
            isRecording = true;
            return captureNoError;
        }

        CaptureErrors write(void *pFramesIn, ma_uint64 frameCount)
        {
            if (!isRecording || pFramesIn == nullptr || frameCount == 0)
                return captureNoError;

            size_t bytes = (size_t)frameCount * mChannels * mBytesPerSample;
            const uint8_t *src = static_cast<const uint8_t*>(pFramesIn);
            mData.insert(mData.end(), src, src + bytes);
            return captureNoError;
        }

        void close()
        {
            if (!isRecording)
                return;

            uint16_t formatCode = (mFormat == ma_format_f32) ? 3 : 1;
            uint16_t bitsPerSample = mBytesPerSample * 8;
            uint16_t blockAlign = mChannels * mBytesPerSample;
            uint32_t byteRate = mSampleRate * blockAlign;
            uint32_t dataSize = static_cast<uint32_t>(mData.size());
            uint32_t totalFileSize = 44 + dataSize;

            std::vector<uint8_t> wavFile(44);
            // "RIFF"
            wavFile[0] = 'R'; wavFile[1] = 'I'; wavFile[2] = 'F'; wavFile[3] = 'F';
            uint32_t riffSize = totalFileSize - 8;
            memcpy(&wavFile[4], &riffSize, 4);
            // "WAVE"
            wavFile[8] = 'W'; wavFile[9] = 'A'; wavFile[10] = 'V'; wavFile[11] = 'E';
            // "fmt "
            wavFile[12] = 'f'; wavFile[13] = 'm'; wavFile[14] = 't'; wavFile[15] = ' ';
            uint32_t fmtSize = 16;
            memcpy(&wavFile[16], &fmtSize, 4);
            memcpy(&wavFile[20], &formatCode, 2);
            uint16_t channels = static_cast<uint16_t>(mChannels);
            memcpy(&wavFile[22], &channels, 2);
            memcpy(&wavFile[24], &mSampleRate, 4);
            memcpy(&wavFile[28], &byteRate, 4);
            memcpy(&wavFile[32], &blockAlign, 2);
            memcpy(&wavFile[34], &bitsPerSample, 2);
            // "data"
            wavFile[36] = 'd'; wavFile[37] = 'a'; wavFile[38] = 't'; wavFile[39] = 'a';
            memcpy(&wavFile[40], &dataSize, 4);

            wavFile.insert(wavFile.end(), mData.begin(), mData.end());

            EM_ASM({
                const data = new Uint8Array(HEAPU8.subarray($0, $0 + $1));
                const blob = new Blob([data], { type: 'audio/wav' });
                const name = UTF8ToString($2) || 'output.wav';
                if (window.showSaveFilePicker) {
                    window.showSaveFilePicker({
                        suggestedName: name,
                        types: [{ description: 'Audio WAV file', accept: { 'audio/wav': ['.wav'] } }],
                    }).then(handle => handle.createWritable())
                      .then(writable => writable.write(blob))
                      .then(() => writable.close())
                      .catch(err => console.error('Error saving WAV file:', err));
                } else {
                    const url = URL.createObjectURL(blob);
                    const link = document.createElement('a');
                    link.href = url;
                    link.download = name;
                    link.click();
                    URL.revokeObjectURL(url);
                }
            }, wavFile.data(), wavFile.size(), mFileName.c_str());

            mData.clear();
            isRecording = false;
        }

    private:
        std::string mFileName;
        std::vector<uint8_t> mData;
        unsigned int mChannels = 0;
        unsigned int mSampleRate = 0;
        ma_format mFormat = ma_format_unknown;
        int mBytesPerSample = 0;
#endif

    }; // class Wav
} // namespace WriteAudio
