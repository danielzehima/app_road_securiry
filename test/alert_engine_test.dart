import 'package:app_road_security/core/alert_engine.dart';
import 'package:app_road_security/core/geo.dart';
import 'package:app_road_security/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _school = Zone(
  id: 'z1',
  type: ZoneType.ecole,
  name: 'École test',
  center: LatLng(5.35, -3.99),
  limitKmh: 30,
  radiusM: 200,
);

final _t0 = DateTime(2026, 1, 1, 8);

/// Position à [metersSouth] mètres au sud de la zone.
LatLng _south(double metersSouth) => LatLng(_school.center.lat - metersSouth / 111195, _school.center.lng);

GpsSample _sample(int second, double speed, {double south = 5000, double accuracy = 5}) => GpsSample(
      position: _south(south),
      speedKmh: speed,
      accuracyM: accuracy,
      time: _t0.add(Duration(seconds: second)),
    );

void main() {
  test('distanceMeters est correcte sur 1 km', () {
    expect(distanceMeters(_south(1000), _school.center), closeTo(1000, 2));
  });

  test('pas d\'alerte sous la limite + marge', () {
    final engine = AlertEngine(zones: const []);
    for (var i = 0; i < 10; i++) {
      final r = engine.onSample(_sample(i, 54)); // limite 50 + marge 5
      expect(r.events, isEmpty);
      expect(r.state.overspeed, isFalse);
    }
  });

  test('bip au début du dépassement, voix après 5 s, fin signalée', () {
    final engine = AlertEngine(zones: const []);
    final events = <AlertEvent>[];
    for (var i = 0; i < 3; i++) {
      events.addAll(engine.onSample(_sample(i, 70)).events);
    }
    expect(events.whereType<OverspeedBeep>(), hasLength(1));

    for (var i = 3; i < 9; i++) {
      events.addAll(engine.onSample(_sample(i, 70)).events);
    }
    expect(events.whereType<OverspeedVoice>(), hasLength(1));
    expect(events.whereType<OverspeedVoice>().first.limitKmh, 50);

    for (var i = 9; i < 13; i++) {
      events.addAll(engine.onSample(_sample(i, 30)).events);
    }
    expect(events.whereType<OverspeedEnded>(), hasLength(1));
  });

  test('un pic GPS isolé ne déclenche pas de bip (lissage)', () {
    final engine = AlertEngine(zones: const []);
    final events = <AlertEvent>[
      ...engine.onSample(_sample(0, 45)).events,
      ...engine.onSample(_sample(1, 45)).events,
      ...engine.onSample(_sample(2, 70)).events, // moyenne 53,3
      ...engine.onSample(_sample(3, 45)).events,
    ];
    expect(events, isEmpty);
  });

  test('GPS imprécis : aucune alerte', () {
    final engine = AlertEngine(zones: const []);
    final r = engine.onSample(_sample(0, 120, accuracy: 50));
    expect(r.events, isEmpty);
    expect(r.state.gpsOk, isFalse);
  });

  test('zone annoncée une seule fois, seulement en s\'approchant', () {
    final engine = AlertEngine(zones: const [_school]);
    final events = <AlertEvent>[];
    var second = 0;
    // On roule de 1 500 m à 250 m de la zone, par pas de 50 m.
    for (var d = 1500.0; d >= 250; d -= 50) {
      events.addAll(engine.onSample(_sample(second++, 40, south: d)).events);
    }
    final approaches = events.whereType<ZoneApproach>().toList();
    expect(approaches, hasLength(1));
    expect(approaches.first.distanceM, lessThanOrEqualTo(1000));
  });

  test('pas d\'annonce en s\'éloignant de la zone', () {
    final engine = AlertEngine(zones: const [_school]);
    final events = <AlertEvent>[];
    var second = 0;
    for (var d = 250.0; d <= 1500; d += 50) {
      events.addAll(engine.onSample(_sample(second++, 40, south: d)).events);
    }
    expect(events.whereType<ZoneApproach>(), isEmpty);
  });

  test('dans la zone, la limite de la zone s\'applique', () {
    final engine = AlertEngine(zones: const [_school]);
    engine.onSample(_sample(0, 40, south: 100));
    final r = engine.onSample(_sample(1, 40, south: 90));
    expect(r.state.limitKmh, 30);
    expect(r.state.activeZone?.id, 'z1');
    expect(r.state.overspeed, isTrue); // 40 > 30 + 5
  });

  test('la marge de tolérance est réglable', () {
    final engine = AlertEngine(zones: const [], config: const AlertConfig(toleranceKmh: 0));
    final r = engine.onSample(_sample(0, 52));
    expect(r.events.whereType<OverspeedBeep>(), hasLength(1));
  });
}
