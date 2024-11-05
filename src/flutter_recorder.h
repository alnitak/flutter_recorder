#ifndef FLUTTER_RECORDER_H
#define FLUTTER_RECORDER_H

#include "common.h"
#include "enums.h"

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    FFI_PLUGIN_EXPORT void createWorkerInWasm();

    FFI_PLUGIN_EXPORT void setDartEventCallback(
        dartSilenceChangedCallback_t silence_changed_callback);

    FFI_PLUGIN_EXPORT void nativeFree(void *pointer);

    FFI_PLUGIN_EXPORT void listCaptureDevices(
        char **devicesName,
        int **deviceId,
        int **isDefault,
        int *n_devices);

    FFI_PLUGIN_EXPORT void freeListCaptureDevices(
        char **devicesName,
        int **deviceId,
        int **isDefault,
        int n_devices);

    FFI_PLUGIN_EXPORT enum CaptureErrors init(
        int deviceID,
        int pcmFormat,
        unsigned int sampleRate,
        unsigned int channels);

    FFI_PLUGIN_EXPORT void deinit();

    FFI_PLUGIN_EXPORT int isInited();

    FFI_PLUGIN_EXPORT int isDeviceStarted();

    FFI_PLUGIN_EXPORT enum CaptureErrors start();

    FFI_PLUGIN_EXPORT void stop();

    FFI_PLUGIN_EXPORT void setSilenceDetection(bool enable);

    FFI_PLUGIN_EXPORT void setSilenceThresholdDb(float silenceThresholdDb);
    
    FFI_PLUGIN_EXPORT void setSilenceDuration(float silenceDuration);

    FFI_PLUGIN_EXPORT void setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore);

    FFI_PLUGIN_EXPORT enum CaptureErrors startRecording(const char *path);

    FFI_PLUGIN_EXPORT void setPauseRecording(bool pause);

    FFI_PLUGIN_EXPORT void stopRecording();

    FFI_PLUGIN_EXPORT void getVolumeDb(float *volumeDb);

    FFI_PLUGIN_EXPORT void getFft(float **fft);

    FFI_PLUGIN_EXPORT void getWave(float **wave);

    FFI_PLUGIN_EXPORT void getTexture(float *samples);

    FFI_PLUGIN_EXPORT void getTexture2D(float **samples);

    FFI_PLUGIN_EXPORT float getTextureValue(int row, int column);

    FFI_PLUGIN_EXPORT void setFftSmoothing(float smooth);

#ifdef __cplusplus
}
#endif

#endif // FLUTTER_RECORDER_H