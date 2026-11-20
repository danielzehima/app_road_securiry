import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/geo.dart';
import '../core/models.dart';

/// Lieux marqués par le conducteur (bouton « Marquer ce lieu »),
/// enregistrés sur le téléphone uniquement.
class MyPlacesStore {
  static const _key = 'my_places_v1';

  Future<List<Zone>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list.cast<Map<String, dynamic>>())
        Zone(
          id: e['id'] as String,
          type: ZoneType.monLieu,
          name: e['name'] as String,
          center: LatLng((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble()),
          limitKmh: e['limit'] as int,
        ),
    ];
  }

  Future<void> save(List<Zone> places) async {
    final prefs = await SharedPreferences.getInstance();
    final data = [
      for (final z in places)
        {
          'id': z.id,
          'name': z.name,
          'lat': z.center.lat,
          'lng': z.center.lng,
          'limit': z.limitKmh,
        },
    ];
    await prefs.setString(_key, jsonEncode(data));
  }
}
