#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "flutter_recorder.h"
#include "capture.h"
#include "analyzer.h"
#include "filters/filters.h"

#include <memory>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif

Capture capture;
std::unique_ptr<Analyzer> analyzerCapture = std::make_unique<Analyzer>(256);
std::unique_ptr<Filters> mFilters = std::make_unique<Filters>(0);

dartSilenceChangedCallback_t dartSilenceChangedCallback;
dartSilenceChangedCallback_t nativeSilenceChangedCallback;
dartStreamDataCallback_t dartStreamDataCallback;
dartStreamDataCallback_t nativeStreamDataCallback;

//////////////////////////////////////////////////////////////
/// WEB WORKER

#ifdef __EMSCRIPTEN__
/// Create the web worker and store a global "RecorderModule.workerUri" in JS.
FFI_PLUGIN_EXPORT void flutter_recorder_createWorkerInWasm()
{
    EM_ASM({
        if (!RecorderModule.wasmWorker)
        {
            // Create a new Worker from the URI
            var workerUri = "assets/packages/flutter_recorder/web/worker.dart.js";
            RecorderModule.wasmWorker = new Worker(workerUri);
            console.log("EM_ASM creating web worker! " + workerUri + "  " + RecorderModule.wasmWorker);
        }
        else
        {
            console.log("EM_ASM web worker already created!");
        }
    });
}

/// Post a new silence event message with the web worker.
FFI_PLUGIN_EXPORT void flutter_recorder_sendSilenceEventToWorker(const char *message, bool isSilent, float energyDb)
{
    EM_ASM({
            if (RecorderModule.wasmWorker)
            {
                // Send the message
                RecorderModule.wasmWorker.postMessage({
                    message : UTF8ToString($0),
                    isSilent : $1,
                    energyDb : $2,
                });
            }
            else
            {
                console.error('Worker not found.');
            } }, message, isSilent, energyDb);
}

/// Post a stream of audio data with the web worker.
FFI_PLUGIN_EXPORT void flutter_recorder_sendStreamToWorker(const char *message, const unsigned char *audioData, int audioDataLength)
{
    EM_ASM({
            if (RecorderModule.wasmWorker)
            {
                // Convert audioData to Uint8Array for JavaScript compatibility
                const audioDataArray = new Uint8Array(RecorderModule.HEAPU8.subarray($1, $1 + $2));
                // Send the message and data
                RecorderModule.wasmWorker.postMessage({
                    message : UTF8ToString($0),
                    data : audioDataArray,
                });
            }
            else
            {
                console.error('Worker not found.');
            } }, message, audioData, audioDataLength);
}
#endif

void silenceChangedCallback(bool *isSilent, float *energyDb)
{
#ifdef __EMSCRIPTEN__
    // Calling JavaScript from C/C++
    // https://emscripten.org/docs/porting/connecting_cpp_and_javascript/Interacting-with-code.html#interacting-with-code-call-javascript-from-native
    // emscripten_run_script("voiceEndedCallbackJS('1234')");
    flutter_recorder_sendSilenceEventToWorker("silenceChangedCallback", *isSilent, *energyDb);
#endif
    if (dartSilenceChangedCallback != nullptr)
        dartSilenceChangedCallback(isSilent, energyDb);
}

void streamDataCallback(const unsigned char *samples, const int numSamples)
{
#ifdef __EMSCRIPTEN__
flutter_recorder_sendStreamToWorker("streamDataCallback", samples, numSamples);
#endif
    if (dartStreamDataCallback != nullptr)
        dartStreamDataCallback(samples, numSamples);
}

/// Set a Dart functions to call when an event occurs.
FFI_PLUGIN_EXPORT void flutter_recorder_setDartEventCallback(
    dartSilenceChangedCallback_t silence_changed_callback,
    dartStreamDataCallback_t stream_data_callback)
{
    dartSilenceChangedCallback = silence_changed_callback;
    nativeSilenceChangedCallback = silenceChangedCallback;

    dartStreamDataCallback = stream_data_callback;
    nativeStreamDataCallback = streamDataCallback;
}

FFI_PLUGIN_EXPORT void flutter_recorder_nativeFree(void *pointer)
{
    free(pointer);
}

// ///////////////////////////////
// Capture bindings functions
// ///////////////////////////////
FFI_PLUGIN_EXPORT void flutter_recorder_listCaptureDevices(
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
            if (d[i].name[n] < 0x20 && d[i].name[n] >= 0)
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

FFI_PLUGIN_EXPORT void flutter_recorder_freeListCaptureDevices(
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

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_init(
    int deviceID,
    int pcmFormat,
    unsigned int sampleRate,
    unsigned int channels)
{
    if (!mFilters || mFilters.get()->mSamplerate != sampleRate)
    {
        mFilters.reset();
        mFilters = std::make_unique<Filters>(sampleRate);
    }
    CaptureErrors res = capture.init(mFilters.get(), deviceID, (PCMFormat)pcmFormat, sampleRate, channels);

    return res;
}

FFI_PLUGIN_EXPORT void flutter_recorder_deinit()
{
    if (capture.isRecording)
        capture.stopRecording();
    capture.dispose();
}

FFI_PLUGIN_EXPORT int flutter_recorder_isInited()
{
    return capture.isInited() ? 1 : 0;
}

FFI_PLUGIN_EXPORT int flutter_recorder_isDeviceStarted()
{
    return capture.isDeviceStarted();
}

FFI_PLUGIN_EXPORT int flutter_recorder_isCaptureStarted()
{
    return capture.isDeviceStarted() ? 1 : 0;
}

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_start()
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.start();
}

FFI_PLUGIN_EXPORT void flutter_recorder_stop()
{
    if (capture.isRecording)
        capture.stopRecording();
    capture.stop();
}

FFI_PLUGIN_EXPORT void flutter_recorder_startStreamingData()
{
    if (!capture.isInited())
        return;
    capture.startStreamingData();
}

FFI_PLUGIN_EXPORT void flutter_recorder_stopStreamingData()
{
    if (!capture.isInited())
        return;
    capture.stopStreamingData();
}

FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceDetection(bool enable)
{
    capture.setSilenceDetection(enable);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceThresholdDb(float silenceThresholdDb)
{
    if (!capture.isInited())
        return;
    capture.setSilenceThresholdDb(silenceThresholdDb);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceDuration(float silenceDuration)
{
    if (!capture.isInited())
        return;
    capture.setSilenceDuration(silenceDuration);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore)
{
    if (!capture.isInited())
        return;
    capture.setSecondsOfAudioToWriteBefore(secondsOfAudioToWriteBefore);
}

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_startRecording(const char *path)
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.startRecording(path);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setPauseRecording(bool pause)
{
    if (!capture.isInited())
        return;
    capture.setPauseRecording(pause);
}

FFI_PLUGIN_EXPORT void flutter_recorder_stopRecording()
{
    if (!capture.isInited())
        return;
    capture.stopRecording();
}

FFI_PLUGIN_EXPORT void flutter_recorder_getVolumeDb(float *volumeDb)
{
    if (!capture.isInited())
    {
        *volumeDb = 0;
        return;
    }
    *volumeDb = capture.getVolumeDb();
}

FFI_PLUGIN_EXPORT void flutter_recorder_setFftSmoothing(float smooth)
{
    if (!capture.isInited())
        return;
    analyzerCapture.get()->setSmoothing(smooth);
}

/// Return a 256 float array containing FFT data.
FFI_PLUGIN_EXPORT void flutter_recorder_getFft(float **fft, bool *isTheSameAsBefore)
{
    if (!capture.isInited())
        return;
    float *wave = capture.getWave(isTheSameAsBefore);
    *fft = analyzerCapture.get()->calcFFT(wave);
}

/// Return a 256 float array containing wave data.
FFI_PLUGIN_EXPORT void flutter_recorder_getWave(float **wave, bool *isTheSameAsBefore)
{
    if (!capture.isInited())
        return;
    *wave = capture.getWave(isTheSameAsBefore);
}

float capturedTexture[512];
FFI_PLUGIN_EXPORT void flutter_recorder_getTexture(float **samples, bool *isTheSameAsBefore)
{
    if (!capture.isInited())
        return;
    if (analyzerCapture.get() == nullptr || !capture.isInited())
    {
        *samples = capturedTexture;
        memset(*samples, 0, sizeof(float) * 512);
        *isTheSameAsBefore = true;
        return;
    }

    float *wave = capture.getWave(isTheSameAsBefore);
    float *fft = analyzerCapture.get()->calcFFT(wave);
    
    memcpy(capturedTexture, fft, sizeof(float) * 256);
    memcpy(capturedTexture + 256, wave, sizeof(float) * 256);
    *samples = capturedTexture;
}

float capturedTexture2D[256][512];
FFI_PLUGIN_EXPORT void flutter_recorder_getTexture2D(float **samples, bool *isTheSameAsBefore)
{
    if (!capture.isInited())
        return;
    if (analyzerCapture.get() == nullptr)
    {
        *samples = *capturedTexture2D;
        memset(*samples, 0, sizeof(float) * 512 * 256);
        *isTheSameAsBefore = true;
        return;
    }
    
    float *wave = capture.getWave(isTheSameAsBefore);
    float *fft = analyzerCapture.get()->calcFFT(wave);
    if (*isTheSameAsBefore)
    {
        *samples = *capturedTexture2D;
        return;
    }

    /// shift up 1 row
    memmove(capturedTexture2D[1], capturedTexture2D[0], sizeof(float) * 512 * 255);
    /// store the new 1st row
    memcpy(capturedTexture2D[0], fft, sizeof(float) * 256);
    memcpy(capturedTexture2D[0]+256, wave, sizeof(float) * 256);
    
    *samples = *capturedTexture2D;
    *isTheSameAsBefore = false;
}

FFI_PLUGIN_EXPORT float flutter_recorder_getTextureValue(int row, int column)
{
    if (!capture.isInited())
        return .0f;
    return capturedTexture2D[row][column];
}

/////////////////////////
/// FILTERS
/////////////////////////
FFI_PLUGIN_EXPORT int flutter_recorder_isFilterActive(enum RecorderFilterType filterType)
{
    return mFilters.get()->isFilterActive(filterType);
}

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_addFilter(enum RecorderFilterType filterType)
{
    return mFilters.get()->addFilter(filterType);
}

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_removeFilter(enum RecorderFilterType filterType)
{
    return mFilters.get()->removeFilter(filterType);
}

FFI_PLUGIN_EXPORT void flutter_recorder_getFilterParamNames(enum RecorderFilterType filterType, char **names, int *paramsCount)
{
    std::vector<std::string> pNames = mFilters.get()->getFilterParamNames(filterType);
    *paramsCount = static_cast<int>(pNames.size());
    *names = (char *)malloc(sizeof(char *) * *paramsCount);
    for (int i = 0; i < *paramsCount; i++)
    {
        names[i] = strdup(pNames[i].c_str());
        printf("C  i: %d  names[i]: %s  names[i]: %p\n", i, names[i], names[i]);
    }
}

FFI_PLUGIN_EXPORT void flutter_recorder_setFilterParams(enum RecorderFilterType filterType, int attributeId, float value)
{
    mFilters.get()->setFilterParams(filterType, attributeId, value);
}

FFI_PLUGIN_EXPORT float flutter_recorder_getFilterParams(enum RecorderFilterType filterType, int attributeId)
{
    return mFilters.get()->getFilterParams(filterType, attributeId);
}
