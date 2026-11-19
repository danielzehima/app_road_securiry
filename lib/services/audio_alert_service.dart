import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/alert_engine.dart';
import '../core/models.dart';

/// Joue les alertes : bip (généré, sans fichier), voix française et vibration.
/// Le son est déclaré comme « guidage de navigation » pour passer
/// par-dessus la musique (qui baisse momentanément).
class AudioAlertService {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  late final Uint8List _beep = _buildBeepWav();

  bool muted = false;

  Future<void> init() async {
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceNavigationGuidance,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  Future<void> handle(AlertEvent event) async {
    if (muted) return;
    switch (event) {
      case OverspeedBeep():
        await HapticFeedback.heavyImpact();
        await _player.play(BytesSource(_beep));
      case OverspeedVoice(:final limitKmh):
        await HapticFeedback.heavyImpact();
        await _tts.speak('Ralentissez. Limite $limitKmh.');
      case ZoneApproach(:final zone, :final distanceM):
        await HapticFeedback.mediumImpact();
        await _player.play(BytesSource(_beep));
        await _tts.speak(
          '${_zoneWord(zone.type)} dans ${_roundDistance(distanceM)} mètres. '
          'Limite ${zone.limitKmh}.',
        );
      case OverspeedEnded():
        break;
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _tts.stop();
  }

  static String _zoneWord(ZoneType t) => switch (t) {
        ZoneType.controle => 'Zone de contrôle',
        ZoneType.ecole => 'École',
        ZoneType.village => 'Traversée de village',
        ZoneType.danger => 'Virage dangereux',
      };

  static int _roundDistance(double m) => ((m / 100).round() * 100).clamp(100, 5000);

  /// Deux bips de 880 Hz (WAV PCM 16 bits mono), générés en mémoire.
  static Uint8List _buildBeepWav() {
    const sampleRate = 22050;
    const toneMs = 180, gapMs = 90, freq = 880.0;
    const toneLen = sampleRate * toneMs ~/ 1000;
    const gapLen = sampleRate * gapMs ~/ 1000;
    final total = toneLen * 2 + gapLen;

    final pcm = Int16List(total);
    for (var i = 0; i < total; i++) {
      final inTone = i < toneLen || i >= toneLen + gapLen;
      if (!inTone) continue;
      final t = i / sampleRate;
      // Petite enveloppe pour éviter les clics.
      final pos = i < toneLen ? i : i - toneLen - gapLen;
      final env = math.min(1.0, math.min(pos, toneLen - pos) / 200);
      pcm[i] = (math.sin(2 * math.pi * freq * t) * 0.8 * env * 32767).round();
    }

    final dataBytes = pcm.lengthInBytes;
    final header = ByteData(44)
      ..setUint32(0, 0x52494646, Endian.big) // "RIFF"
      ..setUint32(4, 36 + dataBytes, Endian.little)
      ..setUint32(8, 0x57415645, Endian.big) // "WAVE"
      ..setUint32(12, 0x666d7420, Endian.big) // "fmt "
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little) // PCM
      ..setUint16(22, 1, Endian.little) // mono
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x64617461, Endian.big) // "data"
      ..setUint32(40, dataBytes, Endian.little);

    return Uint8List.fromList([
      ...header.buffer.asUint8List(),
      ...pcm.buffer.asUint8List(),
    ]);
  }
}
