// Une ligne de la liste d'articles du POS, avec badge "dans le panier"
// et pastille de stock colorée (vert = OK, orange = sous le seuil, rouge = rupture).

import 'package:flutter/material.dart';

import 'package:gestock_pos/core/utils/formatters.dart';
import 'package:gestock_pos/data/models/article.dart';

class ArticleTile extends StatelessWidget {
  const ArticleTile({
    super.key,
    required this.article,
    required this.quantiteDansPanier,
    required this.onTap,
  });

  final Article article;
  final double quantiteDansPanier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Stock "restant" en tenant compte de ce qui est déjà dans le panier.
    final disponible = article.stock - quantiteDansPanier;

    return ListTile(
      onTap: onTap,
      leading: Badge(
        isLabelVisible: quantiteDansPanier > 0,
        label: Text(fmtQte(quantiteDansPanier)),
        child: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Text(
            article.designation.isNotEmpty ? article.designation[0].toUpperCase() : '?',
            style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Text(article.designation, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${article.code} · TVA ${fmtQte(article.tauxTva)} %'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(fmtMonnaie(article.prixVenteTtc), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          StockChip(disponible: disponible, seuil: article.stockMin, unite: article.unite),
        ],
      ),
    );
  }
}

/// Pastille de stock réutilisable (sera aussi utilisée dans le module Article).
class StockChip extends StatelessWidget {
  const StockChip({super.key, required this.disponible, required this.seuil, required this.unite});
  final double disponible;
  final double seuil;
  final String unite;

  @override
  Widget build(BuildContext context) {
    final (Color couleur, String texte) = switch (disponible) {
      <= 0 => (Colors.red.shade700, 'Rupture'),
      _ when disponible <= seuil => (Colors.orange.shade800, 'Stock : ${fmtQte(disponible)} $unite'),
      _ => (Colors.green.shade700, 'Stock : ${fmtQte(disponible)} $unite'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texte, style: TextStyle(fontSize: 11, color: couleur, fontWeight: FontWeight.w600)),
    );
  }
}
