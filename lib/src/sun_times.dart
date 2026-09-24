import 'dart:math' as math;

import 'noaa.dart';
import 'sun_event.dart';

/// Solar altitude of the Sun's centre at sunrise/sunset for a sea-level
/// observer: 34' of standard refraction plus 16' of solar semidiameter.
const double sunriseAltitude = -0.833;

/// Altitude that defines civil twilight.
const double civilTwilightAltitude = -6;

/// Altitude that defines nautical twilight.
const double nauticalTwilightAltitude = -12;

/// Altitude that defines astronomical twilight.
const double astronomicalTwilightAltitude = -18;

/// Lower altitude of the golden hour (and upper altitude of the blue hour).
const double goldenHourLowAltitude = -4;

/// Upper altitude of the golden hour.
const double goldenHourHighAltitude = 6;

/// Lower altitude of the blue hour.
const double blueHourLowAltitude = -6;

/// Sunrise, sunset, solar noon, twilights, golden/blue hours and custom
/// altitude crossings for one local day at one place.
///
/// All times are UTC. Every event is a [SunEvent]: either a time, or
/// [SunEvent.alwaysUp] / [SunEvent.alwaysDown] when the Sun never crosses the
/// altitude that day (polar day / polar night).
///
/// Which day? The events are those around the solar noon closest to 12:00
/// local time on [date] at [utcOffset]. So the sunrise of 20 March in Suva
/// (UTC+12) is on 19 March in UTC. When [utcOffset] is omitted, the local
/// mean solar time of [longitude] is used (`longitude / 15` hours), which
/// picks the same day as the civil time zone almost everywhere.
///
/// Values are computed lazily and cached.
final class SunTimes {
  /// Computes solar events for [date] (only its year, month and day are
  /// used) at [latitude] (degrees, north positive) and [longitude] (degrees,
  /// east positive).
  ///
  /// [elevation] is the observer's height above the surrounding horizon in
  /// metres. It lowers the visible horizon by the dip `1.76' * sqrt(metres)`
  /// and so makes sunrise earlier and sunset later. It does not affect
  /// twilight, the golden/blue hours or [timeForSunAltitude], which are
  /// defined by the Sun's true altitude.
  ///
  /// Throws [ArgumentError] for out-of-range coordinates or a negative or
  /// non-finite [elevation].
  SunTimes({
    required DateTime date,
    required this.latitude,
    required this.longitude,
    this.elevation = 0,
    Duration? utcOffset,
  })  : utcOffset = utcOffset ??
            Duration(microseconds: (longitude / 15 * 3.6e9).round()),
        date = DateTime.utc(date.year, date.month, date.day) {
    checkCoordinates(latitude, longitude);
    if (!(elevation >= 0) || !elevation.isFinite) {
      throw ArgumentError.value(
          elevation, 'elevation', 'must be a finite number of metres >= 0');
    }
  }

  /// The local calendar day, as midnight UTC of that date.
  final DateTime date;

  /// Latitude in degrees, north positive.
  final double latitude;

  /// Longitude in degrees, east positive.
  final double longitude;

  /// Observer height in metres above the horizon.
  final double elevation;

  /// Offset of local time from UTC, used only to decide which day [date] is.
  final Duration utcOffset;

  final Map<double, SunCrossings> _cache = {};

  /// Julian Day of solar noon.
  late final double _noonJd = _computeNoon();

  /// Julian Day of the UTC midnight that [_noonJd] is measured from.
  late double _base;

  double _computeNoon() {
    final localNoon =
        julianDay(date) + 0.5 - utcOffset.inMicroseconds / 8.64e10;
    _base = (localNoon - 0.5).floorToDouble() + 0.5;
    double transit(double eot) => _base + (720 - 4 * longitude - eot) / 1440;
    var noon = transit(0);
    // Pick the transit nearest local noon.
    while (noon - localNoon > 0.5) {
      _base -= 1;
      noon -= 1;
    }
    while (noon - localNoon < -0.5) {
      _base += 1;
      noon += 1;
    }
    for (var i = 0; i < 10; i++) {
      final next =
          transit(solarCoordinates(julianCentury(noon)).equationOfTime);
      final done = (next - noon).abs() < 1e-9;
      noon = next;
      if (done) break;
    }
    return noon;
  }

  /// Solar noon (upper transit): the Sun is highest and due south or north.
  late final DateTime solarNoon = dateTimeFromJulianDay(_noonJd);

  /// Sunrise: the upper limb touches the (dipped) horizon, with standard
  /// refraction.
  SunEvent get sunrise => _horizon.rising;

  /// Sunset: the upper limb touches the (dipped) horizon, with standard
  /// refraction.
  SunEvent get sunset => _horizon.setting;

  late final SunCrossings _horizon = _crossings(
      sunriseAltitude - 1.76 / 60 * math.sqrt(elevation),
      cache: elevation == 0);

  /// Start of civil twilight (Sun at -6 degrees, rising).
  SunEvent get civilDawn => timeForSunAltitude(civilTwilightAltitude).rising;

  /// End of civil twilight (Sun at -6 degrees, setting).
  SunEvent get civilDusk => timeForSunAltitude(civilTwilightAltitude).setting;

  /// Start of nautical twilight (Sun at -12 degrees, rising).
  SunEvent get nauticalDawn =>
      timeForSunAltitude(nauticalTwilightAltitude).rising;

  /// End of nautical twilight (Sun at -12 degrees, setting).
  SunEvent get nauticalDusk =>
      timeForSunAltitude(nauticalTwilightAltitude).setting;

  /// Start of astronomical twilight (Sun at -18 degrees, rising).
  SunEvent get astronomicalDawn =>
      timeForSunAltitude(astronomicalTwilightAltitude).rising;

  /// End of astronomical twilight (Sun at -18 degrees, setting).
  SunEvent get astronomicalDusk =>
      timeForSunAltitude(astronomicalTwilightAltitude).setting;

  /// Morning golden hour: Sun rising from -4 to +6 degrees.
  SunWindow get morningGoldenHour => SunWindow(
        timeForSunAltitude(goldenHourLowAltitude).rising,
        timeForSunAltitude(goldenHourHighAltitude).rising,
      );

  /// Evening golden hour: Sun setting from +6 to -4 degrees.
  SunWindow get eveningGoldenHour => SunWindow(
        timeForSunAltitude(goldenHourHighAltitude).setting,
        timeForSunAltitude(goldenHourLowAltitude).setting,
      );

  /// Morning blue hour: Sun rising from -6 to -4 degrees.
  SunWindow get morningBlueHour => SunWindow(
        timeForSunAltitude(blueHourLowAltitude).rising,
        timeForSunAltitude(goldenHourLowAltitude).rising,
      );

  /// Evening blue hour: Sun setting from -4 to -6 degrees.
  SunWindow get eveningBlueHour => SunWindow(
        timeForSunAltitude(goldenHourLowAltitude).setting,
        timeForSunAltitude(blueHourLowAltitude).setting,
      );

  /// Time between [sunrise] and [sunset].
  ///
  /// 24 hours during polar day, zero during polar night. On the rare
  /// transition day where only one of the two occurs, the missing bound is
  /// taken as 12 hours from solar noon (if the Sun is up) or as solar noon
  /// itself (if it is down).
  Duration get dayLength {
    DateTime bound(SunEvent e, int sign) => switch (e) {
          SunEventAt(:final time) => time,
          SunAlwaysUp() => solarNoon.add(Duration(hours: 12 * sign)),
          SunAlwaysDown() => solarNoon,
        };
    return bound(sunset, 1).difference(bound(sunrise, -1));
  }

  /// When the centre of the Sun crosses [altitude] degrees (geometric, no
  /// refraction) before and after solar noon.
  ///
  /// `timeForSunAltitude(-18)` gives astronomical dawn and dusk. Prayer-time
  /// libraries can build on this: Fajr and Isha are crossings of a
  /// method-specific negative altitude, and Asr is the setting crossing of
  /// the altitude `atan(1 / (k + tan(|latitude - declination|)))`, where the
  /// declination comes from `sunPosition(solarNoon, ...)`. This package does
  /// not implement prayer times itself.
  ///
  /// Throws [ArgumentError] unless `-90 <= altitude <= 90`.
  SunCrossings timeForSunAltitude(double altitude) {
    if (!(altitude >= -90 && altitude <= 90)) {
      throw ArgumentError.value(
          altitude, 'altitude', 'must be between -90 and 90 degrees');
    }
    return _crossings(altitude);
  }

  SunCrossings _crossings(double altitude, {bool cache = true}) {
    if (cache) {
      final hit = _cache[altitude];
      if (hit != null) return hit;
    }
    final result = SunCrossings(
      rising: _crossing(altitude, rising: true),
      setting: _crossing(altitude, rising: false),
    );
    if (cache) _cache[altitude] = result;
    return result;
  }

  SunEvent _crossing(double altitude, {required bool rising}) {
    final noon = _noonJd;
    // Keep cos(latitude) non-zero at the poles; the hour-angle equation then
    // correctly reports "always up/down".
    final lat = rad(latitude.clamp(-89.999999, 89.999999));
    final sinH0 = math.sin(rad(altitude));
    var t = noon;
    for (var i = 0; i < 30; i++) {
      final c = solarCoordinates(julianCentury(t));
      final dec = rad(c.declination);
      final cosH = (sinH0 - math.sin(lat) * math.sin(dec)) /
          (math.cos(lat) * math.cos(dec));
      if (cosH > 1) return SunEvent.alwaysDown;
      if (cosH < -1) return SunEvent.alwaysUp;
      final h = deg(math.acos(cosH));
      final transit = _base + (720 - 4 * longitude - c.equationOfTime) / 1440;
      final next = transit + (rising ? -h : h) / 360;
      final done = (next - t).abs() < 1e-8;
      t = next;
      if (done) break;
    }
    return SunEvent.at(dateTimeFromJulianDay(t));
  }

  @override
  String toString() => 'SunTimes(${date.toIso8601String().substring(0, 10)}, '
      '$latitude, $longitude)';
}
