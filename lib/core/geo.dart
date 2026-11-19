import 'dart:math' as math;

/// Point géographique simple (degrés décimaux).
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);

  @override
  String toString() => 'LatLng($lat, $lng)';
}

const double _earthRadiusM = 6371000;

double _rad(double deg) => deg * math.pi / 180;

/// Distance en mètres entre deux points (formule de haversine).
double distanceMeters(LatLng a, LatLng b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
}
