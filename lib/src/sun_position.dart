import 'dart:math' as math;

import 'noaa.dart';

/// Where the Sun is in the sky at one instant, seen from one place.
final class SunPosition {
  /// Creates a position. Normally obtained from [sunPosition].
  const SunPosition({
    required this.azimuth,
    required this.elevation,
    required this.declination,
    required this.equationOfTime,
  });

  /// Azimuth in degrees clockwise from true north, in `[0, 360)`.
  final double azimuth;

  /// Elevation (altitude) of the Sun's centre above the horizon in degrees,
  /// in `[-90, 90]`. Includes refraction when it was requested.
  final double elevation;

  /// Solar declination in degrees.
  final double declination;

  /// Equation of time in minutes (apparent minus mean solar time).
  final double equationOfTime;

  /// Zenith angle in degrees: `90 - elevation`.
  double get zenith => 90 - elevation;

  @override
  String toString() => 'SunPosition(azimuth: ${azimuth.toStringAsFixed(3)}, '
      'elevation: ${elevation.toStringAsFixed(3)})';
}

/// The Sun's position at [instant] for an observer at [latitude] (degrees,
/// north positive) and [longitude] (degrees, east positive).
///
/// [instant] may be in any time zone; it is converted to UTC.
///
/// When [applyRefraction] is true (the default) the elevation includes NOAA's
/// approximate atmospheric-refraction correction, i.e. it is the apparent
/// elevation. Pass false for the geometric (airless) elevation.
///
/// Throws [ArgumentError] for out-of-range or non-finite coordinates.
SunPosition sunPosition(
  DateTime instant, {
  required double latitude,
  required double longitude,
  bool applyRefraction = true,
}) {
  checkCoordinates(latitude, longitude);
  final utc = instant.toUtc();
  final jd = julianDay(utc);
  final c = solarCoordinates(julianCentury(jd));

  final minutesOfDay = utc.hour * 60 +
      utc.minute +
      utc.second / 60 +
      utc.millisecond / 60000 +
      utc.microsecond / 6e7;
  var hourAngle = (minutesOfDay + c.equationOfTime + 4 * longitude) / 4 - 180;
  hourAngle = (hourAngle + 180) % 360 - 180;

  final lat = rad(latitude);
  final dec = rad(c.declination);
  final ha = rad(hourAngle);

  final sinEl = (math.sin(lat) * math.sin(dec) +
          math.cos(lat) * math.cos(dec) * math.cos(ha))
      .clamp(-1.0, 1.0);
  var elevation = deg(math.asin(sinEl));

  final az = deg(math.atan2(math.sin(ha),
          math.cos(ha) * math.sin(lat) - math.tan(dec) * math.cos(lat))) +
      180;
  final azimuth = az % 360;

  if (applyRefraction) {
    elevation = math.min(90.0, elevation + refraction(elevation));
  }
  return SunPosition(
    azimuth: azimuth,
    elevation: elevation,
    declination: c.declination,
    equationOfTime: c.equationOfTime,
  );
}
