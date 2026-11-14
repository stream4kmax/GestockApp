// Modèle Client : représente une ligne de la table `clients`.

import 'package:gestock_pos/core/constants/app_constants.dart';

class Client {
  const Client({
    required this.id,
    required this.nom,
    this.code,
    this.telephone,
    this.whatsapp,
    this.email,
    this.adresse,
    this.solde = 0,
    this.plafondCredit = 0,
  });

  final String id;
  final String? code;
  final String nom;
  final String? telephone;
  final String? whatsapp;
  final String? email;
  final String? adresse;
  final double solde;          // ce que le client nous doit
  final double plafondCredit;  // 0 = illimité

  /// Client anonyme du comptoir (pas de crédit possible).
  bool get estComptoir => id == kClientComptoirId;

  /// "En cours dépassé" : le client doit plus que son plafond autorisé.
  bool get encoursDepasse => plafondCredit > 0 && solde > plafondCredit;

  factory Client.fromMap(Map<String, Object?> m) => Client(
        id: m['id'] as String,
        code: m['code'] as String?,
        nom: m['nom'] as String,
        telephone: m['telephone'] as String?,
        whatsapp: m['whatsapp'] as String?,
        email: m['email'] as String?,
        adresse: m['adresse'] as String?,
        solde: (m['solde'] as num?)?.toDouble() ?? 0,
        plafondCredit: (m['plafond_credit'] as num?)?.toDouble() ?? 0,
      );
}
