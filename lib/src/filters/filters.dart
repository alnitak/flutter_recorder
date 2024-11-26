import 'package:flutter_recorder/src/exceptions/exceptions.dart';
import 'package:flutter_recorder/src/filters/autogain.dart';
import 'package:flutter_recorder/src/filters/echo_cancellation.dart';
import 'package:flutter_recorder/src/flutter_recorder.dart';
import 'package:meta/meta.dart';

/// This class serves as a base for all audio filter methods.
abstract class FilterBase {
  /// The base class common to all filters. It can be used to [activate],
  /// [deactivate] or query its status and its index in the filter list.
  const FilterBase(FilterType ft) : filterType = ft;

  /// The type of this filter. It can be used to get the number of its
  /// parameters or the name of the filter.
  final FilterType filterType;

  /// Activate this filter.
  void activate() => filterType.activate();

  /// Deactivate this filter.
  void deactivate() => filterType.deactivate();

  /// Returns `-1` if the filter is not active. Otherwise, returns
  /// the index of this filter.
  int get index => filterType.isActive();

  /// Checks whether this filter is active.
  bool get isActive => index >= 0;
}

/// Filters instance used in [Recorder.filters].
final class Filters {
  /// The class to get access to all the filters available globally.
  const Filters();

  /// The `Auto Gain` filter.
  ///
  /// 1. **Target RMS Level (g_targetRMS)**
  ///   - Purpose: Sets the desired loudness level.
  ///   - Typical Value:
  ///   - For speech: 0.05 to 0.2 (RMS values in the -1.0 to +1.0 range).
  ///   - For music: 0.1 to 0.3.
  ///   - Adjust to: Match the desired loudness without introducing excessive
  /// distortion or artifacts.
  /// 2. **Attack Time (g_attackTime)**
  ///   - Purpose: Determines how quickly the gain increases when the signal
  /// level is below the target.
  ///   - Typical Value: 0.005 to 0.05 seconds.
  ///   - Faster attack (e.g., 0.005) ensures quick response to sudden volume
  /// drops, but may sound unnatural.
  ///   - Slower attack (e.g., 0.02-0.05) smoothens gain changes.
  /// 3. **Release Time (g_releaseTime)**
  ///   - Purpose: Determines how quickly the gain decreases when the signal
  /// level is above the target.
  ///   - Typical Value: 0.05 to 0.5 seconds.
  ///   - Short release (e.g., 0.05-0.1) responds quickly to loud bursts but
  /// risks unnatural pumping effects.
  ///   - Long release (e.g., 0.2-0.5) creates smoother transitions for
  /// dynamic content like music.
  /// 4. **Gain Smoothing (g_gainSmoothing)**
  ///   - Purpose: Controls how quickly the gain changes overall, acting as
  /// a dampening factor.
  ///   - Typical Value: 0.01 to 0.1.
  ///   - Lower values (e.g., 0.01) result in slow gain adjustments, reducing
  /// artifacts but possibly underreacting to fast changes.
  ///   - Higher values (e.g., 0.05-0.1) provide faster responsiveness but
  /// may sound less smooth.
  /// 5. **Maximum Gain (g_maxGain)**
  ///   - Purpose: Caps the maximum amplification to avoid over-amplification
  /// or distortion.
  ///   - Typical Value: 4.0 to 10.0.
  ///   - Adjust to: Match the dynamic range of the input; keep lower for
  /// highly dynamic signals to prevent clipping.
  /// 6. **Minimum Gain (g_minGain)**
  ///   - Purpose: Prevents excessive attenuation of the signal.
  ///   - Typical Value: 0.1 to 0.5.
  ///   - Adjust to: Avoid muting low signals unless silence is acceptable.
  ///
  /// #### Recommended Settings for Common Scenarios
  /// 
  /// **Speech in a Noisy Environment**
  ///   - targetRMS = 0.1f
  ///   - attackTime = 0.02f
  ///   - releaseTime = 0.2f
  ///   - gainSmoothing = 0.01f
  ///   - maxGain = 6.0f
  ///   - minGain = 0.2f
  /// 
  /// **Music Playback**
  ///   - targetRMS = 0.2f
  ///   - attackTime = 0.01f
  ///   - releaseTime = 0.3f
  ///   - gainSmoothing = 0.05f
  ///   - maxGain = 4.0f
  ///   - minGain = 0.1f
  /// 
  /// **Podcast Recording**
  ///   - targetRMS = 0.15f
  ///   - attackTime = 0.02f
  ///   - releaseTime = 0.2f
  ///   - gainSmoothing = 0.03f
  ///   - maxGain = 5.0f
  ///   - minGain = 0.1f
  AutoGain get autoGainFilter => const AutoGain();

  /// The `Echo Cancellation` filter.
  EchoCancellation get echoCancellationFilter => const EchoCancellation();
}

/// Common class for single and global filters.
class FilterParam {
  /// Every filter parameter values can be set or get.
  FilterParam(
    this._type,
    this._attributeId,
    this._min,
    this._max,
  );

  final FilterType _type;
  final int _attributeId;
  final double _min;
  final double _max;

  /// Get the parameter value.
  double get value => Recorder.instance.getFilterParamValue(
        _type,
        _attributeId,
      );

  /// Set the parameter value.
  set value(double val) {
    if (val < _min || val > _max) {
      return;
    }
    Recorder.instance.setFilterParamValue(
      _type,
      _attributeId,
      val,
    );
  }
}

/// The different types of audio filters.
enum FilterType {
  /// Auto gain filter.
  autogain(0),

  /// Echo cancellation filter.
  echoCancellation(1);

  /// The number of parameter this filter owns.
  final int value;

  // ignore: sort_constructors_first
  const FilterType(this.value);

  /// Get the filter type from its value.
  static FilterType fromValue(int value) => switch (value) {
        0 => autogain,
        1 => echoCancellation,
        _ => throw ArgumentError('Unknown value for FilterType: $value'),
      };

  @override
  String toString() => switch (this) {
        FilterType.autogain => 'Auto Gain',
        FilterType.echoCancellation => 'Echo Cancellation',
      };

  /// The number of parameter this filter owns.
  int get numParameters => switch (this) {
        FilterType.autogain => 6,
        FilterType.echoCancellation => 2,
      };

  /// Activate this filter.
  @internal
  void activate() {
    Recorder.instance.addFilter(this);
  }

  /// Checks whether this filter is active.
  ///
  /// Returns `-1` if the filter is not active. Otherwise, returns
  /// the index of the given filter.
  @internal
  int isActive() => Recorder.instance.isFilterActive(this);

  /// Deactivate this filter.
  ///
  /// Throws [RecorderFilterNotFoundException] if trying to remove a non active
  /// filter.
  @internal
  void deactivate() {
    Recorder.instance.removeFilter(this);
  }
}
