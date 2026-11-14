# GeStock POS — Démarrage rapide

## Prérequis (une seule fois)
1. Installer **Flutter** (version stable) : https://docs.flutter.dev/get-started/install
2. Installer **Android Studio** (fournit le SDK Android), puis lancer `flutter doctor --android-licenses`.
3. Vérifier : `flutter doctor` (toutes les lignes Android doivent être cochées ✓).

## Créer le projet et y copier ce code
```bash
# 1. Générer le squelette Android/iOS officiel
flutter create --org dz.gestock --project-name gestock_pos gestock_pos
cd gestock_pos

# 2. Remplacer le dossier lib/ et pubspec.yaml par ceux de cette archive
#    (supprimer d'abord lib/ et test/ générés)

# 3. Télécharger les dépendances
flutter pub get
```

## Tester sur le téléphone
* Activer **Options pour les développeurs → Débogage USB** sur le téléphone, le brancher en USB.
* `flutter run`

## Générer l'APK installable
```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```
Copier ce fichier sur le téléphone et l'ouvrir (autoriser « Installer des applications inconnues »).

Pour un APK plus léger par type de processeur :
```bash
flutter build apk --release --split-per-abi
# → app-arm64-v8a-release.apk (la plupart des téléphones récents)
```

> La signature définitive (clé `.jks`) pour publier sur le Play Store sera détaillée à l'étape 4.
