part of 'exceptions.dart';

// ////////////////////////////////////////
// / C++-side exceptions for the recorder /
// ////////////////////////////////////////

/// An exception that is thrown when the recorder failed to initialize.
class RecorderInitializeFailedException extends RecorderCppException {
  /// Creates a new [RecorderInitializeFailedException].
  const RecorderInitializeFailedException([super.message]);

  @override
  String get description => 'An error occurred while initializing recorder. '
      'Maybe it is already inited? (on the C++ side).';
}

/// An exception that is thrown when calling some methods while the recorder is
/// not initialized.
class RecorderCaptureNotInitializedException extends RecorderCppException {
  /// Creates a new [RecorderCaptureNotInitializedException].
  const RecorderCaptureNotInitializedException([super.message]);

  @override
  String get description => 'The recorder has not been initialized yet '
      '(on the C++ side).';
}

/// An exception that is thrown when recording failed to start.
class RecorderFailedToInitializeRecordingException
    extends RecorderCppException {
  /// Creates a new [RecorderFailedToInitializeRecordingException].
  const RecorderFailedToInitializeRecordingException([super.message]);

  @override
  String get description => 'The recording failed to start '
      '(on the C++ side).';
}

/// An exception that is thrown when failed to start the device.
class RecorderFailedToStartDeviceException extends RecorderCppException {
  /// Creates a new [RecorderFailedToStartDeviceException].
  const RecorderFailedToStartDeviceException([super.message]);

  @override
  String get description => 'The device failed to start '
      '(on the C++ side).';
}

/// An exception that is thrown when the wav file could not be written.
class RecorderFailedToWriteWavException extends RecorderCppException {
  /// Creates a new [RecorderFailedToWriteWavException].
  const RecorderFailedToWriteWavException([super.message]);

  @override
  String get description => 'The recording failed to write wav file '
      '(on the C++ side).';
}

/// An exception that is thrown when passing invalid arguments.
class RecorderInvalidArgumentsException extends RecorderCppException {
  /// Creates a new [RecorderInvalidArgumentsException].
  const RecorderInvalidArgumentsException([super.message]);

  @override
  String get description => 'Some invalid arguments were passed in '
      '(on the C++ side).';
}
