import 'dart:async';
import 'dart:math' as math;

import '../core/geo.dart';
import '../core/models.dart';

/// Source GPS simulée pour essayer l'application sans rouler :
/// un véhicule part à 1,5 km d'une zone et roule droit vers elle,
/// à la vitesse réglée par le curseur de l'écran.
class DemoSource {
  final Zone target;
  double speedKmh;

  DemoSource({required this.target, this.speedKmh = 50});

  Stream<GpsSample> samples() {
    // Point de départ : 1 500 m au sud de la zone (1° de latitude ≈ 111 km).
    var lat = target.center.lat - 1500 / 111000;
    final lng = target.center.lng;
    final controller = StreamController<GpsSample>();
    Timer? timer;

    controller.onListen = () {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        lat += (speedKmh / 3.6) / 111000;
        // Une fois la zone dépassée de 1 km, on recommence.
        if (lat > target.center.lat + 1000 / 111000) {
          lat = target.center.lat - 1500 / 111000;
        }
        controller.add(GpsSample(
          position: LatLng(lat, lng),
          speedKmh: math.max(0, speedKmh),
          accuracyM: 5,
          time: DateTime.now(),
        ));
      });
    };
    controller.onCancel = () => timer?.cancel();
    return controller.stream;
  }
}
