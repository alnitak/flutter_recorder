// TODO(marco): add all miniaudio errors
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "flutter_recorder.h"
#include "capture.h"
#include "analyzer.h"

#include <memory>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

Capture capture;
std::unique_ptr<Analyzer> analyzerCapture = std::make_unique<Analyzer>(256);


dartSilenceChangedCallback_t dartSilenceChangedCallback;
dartSilenceChangedCallback_t nativeSilenceChangedCallback;

    //////////////////////////////////////////////////////////////
    /// WEB WORKER

#ifdef __EMSCRIPTEN__
    /// Create the web worker and store a global "Module.workerUri" in JS.
    FFI_PLUGIN_EXPORT void createWorkerInWasm()
    {
        EM_ASM({
            if (!Module.wasmWorker)
            {
                // Create a new Worker from the URI
                var workerUri = "assets/packages/flutter_recorder/web/worker.dart.js";
                Module.wasmWorker = new Worker(workerUri);
                console.log("EM_ASM creating web worker! " + workerUri + "  " + Module.wasmWorker);
            }
            else
            {
                console.log("EM_ASM web worker already created!");
            }
        });
    }

    /// Post a message with the web worker.
    FFI_PLUGIN_EXPORT void sendToWorker(const char *message, bool isSilent, float energyDb)
    {
        EM_ASM({
            if (Module.wasmWorker)
            {
                // console.log("EM_ASM posting message \"" + UTF8ToString($0) + 
                //     "\" with isSilent=" + $1 + "  and energyDb=" + $2);
                // Send the message
                Module.wasmWorker.postMessage(JSON.stringify({
                    "message" : UTF8ToString($0),
                    "isSilent" : $1,
                    "energyDb" : $2,
                }));
            }
            else
            {
                console.error('Worker not found.');
            } }, message, isSilent, energyDb);
    }
#endif


void silenceChangedCallback(bool *isSilent, float *energyDb)
{
#ifdef __EMSCRIPTEN__
    // Calling JavaScript from C/C++
    // https://emscripten.org/docs/porting/connecting_cpp_and_javascript/Interacting-with-code.html#interacting-with-code-call-javascript-from-native
    // emscripten_run_script("voiceEndedCallbackJS('1234')");
    sendToWorker("silenceChangedCallback", *isSilent, *energyDb);
#endif
    if (dartSilenceChangedCallback != nullptr)
        dartSilenceChangedCallback(isSilent, energyDb);
}

/// Set a Dart functions to call when an event occurs.
FFI_PLUGIN_EXPORT void setDartEventCallback(
    dartSilenceChangedCallback_t silence_changed_callback)
{
    dartSilenceChangedCallback = silence_changed_callback;
    nativeSilenceChangedCallback = silenceChangedCallback;
}

FFI_PLUGIN_EXPORT void nativeFree(void *pointer)
{
    free(pointer);
}

// ///////////////////////////////
// Capture bindings functions
// ///////////////////////////////
FFI_PLUGIN_EXPORT void listCaptureDevices(
    char **devicesName,
    int **deviceId,
    int **isDefault,
    int *n_devices)
{
    std::vector<CaptureDevice> d = capture.listCaptureDevices();

    int numDevices = 0;
    for (int i = 0; i < (int)d.size(); i++)
    {
        bool hasSpecialChar = false;
        /// check if the device name has some strange chars (happens on Linux)
        for (int n = 0; n < 5; n++)
        {
            if (d[i].name[n] < 0x20)
                hasSpecialChar = true;
        }
        if (strlen(d[i].name) <= 5 || hasSpecialChar)
            continue;

        devicesName[i] = strdup(d[i].name);
        isDefault[i] = (int *)malloc(sizeof(int *));
        *isDefault[i] = d[i].isDefault;
        deviceId[i] = (int *)malloc(sizeof(int *));
        *deviceId[i] = d[i].id;

        numDevices++;
    }
    *n_devices = numDevices;
}

FFI_PLUGIN_EXPORT void freeListCaptureDevices(
    char **devicesName,
    int **deviceId,
    int **isDefault,
    int n_devices)
{
    for (int i = 0; i < n_devices; i++)
    {
        free(devicesName[i]);
        free(deviceId[i]);
        free(isDefault[i]);
    }
}

FFI_PLUGIN_EXPORT enum CaptureErrors init(int deviceID)
{
    CaptureErrors res = capture.init(deviceID);
    return res;
}

FFI_PLUGIN_EXPORT void deinit()
{
    capture.dispose();
}

FFI_PLUGIN_EXPORT int isInited()
{
    return capture.isInited() ? 1 : 0;
}

FFI_PLUGIN_EXPORT int isDeviceStartedListen()
{
    return capture.isDeviceStartedListen();
}

FFI_PLUGIN_EXPORT int isCaptureStarted()
{
    return capture.isDeviceStartedListen() ? 1 : 0;
}

FFI_PLUGIN_EXPORT enum CaptureErrors startListen()
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.startListen();
}

FFI_PLUGIN_EXPORT void stopListen()
{
    capture.stopListen();
}

FFI_PLUGIN_EXPORT void setSilenceDetection(bool enable)
{
    capture.setSilenceDetection(enable);
}

FFI_PLUGIN_EXPORT void setSilenceThresholdDb(float silenceThresholdDb)
{
    if (!capture.isInited())
        return;
    capture.setSilenceThresholdDb(silenceThresholdDb);
}

FFI_PLUGIN_EXPORT void setSilenceDuration(float silenceDuration)
{
    if (!capture.isInited())
        return;
    capture.setSilenceDuration(silenceDuration);
}

FFI_PLUGIN_EXPORT void setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore)
{
    if (!capture.isInited())
        return;
    capture.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
}

FFI_PLUGIN_EXPORT void wasmAskFileName()
{
    if (!capture.isInited())
        return;
    capture.wasmAskFileName();
}

FFI_PLUGIN_EXPORT enum CaptureErrors startRecording(const char *path)
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.startRecording(path);
}

FFI_PLUGIN_EXPORT void setPauseRecording(bool pause)
{
    if (!capture.isInited())
        return;
    capture.setPauseRecording(pause);
}

FFI_PLUGIN_EXPORT void stopRecording()
{
    if (!capture.isInited())
        return;
    capture.stopRecording();
}

FFI_PLUGIN_EXPORT void getVolumeDb(float *volumeDb)
{
    *volumeDb = capture.getVolumeDb();
}

FFI_PLUGIN_EXPORT void setFftSmoothing(float smooth)
{
    analyzerCapture.get()->setSmoothing(smooth);
}

/// Return a 256 float array containing FFT data.
FFI_PLUGIN_EXPORT void getFft(float **fft)
{
    float *wave = capture.getWave();
    *fft = analyzerCapture.get()->calcFFT(wave);
}

/// Return a 256 float array containing wave data.
FFI_PLUGIN_EXPORT void getWave(float **wave)
{
    *wave = capture.getWave();
}

FFI_PLUGIN_EXPORT void getTexture(float *samples)
{
    if (analyzerCapture.get() == nullptr || !capture.isInited())
    {
        memset(samples, 0, sizeof(float) * 512);
        return;
    }
    float *wave = capture.getWave();
    float *fft = analyzerCapture.get()->calcFFT(wave);

    memcpy(samples, fft, sizeof(float) * 256);
    memcpy(samples + 256, wave, sizeof(float) * 256);
    // for (int i=0; i<56; i++)
    //     printf("%f ", fft[i]);
    // printf("\n");
    // for (int i=0; i<56; i++)
    //     printf("%f ", wave[i]);
    // printf("\n\n");
}

float capturedTexture2D[256][512];
FFI_PLUGIN_EXPORT void getTexture2D(float **samples)
{
    if (analyzerCapture.get() == nullptr || !capture.isInited())
    {
        *samples = *capturedTexture2D;
        memset(*samples, 0, sizeof(float) * 512 * 256);
        printf("capturedTexture2D not inited\n");
        return;
    }
    /// shift up 1 row
    memmove(*capturedTexture2D + 512, capturedTexture2D, sizeof(float) * 512 * 255);
    /// store the new 1st row
    getTexture(capturedTexture2D[0]);
    *samples = *capturedTexture2D;
}

FFI_PLUGIN_EXPORT float getTextureValue(int row, int column)
{
    return capturedTexture2D[row][column];
}
