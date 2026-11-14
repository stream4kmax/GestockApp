// =============================================================================
//  GeStock POS — Point d'entrée de l'application
// =============================================================================
//  Rôle de ce fichier :
//   1. Initialiser Flutter et les services indispensables AVANT l'affichage
//      (formatage des dates en français, ouverture de la base SQLite locale).
//   2. Déclarer le thème, la langue et la page d'accueil (HomeShell), qui
//      contient la barre de navigation inférieure avec les 6 modules.
//
//  Hors ligne d'abord : toutes les données sont lues/écrites dans SQLite.
//  La synchronisation Firebase (étape 5) viendra s'ajouter ici sans rien
//  casser : on initialisera Firebase puis on démarrera un SyncService.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gestock_pos/core/database/database_helper.dart';
import 'package:gestock_pos/core/theme/app_theme.dart';
import 'package:gestock_pos/features/home/home_shell.dart';

Future<void> main() async {
  // Obligatoire quand on exécute du code asynchrone avant runApp()
  // (accès aux plugins natifs : sqflite, etc.).
  WidgetsFlutterBinding.ensureInitialized();

  // Charge les noms de jours/mois en français pour DateFormat('...', 'fr_FR').
  await initializeDateFormatting('fr_FR');

  // Ouvre (ou crée au premier lancement) la base SQLite locale.
  // Au premier lancement, les tables sont créées et des données de
  // démonstration sont insérées (voir database_seed.dart).
  await DatabaseHelper.instance.database;

  // --- Étape 5 (synchro cloud) : décommenter après configuration Firebase ---
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // SyncService.instance.demarrer();

  runApp(const GestockApp());
}

/// Widget racine de l'application.
class GestockApp extends StatelessWidget {
  const GestockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeStock POS',
      debugShowCheckedModeBanner: false,

      // Thème clair et sombre (Material 3), définis dans app_theme.dart
      theme: AppTheme.clair,
      darkTheme: AppTheme.sombre,
      themeMode: ThemeMode.system,

      // Langue : français par défaut, arabe déjà prévu pour plus tard.
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('ar', 'DZ')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Page d'accueil = coquille avec la barre de navigation à 6 modules.
      home: const HomeShell(),
    );
  }
}
