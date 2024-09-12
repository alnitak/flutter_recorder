#ifndef CAPTURE_H
#define CAPTURE_H

#include "enums.h"
#include "common.h"
#include "miniaudio.h"

#include <vector>
#include <string>




struct CaptureDevice {
    char* name;
    unsigned int isDefault;
    unsigned int id;
};

class Capture {
public:
    Capture();
    ~Capture();

    /// stores a list of available capture devices
    /// detected by miniaudio
    std::vector<CaptureDevice> listCaptureDevices();

    /// @brief initialize the capture with a [deviceID]. A list of devices
    ///     can be acquired with [listCaptureDevices].
    ///     If [deviceID] is -1, the default will be used
    /// @param deviceID the device ID chosen to be initialized
    /// @return `captureNoError` if no error or else `captureInitFailed`
    CaptureErrors init(int deviceID);

    /// @brief Must be called when there is no more need of the capture or when closing the app
    void dispose();

    bool isInited();
    bool isDeviceStartedListen();
    CaptureErrors startListen();
    CaptureErrors stopListen();

    CaptureErrors setSilenceDetection(bool enable, float silenceThresholdDb);
    void setDartEventCallback(dartSilenceChangedCallback_t dartSilenceChangedCallback);

    float* getWave();

    float *getVolumeDb();

    /// Wheter or not the callback is detecting silence.
    bool isDetectingSilence;

    /// the threshold for detecting silence.
    float silenceThresholdDb;

private:
    ma_context context;
    ma_device_info *pPlaybackInfos;
    ma_uint32 playbackCount;
    ma_device_info *pCaptureInfos;
    ma_uint32 captureCount;
    ma_result result;
    // ma_encoder_config encoderConfig;
    // ma_encoder encoder;
    ma_device_config deviceConfig;
    ma_device device;

    /// true when the capture device is initialized.
    bool mInited;

};

#endif // CAPTURE_H