// Tableau de bord du jour : CA, nombre de ventes, encaissé, alertes de stock.

import 'package:flutter/material.dart';

import 'package:gestock_pos/core/utils/formatters.dart';
import 'package:gestock_pos/data/repositories/dashboard_repository.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatsJour>(
      // Le Future est recréé quand la clé du widget change (voir ModuleMenuPage).
      future: DashboardRepository().statsDuJour(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        final s = snap.data!;
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte principale : chiffre d'affaires du jour
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chiffre d\'affaires du jour',
                                style: TextStyle(color: scheme.onPrimaryContainer)),
                            const SizedBox(height: 4),
                            Text(fmtMonnaie(s.chiffreAffaires),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                          ],
                        ),
                      ),
                      Icon(Icons.trending_up, size: 40, color: scheme.onPrimaryContainer),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MiniStat(libelle: 'Ventes', valeur: '${s.nbVentes}', icone: Icons.receipt)),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(libelle: 'Encaissé', valeur: fmtMonnaie(s.encaisse), icone: Icons.payments)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      libelle: 'Alertes stock',
                      valeur: '${s.nbAlertesStock}',
                      icone: Icons.warning_amber_rounded,
                      alerte: s.nbAlertesStock > 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.libelle, required this.valeur, required this.icone, this.alerte = false});
  final String libelle;
  final String valeur;
  final IconData icone;
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final couleur = alerte ? scheme.error : scheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Icon(icone, color: couleur, size: 20),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(valeur,
                  style: TextStyle(fontWeight: FontWeight.bold, color: alerte ? scheme.error : null)),
            ),
            Text(libelle, style: Theme.of(context).textTheme.labelSmall, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
