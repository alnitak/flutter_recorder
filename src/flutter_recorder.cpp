#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "flutter_recorder.h"
#include "capture.h"
#include "analyzer.h"

#include <memory>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

Capture capture;
std::unique_ptr<Analyzer> analyzerCapture = std::make_unique<Analyzer>(256);

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
        isDefault[i]   = (int *)malloc(sizeof(int *));
        *isDefault[i]  = d[i].isDefault;
        deviceId[i]   = (int *)malloc(sizeof(int *));
        *deviceId[i]   = d[i].id;

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

FFI_PLUGIN_EXPORT enum CaptureErrors stopListen()
{
    if (!capture.isInited())
        return captureNotInited;
    return capture.stopListen();
}

FFI_PLUGIN_EXPORT enum CaptureErrors setSilenceDetection(bool enable, float silenceThresholdDb)
{
    if (!capture.isInited())
        return captureNotInited;
    capture.setSilenceDetection(enable, silenceThresholdDb);
    return captureNoError;
}

FFI_PLUGIN_EXPORT enum CaptureErrors setFftSmoothing(float smooth)
{
    if (!capture.isInited())
        return captureNotInited;
    analyzerCapture.get()->setSmoothing(smooth);
    return captureNoError;
}

/// Return a 256 float array containing FFT data.
FFI_PLUGIN_EXPORT void getFft(float **fft)
{
    if (!capture.isInited())
        return;
    float *wave = capture.getWave();
    *fft = analyzerCapture.get()->calcFFT(wave);
}

/// Return a 256 float array containing wave data.
FFI_PLUGIN_EXPORT void getWave(float **wave)
{
    if (!capture.isInited())
        return;
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
FFI_PLUGIN_EXPORT enum CaptureErrors getTexture2D(float **samples)
{
    if (analyzerCapture.get() == nullptr || !capture.isInited())
    {
        *samples = *capturedTexture2D;
        memset(*samples, 0, sizeof(float) * 512 * 256);
        return captureNotInited;
    }
    /// shift up 1 row
    memmove(*capturedTexture2D + 512, capturedTexture2D, sizeof(float) * 512 * 255);
    /// store the new 1st row
    getTexture(capturedTexture2D[0]);
    *samples = *capturedTexture2D;
    return captureNoError;
}

FFI_PLUGIN_EXPORT float getTextureValue(int row, int column)
{
    return capturedTexture2D[row][column];
}

// A very short-lived native function.
//
// For very short-lived functions, it is fine to call them on the main isolate.
// They will block the Dart execution while running the native function, so
// only do this for native functions which are guaranteed to be short-lived.
FFI_PLUGIN_EXPORT int sum(int a, int b) { return a + b; }

// A longer-lived native function, which occupies the thread calling it.
//
// Do not call these kind of native functions in the main isolate. They will
// block Dart execution. This will cause dropped frames in Flutter applications.
// Instead, call these native functions on a separate isolate.
FFI_PLUGIN_EXPORT int sum_long_running(int a, int b)
{
    // Simulate work.
#if _WIN32
    Sleep(5000);
#else
    usleep(5000 * 1000);
#endif
    return a + b;
}
