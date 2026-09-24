// Reference values used by the accuracy tests.
//
// Two independent sources, both generated on 2026-09-24:
//
// * `noaa`: the NOAA Global Monitoring Laboratory solar calculator. The
//   calculation functions of https://gml.noaa.gov/grad/solcalc/main.js were
//   run unmodified under Node.js (sunrise/sunset use the calculator's own
//   two-pass `calcSunriseSetUTC`; solar noon uses `calcSolNoon`'s two-pass
//   equation-of-time correction). `null` means the calculator found no
//   sunrise/sunset on that date.
// * `ephem`: PyEphem 4.2.1 (VSOP87 theory, libastro), an implementation that
//   shares no code with NOAA. Sunrise/sunset use the USNO convention (upper
//   limb, 34' horizon refraction, pressure=0, sea level); twilights use the
//   Sun's centre at -6, -12 and -18 degrees. `alwaysUp`/`alwaysDown` are
//   PyEphem's AlwaysUpError/NeverUpError.
//
// Every "date" is a local calendar date at [utcOffsetHours]; all times are UTC.

class ReferenceCase {
  const ReferenceCase({
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.year,
    required this.month,
    required this.day,
    required this.utcOffsetHours,
    required this.noaa,
    required this.ephem,
  });

  final String place;
  final double latitude;
  final double longitude;
  final int year;
  final int month;
  final int day;
  final int utcOffsetHours;

  /// Keys: sunrise, sunset, noon.
  final Map<String, String?> noaa;

  /// Keys: sunrise, sunset, civilDawn, civilDusk, nauticalDawn, nauticalDusk,
  /// astronomicalDawn, astronomicalDusk, noon.
  final Map<String, String> ephem;

  @override
  String toString() =>
      '$place $year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

const referenceCases = <ReferenceCase>[
  ReferenceCase(
    place: 'Algiers',
    latitude: 36.75,
    longitude: 3.06,
    year: 2026,
    month: 3,
    day: 20,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-03-20T05:51:32Z',
      'sunset': '2026-03-20T17:59:27Z',
      'noon': '2026-03-20T11:55:21Z',
    },
    ephem: {
      'sunrise': '2026-03-20T05:51:33Z',
      'sunset': '2026-03-20T17:59:26Z',
      'civilDawn': '2026-03-20T05:25:46Z',
      'civilDusk': '2026-03-20T18:25:16Z',
      'nauticalDawn': '2026-03-20T04:55:38Z',
      'nauticalDusk': '2026-03-20T18:55:28Z',
      'astronomicalDawn': '2026-03-20T04:25:06Z',
      'astronomicalDusk': '2026-03-20T19:26:04Z',
      'noon': '2026-03-20T11:55:11Z',
    },
  ),
  ReferenceCase(
    place: 'Algiers',
    latitude: 36.75,
    longitude: 3.06,
    year: 2026,
    month: 6,
    day: 21,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-06-21T04:29:09Z',
      'sunset': '2026-06-21T19:10:01Z',
      'noon': '2026-06-21T11:49:28Z',
    },
    ephem: {
      'sunrise': '2026-06-21T04:29:11Z',
      'sunset': '2026-06-21T19:09:57Z',
      'civilDawn': '2026-06-21T03:58:26Z',
      'civilDusk': '2026-06-21T19:40:42Z',
      'nauticalDawn': '2026-06-21T03:20:09Z',
      'nauticalDusk': '2026-06-21T20:18:59Z',
      'astronomicalDawn': '2026-06-21T02:37:11Z',
      'astronomicalDusk': '2026-06-21T21:01:57Z',
      'noon': '2026-06-21T11:49:34Z',
    },
  ),
  ReferenceCase(
    place: 'Algiers',
    latitude: 36.75,
    longitude: 3.06,
    year: 2026,
    month: 12,
    day: 21,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-12-21T06:56:30Z',
      'sunset': '2026-12-21T16:35:09Z',
      'noon': '2026-12-21T11:45:35Z',
    },
    ephem: {
      'sunrise': '2026-12-21T06:56:28Z',
      'sunset': '2026-12-21T16:35:09Z',
      'civilDawn': '2026-12-21T06:27:33Z',
      'civilDusk': '2026-12-21T17:04:04Z',
      'nauticalDawn': '2026-12-21T05:55:05Z',
      'nauticalDusk': '2026-12-21T17:36:33Z',
      'astronomicalDawn': '2026-12-21T05:23:31Z',
      'astronomicalDusk': '2026-12-21T18:08:07Z',
      'noon': '2026-12-21T11:45:49Z',
    },
  ),
  ReferenceCase(
    place: 'Tamanrasset',
    latitude: 22.785,
    longitude: 5.5228,
    year: 2026,
    month: 6,
    day: 21,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-06-21T04:53:41Z',
      'sunset': '2026-06-21T18:25:46Z',
      'noon': '2026-06-21T11:39:37Z',
    },
    ephem: {
      'sunrise': '2026-06-21T04:53:42Z',
      'sunset': '2026-06-21T18:25:44Z',
      'civilDawn': '2026-06-21T04:28:28Z',
      'civilDusk': '2026-06-21T18:50:58Z',
      'nauticalDawn': '2026-06-21T03:58:19Z',
      'nauticalDusk': '2026-06-21T19:21:06Z',
      'astronomicalDawn': '2026-06-21T03:26:54Z',
      'astronomicalDusk': '2026-06-21T19:52:32Z',
      'noon': '2026-06-21T11:39:43Z',
    },
  ),
  ReferenceCase(
    place: 'Tamanrasset',
    latitude: 22.785,
    longitude: 5.5228,
    year: 2026,
    month: 12,
    day: 21,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-12-21T06:13:50Z',
      'sunset': '2026-12-21T16:58:07Z',
      'noon': '2026-12-21T11:35:44Z',
    },
    ephem: {
      'sunrise': '2026-12-21T06:13:48Z',
      'sunset': '2026-12-21T16:58:07Z',
      'civilDawn': '2026-12-21T05:49:16Z',
      'civilDusk': '2026-12-21T17:22:39Z',
      'nauticalDawn': '2026-12-21T05:21:14Z',
      'nauticalDusk': '2026-12-21T17:50:41Z',
      'astronomicalDawn': '2026-12-21T04:53:36Z',
      'astronomicalDusk': '2026-12-21T18:18:19Z',
      'noon': '2026-12-21T11:35:57Z',
    },
  ),
  ReferenceCase(
    place: 'London',
    latitude: 51.5074,
    longitude: -0.1278,
    year: 2026,
    month: 6,
    day: 21,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-06-21T03:43:05Z',
      'sunset': '2026-06-21T20:21:35Z',
      'noon': '2026-06-21T12:02:14Z',
    },
    ephem: {
      'sunrise': '2026-06-21T03:43:08Z',
      'sunset': '2026-06-21T20:21:30Z',
      'civilDawn': '2026-06-21T02:55:19Z',
      'civilDusk': '2026-06-21T21:09:19Z',
      'nauticalDawn': '2026-06-21T01:40:40Z',
      'nauticalDusk': '2026-06-21T22:23:58Z',
      'astronomicalDawn': 'alwaysUp',
      'astronomicalDusk': 'alwaysUp',
      'noon': '2026-06-21T12:02:19Z',
    },
  ),
  ReferenceCase(
    place: 'London',
    latitude: 51.5074,
    longitude: -0.1278,
    year: 2026,
    month: 12,
    day: 21,
    utcOffsetHours: 0,
    noaa: {
      'sunrise': '2026-12-21T08:03:45Z',
      'sunset': '2026-12-21T15:53:25Z',
      'noon': '2026-12-21T11:58:20Z',
    },
    ephem: {
      'sunrise': '2026-12-21T08:03:42Z',
      'sunset': '2026-12-21T15:53:25Z',
      'civilDawn': '2026-12-21T07:23:24Z',
      'civilDusk': '2026-12-21T16:33:44Z',
      'nauticalDawn': '2026-12-21T06:40:12Z',
      'nauticalDusk': '2026-12-21T17:16:56Z',
      'astronomicalDawn': '2026-12-21T05:59:22Z',
      'astronomicalDusk': '2026-12-21T17:57:45Z',
      'noon': '2026-12-21T11:58:34Z',
    },
  ),
  ReferenceCase(
    place: 'Tromsø',
    latitude: 69.6492,
    longitude: 18.9553,
    year: 2026,
    month: 3,
    day: 20,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': '2026-03-20T04:43:52Z',
      'sunset': '2026-03-20T17:01:33Z',
      'noon': '2026-03-20T10:51:46Z',
    },
    ephem: {
      'sunrise': '2026-03-20T04:43:54Z',
      'sunset': '2026-03-20T17:01:31Z',
      'civilDawn': '2026-03-20T03:43:49Z',
      'civilDusk': '2026-03-20T18:02:05Z',
      'nauticalDawn': '2026-03-20T02:27:36Z',
      'nauticalDusk': '2026-03-20T19:19:22Z',
      'astronomicalDawn': '2026-03-20T00:46:19Z',
      'astronomicalDusk': '2026-03-20T21:04:42Z',
      'noon': '2026-03-20T10:51:37Z',
    },
  ),
  ReferenceCase(
    place: 'Tromsø',
    latitude: 69.6492,
    longitude: 18.9553,
    year: 2026,
    month: 6,
    day: 21,
    utcOffsetHours: 2,
    noaa: {
      'sunrise': null,
      'sunset': null,
      'noon': '2026-06-21T10:45:53Z',
    },
    ephem: {
      'sunrise': 'alwaysUp',
      'sunset': 'alwaysUp',
      'civilDawn': 'alwaysUp',
      'civilDusk': 'alwaysUp',
      'nauticalDawn': 'alwaysUp',
      'nauticalDusk': 'alwaysUp',
      'astronomicalDawn': 'alwaysUp',
      'astronomicalDusk': 'alwaysUp',
      'noon': '2026-06-21T10:45:59Z',
    },
  ),
  ReferenceCase(
    place: 'Tromsø',
    latitude: 69.6492,
    longitude: 18.9553,
    year: 2026,
    month: 12,
    day: 21,
    utcOffsetHours: 1,
    noaa: {
      'sunrise': null,
      'sunset': null,
      'noon': '2026-12-21T10:41:59Z',
    },
    ephem: {
      'sunrise': 'alwaysDown',
      'sunset': 'alwaysDown',
      'civilDawn': '2026-12-21T08:31:15Z',
      'civilDusk': '2026-12-21T12:53:09Z',
      'nauticalDawn': '2026-12-21T06:46:43Z',
      'nauticalDusk': '2026-12-21T14:37:42Z',
      'astronomicalDawn': '2026-12-21T05:28:19Z',
      'astronomicalDusk': '2026-12-21T15:56:05Z',
      'noon': '2026-12-21T10:42:13Z',
    },
  ),
  ReferenceCase(
    place: 'Ushuaia',
    latitude: -54.8019,
    longitude: -68.303,
    year: 2026,
    month: 6,
    day: 21,
    utcOffsetHours: -3,
    noaa: {
      'sunrise': '2026-06-21T12:58:51Z',
      'sunset': '2026-06-21T20:11:18Z',
      'noon': '2026-06-21T16:34:58Z',
    },
    ephem: {
      'sunrise': '2026-06-21T12:58:54Z',
      'sunset': '2026-06-21T20:11:14Z',
      'civilDawn': '2026-06-21T12:13:37Z',
      'civilDusk': '2026-06-21T20:56:31Z',
      'nauticalDawn': '2026-06-21T11:26:13Z',
      'nauticalDusk': '2026-06-21T21:43:55Z',
      'astronomicalDawn': '2026-06-21T10:41:58Z',
      'astronomicalDusk': '2026-06-21T22:28:10Z',
      'noon': '2026-06-21T16:35:04Z',
    },
  ),
  ReferenceCase(
    place: 'Ushuaia',
    latitude: -54.8019,
    longitude: -68.303,
    year: 2026,
    month: 12,
    day: 21,
    utcOffsetHours: -3,
    noaa: {
      'sunrise': '2026-12-21T07:51:25Z',
      'sunset': '2026-12-22T01:11:21Z',
      'noon': '2026-12-21T16:31:08Z',
    },
    ephem: {
      'sunrise': '2026-12-21T07:51:23Z',
      'sunset': '2026-12-22T01:11:21Z',
      'civilDawn': '2026-12-21T06:53:57Z',
      'civilDusk': '2026-12-22T02:08:47Z',
      'nauticalDawn': 'alwaysUp',
      'nauticalDusk': 'alwaysUp',
      'astronomicalDawn': 'alwaysUp',
      'astronomicalDusk': 'alwaysUp',
      'noon': '2026-12-21T16:31:22Z',
    },
  ),
  ReferenceCase(
    place: 'Suva',
    latitude: -18.1416,
    longitude: 178.4419,
    year: 2026,
    month: 3,
    day: 20,
    utcOffsetHours: 12,
    noaa: {
      'sunrise': '2026-03-19T18:09:56Z',
      'sunset': '2026-03-20T06:17:25Z',
      'noon': '2026-03-20T00:13:57Z',
    },
    ephem: {
      'sunrise': '2026-03-19T18:09:56Z',
      'sunset': '2026-03-20T06:17:25Z',
      'civilDawn': '2026-03-19T17:48:11Z',
      'civilDusk': '2026-03-20T06:39:09Z',
      'nauticalDawn': '2026-03-19T17:22:52Z',
      'nauticalDusk': '2026-03-20T07:04:26Z',
      'astronomicalDawn': '2026-03-19T16:57:30Z',
      'astronomicalDusk': '2026-03-20T07:29:47Z',
      'noon': '2026-03-20T00:13:48Z',
    },
  ),
  ReferenceCase(
    place: 'Suva',
    latitude: -18.1416,
    longitude: 178.4419,
    year: 2026,
    month: 6,
    day: 21,
    utcOffsetHours: 12,
    noaa: {
      'sunrise': '2026-06-20T18:36:42Z',
      'sunset': '2026-06-21T05:39:11Z',
      'noon': '2026-06-21T00:07:50Z',
    },
    ephem: {
      'sunrise': '2026-06-20T18:36:43Z',
      'sunset': '2026-06-21T05:39:09Z',
      'civilDawn': '2026-06-20T18:12:58Z',
      'civilDusk': '2026-06-21T06:02:54Z',
      'nauticalDawn': '2026-06-20T17:45:45Z',
      'nauticalDusk': '2026-06-21T06:30:07Z',
      'astronomicalDawn': '2026-06-20T17:18:50Z',
      'astronomicalDusk': '2026-06-21T06:57:02Z',
      'noon': '2026-06-21T00:07:56Z',
    },
  ),
  ReferenceCase(
    place: 'Apia',
    latitude: -13.8333,
    longitude: -171.7667,
    year: 2026,
    month: 3,
    day: 20,
    utcOffsetHours: 13,
    noaa: {},
    ephem: {
      'sunrise': '2026-03-19T17:30:57Z',
      'sunset': '2026-03-20T05:38:09Z',
      'civilDawn': '2026-03-19T17:09:40Z',
      'civilDusk': '2026-03-20T05:59:25Z',
      'nauticalDawn': '2026-03-19T16:44:55Z',
      'nauticalDusk': '2026-03-20T06:24:09Z',
      'astronomicalDawn': '2026-03-19T16:20:08Z',
      'astronomicalDusk': '2026-03-20T06:48:55Z',
      'noon': '2026-03-19T23:34:39Z',
    },
  ),
];
