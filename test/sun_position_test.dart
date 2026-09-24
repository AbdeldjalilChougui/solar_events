import 'package:sun_times/sun_times.dart';
import 'package:test/test.dart';

/// Worked example shipped in NOAA's NOAA_Solar_Calculations_day.ods
/// (latitude 40 N, longitude 105 W, time zone -7, 21 June 2010). The values
/// below are the spreadsheet's own cached cell values for the rows at local
/// 06:00, 12:00 and 18:00 (13:00, 19:00 and 01:00+1 UTC).
void main() {
  group('sunPosition vs NOAA spreadsheet worked example', () {
    const lat = 40.0;
    const lon = -105.0;

    test('local noon (2010-06-21T19:00Z)', () {
      final p = sunPosition(DateTime.utc(2010, 6, 21, 19),
          latitude: lat, longitude: lon);
      expect(p.elevation, closeTo(73.4384793439627, 0.001));
      expect(p.azimuth, closeTo(178.533230037881, 0.001));
      expect(p.declination, closeTo(23.4381481561729, 0.0001));
      expect(p.equationOfTime, closeTo(-1.82311100828435, 0.001));
    });

    test('without refraction returns the geometric elevation', () {
      final p = sunPosition(DateTime.utc(2010, 6, 21, 19),
          latitude: lat, longitude: lon, applyRefraction: false);
      expect(p.elevation, closeTo(73.4336789718745, 0.001));
      expect(p.zenith, closeTo(16.5663210281255, 0.001));
    });

    test('morning (2010-06-21T13:00Z)', () {
      final p = sunPosition(DateTime.utc(2010, 6, 21, 13),
          latitude: lat, longitude: lon);
      expect(p.elevation, closeTo(14.5538438427532, 0.001));
      expect(p.azimuth, closeTo(71.3721272242721, 0.001));
    });

    test('evening (2010-06-22T01:00Z)', () {
      final p = sunPosition(DateTime.utc(2010, 6, 22, 1),
          latitude: lat, longitude: lon);
      expect(p.elevation, closeTo(15.2132018370298, 0.001));
      expect(p.azimuth, closeTo(288.099272917031, 0.001));
    });
  });

  group('sunPosition behaviour', () {
    test('azimuth is in [0, 360) and elevation in [-90, 90]', () {
      for (var h = 0; h < 48; h++) {
        final p = sunPosition(DateTime.utc(2026, 3, 20).add(Duration(hours: h)),
            latitude: -54.8, longitude: -68.3);
        expect(p.azimuth, inInclusiveRange(0, 360));
        expect(p.azimuth, lessThan(360));
        expect(p.elevation, inInclusiveRange(-90, 90));
      }
    });

    test('refraction only lifts the Sun and vanishes near the zenith', () {
      final t = DateTime.utc(2026, 6, 21, 11, 49);
      final withR = sunPosition(t, latitude: 36.75, longitude: 3.06);
      final noR = sunPosition(t,
          latitude: 36.75, longitude: 3.06, applyRefraction: false);
      expect(withR.elevation - noR.elevation, inInclusiveRange(0, 0.01));
    });

    test('non-UTC instants are converted, not reinterpreted', () {
      final utc = DateTime.utc(2026, 6, 21, 12);
      final local = utc.toLocal();
      final a = sunPosition(utc, latitude: 10, longitude: 20);
      final b = sunPosition(local, latitude: 10, longitude: 20);
      expect(b.elevation, a.elevation);
      expect(b.azimuth, a.azimuth);
    });

    test('rejects out-of-range coordinates', () {
      final t = DateTime.utc(2026);
      expect(() => sunPosition(t, latitude: 91, longitude: 0),
          throwsArgumentError);
      expect(() => sunPosition(t, latitude: 0, longitude: 181),
          throwsArgumentError);
      expect(() => sunPosition(t, latitude: double.nan, longitude: 0),
          throwsArgumentError);
    });

    test('works exactly at a pole', () {
      final p = sunPosition(DateTime.utc(2026, 6, 21, 12),
          latitude: 90, longitude: 0);
      expect(p.elevation, closeTo(23.44, 0.05));
      expect(p.azimuth.isFinite, isTrue);
    });
  });
}
