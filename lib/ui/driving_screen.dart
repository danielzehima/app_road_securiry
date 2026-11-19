import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/alert_engine.dart';
import '../core/models.dart';
import '../data/test_zones.dart';
import '../services/audio_alert_service.dart';
import '../services/demo_source.dart';
import '../services/location_service.dart';

/// Écran de conduite : vitesse, limite, prochaine zone, alertes sonores.
class DrivingScreen extends StatefulWidget {
  const DrivingScreen({super.key});

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  final _engine = AlertEngine(zones: testZones);
  final _audio = AudioAlertService();
  final _location = LocationService();

  StreamSubscription<GpsSample>? _sub;
  DrivingState? _state;
  bool _running = false;
  bool _demoMode = false;
  DemoSource? _demo;

  @override
  void initState() {
    super.initState();
    _audio.init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _audio.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _start() async {
    Stream<GpsSample> stream;
    if (_demoMode) {
      // Zone « école » (limite 30) : on voit l'annonce puis le changement de limite.
      _demo = DemoSource(target: testZones[1], speedKmh: 50);
      stream = _demo!.samples();
    } else {
      final status = await _location.ensurePermission();
      if (status != LocationStatus.ok) {
        _showPermissionMessage(status);
        return;
      }
      stream = _location.samples();
    }

    _engine.reset();
    await WakelockPlus.enable();
    _sub = stream.listen(_onSample);
    setState(() => _running = true);
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    _demo = null;
    await WakelockPlus.disable();
    setState(() {
      _running = false;
      _state = null;
    });
  }

  void _onSample(GpsSample sample) {
    final result = _engine.onSample(sample);
    if (!mounted) return;
    setState(() => _state = result.state);
    for (final event in result.events) {
      _audio.handle(event);
    }
  }

  void _showPermissionMessage(LocationStatus status) {
    final text = switch (status) {
      LocationStatus.serviceDisabled => 'Activez la localisation du téléphone.',
      LocationStatus.denied => 'L\'application a besoin de votre position pour vous alerter.',
      LocationStatus.deniedForever =>
        'Autorisez la localisation dans les réglages de l\'application.',
      LocationStatus.ok => '',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: status == LocationStatus.deniedForever
            ? SnackBarAction(label: 'Réglages', onPressed: _location.openSettings)
            : null,
      ),
    );
  }

  Future<void> _editTolerance() async {
    var value = _engine.config.toleranceKmh.toDouble();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Marge de tolérance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alerte au-delà de la limite + ${value.round()} km/h'),
              Slider(
                value: value,
                min: 0,
                max: 15,
                divisions: 15,
                label: '${value.round()} km/h',
                onChanged: (v) => setLocal(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    setState(() {
      _engine.config = _engine.config.copyWith(toleranceKmh: value.round());
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = _state;
    final Color background;
    if (s != null && s.overspeed) {
      background = Colors.red.withValues(alpha: 0.25);
    } else if (s != null && s.nearLimit) {
      background = Colors.orange.withValues(alpha: 0.2);
    } else {
      background = scheme.surface;
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Sécurité Routière CI'),
        actions: [
          IconButton(
            tooltip: _audio.muted ? 'Réactiver le son' : 'Couper le son',
            icon: Icon(_audio.muted ? Icons.volume_off : Icons.volume_up),
            onPressed: () => setState(() => _audio.muted = !_audio.muted),
          ),
          IconButton(
            tooltip: 'Marge de tolérance',
            icon: const Icon(Icons.tune),
            onPressed: _editTolerance,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<RoadType>(
                segments: [
                  for (final t in RoadType.values)
                    ButtonSegment(value: t, label: Text(t.label, textAlign: TextAlign.center)),
                ],
                selected: {_engine.roadType},
                onSelectionChanged: (sel) => setState(() => _engine.roadType = sel.first),
              ),
              Expanded(child: _SpeedPanel(state: s, running: _running)),
              _NextZoneCard(state: s),
              if (_running && _demo != null) _demoSlider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mode démo'),
                      subtitle: const Text('Simuler un trajet'),
                      value: _demoMode,
                      onChanged: _running ? null : (v) => setState(() => _demoMode = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 64,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _running ? Colors.red : scheme.primary,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _running ? _stop : _start,
                      icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                      label: Text(_running ? 'Arrêter' : 'Démarrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoSlider() {
    final demo = _demo!;
    return Row(
      children: [
        const Text('Vitesse simulée'),
        Expanded(
          child: Slider(
            value: demo.speedKmh,
            min: 0,
            max: 130,
            divisions: 26,
            label: '${demo.speedKmh.round()} km/h',
            onChanged: (v) => setState(() => demo.speedKmh = v),
          ),
        ),
        Text('${demo.speedKmh.round()}'),
      ],
    );
  }
}

class _SpeedPanel extends StatelessWidget {
  final DrivingState? state;
  final bool running;
  const _SpeedPanel({required this.state, required this.running});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (!running) {
      return const Center(
        child: Text(
          'Posez le téléphone sur son support\npuis appuyez sur « Démarrer ».',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    if (s == null) {
      return const Center(child: Text('Recherche du signal GPS…', style: TextStyle(fontSize: 18)));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!s.gpsOk)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Signal GPS faible - alertes en pause',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  s.speedKmh.round().toString(),
                  style: TextStyle(
                    fontSize: 120,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: s.overspeed ? Colors.red : null,
                  ),
                ),
                const Text('km/h', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(width: 28),
            _LimitSign(limitKmh: s.limitKmh),
          ],
        ),
        if (s.activeZone != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Dans la zone : ${s.activeZone!.name}', style: const TextStyle(fontSize: 16)),
          ),
      ],
    );
  }
}

class _LimitSign extends StatelessWidget {
  final int limitKmh;
  const _LimitSign({required this.limitKmh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 12),
      ),
      child: Text(
        '$limitKmh',
        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.black),
      ),
    );
  }
}

class _NextZoneCard extends StatelessWidget {
  final DrivingState? state;
  const _NextZoneCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final zone = s?.nextZone;
    final dist = s?.nextZoneDistanceM;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, size: 32),
        title: Text(zone == null ? 'Aucune zone sensible proche' : zone.type.label),
        subtitle: zone == null || dist == null
            ? null
            : Text('${zone.name} - ${dist.round()} m - limite ${zone.limitKmh} km/h'),
      ),
    );
  }
}
