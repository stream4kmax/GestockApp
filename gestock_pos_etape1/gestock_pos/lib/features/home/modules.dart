// =============================================================================
//  Déclaration des 6 modules et de leurs sous-menus
// =============================================================================
//  Toute la navigation de l'application est décrite ICI, sous forme de
//  données. Pour ajouter un écran : ajouter un SousModule avec son `builder`.
//  Un SousModule sans builder affiche automatiquement "Bientôt disponible".
//
//  Astuce : tous les documents de vente réutilisent le même écran PosPage,
//  seul le TypeDocument change (le stock, la caisse et le solde client sont
//  gérés automatiquement selon le type).
// =============================================================================

import 'package:flutter/material.dart';

import 'package:gestock_pos/core/constants/type_document.dart';
import 'package:gestock_pos/features/vente/pos_page.dart';

/// Un écran accessible depuis le menu d'un module.
class SousModule {
  const SousModule(this.libelle, this.icone, [this.builder]);
  final String libelle;
  final IconData icone;
  final WidgetBuilder? builder; // null = pas encore développé
}

/// Un des 6 onglets de la barre de navigation inférieure.
class ModuleApp {
  const ModuleApp({
    required this.libelle,
    required this.icone,
    required this.iconeActive,
    required this.couleur,
    required this.sousModules,
    this.avecTableauDeBord = false,
  });
  final String libelle;
  final IconData icone;
  final IconData iconeActive;
  final Color couleur;
  final List<SousModule> sousModules;
  final bool avecTableauDeBord;
}

/// Raccourci : crée le builder d'un écran PosPage pour un type de document.
WidgetBuilder _pos(TypeDocument t) => (_) => PosPage(type: t);

final List<ModuleApp> modulesApp = [
  // 1. VENTE ------------------------------------------------------------------
  ModuleApp(
    libelle: 'Vente',
    icone: Icons.point_of_sale_outlined,
    iconeActive: Icons.point_of_sale,
    couleur: const Color(0xFF1E5AA8),
    avecTableauDeBord: true, // indicateurs du jour en haut de l'accueil
    sousModules: [
      SousModule('Vente électronique (POS)', Icons.shopping_cart_checkout, _pos(TypeDocument.venteComptoir)),
      SousModule('Bon de livraison', Icons.local_shipping_outlined, _pos(TypeDocument.bonLivraison)),
      SousModule('Facture', Icons.receipt_long_outlined, _pos(TypeDocument.factureVente)),
      SousModule('Bon de retour', Icons.assignment_return_outlined, _pos(TypeDocument.retourClient)),
      SousModule('Bon de commande', Icons.shopping_bag_outlined, _pos(TypeDocument.commandeClient)),
      SousModule('Facture proforma', Icons.request_quote_outlined, _pos(TypeDocument.proforma)),
      SousModule('Avoir', Icons.money_off_csred_outlined, _pos(TypeDocument.avoir)),
    ],
  ),

  // 2. ACHAT ------------------------------------------------------------------
  const ModuleApp(
    libelle: 'Achat',
    icone: Icons.shopping_basket_outlined,
    iconeActive: Icons.shopping_basket,
    couleur: Color(0xFF2E7D32),
    sousModules: [
      SousModule('Bon de réception', Icons.move_to_inbox_outlined),
      SousModule('Bon de retour', Icons.outbox_outlined),
      SousModule('Facture', Icons.receipt_outlined),
      SousModule('Bon de commande', Icons.playlist_add_check),
    ],
  ),

  // 3. ARTICLE (STOCK) ------------------------------------------------------- (étape 2)
  const ModuleApp(
    libelle: 'Article',
    icone: Icons.inventory_2_outlined,
    iconeActive: Icons.inventory_2,
    couleur: Color(0xFFEF6C00),
    sousModules: [
      SousModule('Liste des articles', Icons.list_alt),
      SousModule('État du stock', Icons.warehouse_outlined),
      SousModule('Bon d\'entrée', Icons.add_box_outlined),
      SousModule('Bon de sortie', Icons.indeterminate_check_box_outlined),
      SousModule('Mouvements de stock', Icons.swap_vert),
      SousModule('Articles en rupture', Icons.warning_amber_rounded),
      SousModule('Achat par article', Icons.trending_down),
      SousModule('Vente par article', Icons.trending_up),
      SousModule('Familles d\'articles', Icons.category_outlined),
    ],
  ),

  // 4. TRÉSORERIE -------------------------------------------------------------
  const ModuleApp(
    libelle: 'Trésorerie',
    icone: Icons.account_balance_wallet_outlined,
    iconeActive: Icons.account_balance_wallet,
    couleur: Color(0xFF6A1B9A),
    sousModules: [
      SousModule('Mouvement caisse', Icons.compare_arrows),
      SousModule('État de caisse', Icons.savings_outlined),
      SousModule('Règlement client', Icons.price_check),
      SousModule('État de paiement client', Icons.fact_check_outlined),
      SousModule('Relance client', Icons.notifications_active_outlined),
      SousModule('En cours dépassé', Icons.report_gmailerrorred),
      SousModule('Règlement fournisseur', Icons.payments_outlined),
      SousModule('Relance fournisseur', Icons.campaign_outlined),
    ],
  ),

  // 5. PARAMÈTRES -------------------------------------------------------------
  const ModuleApp(
    libelle: 'Paramètres',
    icone: Icons.settings_outlined,
    iconeActive: Icons.settings,
    couleur: Color(0xFF455A64),
    sousModules: [
      SousModule('Société', Icons.business_outlined),
      SousModule('Taxes', Icons.percent),
      SousModule('Commerciaux', Icons.badge_outlined),
      SousModule('Point de vente', Icons.storefront_outlined),
    ],
  ),

  // 6. OUTILS -----------------------------------------------------------------
  const ModuleApp(
    libelle: 'Outils',
    icone: Icons.handyman_outlined,
    iconeActive: Icons.handyman,
    couleur: Color(0xFF00838F),
    sousModules: [
      SousModule('Imprimante', Icons.print_outlined),
      SousModule('Calculatrice', Icons.calculate_outlined),
      SousModule('Options', Icons.tune),
    ],
  ),
];
