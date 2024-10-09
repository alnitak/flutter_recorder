#include "miniaudio.h"

#include <iostream>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

namespace WriteAudio
{
    // Class to write the WAV audio file. It uses miniaudio when not on the web platform and
    // JS implementation within EM_ASM emscripten macro when on the web platform.
    class Wav
    {
    public:
        Wav() {};

        ~Wav()
        {
            close();
        };

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
            ma_encoder_uninit(&encoder);
        }

        ma_encoder encoder;
#else
        // JS implementation for the web platform.
    
        // Initialize WAV parameters.
        CaptureErrors init(const char *fileName, ma_device_config deviceConfig)
        {
            // Store parameters to the WASM Module.
            EM_ASM({
                Module.dataChunks = [];
                Module.fileName = "output.wav";
                Module.numChannels = $0;
                Module.sampleRate = $1;
            }, deviceConfig.capture.channels, deviceConfig.sampleRate);

            return captureNoError;
        }

        // Write audio data.
        void write(void *bufferPointer, int numFrames)
        {
            EM_ASM({
                if ($0 == 0 || $1 <= 0) {
                    console.error("Invalid buffer pointer or number of frames");
                    return;
                }
        
                let buffer = HEAPF32.subarray($0 / 4, ($0 / 4) + $1);
        
                if (!Module.dataChunks) {
                    Module.dataChunks = [];
                }
        
                // Add new audio data to the buffer.
                Module.dataChunks.push(...buffer);
            },
                   bufferPointer, numFrames);
        }

        // Finalize WAV file.
        void close()
        {
            EM_ASM({

                function encodeWAV() {
                    // Wav file parameters.
                    const numChannels = Module.numChannels;
                    const sampleRate = Module.sampleRate;
                    const bitsPerSample = 16;  // 16-bit per sample
                
                    // Convert audio audio from float32 to int16
                    let float32Data = Module.dataChunks;
                    let int16Data = new Int16Array(float32Data.length);
                
                    // Clipping values from float32 to int16
                    for (let i = 0; i < float32Data.length; i++) {
                        let sample = float32Data[i];
                        sample = Math.max(-1, Math.min(1, sample)); // -1 e 1 clipping
                        int16Data[i] = sample < 0 ? sample * 32768 : sample * 32767; // Conversion to int16
                    }
                
                    // Calcolate dimensions.
                    const blockAlign = numChannels * bitsPerSample / 8;
                    const byteRate = sampleRate * blockAlign;
                    const dataSize = int16Data.length * bitsPerSample / 8;
                    const totalFileSize = 44 + dataSize; // 44 byte header + dati audio
                
                    const wavBuffer = new ArrayBuffer(totalFileSize);
                    const view = new DataView(wavBuffer);
                
                    // Writing RIFF header
                    view.setUint32(0, 0x52494646, false); // "RIFF"
                    view.setUint32(4, totalFileSize - 8, true); // Dimensione del file meno 8 byte
                    view.setUint32(8, 0x57415645, false); // "WAVE"
                
                    // Writing fmt subchunk
                    view.setUint32(12, 0x666d7420, false); // "fmt "
                    view.setUint32(16, 16, true); // Subchunk size (16 per PCM)
                    view.setUint16(20, 1, true); // Audio format (1 per PCM)
                    view.setUint16(22, numChannels, true); // Channel number
                    view.setUint32(24, sampleRate, true); // Sampling rate
                    view.setUint32(28, byteRate, true); // Byte rate
                    view.setUint16(32, blockAlign, true); // Block align (channels * sample bytes)
                    view.setUint16(34, bitsPerSample, true); // Bits per sample
                
                    // Scrittura del subchunk data
                    view.setUint32(36, 0x64617461, false); // "data"
                    view.setUint32(40, dataSize, true); // audio data size
                
                    // Write audio data
                    for (let i = 0; i < int16Data.length; i++) {
                        view.setInt16(44 + i * 2, int16Data[i], true); // true means little-endian
                    }
                
                    return wavBuffer;
                }
                
                async function saveWavFile()
                {
                    const wavFile = encodeWAV();
                    // Save the file using showSaveFilePicker (Chrome) or a fallback for unsupported browsers
                    if (window.showSaveFilePicker)
                    {
                        try
                        {
                            const handle = await window.showSaveFilePicker({
                                suggestedName : Module.fileName || 'output.wav',
                                types : [ {
                                    description : 'Audio WAV file',
                                    accept : {'audio/wav' : ['.wav']},
                                } ],
                            });
                            const writable = await handle.createWritable();
                            await writable.write(wavFile);
                            await writable.close();
                        }
                        catch (err)
                        {
                            console.error('Error saving file:', err);
                        }
                    }
                    else
                    {
                        // Fallback for browsers that don't support showSaveFilePicker
                        const blob = new Blob([wavFile],
                                              { type: 'audio/wav' });
                        const link = document.createElement('a');
                        link.href = URL.createObjectURL(blob);
                        link.download = Module.fileName || 'output.wav';
                        link.click();
                        URL.revokeObjectURL(link.href);
                    }
                }

                saveWavFile();
            });
        }

#endif

    }; // class Wav
} // namespace WriteAudio
