# solar_events

Dependency-free solar calculations for Dart: sunrise, sunset, solar noon, twilights,
golden and blue hour, the time the Sun reaches any altitude, and the Sun's position.
It is based on the NOAA solar calculator equations (after Meeus) and has explicit
results for polar day and polar night.

[![pub package](https://img.shields.io/pub/v/solar_events.svg)](https://pub.dev/packages/solar_events)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- For a date, latitude, longitude and optional observer elevation you get:
  - sunrise, sunset, solar noon and day length;
  - civil (-6°), nautical (-12°) and astronomical (-18°) dawn and dusk;
  - morning and evening golden hour (-4° to +6°) and blue hour (-6° to -4°).
- `timeForSunAltitude(degrees)` gives the rising and setting crossings of any solar
  altitude.
- `sunPosition(instant, ...)` gives the Sun's azimuth and elevation at any instant,
  with optional atmospheric-refraction correction. It also returns the declination
  and the equation of time.
- Polar day and polar night come back as `SunEvent.alwaysUp` or
  `SunEvent.alwaysDown`, never as `NaN` or a made-up `DateTime`.
- All times are UTC `DateTime`s. `atUtcOffset(Duration)` turns one into wall-clock time
  for display. The package has no time-zone database and no dependencies.
- It is pure Dart, so it works on every platform, including Flutter and the web.

## Install

```sh
dart pub add solar_events
```

## Usage

```dart
import 'package:solar_events/solar_events.dart';

void main() {
  const algiers = Duration(hours: 1); // UTC+01:00
  final times = SunTimes(
    date: DateTime(2026, 3, 20),
    latitude: 36.75,
    longitude: 3.06,
    utcOffset: algiers, // which local day "20 March" means
  );

  String show(SunEvent e) => switch (e) {
        SunEventAt(:final time) => time.atUtcOffset(algiers).toIso8601String(),
        SunAlwaysUp() => 'Sun up all day',
        SunAlwaysDown() => 'Sun down all day',
      };

  print(show(times.sunrise)); // 2026-03-20T06:51:32+01:00
  print(show(times.sunset)); // 2026-03-20T18:59:27+01:00
  print(times.solarNoon); // 2026-03-20 11:55:12.000Z
  print(times.dayLength); // 12:07:55.000000
  print(show(times.civilDawn)); // 2026-03-20T06:25:45+01:00
  print(show(times.eveningGoldenHour.start)); // 2026-03-20T18:25:17+01:00

  // Any altitude: the Sun's centre 18° below the horizon.
  final c = times.timeForSunAltitude(-18);
  print(show(c.rising)); // 2026-03-20T05:25:05+01:00

  // The Sun's position at an instant.
  final p = sunPosition(DateTime.utc(2026, 3, 20, 12),
      latitude: 36.75, longitude: 3.06);
  print('${p.azimuth} ${p.elevation}'); // ~182.01 ~53.20
}
```

A runnable version is in [`example/main.dart`](example/main.dart).

### Which day?

The package returns the events around the solar noon closest to 12:00 local time on
`date` at `utcOffset`. In Suva (UTC+12), for example, the sunrise of 20 March falls on
19 March in UTC. If you leave out `utcOffset`, the package uses the longitude's local
mean solar time (`longitude / 15` hours). That picks the same day as the civil time
zone in almost every place.

### Polar day and night

```dart
final t = SunTimes(date: DateTime(2026, 12, 21), latitude: 69.6492, longitude: 18.9553);
t.sunrise;   // SunEvent.alwaysDown (polar night in Tromsø)
t.civilDawn; // SunEvent.at(2026-12-21T08:31:13.000Z): civil twilight still happens
t.dayLength; // Duration.zero
```

`alwaysUp` means the Sun stays above the altitude asked about all day. `alwaysDown`
means it stays below it all day. `SunEvent.time` is `null` in both cases.

### Elevation

`elevation` is the observer's height in metres above the surrounding horizon. It lowers
the visible horizon by the Nautical Almanac dip, `1.76′ × √metres`, so sunrise comes
earlier and sunset later. It affects only sunrise and sunset. Twilight, the golden and
blue hours and `timeForSunAltitude` are defined by the Sun's true altitude, so
elevation does not change them.

### Building prayer times on top

This package does **not** compute prayer times. It does give a prayer-time library what
it needs:

- Fajr and Isha are the rising and setting crossings of a method-specific depression
  angle, for example `timeForSunAltitude(-18).rising`.
- Dhuhr is based on `solarNoon`.
- For Asr, take the declination δ from `sunPosition(solarNoon, ...)`. Compute
  `a = atan(1 / (k + tan(|φ − δ|)))` with shadow factor k = 1 or 2, then use
  `timeForSunAltitude(a).setting`.
- Maghrib is based on `sunset`.

High-latitude rules and method parameters belong in that library.

## Accuracy

The core equations are the ones in NOAA's solar calculator. That includes the
spreadsheet formulas and the web calculator's `main.js`. NOAA states that its sunrise
and sunset results are "theoretically accurate to within a minute for locations between
+/- 72° latitude, and within 10 minutes outside of those latitudes". This package goes
further than NOAA's two-pass estimate: it iterates each event until it converges, using
the declination and equation of time at the event itself. Results are rounded to the
second.

The test suite measured the following against the reference values:

| Comparison | Places | Max difference |
|---|---|---|
| Sunrise/sunset vs NOAA calculator | Algiers ×3, Tamanrasset ×2, London ×2, Tromsø (equinox), Ushuaia ×2, Suva ×2 | 0 s (rounded) |
| All sunrise/sunset/twilight events vs PyEphem | all of the above, plus Apia | 6 s |
| Solar noon vs PyEphem | all | 1 s |
| Solar noon vs NOAA web calculator | all | 15 s (NOAA's own two-pass noon is the less accurate one) |
| Azimuth and elevation vs the NOAA spreadsheet worked example | 40° N 105° W, 21 June 2010 | < 0.001° |

The tests fail when a difference exceeds **1 minute for |latitude| < 65°** or 3 minutes
above that. Expect **1–2 minutes of real-world accuracy for |latitude| < 65°**. The
remaining uncertainty is atmospheric: the standard 34′ of refraction at the horizon
changes with temperature and pressure, and near the poles the Sun crosses the horizon at
such a shallow angle that a small change in altitude moves the time a lot.

## Limitations

- The equations are NOAA's low-precision solar theory. They are very good for
  1800–2100, NOAA calls them usable from −1000 to 3000, and they are not
  ephemeris-grade.
- ΔT (TT − UT) is ignored, as in NOAA's calculator. This changes results by well under a
  second.
- Refraction is a fixed standard value: 34′ at the horizon (which, with the 16′ solar
  semidiameter, gives the 0.833° sunrise altitude), plus NOAA's elevation-dependent
  model in `sunPosition`. The package does not take temperature or
  pressure as input.
- Near the start and end of polar day or polar night, the Sun skims the horizon.
  There, a crossing can be missing on one side of noon only, and times are less
  accurate (NOAA gives up to 10 minutes beyond 72°).
- The observer-elevation dip assumes a flat, unobstructed horizon at sea level. Terrain
  is not modelled.
- Golden hour (-4° to +6°) and blue hour (-6° to -4°) have no official definition.
  These are common photography conventions. For other bounds, use
  `timeForSunAltitude`.
- The package has no time-zone database. Supply the UTC offset yourself.
- US Naval Observatory data could not be reached while the package was being built,
  because the service reset connections. The independent cross-check therefore uses
  PyEphem instead. See below.

## Data sources

The package contains no datasets. The test reference values in
`test/reference_data.dart` were generated on 2026-09-24 from three sources:

- **NOAA Global Monitoring Laboratory solar calculator.** The calculation functions
  of <https://gml.noaa.gov/grad/solcalc/main.js> were run unmodified under Node.js
  to get sunrise, sunset and solar noon. This is a US Government work in the
  public domain.
- **NOAA `NOAA_Solar_Calculations_day.ods`**
  (<https://gml.noaa.gov/grad/solcalc/calcdetails.html>). The tests use its shipped
  worked example (40° N, 105° W, UTC−7, 21 June 2010): the cached cell values for
  elevation, azimuth, declination and equation of time.
- **PyEphem 4.2.1** (<https://rhodesmill.org/pyephem/>, MIT license). It is an
  independent VSOP87-based implementation. Sunrise and sunset follow the USNO
  convention (upper limb, 34′ refraction). Twilights use the Sun's centre.

The dip formula `1.76′ √h(m)` comes from the Nautical Almanac and Bowditch, *The
American Practical Navigator*, Appendix B.

## License

MIT. See [LICENSE](LICENSE).

Made by [Abdeldjalil Chougui](https://abdeldjalilchougui.biz/).
