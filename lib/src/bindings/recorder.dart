// ignore_for_file: avoid_positional_boolean_parameters

import 'package:meta/meta.dart';

/// Callback when silence state is changed.
typedef SilenceCallback = void Function(bool isSilent, double decibel);

/// Silence state.
typedef SilenceState = ({bool isSilent, double decibel});

abstract class Recorder {
  @mustBeOverridden
  void setSilenceThresholdDb(double silenceThresholdDb);
}
