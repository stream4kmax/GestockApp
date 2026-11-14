// Modèle Article : représente une ligne de la table `articles`.

import 'package:gestock_pos/core/utils/formatters.dart';

class Article {
  const Article({
    required this.id,
    required this.code,
    required this.designation,
    this.codeBarre,
    this.familleId,
    this.unite = 'U',
    this.prixAchatHt = 0,
    this.prixVenteHt = 0,
    this.tauxTva = 19,
    this.stock = 0,
    this.stockMin = 0,
    this.actif = true,
  });

  final String id;
  final String code;
  final String? codeBarre;
  final String designation;
  final String? familleId;
  final String unite;
  final double prixAchatHt;
  final double prixVenteHt;
  final double tauxTva;
  final double stock;
  final double stockMin;
  final bool actif;

  /// Prix de vente TTC affiché au client.
  double get prixVenteTtc => round2(prixVenteHt * (1 + tauxTva / 100));

  /// Rupture : plus rien en stock.
  bool get enRupture => stock <= 0;

  /// Alerte : il reste du stock, mais sous le seuil minimum → à réapprovisionner.
  bool get sousSeuil => !enRupture && stock <= stockMin;

  /// Conversion ligne SQLite → objet Dart.
  /// SQLite renvoie les nombres en int OU double : on passe par `num`.
  factory Article.fromMap(Map<String, Object?> m) => Article(
        id: m['id'] as String,
        code: m['code'] as String,
        codeBarre: m['code_barre'] as String?,
        designation: m['designation'] as String,
        familleId: m['famille_id'] as String?,
        unite: (m['unite'] as String?) ?? 'U',
        prixAchatHt: (m['prix_achat_ht'] as num?)?.toDouble() ?? 0,
        prixVenteHt: (m['prix_vente_ht'] as num?)?.toDouble() ?? 0,
        tauxTva: (m['taux_tva'] as num?)?.toDouble() ?? 0,
        stock: (m['stock'] as num?)?.toDouble() ?? 0,
        stockMin: (m['stock_min'] as num?)?.toDouble() ?? 0,
        actif: ((m['actif'] as int?) ?? 1) == 1,
      );

  /// Conversion objet Dart → ligne SQLite (sans les colonnes de synchro).
  Map<String, Object?> toMap() => {
        'id': id,
        'code': code,
        'code_barre': codeBarre,
        'designation': designation,
        'famille_id': familleId,
        'unite': unite,
        'prix_achat_ht': prixAchatHt,
        'prix_vente_ht': prixVenteHt,
        'taux_tva': tauxTva,
        'stock': stock,
        'stock_min': stockMin,
        'actif': actif ? 1 : 0,
      };
}
