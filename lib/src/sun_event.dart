/// The outcome of asking "when does the Sun cross this altitude?".
///
/// Either the crossing happens at a UTC time ([SunEventAt]), or it does not
/// happen that day because the Sun stays above the altitude all day
/// ([SunEvent.alwaysUp]) or below it all day ([SunEvent.alwaysDown]).
///
/// Polar day and polar night are therefore explicit results, never `NaN` or
/// an invented DateTime:
///
/// ```dart
/// final text = switch (times.sunrise) {
///   SunEventAt(:final time) => 'Sunrise at $time',
///   SunAlwaysUp() => 'Midnight sun',
///   SunAlwaysDown() => 'Polar night',
/// };
/// ```
sealed class SunEvent {
  const SunEvent._();

  /// A crossing at [time]. A non-UTC [time] is converted to UTC.
  factory SunEvent.at(DateTime time) = SunEventAt;

  /// The Sun stays above the requested altitude for the whole day.
  static const SunEvent alwaysUp = SunAlwaysUp._();

  /// The Sun stays below the requested altitude for the whole day.
  static const SunEvent alwaysDown = SunAlwaysDown._();

  /// The UTC time of the crossing, or null for [alwaysUp] / [alwaysDown].
  DateTime? get time;

  /// Whether the crossing happens (i.e. [time] is not null).
  bool get occurs => time != null;
}

/// A crossing that happens at [time] (UTC).
final class SunEventAt extends SunEvent {
  /// Creates an event at [time], converted to UTC.
  SunEventAt(DateTime time)
      : time = time.toUtc(),
        super._();

  @override
  final DateTime time;

  @override
  bool operator ==(Object other) => other is SunEventAt && other.time == time;

  @override
  int get hashCode => time.hashCode;

  @override
  String toString() => 'SunEvent.at(${time.toIso8601String()})';
}

/// The Sun stays above the requested altitude all day (e.g. midnight sun).
final class SunAlwaysUp extends SunEvent {
  const SunAlwaysUp._() : super._();

  @override
  DateTime? get time => null;

  @override
  String toString() => 'SunEvent.alwaysUp';
}

/// The Sun stays below the requested altitude all day (e.g. polar night).
final class SunAlwaysDown extends SunEvent {
  const SunAlwaysDown._() : super._();

  @override
  DateTime? get time => null;

  @override
  String toString() => 'SunEvent.alwaysDown';
}

/// A time window bounded by two Sun events, e.g. the golden hour.
final class SunWindow {
  /// Creates a window from [start] to [end].
  const SunWindow(this.start, this.end);

  /// When the window opens.
  final SunEvent start;

  /// When the window closes.
  final SunEvent end;

  /// `end - start`, or null when either bound does not occur that day.
  Duration? get duration {
    final s = start.time;
    final e = end.time;
    return (s == null || e == null) ? null : e.difference(s);
  }

  @override
  bool operator ==(Object other) =>
      other is SunWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SunWindow($start, $end)';
}

/// The two daily crossings of one solar altitude.
final class SunCrossings {
  /// Creates the pair.
  const SunCrossings({required this.rising, required this.setting});

  /// The morning crossing, while the Sun climbs (before solar noon).
  final SunEvent rising;

  /// The evening crossing, while the Sun sinks (after solar noon).
  final SunEvent setting;

  @override
  bool operator ==(Object other) =>
      other is SunCrossings &&
      other.rising == rising &&
      other.setting == setting;

  @override
  int get hashCode => Object.hash(rising, setting);

  @override
  String toString() => 'SunCrossings(rising: $rising, setting: $setting)';
}
