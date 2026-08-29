#ifndef ENUMS_H
#define ENUMS_H

/// Possible capture errors
typedef enum CaptureErrors
{
    /// No error
    captureNoError = 0,
    /// The capture device has failed to initialize.
    captureInitFailed = 1,
    /// The capture device has not yet been initialized.
    captureNotInited = 2,
    /// Failed to start the device.
    failedToStartDevice = 3,
    /// Failed to initialize wav recording.
    failedToInitializeRecording = 4,
    /// Invalid arguments while initializing wav recording.
    invalidArgs = 5,
    /// Failed to write wav file.
    failedToWriteWav = 6,
    /// Filter not found
    filterNotFound = 7,
    /// The filter has already been added.
    filterAlreadyAdded = 8,
    /// Error getting filter parameter.
    filterParameterGetError = 9
} CaptureErrorsInternal_t;

typedef enum PCMFormat
{
    pcm_u8,
    pcm_s16,
    pcm_s24,
    pcm_s32,
    pcm_f32
} PCMFormatInternal_t;

typedef enum RecorderFilterType
{
    autogain,
    echoCancellation
} FilterType_t;

typedef enum RecordingFormat
{
    recordingFormatWav,
    recordingFormatOpusOgg
} RecordingFormat;

typedef enum StreamingFormat
{
    streamingFormatPcm,
    streamingFormatOpus
} StreamingFormat;

typedef enum VisualizationKind
{
    VISUALIZATION_WAVE = 0,
    VISUALIZATION_FFT = 1,
    VISUALIZATION_WAVE_AND_FFT = 2
} VisualizationKind;

#define VISUALIZATION_CHANNEL_MERGED -1
#define VISUALIZATION_CHANNEL_ALL -2

typedef void (*dartVisualizationCallback_t)(
    int channelCount,
    const float **waveDataPerChannel,
    int waveSamples,
    const float **fftDataPerChannel,
    int fftSamples);

#endif // ENUMS_H