/// A UTC instant paired with a fixed UTC offset, for display.
///
/// This package has no time-zone database. If you know the offset that
/// applies (for example from the platform or your own tz data), use
/// [DateTime.atUtcOffset] to turn a UTC result into wall-clock time.
final class OffsetDateTime {
  /// Pairs [utc] (converted to UTC if needed) with [offset].
  OffsetDateTime(DateTime utc, this.offset) : utc = utc.toUtc();

  /// The instant, in UTC.
  final DateTime utc;

  /// The offset from UTC, e.g. `Duration(hours: 1)` for UTC+01:00.
  final Duration offset;

  /// Wall-clock fields at [offset].
  ///
  /// Dart's DateTime cannot carry an arbitrary offset, so this is returned as
  /// a DateTime flagged UTC whose year/month/day/hour/... read as local
  /// wall-clock time. Use it for its fields, not as an instant.
  DateTime get local => utc.add(offset);

  /// ISO 8601 with the offset, e.g. `2026-03-20T06:09:56+12:00`.
  String toIso8601String() {
    final l = local;
    String two(int n) => n.toString().padLeft(2, '0');
    final year = l.year.toString().padLeft(4, '0');
    final fraction = (l.millisecond == 0 && l.microsecond == 0)
        ? ''
        : '.${l.millisecond.toString().padLeft(3, '0')}'
            '${l.microsecond == 0 ? '' : l.microsecond.toString().padLeft(3, '0')}';
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    return '$year-${two(l.month)}-${two(l.day)}T${two(l.hour)}:${two(l.minute)}'
        ':${two(l.second)}$fraction'
        '$sign${two(abs.inHours)}:${two(abs.inMinutes % 60)}';
  }

  @override
  bool operator ==(Object other) =>
      other is OffsetDateTime && other.utc == utc && other.offset == offset;

  @override
  int get hashCode => Object.hash(utc, offset);

  @override
  String toString() => toIso8601String();
}

/// Applies a fixed UTC offset to a DateTime.
extension DateTimeUtcOffset on DateTime {
  /// This instant viewed at a fixed [offset] from UTC.
  ///
  /// ```dart
  /// sunrise.atUtcOffset(const Duration(hours: 1)).toIso8601String();
  /// // 2026-03-20T06:51:33+01:00
  /// ```
  OffsetDateTime atUtcOffset(Duration offset) => OffsetDateTime(this, offset);
}
