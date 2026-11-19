import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/geo.dart';
import '../core/models.dart';

/// Résultat de la vérification des autorisations de localisation.
enum LocationStatus { ok, serviceDisabled, denied, deniedForever }

/// Accès au GPS. Sur Android, un service de premier plan garde le suivi
/// actif écran éteint (notification permanente « Surveillance active »).
class LocationService {
  Future<LocationStatus> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return LocationStatus.denied;
      case LocationPermission.deniedForever:
        return LocationStatus.deniedForever;
      default:
        return LocationStatus.ok;
    }
  }

  Stream<GpsSample> samples() {
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Surveillance de vitesse active',
        notificationText: 'Les alertes restent actives écran éteint.',
        enableWakeLock: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => GpsSample(
        position: LatLng(p.latitude, p.longitude),
        // Geolocator renvoie la vitesse en m/s.
        speedKmh: p.speed * 3.6,
        accuracyM: p.accuracy,
        time: p.timestamp,
      ),
    );
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
