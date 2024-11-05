#ifndef ENUMS_H
#define ENUMS_H

/// Possible capture errors
typedef enum CaptureErrors
{
    /// No error
    captureNoError,
    /// The capture device has failed to initialize.
    captureInitFailed,
    /// The capture device has not yet been initialized.
    captureNotInited,
    /// Failed to start the device.
    failedToStartDevice,
    /// Failed to initialize wav recording.
    failedToInitializeRecording,
    /// Invalid arguments while initializing wav recording.
    invalidArgs,
    /// Failed to write wav file.
    failedToWriteWav

} CaptureErrorsInternal_t;

typedef enum PCMFormat
{
    pcm_u8,
    pcm_s16,
    pcm_s24,
    pcm_s32,
    pcm_f32
} PCMFormatInternal_t;

#endif // ENUMS_H