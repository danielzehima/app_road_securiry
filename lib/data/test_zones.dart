import '../core/geo.dart';
import '../core/models.dart';

/// Zones de TEST pour le prototype.
///
/// Les coordonnées sont approximatives et servent uniquement à essayer
/// les alertes. Elles ne représentent pas des emplacements officiels.
/// À remplacer par les données validées (base serveur, phase « Données »).
/// Ajoutez vos propres points (ex. votre trajet quotidien) pour tester.
const List<Zone> testZones = [
  Zone(
    id: 'test-plateau',
    type: ZoneType.controle,
    name: 'Plateau - centre (test)',
    center: LatLng(5.3197, -4.0167),
    limitKmh: 50,
  ),
  Zone(
    id: 'test-cocody-ecole',
    type: ZoneType.ecole,
    name: 'Cocody - abords d\'école (test)',
    center: LatLng(5.3485, -3.9870),
    limitKmh: 30,
    radiusM: 200,
  ),
  Zone(
    id: 'test-vge',
    type: ZoneType.controle,
    name: 'Boulevard VGE (test)',
    center: LatLng(5.2990, -3.9830),
    limitKmh: 70,
    radiusM: 400,
  ),
  Zone(
    id: 'test-yopougon',
    type: ZoneType.village,
    name: 'Yopougon - axe principal (test)',
    center: LatLng(5.3360, -4.0730),
    limitKmh: 50,
  ),
];
