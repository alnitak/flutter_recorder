#ifndef FLUTTER_RECORDER_H
#define FLUTTER_RECORDER_H

#include "common.h"
#include "enums.h"

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    FFI_PLUGIN_EXPORT void flutter_recorder_createWorkerInWasm();

    FFI_PLUGIN_EXPORT void flutter_recorder_setDartEventCallback(
        dartSilenceChangedCallback_t silence_changed_callback,
        dartStreamDataCallback_t stream_data_callback);

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
        unsigned int channels);

    FFI_PLUGIN_EXPORT void flutter_recorder_deinit();

    FFI_PLUGIN_EXPORT int flutter_recorder_isInited();

    FFI_PLUGIN_EXPORT int flutter_recorder_isDeviceStarted();

    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_start();

    FFI_PLUGIN_EXPORT void flutter_recorder_stop();

    FFI_PLUGIN_EXPORT void flutter_recorder_startStreamingData();

    FFI_PLUGIN_EXPORT void flutter_recorder_stopStreamingData();

    FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceDetection(bool enable);

    FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceThresholdDb(float silenceThresholdDb);

    FFI_PLUGIN_EXPORT void flutter_recorder_setSilenceDuration(float silenceDuration);

    FFI_PLUGIN_EXPORT void flutter_recorder_setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore);

    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_startRecording(const char *path);

    FFI_PLUGIN_EXPORT void flutter_recorder_setPauseRecording(bool pause);

    FFI_PLUGIN_EXPORT void flutter_recorder_stopRecording();

    FFI_PLUGIN_EXPORT void flutter_recorder_getVolumeDb(float *volumeDb);

    FFI_PLUGIN_EXPORT void flutter_recorder_getFft(float **fft, bool *isTheSameAsBefore);

    FFI_PLUGIN_EXPORT void flutter_recorder_getWave(float **wave, bool *isTheSameAsBefore);

    FFI_PLUGIN_EXPORT void flutter_recorder_getTexture(float **samples, bool *isTheSameAsBefore);

    FFI_PLUGIN_EXPORT void flutter_recorder_getTexture2D(float **samples, bool *isTheSameAsBefore);

    FFI_PLUGIN_EXPORT float flutter_recorder_getTextureValue(int row, int column);

    FFI_PLUGIN_EXPORT void flutter_recorder_setFftSmoothing(float smooth);

    /////////////////////////
    /// FILTERS
    /////////////////////////
    FFI_PLUGIN_EXPORT int flutter_recorder_isFilterActive(enum RecorderFilterType filterType);
    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_addFilter(enum RecorderFilterType filterType);
    FFI_PLUGIN_EXPORT enum CaptureErrors flutter_recorder_removeFilter(enum RecorderFilterType filterType);
    FFI_PLUGIN_EXPORT void flutter_recorder_getFilterParamNames(enum RecorderFilterType filterType, char **names, int *paramsCount);
    FFI_PLUGIN_EXPORT void flutter_recorder_setFilterParams(enum RecorderFilterType filterType, int attributeId, float value);
    FFI_PLUGIN_EXPORT float flutter_recorder_getFilterParams(enum RecorderFilterType filterType, int attributeId);

#ifdef __cplusplus
}
#endif

#endif // FLUTTER_RECORDER_H