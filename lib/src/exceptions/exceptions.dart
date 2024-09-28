import 'package:flutter_recorder/src/bindings/flutter_recorder_bindings_generated.dart';

part 'exceptions_from_cpp.dart';

/// A base class for all flutter_recorder exceptions.
sealed class RecorderException implements Exception {
  /// Creates a new Recorder exception.
  const RecorderException([this.message]);

  /// A message that explains what exactly went wrong in that particular case.
  final String? message;

  /// A verbose description of what this exception means, in general.
  /// Don't confuse with the optional [message] parameter, which is there
  /// to explain what exactly went wrong in that particular case.
  String get description;

  @override
  String toString() {
    final buffer = StringBuffer()
      // ignore: no_runtimeType_toString
      ..write(runtimeType)
      ..write(': ')
      ..write(description);

    if (message != null) {
      buffer
        ..write(' (')
        ..write(message)
        ..write(')');
    }

    return buffer.toString();
  }
}

/// A base class for all flutter_recorder exceptions that are thrown from
/// the C++ side.
///
/// These exceptions correspond to the errors define in the
/// [CaptureErrors] enum.
abstract class RecorderCppException extends RecorderException {
  /// Creates a new Recorder exception that is thrown from the C++ side.
  const RecorderCppException([super.message]);

  /// Takes a [CaptureErrors] enum value and returns a corresponding exception.
  /// This is useful when we need to convert a C++ error to a Dart exception.
  ///
  /// If [error] is [CaptureErrors.captureNoError], this constructor throws
  /// an [ArgumentError].
  factory RecorderCppException.fromPlayerError(CaptureErrors error) {
    switch (error) {
      case CaptureErrors.captureNoError:
        throw ArgumentError(
          'Trying to create an exception from CaptureErrors.noError. '
              'This is a bug in the library. Please report it.',
          'error',
        );
      case CaptureErrors.captureInitFailed:
        return const RecorderInitializeFailedException();
      case CaptureErrors.captureNotInited:
        return const RecorderCaptureNotInitializedException();
      case CaptureErrors.failedToInitializeRecording:
        return const RecorderFailedToInitializeRecordingException();
      case CaptureErrors.failedToStartDevice:
        throw const RecorderFailedToStartDeviceException();
      case CaptureErrors.failedToWriteWav:
        return const RecorderFailedToWriteWavException();
      case CaptureErrors.invalidArgs:
        return const RecorderInvalidArgumentsException();
    }
  }
}
