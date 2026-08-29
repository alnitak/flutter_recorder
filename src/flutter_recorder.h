#ifndef FLUTTER_RECORDER_H
#define FLUTTER_RECORDER_H

#include "common.h"
#include "enums.h"

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

    FFI_PLUGIN_EXPORT void flutter_recorder_createWorkerInWasm();

    FFI_PLUGIN_EXPORT void flutter_recorder_setDartEventCallback(
        dartSilenceChangedCallback_t silence_changed_callback,
        dartStreamDataCallback_t stream_data_callback);

    FFI_PLUGIN_EXPORT void flutter_recorder_setDartEventCallbackForEngine(
        dartSilenceChangedCallback_t silence_changed_callback,
        dartStreamDataCallback_t stream_data_callback,
        int64_t engine_id);

    FFI_PLUGIN_EXPORT void flutter_recorder_setDartVisualizationCallback(
        dartVisualizationCallback_t callback);

    FFI_PLUGIN_EXPORT void flutter_recorder_setDartVisualizationCallbackForEngine(
        dartVisualizationCallback_t callback,
        int64_t engine_id);

    // Engine lifecycle exports
    FFI_PLUGIN_EXPORT void prepareEngineInit(int64_t owner_engine_id);
    FFI_PLUGIN_EXPORT uint64_t currentEngineShutdownEpoch(void);
    FFI_PLUGIN_EXPORT bool prepareEngineInitForRequest(int64_t owner_engine_id, uint64_t shutdown_epoch);
    FFI_PLUGIN_EXPORT bool clearDartCallbackRegistrationsForEngine(int64_t engine_id);
    FFI_PLUGIN_EXPORT void clearDartCallbackRegistrations(void);
    FFI_PLUGIN_EXPORT bool requestEngineTeardownForEngine(int64_t engine_id);
    FFI_PLUGIN_EXPORT void retireDartCallbacksFinalizer(void *token);

    FFI_PLUGIN_EXPORT void flutter_recorder_nativeFree(void *pointer);

    FFI_PLUGIN_EXPORT void flutter_recorder_listCaptureDevices(
        char **devicesName,
        int **deviceId,
        int **isDefault,
        int *n_devices);

    FFI_PLUGIN_EXPORT void flutter_recorder_freeListCaptureDevices(
        char **devicesName,
        int **deviceId,
        int **isDefault,
        int n_devices);

    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_init(
        int deviceID,
        int pcmFormat,
        unsigned int sampleRate,
        unsigned int channels,
        int androidInputPreset,
        int iosInputPreset);

    FFI_PLUGIN_EXPORT void flutter_recorder_deinit();

    FFI_PLUGIN_EXPORT int flutter_recorder_isInited();

    FFI_PLUGIN_EXPORT int flutter_recorder_isDeviceStarted();

    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_start();

    FFI_PLUGIN_EXPORT void flutter_recorder_stop();

    FFI_PLUGIN_EXPORT void flutter_recorder_startStreamingData(int streamingFormat);

    FFI_PLUGIN_EXPORT void flutter_recorder_stopStreamingData();

    FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceDetection(bool enable);

    FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceThresholdDb(float silenceThresholdDb);

    FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceDuration(float silenceDuration);

    FFI_PLUGIN_EXPORT void flutter_recorder_setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore);

    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_startRecording(const char *path, int recordingFormat);

    FFI_PLUGIN_EXPORT void flutter_recorder_setPauseRecording(bool pause);

    FFI_PLUGIN_EXPORT void flutter_recorder_stopRecording();

    FFI_PLUGIN_EXPORT void flutter_recorder_getVolumeDb(float *volumeDb);

    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_setVisualizationEnabled(
        bool enabled,
        int windowSize,
        int kind,
        int channel);

    FFI_PLUGIN_EXPORT int flutter_recorder_isVisualizationEnabled();

    FFI_PLUGIN_EXPORT void flutter_recorder_setFftSmoothing(float smooth);

    FFI_PLUGIN_EXPORT void flutter_recorder_setLoopback(bool enable);

    FFI_PLUGIN_EXPORT int flutter_recorder_isLoopbackEnabled();

    /////////////////////////
    /// FILTERS
    /////////////////////////
    FFI_PLUGIN_EXPORT int flutter_recorder_isFilterActive(enum RecorderFilterType filterType);
    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_addFilter(enum RecorderFilterType filterType);
    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_removeFilter(enum RecorderFilterType filterType);
    FFI_PLUGIN_EXPORT void flutter_recorder_getFilterParamNames(enum RecorderFilterType filterType, char **names, int *paramsCount);
    FFI_PLUGIN_EXPORT void flutter_recorder_setFilterParams(enum RecorderFilterType filterType, int attributeId, float value);
    FFI_PLUGIN_EXPORT float flutter_recorder_getFilterParams(enum RecorderFilterType filterType, int attributeId);
    FFI_PLUGIN_EXPORT void flutter_recorder_feedPlaybackData(const void *data, unsigned int frameCount, unsigned int channels, int pcmFormat);

#ifdef __cplusplus
}
#endif

#endif // FLUTTER_RECORDER_H
