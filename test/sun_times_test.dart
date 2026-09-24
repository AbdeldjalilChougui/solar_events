import 'package:sun_times/sun_times.dart';
import 'package:test/test.dart';

const _algiersLat = 36.75;
const _algiersLon = 3.06;

SunTimes _algiers(DateTime date, {double elevation = 0}) => SunTimes(
      date: date,
      latitude: _algiersLat,
      longitude: _algiersLon,
      elevation: elevation,
      utcOffset: const Duration(hours: 1),
    );

double _geometricElevation(DateTime t, double lat, double lon) =>
    sunPosition(t, latitude: lat, longitude: lon, applyRefraction: false)
        .elevation;

void main() {
  group('SunEvent', () {
    test('at() carries a UTC time', () {
      final e = SunEvent.at(DateTime.utc(2026, 1, 1, 6));
      expect(e.occurs, isTrue);
      expect(e.time, DateTime.utc(2026, 1, 1, 6));
      expect(e, SunEvent.at(DateTime.utc(2026, 1, 1, 6)));
      expect(e, isA<SunEventAt>());
    });

    test('at() normalises a local DateTime to UTC', () {
      final local = DateTime(2026, 1, 1, 6);
      expect(SunEvent.at(local).time!.isUtc, isTrue);
      expect(SunEvent.at(local).time, local.toUtc());
    });

    test('polar results have no time', () {
      expect(SunEvent.alwaysUp.occurs, isFalse);
      expect(SunEvent.alwaysUp.time, isNull);
      expect(SunEvent.alwaysDown.time, isNull);
      expect(SunEvent.alwaysUp, isNot(SunEvent.alwaysDown));
    });

    test('is exhaustively switchable', () {
      String describe(SunEvent e) => switch (e) {
            SunEventAt(:final time) => 'at ${time.hour}',
            SunAlwaysUp() => 'up',
            SunAlwaysDown() => 'down',
          };
      expect(describe(SunEvent.at(DateTime.utc(2026, 1, 1, 6))), 'at 6');
      expect(describe(SunEvent.alwaysUp), 'up');
      expect(describe(SunEvent.alwaysDown), 'down');
    });
  });

  group('SunTimes basics', () {
    final t = _algiers(DateTime(2026, 3, 20));

    test('events are ordered through the day', () {
      final order = [
        t.astronomicalDawn,
        t.nauticalDawn,
        t.civilDawn,
        t.sunrise,
        SunEvent.at(t.solarNoon),
        t.sunset,
        t.civilDusk,
        t.nauticalDusk,
        t.astronomicalDusk,
      ].map((e) => e.time!).toList();
      for (var i = 1; i < order.length; i++) {
        expect(order[i].isAfter(order[i - 1]), isTrue, reason: 'index $i');
      }
    });

    test('day length is sunset minus sunrise', () {
      expect(t.dayLength, t.sunset.time!.difference(t.sunrise.time!));
      expect(t.dayLength.inMinutes, inInclusiveRange(12 * 60, 12 * 60 + 12));
    });

    test('solar noon is the highest point of the day', () {
      final noon = _geometricElevation(t.solarNoon, _algiersLat, _algiersLon);
      for (final m in [-10, 10]) {
        final other = _geometricElevation(
            t.solarNoon.add(Duration(minutes: m)), _algiersLat, _algiersLon);
        expect(noon, greaterThan(other));
      }
    });

    test('twilight events sit at their defining solar altitudes', () {
      final cases = {
        -6.0: [t.civilDawn, t.civilDusk],
        -12.0: [t.nauticalDawn, t.nauticalDusk],
        -18.0: [t.astronomicalDawn, t.astronomicalDusk],
      };
      cases.forEach((alt, events) {
        for (final e in events) {
          expect(_geometricElevation(e.time!, _algiersLat, _algiersLon),
              closeTo(alt, 0.01));
        }
      });
    });

    test('sunrise and sunset sit at -0.833 degrees', () {
      for (final e in [t.sunrise, t.sunset]) {
        expect(_geometricElevation(e.time!, _algiersLat, _algiersLon),
            closeTo(-0.833, 0.01));
      }
    });

    test('only year, month and day of the date are used', () {
      final a = _algiers(DateTime(2026, 3, 20, 23, 59));
      final b = _algiers(DateTime.utc(2026, 3, 20));
      expect(a.sunrise, t.sunrise);
      expect(b.sunset, t.sunset);
    });
  });

  group('timeForSunAltitude', () {
    final t = _algiers(DateTime(2026, 6, 21));

    test('-18 matches astronomical twilight', () {
      final c = t.timeForSunAltitude(-18);
      expect(c.rising, t.astronomicalDawn);
      expect(c.setting, t.astronomicalDusk);
    });

    test('a positive altitude is crossed after sunrise and before sunset', () {
      final c = t.timeForSunAltitude(30);
      expect(c.rising.time!.isAfter(t.sunrise.time!), isTrue);
      expect(c.setting.time!.isBefore(t.sunset.time!), isTrue);
      expect(_geometricElevation(c.rising.time!, _algiersLat, _algiersLon),
          closeTo(30, 0.01));
      expect(_geometricElevation(c.setting.time!, _algiersLat, _algiersLon),
          closeTo(30, 0.01));
    });

    test('an altitude above the noon maximum is never reached', () {
      // Noon altitude at Algiers on the June solstice is about 76.7 degrees.
      final c = t.timeForSunAltitude(80);
      expect(c.rising, SunEvent.alwaysDown);
      expect(c.setting, SunEvent.alwaysDown);
    });

    test('rejects altitudes outside [-90, 90]', () {
      expect(() => t.timeForSunAltitude(-91), throwsArgumentError);
      expect(() => t.timeForSunAltitude(double.nan), throwsArgumentError);
    });
  });

  group('golden and blue hour', () {
    final t = _algiers(DateTime(2026, 12, 21));

    test('morning: blue hour -6..-4, then golden hour -4..+6', () {
      expect(t.morningBlueHour.start, t.timeForSunAltitude(-6).rising);
      expect(t.morningBlueHour.end, t.timeForSunAltitude(-4).rising);
      expect(t.morningGoldenHour.start, t.timeForSunAltitude(-4).rising);
      expect(t.morningGoldenHour.end, t.timeForSunAltitude(6).rising);
    });

    test('evening: golden hour +6..-4, then blue hour -4..-6', () {
      expect(t.eveningGoldenHour.start, t.timeForSunAltitude(6).setting);
      expect(t.eveningGoldenHour.end, t.timeForSunAltitude(-4).setting);
      expect(t.eveningBlueHour.start, t.timeForSunAltitude(-4).setting);
      expect(t.eveningBlueHour.end, t.timeForSunAltitude(-6).setting);
    });

    test('windows have a positive duration', () {
      for (final w in [
        t.morningBlueHour,
        t.morningGoldenHour,
        t.eveningGoldenHour,
        t.eveningBlueHour,
      ]) {
        expect(w.duration, isNotNull);
        expect(w.duration! > Duration.zero, isTrue);
        expect(w.duration! < const Duration(hours: 2), isTrue);
      }
    });

    test('golden hour never ends when the Sun stays below +6 degrees', () {
      final tromso = SunTimes(
          date: DateTime(2026, 12, 21), latitude: 69.6492, longitude: 18.9553);
      expect(tromso.morningGoldenHour.end, SunEvent.alwaysDown);
      expect(tromso.morningGoldenHour.duration, isNull);
    });
  });

  group('polar handling', () {
    SunTimes tromso(DateTime d) =>
        SunTimes(date: d, latitude: 69.6492, longitude: 18.9553);

    test('midnight sun: no NaN, no bogus DateTime', () {
      final t = tromso(DateTime(2026, 6, 21));
      expect(t.sunrise, SunEvent.alwaysUp);
      expect(t.sunset, SunEvent.alwaysUp);
      expect(t.dayLength, const Duration(hours: 24));
      expect(t.solarNoon.isUtc, isTrue);
    });

    test('polar night: the Sun never rises but civil twilight happens', () {
      final t = tromso(DateTime(2026, 12, 21));
      expect(t.sunrise, SunEvent.alwaysDown);
      expect(t.sunset, SunEvent.alwaysDown);
      expect(t.dayLength, Duration.zero);
      expect(t.civilDawn.occurs, isTrue);
      expect(t.civilDusk.occurs, isTrue);
    });

    test('North Pole at the June solstice and South Pole at the same time', () {
      final north =
          SunTimes(date: DateTime(2026, 6, 21), latitude: 90, longitude: 0);
      final south =
          SunTimes(date: DateTime(2026, 6, 21), latitude: -90, longitude: 0);
      expect(north.sunrise, SunEvent.alwaysUp);
      expect(north.astronomicalDusk, SunEvent.alwaysUp);
      expect(south.sunrise, SunEvent.alwaysDown);
      expect(south.astronomicalDawn, SunEvent.alwaysDown);
    });

    test('every day of a year at 78 N gives a time or a polar result', () {
      var day = DateTime.utc(2026);
      while (day.year == 2026) {
        final t = SunTimes(date: day, latitude: 78.22, longitude: 15.65);
        for (final e in [t.sunrise, t.sunset, t.civilDawn, t.civilDusk]) {
          if (e case SunEventAt(:final time)) {
            expect(time.isUtc, isTrue);
            expect(time.difference(day).inHours.abs(), lessThan(48));
          }
        }
        expect(t.dayLength.inMinutes, inInclusiveRange(0, 24 * 60));
        day = day.add(const Duration(days: 1));
      }
    });
  });

  group('observer elevation', () {
    test('a higher observer sees an earlier sunrise and later sunset', () {
      final sea = _algiers(DateTime(2026, 3, 20));
      final high = _algiers(DateTime(2026, 3, 20), elevation: 1000);
      expect(high.sunrise.time!.isBefore(sea.sunrise.time!), isTrue);
      expect(high.sunset.time!.isAfter(sea.sunset.time!), isTrue);
      // Dip at 1000 m is 1.76' * sqrt(1000) = 55.7', about 0.93 degrees.
      final depressed =
          _geometricElevation(high.sunrise.time!, _algiersLat, _algiersLon);
      expect(depressed, closeTo(-0.833 - 1.76 * 31.6228 / 60, 0.01));
    });

    test('elevation does not change twilight or solar noon', () {
      final sea = _algiers(DateTime(2026, 3, 20));
      final high = _algiers(DateTime(2026, 3, 20), elevation: 1000);
      expect(high.civilDawn, sea.civilDawn);
      expect(high.solarNoon, sea.solarNoon);
    });

    test('negative elevation is rejected', () {
      expect(() => _algiers(DateTime(2026, 3, 20), elevation: -1),
          throwsArgumentError);
    });
  });

  group('local day selection', () {
    test('Suva (UTC+12): the local-date sunrise falls on the previous UTC day',
        () {
      final t = SunTimes(
        date: DateTime(2026, 3, 20),
        latitude: -18.1416,
        longitude: 178.4419,
        utcOffset: const Duration(hours: 12),
      );
      expect(t.sunrise.time!.day, 19);
      expect(t.sunset.time!.day, 20);
      final local = t.sunrise.time!.atUtcOffset(const Duration(hours: 12));
      expect(local.local.day, 20);
      expect(local.local.hour, 6);
    });

    test('default offset follows longitude (mean solar time)', () {
      final byDefault = SunTimes(
          date: DateTime(2026, 3, 20), latitude: -18.1416, longitude: 178.4419);
      final explicit = SunTimes(
        date: DateTime(2026, 3, 20),
        latitude: -18.1416,
        longitude: 178.4419,
        utcOffset: const Duration(hours: 12),
      );
      expect(byDefault.sunrise, explicit.sunrise);
      expect(byDefault.solarNoon, explicit.solarNoon);
    });

    test('rejects out-of-range coordinates', () {
      expect(
          () => SunTimes(date: DateTime(2026), latitude: -90.5, longitude: 0),
          throwsArgumentError);
      expect(() => SunTimes(date: DateTime(2026), latitude: 0, longitude: 200),
          throwsArgumentError);
    });
  });

  group('OffsetDateTime', () {
    final utc = DateTime.utc(2026, 3, 19, 18, 9, 56);

    test('applies the offset to the wall clock', () {
      final o = utc.atUtcOffset(const Duration(hours: 12));
      expect(o.utc, utc);
      expect(o.offset, const Duration(hours: 12));
      expect(o.local, DateTime.utc(2026, 3, 20, 6, 9, 56));
      expect(o.toIso8601String(), '2026-03-20T06:09:56+12:00');
    });

    test('formats negative and fractional offsets', () {
      expect(
          utc
              .atUtcOffset(const Duration(hours: -3, minutes: -30))
              .toIso8601String(),
          '2026-03-19T14:39:56-03:30');
      expect(utc.atUtcOffset(Duration.zero).toIso8601String(),
          '2026-03-19T18:09:56+00:00');
    });

    test('converts a non-UTC input to UTC first', () {
      final local = utc.toLocal();
      expect(local.atUtcOffset(Duration.zero).utc, utc);
    });

    test('equality uses both instant and offset', () {
      expect(utc.atUtcOffset(const Duration(hours: 1)),
          utc.atUtcOffset(const Duration(hours: 1)));
      expect(utc.atUtcOffset(const Duration(hours: 1)),
          isNot(utc.atUtcOffset(const Duration(hours: 2))));
    });
  });
}
