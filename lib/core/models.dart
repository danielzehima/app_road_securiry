import 'geo.dart';

/// Type de route choisi par le conducteur tant que les limites
/// par tronçon (OpenStreetMap) ne sont pas encore intégrées.
///
/// Les valeurs par défaut sont À VÉRIFIER auprès du code de la route
/// ivoirien / de l'OSER avant toute publication.
enum RoadType {
  agglomeration('Agglomération', 50),
  route('Route nationale', 90),
  autoroute('Autoroute', 120);

  final String label;
  final int defaultLimitKmh;
  const RoadType(this.label, this.defaultLimitKmh);
}

enum ZoneType {
  controle('Zone de contrôle'),
  ecole('École'),
  village('Traversée de village'),
  danger('Virage dangereux');

  final String label;
  const ZoneType(this.label);
}

/// Zone sensible : un point, un rayon d'application et une limite recommandée.
class Zone {
  final String id;
  final ZoneType type;
  final String name;
  final LatLng center;

  /// Rayon (m) dans lequel la limite de la zone s'applique.
  final double radiusM;
  final int limitKmh;

  const Zone({
    required this.id,
    required this.type,
    required this.name,
    required this.center,
    required this.limitKmh,
    this.radiusM = 300,
  });
}

/// Échantillon GPS déjà converti dans nos unités.
class GpsSample {
  final LatLng position;
  final double speedKmh;
  final double accuracyM;
  final DateTime time;

  const GpsSample({
    required this.position,
    required this.speedKmh,
    required this.accuracyM,
    required this.time,
  });
}
