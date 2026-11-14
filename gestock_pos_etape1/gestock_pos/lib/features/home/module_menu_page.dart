// Page d'un module : grille de tuiles (une par sous-module).
// Pour le module Vente, un tableau de bord du jour est affiché en haut.

import 'package:flutter/material.dart';

import 'package:gestock_pos/features/home/dashboard_header.dart';
import 'package:gestock_pos/features/home/modules.dart';
import 'package:gestock_pos/features/home/placeholder_page.dart';

class ModuleMenuPage extends StatefulWidget {
  const ModuleMenuPage({super.key, required this.module});
  final ModuleApp module;

  @override
  State<ModuleMenuPage> createState() => _ModuleMenuPageState();
}

class _ModuleMenuPageState extends State<ModuleMenuPage> {
  /// Incrémenté au retour d'un écran → force le tableau de bord à se recharger
  /// (le chiffre d'affaires a pu changer après une vente).
  int _rafraichir = 0;

  Future<void> _ouvrir(SousModule sm) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: sm.builder ?? (_) => PlaceholderPage(titre: sm.libelle),
    ));
    if (mounted) setState(() => _rafraichir++);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    final largeur = MediaQuery.sizeOf(context).width;
    final colonnes = largeur >= 900 ? 4 : (largeur >= 600 ? 3 : 2); // tablette / téléphone

    return Scaffold(
      appBar: AppBar(
        title: Text(m.libelle),
        // Indicateur visuel discret de l'état de la synchro (étape 5)
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Tooltip(message: 'Mode hors ligne', child: Icon(Icons.cloud_off_outlined)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (m.avecTableauDeBord)
            SliverToBoxAdapter(child: DashboardHeader(key: ValueKey(_rafraichir))),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.count(
              crossAxisCount: colonnes,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                for (final sm in m.sousModules)
                  _TuileSousModule(sousModule: sm, couleur: m.couleur, onTap: () => _ouvrir(sm)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TuileSousModule extends StatelessWidget {
  const _TuileSousModule({required this.sousModule, required this.couleur, required this.onTap});
  final SousModule sousModule;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disponible = sousModule.builder != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: couleur.withValues(alpha: disponible ? 0.15 : 0.07),
                child: Icon(sousModule.icone, color: disponible ? couleur : couleur.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 10),
              Text(
                sousModule.libelle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
