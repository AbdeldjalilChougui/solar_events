// Solar-position equations from the NOAA Global Monitoring Laboratory solar
// calculator (NOAA_Solar_Calculations_day.xls/.ods and solcalc/main.js),
// which in turn follow Jean Meeus, "Astronomical Algorithms".
//
// Internal: not exported from the package.

import 'dart:math' as math;

const double _deg = math.pi / 180.0;

/// Degrees to radians.
double rad(double degrees) => degrees * _deg;

/// Radians to degrees.
double deg(double radians) => radians / _deg;

/// Julian Day of an instant (any DateTime; converted to UTC).
///
/// Uses the Unix epoch, so unlike the spreadsheet's approximation it is valid
/// for every date DateTime can represent.
double julianDay(DateTime instant) =>
    instant.toUtc().microsecondsSinceEpoch / 8.64e10 + 2440587.5;

/// UTC DateTime of a Julian Day, rounded to the millisecond.
DateTime dateTimeFromJulianDay(double jd) =>
    DateTime.fromMillisecondsSinceEpoch(((jd - 2440587.5) * 8.64e7).round(),
        isUtc: true);

/// Julian centuries since J2000.0.
double julianCentury(double jd) => (jd - 2451545.0) / 36525.0;

/// Declination (degrees) and equation of time (minutes) at [t] Julian
/// centuries.
({double declination, double equationOfTime}) solarCoordinates(double t) {
  final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360.0;
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final mRad = rad(m);
  final c = math.sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * mRad) * (0.019993 - 0.000101 * t) +
      math.sin(3 * mRad) * 0.000289;
  final trueLong = l0 + c;
  final omega = rad(125.04 - 1934.136 * t);
  final appLong = trueLong - 0.00569 - 0.00478 * math.sin(omega);
  final seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
  final meanObliq = 23.0 + (26.0 + seconds / 60.0) / 60.0;
  final obliq = meanObliq + 0.00256 * math.cos(omega);

  final declination =
      deg(math.asin(math.sin(rad(obliq)) * math.sin(rad(appLong))));

  var y = math.tan(rad(obliq) / 2);
  y *= y;
  final l0Rad = rad(l0);
  final eot = y * math.sin(2 * l0Rad) -
      2 * e * math.sin(mRad) +
      4 * e * y * math.sin(mRad) * math.cos(2 * l0Rad) -
      0.5 * y * y * math.sin(4 * l0Rad) -
      1.25 * e * e * math.sin(2 * mRad);
  return (declination: declination, equationOfTime: 4 * deg(eot));
}

/// NOAA's approximate atmospheric refraction (degrees) for a geometric
/// elevation in degrees.
double refraction(double elevation) {
  if (elevation > 85.0) return 0;
  final te = math.tan(rad(elevation));
  final double arcsec;
  if (elevation > 5.0) {
    arcsec = 58.1 / te - 0.07 / (te * te * te) + 0.000086 / math.pow(te, 5);
  } else if (elevation > -0.575) {
    arcsec = 1735.0 +
        elevation *
            (-518.2 +
                elevation * (103.4 + elevation * (-12.79 + elevation * 0.711)));
  } else {
    arcsec = -20.772 / te;
  }
  return arcsec / 3600.0;
}

/// Throws [ArgumentError] unless latitude/longitude are finite and in range.
void checkCoordinates(double latitude, double longitude) {
  if (!(latitude >= -90 && latitude <= 90)) {
    throw ArgumentError.value(
        latitude, 'latitude', 'must be between -90 and 90');
  }
  if (!(longitude >= -180 && longitude <= 180)) {
    throw ArgumentError.value(
        longitude, 'longitude', 'must be between -180 and 180');
  }
}
