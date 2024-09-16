#include "miniaudio.h"

#include <iostream>

namespace WriteAudio
{
    class Wav
    {
    public:
        Wav() {};

        ~Wav()
        {
            close();
        };

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
                if (result == MA_INVALID_ARGS) return invalidArgs;
                return failedToInitializeRecording;
            }
            return captureNoError;
        }

        CaptureErrors write(void *pFramesIn, ma_uint64 frameCount)
        {
            ma_uint64 framesWritten;
            ma_result result = ma_encoder_write_pcm_frames(&encoder, pFramesIn, frameCount, &framesWritten);
            if (result != MA_SUCCESS)
            {
                printf("error %d. Failed to write to output file.\n", result);
                if (result == MA_INVALID_ARGS) return invalidArgs;
                return failedToWriteWav;
            }
            return captureNoError;
        }

        void close()
        {
            ma_encoder_uninit(&encoder);
        }

    private:
        ma_encoder encoder;
    };
}