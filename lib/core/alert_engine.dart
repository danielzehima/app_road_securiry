import 'geo.dart';
import 'models.dart';

/// Réglages du moteur d'alertes (cahier des charges, F2 / F3 / exigences).
class AlertConfig {
  /// Marge de tolérance au-dessus de la limite (0 à 15 km/h).
  final int toleranceKmh;

  /// Durée de dépassement continu avant l'annonce vocale.
  final Duration voiceAfter;

  /// Intervalle de répétition du bip tant que le dépassement dure.
  final Duration repeatBeepEvery;

  /// Distance d'annonce d'une zone sensible.
  final double approachDistanceM;

  /// Précision GPS minimale pour déclencher une alerte.
  final double minAccuracyM;

  /// Nombre d'échantillons pour lisser la vitesse (évite les faux bips).
  final int smoothingWindow;

  const AlertConfig({
    this.toleranceKmh = 5,
    this.voiceAfter = const Duration(seconds: 5),
    this.repeatBeepEvery = const Duration(seconds: 10),
    this.approachDistanceM = 1000,
    this.minAccuracyM = 20,
    this.smoothingWindow = 3,
  });

  AlertConfig copyWith({int? toleranceKmh}) => AlertConfig(
        toleranceKmh: toleranceKmh ?? this.toleranceKmh,
        voiceAfter: voiceAfter,
        repeatBeepEvery: repeatBeepEvery,
        approachDistanceM: approachDistanceM,
        minAccuracyM: minAccuracyM,
        smoothingWindow: smoothingWindow,
      );
}

/// Événements sonores produits par le moteur.
sealed class AlertEvent {
  const AlertEvent();
}

/// Début de dépassement, ou rappel périodique : un bip.
class OverspeedBeep extends AlertEvent {
  final int limitKmh;
  const OverspeedBeep(this.limitKmh);
}

/// Dépassement qui dure : annonce vocale « Limite 50 ».
class OverspeedVoice extends AlertEvent {
  final int limitKmh;
  const OverspeedVoice(this.limitKmh);
}

/// Retour sous la limite.
class OverspeedEnded extends AlertEvent {
  const OverspeedEnded();
}

/// Approche d'une zone sensible (une fois par passage).
class ZoneApproach extends AlertEvent {
  final Zone zone;
  final double distanceM;
  const ZoneApproach(this.zone, this.distanceM);
}

/// État affiché par l'écran de conduite.
class DrivingState {
  final bool gpsOk;
  final double speedKmh;
  final int limitKmh;
  final bool overspeed;
  final Zone? activeZone;
  final Zone? nextZone;
  final double? nextZoneDistanceM;

  const DrivingState({
    required this.gpsOk,
    required this.speedKmh,
    required this.limitKmh,
    required this.overspeed,
    this.activeZone,
    this.nextZone,
    this.nextZoneDistanceM,
  });

  /// Proche de la limite (affichage orange).
  bool get nearLimit => !overspeed && speedKmh >= limitKmh - 5;
}

class EngineResult {
  final DrivingState state;
  final List<AlertEvent> events;
  const EngineResult(this.state, this.events);
}

/// Moteur d'alertes, en Dart pur (aucune dépendance Flutter) pour être testable.
///
/// On lui donne chaque échantillon GPS ; il renvoie l'état à afficher
/// et les éventuels sons à jouer.
class AlertEngine {
  AlertConfig config;
  RoadType roadType;
  final List<Zone> zones;

  AlertEngine({
    required this.zones,
    this.config = const AlertConfig(),
    this.roadType = RoadType.agglomeration,
  });

  final List<double> _speeds = [];
  bool _overspeed = false;
  DateTime? _overspeedSince;
  DateTime? _lastBeep;
  bool _voiceDone = false;

  /// Dernière distance connue par zone (pour savoir si l'on s'en approche).
  final Map<String, double> _lastDistance = {};

  /// Zones déjà annoncées pendant ce passage.
  final Set<String> _announced = {};

  DrivingState? _lastState;

  void reset() {
    _speeds.clear();
    _overspeed = false;
    _overspeedSince = null;
    _lastBeep = null;
    _voiceDone = false;
    _lastDistance.clear();
    _announced.clear();
    _lastState = null;
  }

  EngineResult onSample(GpsSample s) {
    final events = <AlertEvent>[];

    // GPS trop imprécis : on n'alerte pas, on signale l'état à l'écran.
    if (s.accuracyM > config.minAccuracyM) {
      final prev = _lastState;
      final state = DrivingState(
        gpsOk: false,
        speedKmh: prev?.speedKmh ?? 0,
        limitKmh: prev?.limitKmh ?? roadType.defaultLimitKmh,
        overspeed: false,
      );
      return EngineResult(state, events);
    }

    // Lissage de la vitesse.
    _speeds.add(s.speedKmh < 0 ? 0 : s.speedKmh);
    while (_speeds.length > config.smoothingWindow) {
      _speeds.removeAt(0);
    }
    final speed = _speeds.reduce((a, b) => a + b) / _speeds.length;

    // Zones : zone active (on est dedans) et prochaine zone annoncée.
    Zone? active;
    Zone? next;
    double? nextDist;
    for (final z in zones) {
      final d = distanceMeters(s.position, z.center);
      final prevD = _lastDistance[z.id];

      if (d <= z.radiusM) {
        if (active == null || z.limitKmh < active.limitKmh) active = z;
      } else if (d <= config.approachDistanceM) {
        final approaching = prevD != null && d < prevD - 2;
        if (approaching && !_announced.contains(z.id)) {
          _announced.add(z.id);
          events.add(ZoneApproach(z, d));
        }
        if (approaching && (nextDist == null || d < nextDist)) {
          next = z;
          nextDist = d;
        }
      } else if (d > config.approachDistanceM + 200) {
        // Hystérésis : la zone pourra être annoncée au prochain passage.
        _announced.remove(z.id);
      }

      if (d <= config.approachDistanceM * 2) {
        _lastDistance[z.id] = d;
      } else {
        _lastDistance.remove(z.id);
      }
    }

    final limit = active != null && active.limitKmh < roadType.defaultLimitKmh
        ? active.limitKmh
        : roadType.defaultLimitKmh;

    // Dépassement de vitesse.
    final over = speed > limit + config.toleranceKmh;
    if (over && !_overspeed) {
      _overspeed = true;
      _overspeedSince = s.time;
      _lastBeep = s.time;
      _voiceDone = false;
      events.add(OverspeedBeep(limit));
    } else if (over && _overspeed) {
      if (!_voiceDone && s.time.difference(_overspeedSince!) >= config.voiceAfter) {
        _voiceDone = true;
        _lastBeep = s.time;
        events.add(OverspeedVoice(limit));
      } else if (s.time.difference(_lastBeep!) >= config.repeatBeepEvery) {
        _lastBeep = s.time;
        events.add(OverspeedBeep(limit));
      }
    } else if (!over && _overspeed) {
      _overspeed = false;
      _overspeedSince = null;
      events.add(const OverspeedEnded());
    }

    final state = DrivingState(
      gpsOk: true,
      speedKmh: speed,
      limitKmh: limit,
      overspeed: _overspeed,
      activeZone: active,
      nextZone: next,
      nextZoneDistanceM: nextDist,
    );
    _lastState = state;
    return EngineResult(state, events);
  }
}
