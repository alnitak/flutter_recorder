#include "miniaudio.h"

#include <iostream>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

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

        // dummy implementation for JS
        void wasmAskFileName()
        {}

        ma_encoder encoder;
#else
        // JS implementation
        // Funzione per inizializzare il file WAV
        CaptureErrors init(const char *fileName, ma_device_config deviceConfig)
        {
            
            // Passa i parametri al modulo JavaScript
            EM_ASM({
                // Definisci un costruttore per WavWriter
                function WavWriter() {
                    this.dataChunks = [];
                    this.byteRate = 0;
                    this.blockAlign = 0;
                    this.view = null;

                    console.log('Formato ricevuto:', Module.format);
                    this.init = function() {
                        let bitDepth;
                        switch (Module.format) {
                            case 'float32':
                                this.audioFormat = 3; // IEEE Float
                                bitDepth = 32;
                                break;
                            case 'uint8':
                                this.audioFormat = 1; // PCM
                                bitDepth = 8;
                                break;
                            case 'int16':
                                this.audioFormat = 1; // PCM
                                bitDepth = 16;
                                break;
                            case 'int24':
                                this.audioFormat = 1; // PCM
                                bitDepth = 24;
                                break;
                            case 'int32':
                                this.audioFormat = 1; // PCM
                                bitDepth = 32;
                                break;
                            default:
                                throw new Error('Unsupported format');
                        }

                        this.byteRate = (Module.sampleRate * Module.numChannels * bitDepth) / 8;
                        this.blockAlign = (Module.numChannels * bitDepth) / 8;

                        // Intestazione WAV
                        this.wavHeader = new ArrayBuffer(44);
                        this.view = new DataView(this.wavHeader);

                        // RIFF Header
                        this.writeString(0, 'RIFF');
                        this.view.setUint32(4, 36, true); // ChunkSize
                        this.writeString(8, 'WAVE');

                        // fmt Subchunk
                        this.writeString(12, 'fmt ');
                        this.view.setUint32(16, 16, true); // Subchunk1Size
                        this.view.setUint16(20, this.audioFormat, true); // AudioFormat
                        this.view.setUint16(22, Module.numChannels, true); // NumChannels
                        this.view.setUint32(24, Module.sampleRate, true); // SampleRate
                        this.view.setUint32(28, this.byteRate, true); // ByteRate
                        this.view.setUint16(32, this.blockAlign, true); // BlockAlign
                        this.view.setUint16(34, bitDepth, true); // BitsPerSample

                        // Data chunk
                        this.writeString(36, 'data');
                        this.view.setUint32(40, 0, true); // Subchunk2Size
                    };

                    this.writeString = function(offset, string) {
                        for (let i = 0; i < string.length; i++) {
                            this.view.setUint8(offset + i, string.charCodeAt(i));
                        }
                    };
                }

                function askFileName() {
                    this.ask = function() {
                        const fileName = 'output.wav'; // Nome file predefinito
                        Module.fileName = fileName;

                        // Funzione per salvare il file creato come Blob
                        function saveBlobFile(content, fileName) {
                            const blob = new Blob([content], { type: 'audio/wav' });
                            const link = document.createElement('a');
                            link.href = URL.createObjectURL(blob);
                            link.download = fileName;

                            // Simula un click sul link per forzare il download
                            link.click();

                            // Libera l'oggetto URL per evitare perdite di memoria
                            URL.revokeObjectURL(link.href);
                        }

                        // Creiamo un esempio di contenuto vuoto (il tuo file .wav sarà scritto qui)
                        const wavContent = new Uint8Array(44); // Intestazione WAV vuota

                        // Salva il file usando la funzione saveBlobFile
                        saveBlobFile(wavContent, fileName);
                    }
                }

                // Imposta i parametri nel Module
                // Module.fileName = UTF8ToString($0); // this must already been set by wasmAskFileName()
                Module.fileName = "output.wav";
                Module.format = UTF8ToString($1);
                Module.numChannels = $2;
                Module.sampleRate = $3;
                console.log("EM_ASM init1: " + Module.fileName + "  " + Module.format + "  " + Module.numChannels + "  " + Module.sampleRate);

                // Module.askFileName = new askFileName();

                // Crea e inizializza l'oggetto WavWriter
                Module.wavWriter = new WavWriter();
                console.log("EM_ASM init2: " + Module.wavWriter);
                Module.wavWriter.init();
                console.log("EM_ASM init3: " + Module.wavWriter);
                
            }, fileName, "float32", deviceConfig.capture.channels, deviceConfig.sampleRate);

            return captureNoError;
        }

        // Funzione per scrivere i dati
        void write(void *bufferPointer, int numFrames)
        {
            EM_ASM({
            console.log("EM_ASM writing: " + $1);
            const buffer = HEAPU8.subarray($0, $0 + $1);
            Module.wavWriter.dataChunks.push(buffer); }, bufferPointer, numFrames);
        }

        // Funzione per chiudere e finalizzare il file
        void close()
        {
            EM_ASM({
            console.log("EM_ASM close1");
            // Calcola la dimensione totale dei dati audio
            let dataSize = 0;
            for (let i = 0; i < Module.wavWriter.dataChunks.length; i++) {
                dataSize += Module.wavWriter.dataChunks[i].length;
            }

            // Aggiorna la dimensione del Chunk RIFF e del Subchunk2
            Module.wavWriter.view.setUint32(4, 36 + dataSize, true); // Aggiorna ChunkSize
            Module.wavWriter.view.setUint32(40, dataSize, true); // Aggiorna Subchunk2Size

            // Crea un nuovo Uint8Array per contenere il file WAV completo
            const wavFile = new Uint8Array(44 + dataSize);
            
            // Copia l'intestazione WAV
            wavFile.set(new Uint8Array(Module.wavWriter.wavHeader), 0);

            // Copia i dati audio dai chunk
            let offset = 44;
            for (let i = 0; i < Module.wavWriter.dataChunks.length; i++) {
                wavFile.set(Module.wavWriter.dataChunks[i], offset);
                offset += Module.wavWriter.dataChunks[i].length;
            }

            // Module.askFileName.ask();

            // Crea un Blob per il file WAV
            const blob = new Blob([wavFile], { type: 'audio/wav' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            console.log("EM_ASM close2");

            link.download = Module.fileName; // Usa il nome del file memorizzato in Module
            console.log("EM_ASM close3");
            link.click(); // Avvia il download
            console.log("EM_ASM close4");
        });
    }

        // Funzione per chiedere il file all'utente e memorizzarlo in Module.fileName
        void wasmAskFileName()
        {
            EM_ASM({
                if (window.showSaveFilePicker)
                {
                    const options = {};

                    // Add the types property
                    options.types = [ {
                        description : 'WAV Files'
                    } ];

                    // Add the accept property
                    options.types[0].accept = {'audio/wav' : ['.wav']};

                    // Add the suggestedName property
                    options.suggestedName = 'output.wav';

                    window.showSaveFilePicker(options).then((fileHandle) => {
                                                        Module.fileName = fileHandle.name;
                                                        console.log('Saving to: ' + Module.fileName);
                                                    })
                        .catch((err) => {
                            console.error('Errore nella selezione del file:', err);
                        });
                } else {
                    // Soluzione di fallback per browser che non supportano showSaveFilePicker
                    const fileName = 'output.wav'; // Nome file predefinito
                    Module.fileName = fileName;

                    // Funzione per salvare il file creato come Blob
                    function saveBlobFile(content, fileName) {
                        const blob = new Blob([content], { type: 'audio/wav' });
                        const link = document.createElement('a');
                        link.href = URL.createObjectURL(blob);
                        link.download = fileName;

                        // Simula un click sul link per forzare il download
                        link.click();

                        // Libera l'oggetto URL per evitare perdite di memoria
                        URL.revokeObjectURL(link.href);
                    }

                    // Creiamo un esempio di contenuto vuoto (il tuo file .wav sarà scritto qui)
                    const wavContent = new Uint8Array(44); // Intestazione WAV vuota

                    // Salva il file usando la funzione saveBlobFile
                    saveBlobFile(wavContent, fileName);
                }
            });
        }

#endif

    }; // class Wav
} // namespace WriteAudio
