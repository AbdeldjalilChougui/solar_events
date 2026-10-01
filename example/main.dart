import 'package:solar_events/solar_events.dart';

void main() {
  const algiers = Duration(hours: 1); // UTC+01:00, no daylight saving.
  final times = SunTimes(
    date: DateTime(2026, 3, 20),
    latitude: 36.75,
    longitude: 3.06,
    utcOffset: algiers,
  );

  String show(SunEvent e) => switch (e) {
        SunEventAt(:final time) => time.atUtcOffset(algiers).toIso8601String(),
        SunAlwaysUp() => 'Sun up all day',
        SunAlwaysDown() => 'Sun down all day',
      };

  print('Algiers, 20 March 2026');
  print('  astronomical dawn  ${show(times.astronomicalDawn)}');
  print('  civil dawn         ${show(times.civilDawn)}');
  print('  sunrise            ${show(times.sunrise)}');
  print('  solar noon         '
      '${times.solarNoon.atUtcOffset(algiers).toIso8601String()}');
  print('  sunset             ${show(times.sunset)}');
  print('  civil dusk         ${show(times.civilDusk)}');
  print('  day length         ${times.dayLength}');
  print('  evening golden hr  ${show(times.eveningGoldenHour.start)} '
      '-> ${show(times.eveningGoldenHour.end)}');

  // Custom altitude: the Sun's centre 18 degrees below the horizon.
  final minus18 = times.timeForSunAltitude(-18);
  print('  -18 deg rising     ${show(minus18.rising)}');

  // Where is the Sun right now at noon UTC?
  final p = sunPosition(DateTime.utc(2026, 3, 20, 12),
      latitude: 36.75, longitude: 3.06);
  print('  12:00Z position    azimuth ${p.azimuth.toStringAsFixed(2)} deg, '
      'elevation ${p.elevation.toStringAsFixed(2)} deg');

  // Polar night in Tromsø: an explicit result, not NaN.
  final tromso = SunTimes(
      date: DateTime(2026, 12, 21), latitude: 69.6492, longitude: 18.9553);
  print('Tromsø, 21 December 2026: sunrise = ${tromso.sunrise}, '
      'civil dawn = ${tromso.civilDawn}');
}
