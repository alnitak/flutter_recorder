// ignore_for_file: public_member_api_docs
import 'package:flutter_recorder/src/filters/filters.dart';

enum EchoCancellationEnum {
  echoDelayMs,
  echoAttenuation;

  final List<double> _mins = const [0, 0, 0, 0, 0];
  final List<double> _maxs = const [1, 1, 1, 1, 1];
  final List<double> _defs = const [1, 0, 0.5, 0.5, 1];

  double get min => _mins[index];
  double get max => _maxs[index];
  double get def => _defs[index];

  @override
  String toString() => switch (this) {
        EchoCancellationEnum.echoDelayMs => 'Echo Delay (ms)',
        EchoCancellationEnum.echoAttenuation => 'Echo Attenuation',
      };
}

abstract class _EchoCancellationInternal extends FilterBase {
  const _EchoCancellationInternal() : super(FilterType.autogain);

  EchoCancellationEnum get queryEchoDelayMs => EchoCancellationEnum.echoDelayMs;
  EchoCancellationEnum get queryEchoAttenuation =>
      EchoCancellationEnum.echoAttenuation;
}

class EchoCancellation extends _EchoCancellationInternal {
  const EchoCancellation() : super();

  FilterParam get echoDelayMs => FilterParam(
        filterType,
        EchoCancellationEnum.echoDelayMs.index,
        EchoCancellationEnum.echoDelayMs.min,
        EchoCancellationEnum.echoDelayMs.max,
      );

  FilterParam get echoAttenuation => FilterParam(
        filterType,
        EchoCancellationEnum.echoAttenuation.index,
        EchoCancellationEnum.echoAttenuation.min,
        EchoCancellationEnum.echoAttenuation.max,
      );
}
