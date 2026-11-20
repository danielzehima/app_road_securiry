import '../core/geo.dart';
import '../core/models.dart';
import 'test_zones.dart';

/// Itinéraire Bingerville → Yopougon en passant par le carrefour 9 Kilo.
///
/// ATTENTION : les coordonnées sont APPROXIMATIVES (estimées sans accès
/// à une carte). Elles peuvent être décalées de plusieurs centaines de mètres.
/// Pour des alertes précises, utilisez « Marquer ce lieu » en passant
/// réellement à chaque carrefour, puis remplacez les valeurs ci-dessous.
const DrivingRoute bingervilleYopougon = DrivingRoute(
  id: 'bingerville-yopougon-9kilo',
  name: 'Bingerville → Yopougon (via 9 Kilo)',
  path: [
    LatLng(5.3536, -3.8930), // Bingerville centre
    LatLng(5.3590, -3.9150), // Route de Bingerville, sortie ouest
    LatLng(5.3655, -3.9380), // Carrefour 9 Kilo
    LatLng(5.3600, -3.9600), // Boulevard Mitterrand, Riviera
    LatLng(5.3570, -3.9720), // Carrefour Riviera 2
    LatLng(5.3490, -4.0005), // Carrefour de la Vie (Cocody)
    LatLng(5.3420, -4.0150), // Vers Adjamé
    LatLng(5.3400, -4.0220), // Adjamé - Indénié
    LatLng(5.3550, -4.0300), // Williamsville / Autoroute du Nord
    LatLng(5.3470, -4.0620), // Yopougon - Siporex
    LatLng(5.3360, -4.0730), // Yopougon centre
  ],
  zones: [
    Zone(
      id: 'r1-entree-bingerville',
      type: ZoneType.village,
      name: 'Sortie de Bingerville',
      center: LatLng(5.3590, -3.9150),
      limitKmh: 50,
    ),
    Zone(
      id: 'r1-9kilo',
      type: ZoneType.carrefour,
      name: 'Carrefour 9 Kilo',
      center: LatLng(5.3655, -3.9380),
      limitKmh: 50,
      radiusM: 350,
    ),
    Zone(
      id: 'r1-riviera2',
      type: ZoneType.carrefour,
      name: 'Carrefour Riviera 2',
      center: LatLng(5.3570, -3.9720),
      limitKmh: 50,
    ),
    Zone(
      id: 'r1-carrefour-vie',
      type: ZoneType.carrefour,
      name: 'Carrefour de la Vie',
      center: LatLng(5.3490, -4.0005),
      limitKmh: 50,
    ),
    Zone(
      id: 'r1-indenie',
      type: ZoneType.carrefour,
      name: 'Carrefour Indénié',
      center: LatLng(5.3400, -4.0220),
      limitKmh: 50,
    ),
    Zone(
      id: 'r1-siporex',
      type: ZoneType.carrefour,
      name: 'Carrefour Siporex',
      center: LatLng(5.3470, -4.0620),
      limitKmh: 50,
    ),
  ],
);

/// Zones de test d'origine, avec un court tracé vers la zone « école ».
final DrivingRoute testRoute = DrivingRoute(
  id: 'test-abidjan',
  name: 'Zones de test Abidjan',
  path: [
    LatLng(testZones[1].center.lat - 1500 / 111195, testZones[1].center.lng),
    LatLng(testZones[1].center.lat + 1000 / 111195, testZones[1].center.lng),
  ],
  zones: testZones,
);

final List<DrivingRoute> allRoutes = [bingervilleYopougon, testRoute];
