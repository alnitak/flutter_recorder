#include "miniaudio.h"

#include "flutter_recorder.h"
#include "engine_lifecycle.h"
#include "dart_callback_gate.h"
#include "capture.h"
#include "analyzer.h"
#include "filters/filters.h"

#include <memory>
#include <mutex>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <thread>

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#include <pthread.h>
#ifdef MA_ENABLE_AUDIO_WORKLETS
#include <emscripten/threading.h>
#include <emscripten/webaudio.h>
#endif
#endif

Capture capture;
std::unique_ptr<Filters> mFilters = std::make_unique<Filters>(0);

dartSilenceChangedCallback_t dartSilenceChangedCallback = nullptr;
dartSilenceChangedCallback_t nativeSilenceChangedCallback = nullptr;
dartStreamDataCallback_t dartStreamDataCallback = nullptr;
dartStreamDataCallback_t nativeStreamDataCallback = nullptr;

uint64_t g_eventCallbackGeneration = dart_callbacks::kNoGeneration;

namespace {
  std::mutex engine_lifecycle_mutex;
  int64_t nativeInitOwnerEngineId = dart_callbacks::kNoEngineId;
  uint64_t engineInitGeneration = 0;
  uint64_t engineShutdownEpoch = 0;

  void clearDartCallbackPointersLocked() {
    dartSilenceChangedCallback = nullptr;
    nativeSilenceChangedCallback = nullptr;
    dartStreamDataCallback = nullptr;
    nativeStreamDataCallback = nullptr;
  }
}

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

static void postSilenceToWorker(int messagePtr, int isSilent, int energyDbBits)
{
    float energyDb;
    memcpy(&energyDb, &energyDbBits, sizeof(float));
    EM_ASM({
        if (RecorderModule.wasmWorker)
        {
            RecorderModule.wasmWorker.postMessage({
                message : UTF8ToString($0),
                isSilent : $1,
                energyDb : $2,
            });
        }
        else
        {
            console.error('Worker not found.');
        }
    }, messagePtr, isSilent, energyDb);
}

/// Post a new silence event message with the web worker.
FFI_PLUGIN_EXPORT void flutter_recorder_sendSilenceEventToWorker(const char *message, bool isSilent, float energyDb)
{
    int energyDbBits;
    memcpy(&energyDbBits, &energyDb, sizeof(float));
#ifdef MA_ENABLE_AUDIO_WORKLETS
    if (!emscripten_is_main_browser_thread())
    {
        emscripten_audio_worklet_post_function_viii(
            EMSCRIPTEN_AUDIO_MAIN_THREAD, postSilenceToWorker,
            (int)(uintptr_t)message, isSilent ? 1 : 0, energyDbBits);
        return;
    }
#endif
    postSilenceToWorker((int)(uintptr_t)message, isSilent ? 1 : 0, energyDbBits);
}

static void postStreamToWorker(int messagePtr, int audioDataPtr, int audioDataLength)
{
    EM_ASM({
        if (RecorderModule.wasmWorker)
        {
            const audioDataArray = new Uint8Array(RecorderModule.HEAPU8.subarray($1, $1 + $2));
            RecorderModule.wasmWorker.postMessage({
                message : UTF8ToString($0),
                data : audioDataArray,
            });
        }
        else
        {
            console.error('Worker not found.');
        }
    }, messagePtr, audioDataPtr, audioDataLength);
    delete[] (unsigned char*)audioDataPtr;
}

/// Post a stream of audio data with the web worker.
FFI_PLUGIN_EXPORT void flutter_recorder_sendStreamToWorker(const char *message, const unsigned char *audioData, int audioDataLength)
{
#ifdef MA_ENABLE_AUDIO_WORKLETS
    if (!emscripten_is_main_browser_thread())
    {
        emscripten_audio_worklet_post_function_viii(
            EMSCRIPTEN_AUDIO_MAIN_THREAD, postStreamToWorker,
            (int)(uintptr_t)message, (int)(uintptr_t)audioData, audioDataLength);
        return;
    }
#endif
    postStreamToWorker((int)(uintptr_t)message, (int)(uintptr_t)audioData, audioDataLength);
}
#endif

void silenceChangedCallback(bool *isSilent, float *energyDb)
{
#ifdef __EMSCRIPTEN__
    // Calling JavaScript from C/C++
    flutter_recorder_sendSilenceEventToWorker("silenceChangedCallback", *isSilent, *energyDb);
#endif
    dart_callbacks::InvocationPass pass;
    if (pass.isLive(g_eventCallbackGeneration) && dartSilenceChangedCallback != nullptr)
        dartSilenceChangedCallback(isSilent, energyDb);
}

void streamDataCallback(const unsigned char *samples, const int numSamples)
{
#ifdef __EMSCRIPTEN__
    flutter_recorder_sendStreamToWorker("streamDataCallback", samples, numSamples);
#else
    dart_callbacks::InvocationPass pass;
    if (pass.isLive(g_eventCallbackGeneration) && dartStreamDataCallback != nullptr)
        dartStreamDataCallback(samples, numSamples);
#endif
}

/// Set Dart functions to call when an event occurs with engine id.
FFI_PLUGIN_EXPORT void flutter_recorder_setDartEventCallbackForEngine(
    dartSilenceChangedCallback_t silence_changed_callback,
    dartStreamDataCallback_t stream_data_callback,
    int64_t engine_id)
{
    dart_callbacks::Registration registration;
    g_eventCallbackGeneration = registration.claim(engine_id);

    dartSilenceChangedCallback = silence_changed_callback;
    nativeSilenceChangedCallback = silenceChangedCallback;

    dartStreamDataCallback = stream_data_callback;
    nativeStreamDataCallback = streamDataCallback;
}

/// Set Dart functions to call when an event occurs.
FFI_PLUGIN_EXPORT void flutter_recorder_setDartEventCallback(
    dartSilenceChangedCallback_t silence_changed_callback,
    dartStreamDataCallback_t stream_data_callback)
{
    flutter_recorder_setDartEventCallbackForEngine(
        silence_changed_callback,
        stream_data_callback,
        dart_callbacks::kNoEngineId);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setDartVisualizationCallbackForEngine(
    dartVisualizationCallback_t callback,
    int64_t engine_id)
{
    Analyzer::instance().setDataCallbackForEngine(callback, engine_id);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setDartVisualizationCallback(
    dartVisualizationCallback_t callback)
{
    Analyzer::instance().setDataCallback(callback);
}

// Engine lifecycle implementations
FFI_PLUGIN_EXPORT void flutter_recorder_prepareEngineInit(int64_t owner_engine_id)
{
    std::lock_guard<std::mutex> guard(engine_lifecycle_mutex);
    nativeInitOwnerEngineId = owner_engine_id;
    ++engineInitGeneration;
}

FFI_PLUGIN_EXPORT uint64_t flutter_recorder_currentEngineShutdownEpoch(void)
{
    std::lock_guard<std::mutex> guard(engine_lifecycle_mutex);
    return engineShutdownEpoch;
}

FFI_PLUGIN_EXPORT bool flutter_recorder_prepareEngineInitForRequest(int64_t owner_engine_id, uint64_t shutdown_epoch)
{
    std::lock_guard<std::mutex> guard(engine_lifecycle_mutex);
    if (shutdown_epoch != engineShutdownEpoch)
    {
        return false;
    }
    nativeInitOwnerEngineId = owner_engine_id;
    ++engineInitGeneration;
    return true;
}

FFI_PLUGIN_EXPORT bool flutter_recorder_clearDartCallbackRegistrationsForEngine(int64_t engine_id)
{
    if (engine_id == dart_callbacks::kNoEngineId)
        return false;

    dart_callbacks::Registration registration;
    if (!registration.retire(engine_id))
        return false;

    clearDartCallbackPointersLocked();
    Analyzer::instance().setDataCallback(nullptr);
    Analyzer::instance().setVisualizationEnabled(false);
    return true;
}

FFI_PLUGIN_EXPORT void flutter_recorder_clearDartCallbackRegistrations(void)
{
    dart_callbacks::Registration registration;
    registration.retireAll();

    clearDartCallbackPointersLocked();
    Analyzer::instance().setDataCallback(nullptr);
    Analyzer::instance().setVisualizationEnabled(false);
}

FFI_PLUGIN_EXPORT bool flutter_recorder_requestEngineTeardownForEngine(int64_t engine_id)
{
    {
        std::lock_guard<std::mutex> guard(engine_lifecycle_mutex);
        if (engine_id == dart_callbacks::kNoEngineId || nativeInitOwnerEngineId != engine_id)
            return false;
        ++engineShutdownEpoch;
        nativeInitOwnerEngineId = dart_callbacks::kNoEngineId;
    }

    flutter_recorder_clearDartCallbackRegistrationsForEngine(engine_id);

    std::thread teardownWorker([]() {
        flutter_recorder_deinit();
    });
    teardownWorker.detach();
    return true;
}

FFI_PLUGIN_EXPORT void flutter_recorder_retireDartCallbacksFinalizer(void *token)
{
    const int64_t engine_id = reinterpret_cast<intptr_t>(token);
    dart_callbacks::Registration registration;
    if (engine_id != dart_callbacks::kNoEngineId)
    {
        if (!registration.retire(engine_id))
            return;
    }
    else
    {
        registration.retireAll();
    }

    clearDartCallbackPointersLocked();
    Analyzer::instance().setDataCallback(nullptr);
    Analyzer::instance().setVisualizationEnabled(false);
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

        devicesName[numDevices] = strdup(d[i].name);
        isDefault[numDevices] = (int *)malloc(sizeof(int *));
        *isDefault[numDevices] = d[i].isDefault;
        deviceId[numDevices] = (int *)malloc(sizeof(int *));
        *deviceId[numDevices] = d[i].id;

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
    unsigned int channels,
    int androidInputPreset,
    int iosInputPreset)
{
    if (!mFilters)
    {
        mFilters = std::make_unique<Filters>(sampleRate);
    }
    else
    {
        mFilters->setSampleRate(sampleRate);
    }
    CaptureErrors res = capture.init(mFilters.get(), deviceID, (PCMFormat)pcmFormat, sampleRate, channels, androidInputPreset, iosInputPreset);

    return res;
}

FFI_PLUGIN_EXPORT void flutter_recorder_deinit()
{
    if (capture.isRecording)
        capture.stopRecording();
    capture.stopStreamingData();
    capture.stop();
    capture.dispose();

    dartSilenceChangedCallback = nullptr;
    dartStreamDataCallback = nullptr;
    Analyzer::instance().setDataCallback(nullptr);
    Analyzer::instance().setVisualizationEnabled(false);
}

FFI_PLUGIN_EXPORT int flutter_recorder_isInited()
{
    return capture.isInited() ? 1 : 0;
}

FFI_PLUGIN_EXPORT int flutter_recorder_isDeviceStarted()
{
    return capture.isDeviceStarted();
}

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_start()
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.start();
}

FFI_PLUGIN_EXPORT void flutter_recorder_stop()
{
    Analyzer::instance().setVisualizationEnabled(false);
    if (capture.isRecording)
        capture.stopRecording();
    capture.stop();
}

FFI_PLUGIN_EXPORT void flutter_recorder_startStreamingData(int streamingFormat)
{
    if (!capture.isInited())
        return;
    capture.startStreamingData((StreamingFormat)streamingFormat);
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

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_startRecording(const char *path, int recordingFormat)
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.startRecording(path, (RecordingFormat)recordingFormat);
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

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_setVisualizationEnabled(
    bool enabled,
    int windowSize,
    int kind,
    int channel)
{
    int channels = capture.isInited() ? capture.deviceConfig.capture.channels : 1;
    return Analyzer::instance().setVisualizationEnabled(
        enabled, windowSize, (VisualizationKind)kind, channel, channels);
}

FFI_PLUGIN_EXPORT int flutter_recorder_isVisualizationEnabled()
{
    return Analyzer::instance().isVisualizationEnabled() ? 1 : 0;
}

FFI_PLUGIN_EXPORT void flutter_recorder_setFftSmoothing(float smooth)
{
    Analyzer::instance().setSmoothing(smooth);
}

FFI_PLUGIN_EXPORT void flutter_recorder_setLoopback(bool enable)
{
    capture.setLoopback(enable);
}

FFI_PLUGIN_EXPORT int flutter_recorder_isLoopbackEnabled()
{
    return capture.isLoopback() ? 1 : 0;
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
    CaptureErrors err = mFilters.get()->addFilter(filterType);
    if (err == captureNoError && filterType == RecorderFilterType::echoCancellation && capture.isInited())
    {
        capture.reinitDevice();
    }
    return err;
}

FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_removeFilter(enum RecorderFilterType filterType)
{
    CaptureErrors err = mFilters.get()->removeFilter(filterType);
    if (err == captureNoError && filterType == RecorderFilterType::echoCancellation && capture.isInited())
    {
        capture.reinitDevice();
    }
    return err;
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

FFI_PLUGIN_EXPORT void flutter_recorder_feedPlaybackData(const void *data, unsigned int frameCount, unsigned int channels, int pcmFormat)
{
    if (mFilters && data != nullptr && frameCount > 0 && channels > 0)
    {
        ma_format maFormat = ma_format_f32;
        switch ((PCMFormat)pcmFormat)
        {
        case pcm_u8:
            maFormat = ma_format_u8;
            break;
        case pcm_s16:
            maFormat = ma_format_s16;
            break;
        case pcm_s24:
            maFormat = ma_format_s24;
            break;
        case pcm_s32:
            maFormat = ma_format_s32;
            break;
        case pcm_f32:
        default:
            maFormat = ma_format_f32;
            break;
        }
        mFilters->feedPlaybackData(data, frameCount, channels, maFormat);
    }
}

#if defined(_IS_ANDROID_)
#include <jni.h>

extern "C" {
  JNIEXPORT jboolean JNICALL
  Java_flutter_recorder_flutter_1recorder_FlutterRecorderPlugin_nativeClearDartCallbackRegistrationsForEngine(
      JNIEnv *, jclass, jlong engine_id)
  {
    return flutter_recorder_clearDartCallbackRegistrationsForEngine(
        static_cast<int64_t>(engine_id));
  }

  JNIEXPORT jboolean JNICALL
  Java_flutter_recorder_flutter_1recorder_FlutterRecorderPlugin_nativeRequestEngineTeardownForEngine(
      JNIEnv *, jclass, jlong engine_id)
  {
    return flutter_recorder_requestEngineTeardownForEngine(static_cast<int64_t>(engine_id));
  }
}
#endif
