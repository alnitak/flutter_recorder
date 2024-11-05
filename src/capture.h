#ifndef CAPTURE_H
#define CAPTURE_H

#include "enums.h"
#include "common.h"
#include "wav.h"
#include "miniaudio.h"

#include <vector>
#include <string>

struct CaptureDevice
{
    char *name;
    unsigned int isDefault;
    unsigned int id;
};

class Capture
{
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
    /// @param sampleRate the sample rate
    /// @param channels the number of channels
    /// @return `captureNoError` if no error or else `captureInitFailed`
    CaptureErrors init(
        int deviceID,
        unsigned int sampleRate,
        unsigned int channels);

    /// @brief Must be called when there is no more need of the capture or when closing the app
    void dispose();

    bool isInited();

    bool isDeviceStarted();

    CaptureErrors start();

    void stop();

    void setSilenceDetection(bool enable);

    void setSilenceThresholdDb(float silenceThresholdDb);
    void setSilenceDuration(float silenceDuration);
    void setSecondsOfAudioToWriteBefore(float secondsOfAudioToWriteBefore);

    CaptureErrors startRecording(const char *path);

    void setPauseRecording(bool pause);

    void stopRecording();

    float *getWave();

    float getVolumeDb();

    ma_device_config deviceConfig;

    /// Wheter or not the callback is detecting silence.
    bool isDetectingSilence;

    /// The threshold for detecting silence.
    float silenceThresholdDb;

    /// The duration of silence in seconds after which the silence is considered silence.
    float silenceDuration;

    /// ms of audio to write occurred before starting recording againg after silence.
    float secondsOfAudioToWriteBefore;

    ///
    WriteAudio::Wav wav;

    /// true when the capture device is recording.
    bool isRecording;

    /// true when the capture device is paused.
    bool isRecordingPaused;

private:
    ma_context context;
    ma_device_info *pPlaybackInfos;
    ma_uint32 playbackCount;
    ma_device_info *pCaptureInfos;
    ma_uint32 captureCount;
    ma_result result;
    ma_device device;

    /// true when the capture device is initialized.
    bool mInited;
};

#endif // CAPTURE_H