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
    failedToStartDevice

} CaptureErrorsInternal_t;

#endif // ENUMS_H