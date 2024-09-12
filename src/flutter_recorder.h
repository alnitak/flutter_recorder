#ifndef FLUTTER_RECORDER_H
#define FLUTTER_RECORDER_H

#include "common.h"
#include "enums.h"

#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    FFI_PLUGIN_EXPORT enum CaptureErrors setDartEventCallback(
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

    FFI_PLUGIN_EXPORT enum CaptureErrors init(int deviceID);

    FFI_PLUGIN_EXPORT void deinit();

    FFI_PLUGIN_EXPORT int isInited();

    FFI_PLUGIN_EXPORT int isDeviceStartedListen();

    FFI_PLUGIN_EXPORT enum CaptureErrors startListen();

    FFI_PLUGIN_EXPORT enum CaptureErrors stopListen();

    FFI_PLUGIN_EXPORT enum CaptureErrors setSilenceDetection(bool enable, float silenceThresholdDb);

    FFI_PLUGIN_EXPORT enum CaptureErrors getVolumeDb(float *volumeDb);

    FFI_PLUGIN_EXPORT void getFft(float **fft);

    FFI_PLUGIN_EXPORT void getWave(float **wave);

    FFI_PLUGIN_EXPORT void getTexture(float *samples);

    FFI_PLUGIN_EXPORT enum CaptureErrors getTexture2D(float **samples);

    FFI_PLUGIN_EXPORT float getTextureValue(int row, int column);

    FFI_PLUGIN_EXPORT enum CaptureErrors setFftSmoothing(float smooth);



#ifdef __cplusplus
}
#endif

#endif // FLUTTER_RECORDER_H