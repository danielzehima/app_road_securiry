import 'package:app_road_security/core/alert_engine.dart';
import 'package:app_road_security/core/geo.dart';
import 'package:app_road_security/core/models.dart';
import 'package:app_road_security/data/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Points tous les [step] mètres le long d'un tracé.
List<LatLng> _walk(List<LatLng> path, double step) {
  final out = <LatLng>[path.first];
  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1], b = path[i];
    final n = (distanceMeters(a, b) / step).ceil();
    for (var k = 1; k <= n; k++) {
      final f = k / n;
      out.add(LatLng(a.lat + (b.lat - a.lat) * f, a.lng + (b.lng - a.lng) * f));
    }
  }
  return out;
}

void main() {
  test('chaque zone de l\'itinéraire est sur le tracé', () {
    for (final z in bingervilleYopougon.zones) {
      final nearest = _walk(bingervilleYopougon.path, 20)
          .map((p) => distanceMeters(p, z.center))
          .reduce((a, b) => a < b ? a : b);
      expect(nearest, lessThan(50), reason: z.name);
    }
  });

  test('en roulant de Bingerville à Yopougon, chaque carrefour est annoncé une fois, dans l\'ordre', () {
    final engine = AlertEngine(zones: bingervilleYopougon.zones);
    final t0 = DateTime(2026, 1, 1, 8);
    final announced = <String>[];
    var i = 0;
    for (final p in _walk(bingervilleYopougon.path, 20)) {
      final r = engine.onSample(GpsSample(
        position: p,
        speedKmh: 45,
        accuracyM: 5,
        time: t0.add(Duration(seconds: i++)),
      ));
      announced.addAll(r.events.whereType<ZoneApproach>().map((e) => e.zone.id));
    }
    // La 1re zone (sortie de Bingerville) est à moins de 1 km du départ :
    // on ne s'en « approche » pas depuis plus loin, elle peut ne pas être annoncée.
    final expected = bingervilleYopougon.zones.skip(1).map((z) => z.id).toList();
    expect(announced.where(expected.contains).toList(), expected);
    expect(announced.toSet().length, announced.length);
  });
}
