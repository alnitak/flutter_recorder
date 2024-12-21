#include "miniaudio.h"
#include "enums.h"

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
        // JS implementation for the web platform.

        // Initialize WAV parameters.
        CaptureErrors init(const char *fileName, ma_device_config deviceConfig)
        {
            // ma_format_unknown = 0
            // ma_format_u8      = 1
            // ma_format_s16     = 2
            // ma_format_s24     = 3
            // ma_format_s32     = 4
            // ma_format_f32     = 5
            
            // Store parameters to the WASM RecorderModule.
            EM_ASM({
                let format;
                switch ($2) {
                    case 5:
                        format = 'f32';
                        break;
                    case 4:
                        format = 's32';
                        break;
                    case 3:
                        format = 's24';
                        break;
                    case 2:
                        format = 's16';
                        break;
                    case 1:
                        format = 'u8';
                        break;
                    default:
                        format = 'unknown';
                        break;
                }
                console.log("EM_ASM init wav! " + $0 + "  " + $1 + "  " + format);
                RecorderModule.dataChunks = [];
                RecorderModule.fileName = "output.wav";
                RecorderModule.numChannels = $0;
                RecorderModule.sampleRate = $1; 
                RecorderModule.format = format; }, deviceConfig.capture.channels, deviceConfig.sampleRate, deviceConfig.capture.format);

            isRecording = true;
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
        
                let buffer;
                switch (RecorderModule.format) {
                    case 'u8':
                        buffer = HEAPU8.subarray($0, $0 + $1 * RecorderModule.numChannels);
                        break;
                    case 's16':
                        buffer = HEAP16.subarray($0 / 2, ($0 / 2) + $1 * RecorderModule.numChannels);
                        break;
                    case 's24':
                        buffer = HEAPU8.subarray($0, $0 + $1 * RecorderModule.numChannels * 3);
                        break;
                    case 's32':
                        buffer = HEAP32.subarray($0 / 4, ($0 / 4) + $1 * RecorderModule.numChannels);
                        break;
                    case 'f32':
                    default:
                        buffer = HEAPF32.subarray($0 / 4, ($0 / 4) + $1 * RecorderModule.numChannels);
                }
        
                if (!RecorderModule.dataChunks) {
                    RecorderModule.dataChunks = [];
                }
        
                // Add new audio data to the buffer.
                RecorderModule.dataChunks.push(...buffer); 
            }, bufferPointer, numFrames);
        }

        // Finalize WAV file.
        void close()
        {
            if (isRecording)
                EM_ASM({
                    function encodeWAV()
                    {
                        const numChannels = RecorderModule.numChannels;
                        const sampleRate = RecorderModule.sampleRate;
                        let bitsPerSample;
                        let audioData;
                        let formatCode = 1;  // Default to PCM

                        switch (RecorderModule.format) {
                            case 'u8':
                                bitsPerSample = 8;
                                audioData = new Uint8Array(RecorderModule.dataChunks);
                                break;
                            case 's16':
                                bitsPerSample = 16;
                                audioData = new Int16Array(RecorderModule.dataChunks);
                                break;
                            case 's24':
                                bitsPerSample = 24;
                                audioData = new Uint8Array(RecorderModule.dataChunks);
                                break;
                            case 's32':
                                bitsPerSample = 32;
                                audioData = new Int32Array(RecorderModule.dataChunks);
                                break;
                            case 'f32':
                                bitsPerSample = 32;
                                formatCode = 3;  // Floating-point PCM format
                                audioData = new Float32Array(RecorderModule.dataChunks);
                                break;
                            default:
                                throw new Error("Formato non supportato");
                        }

                        const blockAlign = numChannels * (bitsPerSample / 8);
                        const byteRate = sampleRate * blockAlign;
                        let dataSize = audioData.length * (bitsPerSample / 8);
                        const totalFileSize = 44 + dataSize;
                        if (RecorderModule.format == 's24') {
                            // If we are using s24 `audioData` is a Uint8Array which reflects the `dataSize`.
                            dataSize = audioData.length;
                        }

                        const wavBuffer = new ArrayBuffer(totalFileSize);
                        const view = new DataView(wavBuffer);

                        // Writing RIFF header
                        view.setUint32(0, 0x52494646, false);       // "RIFF"
                        view.setUint32(4, totalFileSize - 8, true); // File size minus 8 bytes
                        view.setUint32(8, 0x57415645, false);       // "WAVE"

                        // Writing fmt subchunk
                        view.setUint32(12, 0x666d7420, false);   // "fmt "
                        view.setUint32(16, 16, true);            // PCM subchunk size
                        view.setUint16(20, formatCode, true);             // Audio format (1 for PCM)
                        view.setUint16(22, numChannels, true);   // Number of channels
                        view.setUint32(24, sampleRate, true);    // Sample rate
                        view.setUint32(28, byteRate, true);      // Byte rate
                        view.setUint16(32, blockAlign, true);    // Block align
                        view.setUint16(34, bitsPerSample, true); // Bits per sample

                        // Data subchunk
                        view.setUint32(36, 0x64617461, false); // "data"
                        view.setUint32(40, dataSize, true);    // Data chunk size

                        // Writing audio data
                        for (let i = 0; i < audioData.length; i++) {
                            if (bitsPerSample === 8) {
                                view.setUint8(44 + i, audioData[i]);
                            } else if (bitsPerSample === 16) {
                                view.setInt16(44 + i * 2, audioData[i], true);
                            } else if (bitsPerSample === 24) {
                                // view.setUint8(44 + i * 3, audioData[i * 3]);
                                // view.setUint8(44 + i * 3 + 1, audioData[i * 3 + 1]);
                                // view.setUint8(44 + i * 3 + 2, audioData[i * 3 + 2]);
                                view.setUint8(44 + i, audioData[i]);
                            } else if (bitsPerSample === 32) {
                                if (RecorderModule.format === 'f32') {
                                    view.setFloat32(44 + i * 4, audioData[i], true);
                                } else {
                                    view.setInt32(44 + i * 4, audioData[i], true);
                                }
                            }
                        }

                        return wavBuffer;
                    }

                    async function saveWavFile()
                    {
                        const wavFile = encodeWAV();
                        if (window.showSaveFilePicker) {
                            try {
                                const handle = await window.showSaveFilePicker({
                                    suggestedName : RecorderModule.fileName || 'output.wav',
                                    types : [ { description : 'Audio WAV file', accept : {'audio/wav' : ['.wav']} } ],
                                });
                                const writable = await handle.createWritable();
                                await writable.write(wavFile);
                                await writable.close();
                            } catch (err) {
                                console.error('Error saving file:', err);
                            }
                        } else {
                            const blob = new Blob([wavFile], { type: 'audio/wav' });
                            const link = document.createElement('a');
                            link.href = URL.createObjectURL(blob);
                            link.download = RecorderModule.fileName || 'output.wav';
                            link.click();
                            URL.revokeObjectURL(link.href);
                        }
                    }

                    saveWavFile();
                });
            isRecording = false;
        }

#endif

    }; // class Wav
} // namespace WriteAudio
