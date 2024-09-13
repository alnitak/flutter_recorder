#include "capture.h"

#include <cstdarg>
#include <memory.h>
#include <cmath>

// 1024 means 1/(44100*2)*1024 = 0.0116 ms
#define BUFFER_SIZE 1024            // Buffer length
#define MOVING_AVERAGE_SIZE 5       // Moving average window size
float capturedBuffer[BUFFER_SIZE];
float energy_db = -200.0f;

// to be used by `NativeCallable` since it will be called inside the audio thread,
// these functions must return void.
void (*dartSilenceChangedCallback)(bool *, float *) = nullptr;

// Function to convert energy to decibels
float energy_to_db(float energy)
{
    return 10.0f * log10f(energy + 1e-10f); // Add a small value to avoid log(0)
}

void detectSilence(float *captured, ma_uint32 frameCount, float silenceThresholdDb)
{
    static bool is_silent = true;                           // Initial state
    static float moving_average[MOVING_AVERAGE_SIZE] = {0}; // Moving average window
    static int average_index = 0;                           // Circular buffer index
    float sum = 0.0f;

    // Calculate the average energy of the current buffer
    for (int i = 0; i < frameCount; i++)
    {
        sum += captured[i] * captured[i];
    }
    float average_energy = sum / frameCount;

    // Update the moving average window
    moving_average[average_index] = average_energy;
    average_index = (average_index + 1) % MOVING_AVERAGE_SIZE; // Circular buffer cycle

    // Calculate the moving average
    float moving_average_sum = 0.0f;
    for (int i = 0; i < MOVING_AVERAGE_SIZE; i++)
    {
        moving_average_sum += moving_average[i];
    }
    float smoothed_energy = moving_average_sum / MOVING_AVERAGE_SIZE;

    // Convert energy to decibels
    energy_db = energy_to_db(smoothed_energy);

    // Check if the signal is below the silence threshold
    if (energy_db < silenceThresholdDb)
    {
        if (!is_silent)
        {
            // Transition: Sound -> Silence
            // printf("Silence started. Level in dB: %.2f\n", energy_db);
            is_silent = true;
            if (dartSilenceChangedCallback != nullptr)
                dartSilenceChangedCallback(&is_silent, &energy_db);
        }
    }
    else
    {
        if (is_silent)
        {
            // Transition: Silence -> Sound
            // printf("Sound started. Level in dB: %.2f\n", energy_db);
            is_silent = false;
            if (dartSilenceChangedCallback != nullptr)
                dartSilenceChangedCallback(&is_silent, &energy_db);
        }
    }
}

void data_callback(ma_device *pDevice, void *pOutput, const void *pInput, ma_uint32 frameCount)
{
    // Process the captured audio data as needed
    // For example, you can copy it to a buffer for later use.
    float *captured = (float *)(pInput); // Assuming float format
    // Do something with the captured audio data...
    memcpy(capturedBuffer, captured, sizeof(float) * BUFFER_SIZE);

    Capture *userData = (Capture *)pDevice->pUserData;
    if (userData->isDetectingSilence)
    {
        detectSilence(captured, frameCount, userData->silenceThresholdDb);
    }
}

Capture::Capture() : isDetectingSilence(false),
                     silenceThresholdDb(-40.0f),
                     mInited(false) {};

Capture::~Capture()
{
    dispose();
}

void Capture::setDartEventCallback(dartSilenceChangedCallback_t callback)
{
    dartSilenceChangedCallback = callback;
}
std::vector<CaptureDevice> Capture::listCaptureDevices()
{
    // printf("***************** LIST DEVICES START\n");
    std::vector<CaptureDevice> ret;
    if ((result = ma_context_init(NULL, 0, NULL, &context)) != MA_SUCCESS)
    {
        printf("Failed to initialize context %d\n", result);
        return ret;
    }

    if ((result = ma_context_get_devices(
             &context,
             &pPlaybackInfos,
             &playbackCount,
             &pCaptureInfos,
             &captureCount)) != MA_SUCCESS)
    {
        printf("Failed to get devices %d\n", result);
        return ret;
    }

    // Loop over each device info and do something with it. Here we just print
    // the name with their index. You may want
    // to give the user the opportunity to choose which device they'd prefer.
    for (ma_uint32 i = 0; i < captureCount; i++)
    {
        printf("######%s %d - %s\n",
                     pCaptureInfos[i].isDefault ? " X" : "-",
                     i,
                     pCaptureInfos[i].name);
        CaptureDevice cd;
        cd.name = strdup(pCaptureInfos[i].name);
        cd.isDefault = pCaptureInfos[i].isDefault;
        cd.id = i;
        ret.push_back(cd);
    }
    printf("***************** LIST DEVICES END\n");
    return ret;
}

CaptureErrors Capture::init(int deviceID)
{
    if (mInited)
        return captureInitFailed;
    deviceConfig = ma_device_config_init(ma_device_type_capture);
    deviceConfig.periodSizeInFrames = BUFFER_SIZE;
    if (deviceID != -1) {
        if (listCaptureDevices().size() == 0) return captureInitFailed;
        deviceConfig.capture.pDeviceID = &pCaptureInfos[deviceID].id;
    }
    deviceConfig.capture.format = ma_format_f32;
    deviceConfig.capture.channels = 2;
    deviceConfig.sampleRate = 44100;
    deviceConfig.dataCallback = data_callback;
    deviceConfig.pUserData = this;

    result = ma_device_init(NULL, &deviceConfig, &device);
    if (result != MA_SUCCESS)
    {
        printf("Failed to initialize capture device.\n");
        return captureInitFailed;
    }
    mInited = true;
    return captureNoError;
}

void Capture::dispose()
{
    mInited = false;
    ma_device_uninit(&device);
}

bool Capture::isInited()
{
    return mInited;
}

bool Capture::isDeviceStartedListen()
{
    ma_device_state result = ma_device_get_state(&device);
    return result == ma_device_state_started;
}

CaptureErrors Capture::startListen()
{
    if (!mInited)
        return captureNotInited;

    result = ma_device_start(&device);
    if (result != MA_SUCCESS)
    {
        ma_device_uninit(&device);
        printf("Failed to start device.\n");
        return failedToStartDevice;
    }
    return captureNoError;
}

CaptureErrors Capture::stopListen()
{
    if (!mInited)
        return captureNotInited;

    ma_device_uninit(&device);
    mInited = false;
    return captureNoError;
}

float Capture::getVolumeDb()
{
    return energy_db;
}

CaptureErrors Capture::setSilenceDetection(bool enable, float silenceThresholdDb)
{
    if (!mInited)
        return captureNotInited;

    this->isDetectingSilence = enable;
    this->silenceThresholdDb = silenceThresholdDb;
    return captureNoError;
}

float waveData[256];
float *Capture::getWave()
{
    int n = BUFFER_SIZE >> 8;
    for (int i = 0; i < 256; i++)
    {
        waveData[i] = (capturedBuffer[i * n] +
                       capturedBuffer[i * n + 1] +
                       capturedBuffer[i * n + 2] +
                       capturedBuffer[i * n + 3]) /
                      n;
    }
    return waveData;
}