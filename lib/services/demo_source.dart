import 'dart:async';
import 'dart:math' as math;

import '../core/geo.dart';
import '../core/models.dart';

/// Source GPS simulée : un véhicule suit le tracé [path] point par point,
/// à la vitesse réglée par le curseur, puis recommence au début.
class DemoSource {
  final List<LatLng> path;
  double speedKmh;

  late final List<double> _cumul = _cumulative(path);
  double _travelled = 0;

  DemoSource({required this.path, this.speedKmh = 50}) : assert(path.length >= 2);

  /// Distance parcourue sur le tracé (m) et longueur totale.
  double get travelledM => _travelled;
  double get totalM => _cumul.last;

  static List<double> _cumulative(List<LatLng> p) {
    final out = <double>[0];
    for (var i = 1; i < p.length; i++) {
      out.add(out.last + distanceMeters(p[i - 1], p[i]));
    }
    return out;
  }

  /// Position sur le tracé après [d] mètres (interpolation linéaire).
  LatLng _positionAt(double d) {
    for (var i = 1; i < path.length; i++) {
      if (d <= _cumul[i]) {
        final seg = _cumul[i] - _cumul[i - 1];
        final f = seg == 0 ? 0.0 : (d - _cumul[i - 1]) / seg;
        final a = path[i - 1], b = path[i];
        return LatLng(a.lat + (b.lat - a.lat) * f, a.lng + (b.lng - a.lng) * f);
      }
    }
    return path.last;
  }

  Stream<GpsSample> samples() {
    final controller = StreamController<GpsSample>();
    Timer? timer;

    controller.onListen = () {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _travelled += math.max(0, speedKmh) / 3.6;
        if (_travelled > totalM) _travelled = 0;
        controller.add(GpsSample(
          position: _positionAt(_travelled),
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
