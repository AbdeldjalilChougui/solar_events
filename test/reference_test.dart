import 'package:sun_times/sun_times.dart';
import 'package:test/test.dart';

import 'reference_data.dart';

/// Tolerance: 1 minute below 65 degrees of latitude, 3 minutes above.
Duration _tolerance(ReferenceCase c) => c.latitude.abs() < 65
    ? const Duration(minutes: 1)
    : const Duration(minutes: 3);

void _expectEvent(SunEvent actual, String expected, Duration tolerance,
    {required String reason}) {
  switch (expected) {
    case 'none':
      expect(actual.time, isNull, reason: '$reason: expected no event');
    case 'alwaysUp':
      expect(actual, SunEvent.alwaysUp, reason: reason);
    case 'alwaysDown':
      expect(actual, SunEvent.alwaysDown, reason: reason);
    default:
      final want = DateTime.parse(expected);
      final got = actual.time;
      expect(got, isNotNull, reason: '$reason: expected $want, got $actual');
      final diff = got!.difference(want).abs();
      expect(diff <= tolerance, isTrue,
          reason: '$reason: expected $want, got $got (off by $diff)');
      expect(got.isUtc, isTrue, reason: '$reason must be UTC');
  }
}

SunTimes _times(ReferenceCase c) => SunTimes(
      date: DateTime(c.year, c.month, c.day),
      latitude: c.latitude,
      longitude: c.longitude,
      utcOffset: Duration(hours: c.utcOffsetHours),
    );

void main() {
  group('against the NOAA solar calculator', () {
    for (final c in referenceCases.where((c) => c.noaa.isNotEmpty)) {
      test('$c', () {
        final t = _times(c);
        final tol = _tolerance(c);
        _expectEvent(t.sunrise, c.noaa['sunrise'] ?? 'none', tol,
            reason: 'sunrise');
        _expectEvent(t.sunset, c.noaa['sunset'] ?? 'none', tol,
            reason: 'sunset');
        final noonDiff =
            t.solarNoon.difference(DateTime.parse(c.noaa['noon']!)).abs();
        expect(noonDiff <= const Duration(seconds: 30), isTrue,
            reason: 'solar noon ${t.solarNoon} vs ${c.noaa['noon']}');
      });
    }
  });

  group('against PyEphem (independent theory)', () {
    for (final c in referenceCases) {
      test('$c', () {
        final t = _times(c);
        final tol = _tolerance(c);
        final events = <String, SunEvent>{
          'sunrise': t.sunrise,
          'sunset': t.sunset,
          'civilDawn': t.civilDawn,
          'civilDusk': t.civilDusk,
          'nauticalDawn': t.nauticalDawn,
          'nauticalDusk': t.nauticalDusk,
          'astronomicalDawn': t.astronomicalDawn,
          'astronomicalDusk': t.astronomicalDusk,
        };
        for (final e in events.entries) {
          _expectEvent(e.value, c.ephem[e.key]!, tol, reason: e.key);
        }
        final noonDiff =
            t.solarNoon.difference(DateTime.parse(c.ephem['noon']!)).abs();
        expect(noonDiff <= const Duration(seconds: 30), isTrue,
            reason: 'solar noon ${t.solarNoon} vs ${c.ephem['noon']}');
      });
    }
  });

  test('NOAA "no sunrise" cases are the polar ones', () {
    final polar = referenceCases
        .where((c) => c.noaa.isNotEmpty && c.noaa['sunrise'] == null);
    expect(polar.map((c) => c.toString()),
        ['Tromsø 2026-06-21', 'Tromsø 2026-12-21']);
  });
}
