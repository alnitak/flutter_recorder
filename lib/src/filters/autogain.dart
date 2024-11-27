// ignore_for_file: public_member_api_docs
import 'package:flutter_recorder/src/filters/filters.dart';

enum AutoGainEnum {
  targetRms,
  attackTime,
  releaseTime,
  gainSmoothing,
  maxGain,
  minGain;

  final List<double> _defs = const [0.1, 0.1, 0.2, 0.05, 6, 0.2];
  final List<double> _mins = const [0.01, 0.01, 0.01, 0.001, 1, 0.1];
  final List<double> _maxs = const [1, 0.5, 0.5, 1, 6, 1];

  double get min => _mins[index];
  double get max => _maxs[index];
  double get def => _defs[index];

  @override
  String toString() => switch (this) {
        AutoGainEnum.targetRms => 'Target RMS',
        AutoGainEnum.attackTime => 'Attack Time',
        AutoGainEnum.releaseTime => 'Release Time',
        AutoGainEnum.gainSmoothing => 'Gain Smoothing',
        AutoGainEnum.maxGain => 'Max Gain',
        AutoGainEnum.minGain => 'Min Gain',
      };
}

abstract class _AutoGainInternal extends FilterBase {
  const _AutoGainInternal() : super(FilterType.autogain);

  AutoGainEnum get queryTargetRms => AutoGainEnum.targetRms;
  AutoGainEnum get queryAttackTime => AutoGainEnum.attackTime;
  AutoGainEnum get queryReleaseTime => AutoGainEnum.releaseTime;
  AutoGainEnum get queryGainSmoothing => AutoGainEnum.gainSmoothing;
  AutoGainEnum get queryMaxGain => AutoGainEnum.maxGain;
  AutoGainEnum get queryMinGain => AutoGainEnum.minGain;
}

class AutoGain extends _AutoGainInternal {
  const AutoGain() : super();

  FilterParam get targetRms => FilterParam(
        filterType,
        AutoGainEnum.targetRms.index,
        AutoGainEnum.targetRms.min,
        AutoGainEnum.targetRms.max,
      );

  FilterParam get attackTime => FilterParam(
        filterType,
        AutoGainEnum.attackTime.index,
        AutoGainEnum.attackTime.min,
        AutoGainEnum.attackTime.max,
      );

  FilterParam get releaseTime => FilterParam(
        filterType,
        AutoGainEnum.releaseTime.index,
        AutoGainEnum.releaseTime.min,
        AutoGainEnum.releaseTime.max,
      );

  FilterParam get gainSmoothing => FilterParam(
        filterType,
        AutoGainEnum.gainSmoothing.index,
        AutoGainEnum.gainSmoothing.min,
        AutoGainEnum.gainSmoothing.max,
      );

  FilterParam get maxGain => FilterParam(
        filterType,
        AutoGainEnum.maxGain.index,
        AutoGainEnum.maxGain.min,
        AutoGainEnum.maxGain.max,
      );

  FilterParam get minGain => FilterParam(
        filterType,
        AutoGainEnum.minGain.index,
        AutoGainEnum.minGain.min,
        AutoGainEnum.minGain.max,
      );
}
