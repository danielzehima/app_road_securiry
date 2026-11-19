# Sécurité Routière CI - prototype

Assistant de conduite pour la Côte d'Ivoire. Il affiche votre vitesse et la limite de la route, et il vous prévient par un **bip** puis une **voix** quand vous dépassez la limite. Il annonce aussi les **zones sensibles** (écoles, zones de contrôle, traversées de villages) environ **1 km avant**.

L'application utilise **uniquement le GPS du téléphone**. Elle ne détecte et ne brouille aucun signal radar.

## Contenu du prototype (cahier des charges : F1, F2, F3)

| Fonction | État |
| --- | --- |
| F1 - Vitesse GPS en temps réel et limite selon le type de route | Fait (limite choisie : agglomération / nationale / autoroute) |
| F2 - Bip au début du dépassement, voix après 5 s, rappel toutes les 10 s | Fait |
| F3 - Annonce d'une zone sensible à environ 1 km, une fois par passage, seulement si l'on s'en approche | Fait, avec des **zones de test** |
| Suivi écran éteint (service de premier plan Android) | Fait |
| Mode démo (trajet simulé, vitesse réglable au curseur) | Fait |
| Marge de tolérance réglable (0 à 15 km/h), bouton muet | Fait |
| Limites par tronçon (OpenStreetMap), signalements, hors ligne complet | Phases suivantes |

> **À vérifier avant toute publication :** les limites par défaut (50 / 90 / 120 km/h) dans `lib/core/models.dart` doivent être confirmées avec le code de la route ivoirien. Les zones de `lib/data/test_zones.dart` sont des points **approximatifs, pour les tests**, et ne correspondent pas à des emplacements officiels.

## Structure

```
lib/
  core/            logique en Dart pur, testable sans téléphone
    alert_engine.dart   moteur d'alertes (lissage, dépassement, zones)
    geo.dart            calcul de distance (haversine)
    models.dart         RoadType, Zone, GpsSample
  data/test_zones.dart  zones de test à Abidjan
  services/
    location_service.dart     GPS (geolocator) + service de premier plan
    audio_alert_service.dart  bip généré, voix française, vibration
    demo_source.dart          trajet simulé
  ui/driving_screen.dart      écran de conduite
test/alert_engine_test.dart   tests du moteur d'alertes
```

## Installation

Il faut [Flutter](https://docs.flutter.dev/get-started/install) (3.22 ou plus récent) et un téléphone Android, ou un émulateur.

```bash
# 1. Générer le dossier android/ (le code dans lib/ et test/ est conservé)
flutter create . --platforms android --project-name app_road_security

# 2. Dépendances et tests
flutter pub get
flutter test

# 3. Lancer sur le téléphone branché en USB
flutter run
```

### Autorisations Android

Ajoutez ces lignes dans `android/app/src/main/AndroidManifest.xml`, juste avant `<application ...>` :

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
```

Sur certains téléphones (Tecno, Infinix, Itel, Xiaomi…), désactivez aussi l'**optimisation de batterie** pour l'application. Sinon, Android peut couper les alertes en arrière-plan.

## Essayer sans rouler

1. Activez **Mode démo**, puis appuyez sur **Démarrer**.
2. Un trajet simulé part à 1,5 km d'une zone « école » (limite 30) et roule vers elle.
3. Avec le curseur, montez au-dessus de 55 km/h : un bip, puis « Ralentissez. Limite 50. »
4. Vers 1 km de la zone : « École dans 1000 mètres. Limite 30. » En entrant dans la zone, la limite affichée passe à 30.

## Prochaines étapes

- Remplacer les zones de test par une base serveur (Supabase + PostGIS) avec synchronisation hors ligne.
- Récupérer les limites par tronçon depuis OpenStreetMap.
- Ajouter les signalements communautaires (F4) et l'historique des trajets (F6).
