// Indicateurs du jour affichés sur la page d'accueil.

import 'package:sqflite/sqflite.dart';

import 'package:gestock_pos/core/database/database_helper.dart';

class StatsJour {
  const StatsJour({
    required this.chiffreAffaires,
    required this.nbVentes,
    required this.encaisse,
    required this.nbAlertesStock,
  });
  final double chiffreAffaires; // TTC
  final int nbVentes;
  final double encaisse;
  final int nbAlertesStock;     // ruptures + articles sous le seuil
}

class DashboardRepository {
  Future<StatsJour> statsDuJour() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final debut = DateTime(now.year, now.month, now.day).toIso8601String();
    final fin = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    // Ventes du jour : comptoir + BL + factures DIRECTES (une facture issue d'un
    // BL est exclue pour ne pas compter deux fois le même chiffre d'affaires).
    final ventes = await db.rawQuery('''
      SELECT COUNT(*) AS nb,
             COALESCE(SUM(total_ttc), 0)    AS ca,
             COALESCE(SUM(montant_paye), 0) AS paye
      FROM documents
      WHERE deleted = 0 AND statut = 'VALIDE'
        AND type_doc IN ('VC', 'BL', 'FV') AND document_source_id IS NULL
        AND date_doc >= ? AND date_doc < ?
    ''', [debut, fin]);

    final alertes = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM articles WHERE deleted = 0 AND actif = 1 AND stock <= stock_min',
        )) ??
        0;

    final r = ventes.first;
    return StatsJour(
      chiffreAffaires: (r['ca'] as num).toDouble(),
      nbVentes: (r['nb'] as num).toInt(),
      encaisse: (r['paye'] as num).toDouble(),
      nbAlertesStock: alertes,
    );
  }
}
