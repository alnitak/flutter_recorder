// ignore_for_file: public_member_api_docs
import 'package:flutter_recorder/src/filters/filters.dart';

enum AutoGainEnum {
  targetRms,
  attackTime,
  releaseTime,
  gainSmoothing,
  maxGain,
  minGain,
  noiseFloorDb,
  headroomDb,
  currentGain,
  inputRms,
  outputPeak,
  limiterClipCount,
  totalLimiterClipCount,
  lastFrameCount;

  static const List<double> _defs = <double>[
    0.1,
    0.1,
    0.2,
    0.05,
    6,
    0.2,
    -55,
    1,
    1,
    0,
    0,
    0,
    0,
    0,
  ];
  static const List<double> _mins = <double>[
    0.001,
    0.001,
    0.001,
    0.001,
    1,
    0,
    -100,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];
  static const List<double> _maxs = <double>[
    0.95,
    2,
    5,
    1,
    12,
    1,
    -10,
    24,
    12,
    1,
    1,
    double.maxFinite,
    double.maxFinite,
    double.maxFinite,
  ];
  static const List<bool> _writable = <bool>[
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  double get min => _mins[index];
  double get max => _maxs[index];
  double get def => _defs[index];
  bool get isWritable => _writable[index];

  @override
  String toString() => switch (this) {
        AutoGainEnum.targetRms => 'Target RMS',
        AutoGainEnum.attackTime => 'Attack Time',
        AutoGainEnum.releaseTime => 'Release Time',
        AutoGainEnum.gainSmoothing => 'Gain Smoothing',
        AutoGainEnum.maxGain => 'Max Gain',
        AutoGainEnum.minGain => 'Min Gain',
        AutoGainEnum.noiseFloorDb => 'Noise Floor dB',
        AutoGainEnum.headroomDb => 'Headroom dB',
        AutoGainEnum.currentGain => 'Current Gain',
        AutoGainEnum.inputRms => 'Input RMS',
        AutoGainEnum.outputPeak => 'Output Peak',
        AutoGainEnum.limiterClipCount => 'Limiter Clip Count',
        AutoGainEnum.totalLimiterClipCount => 'Total Limiter Clip Count',
        AutoGainEnum.lastFrameCount => 'Last Frame Count',
      };
}

abstract class _AutoGainInternal extends FilterBase {
  const _AutoGainInternal() : super(RecorderFilterType.autogain);

  AutoGainEnum get queryTargetRms => AutoGainEnum.targetRms;
  AutoGainEnum get queryAttackTime => AutoGainEnum.attackTime;
  AutoGainEnum get queryReleaseTime => AutoGainEnum.releaseTime;
  AutoGainEnum get queryGainSmoothing => AutoGainEnum.gainSmoothing;
  AutoGainEnum get queryMaxGain => AutoGainEnum.maxGain;
  AutoGainEnum get queryMinGain => AutoGainEnum.minGain;
  AutoGainEnum get queryNoiseFloorDb => AutoGainEnum.noiseFloorDb;
  AutoGainEnum get queryHeadroomDb => AutoGainEnum.headroomDb;
  AutoGainEnum get queryCurrentGain => AutoGainEnum.currentGain;
  AutoGainEnum get queryInputRms => AutoGainEnum.inputRms;
  AutoGainEnum get queryOutputPeak => AutoGainEnum.outputPeak;
  AutoGainEnum get queryLimiterClipCount => AutoGainEnum.limiterClipCount;
  AutoGainEnum get queryTotalLimiterClipCount =>
      AutoGainEnum.totalLimiterClipCount;
  AutoGainEnum get queryLastFrameCount => AutoGainEnum.lastFrameCount;
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

  FilterParam get noiseFloorDb => FilterParam(
        filterType,
        AutoGainEnum.noiseFloorDb.index,
        AutoGainEnum.noiseFloorDb.min,
        AutoGainEnum.noiseFloorDb.max,
      );

  FilterParam get headroomDb => FilterParam(
        filterType,
        AutoGainEnum.headroomDb.index,
        AutoGainEnum.headroomDb.min,
        AutoGainEnum.headroomDb.max,
      );

  FilterMetric get currentGain => FilterMetric(
        filterType,
        AutoGainEnum.currentGain.index,
      );

  FilterMetric get inputRms => FilterMetric(
        filterType,
        AutoGainEnum.inputRms.index,
      );

  FilterMetric get outputPeak => FilterMetric(
        filterType,
        AutoGainEnum.outputPeak.index,
      );

  FilterMetric get limiterClipCount => FilterMetric(
        filterType,
        AutoGainEnum.limiterClipCount.index,
      );

  FilterMetric get totalLimiterClipCount => FilterMetric(
        filterType,
        AutoGainEnum.totalLimiterClipCount.index,
      );

  FilterMetric get lastFrameCount => FilterMetric(
        filterType,
        AutoGainEnum.lastFrameCount.index,
      );
}
