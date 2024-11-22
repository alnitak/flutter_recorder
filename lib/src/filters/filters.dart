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
  AutoGain get autoGainFilter => const AutoGain();

  /// The `Echo Cancellation` filter.
  EchoCancellation get echoFilter => const EchoCancellation();
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
