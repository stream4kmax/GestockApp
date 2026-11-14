// =============================================================================
//  PosPage — écran de vente (Vente électronique, BL, Facture, Avoir…)
// =============================================================================
//  Disposition (téléphone) :
//   ┌──────────────────────────────┐
//   │ AppBar : type de document    │
//   │ Client : Client comptoir  ▸  │
//   ├──────────────────────────────┤
//   │ 🔍 Recherche / code-barres   │
//   │ Liste des articles (tap = +1)│
//   ├──────────────────────────────┤
//   │ HT · TVA · TTC  [Panier][OK] │  ← barre des totaux
//   └──────────────────────────────┘
//
//  Le panier (CartProvider) est créé PAR écran : chaque document a son propre
//  panier, et il est détruit automatiquement quand on quitte l'écran.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestock_pos/core/constants/app_constants.dart';
import 'package:gestock_pos/core/constants/type_document.dart';
import 'package:gestock_pos/core/utils/formatters.dart';
import 'package:gestock_pos/data/models/article.dart';
import 'package:gestock_pos/data/models/client.dart';
import 'package:gestock_pos/data/models/paiement.dart';
import 'package:gestock_pos/data/repositories/article_repository.dart';
import 'package:gestock_pos/data/repositories/client_repository.dart';
import 'package:gestock_pos/data/repositories/vente_repository.dart';
import 'package:gestock_pos/features/vente/cart_provider.dart';
import 'package:gestock_pos/features/vente/widgets/article_tile.dart';
import 'package:gestock_pos/features/vente/widgets/cart_sheet.dart';
import 'package:gestock_pos/features/vente/widgets/paiement_dialog.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key, required this.type});
  final TypeDocument type;

  @override
  Widget build(BuildContext context) {
    // Fournit un panier neuf à cet écran et à tous ses descendants.
    return ChangeNotifierProvider(
      create: (_) => CartProvider(controleStock: type.controleStock),
      child: _PosView(type: type),
    );
  }
}

class _PosView extends StatefulWidget {
  const _PosView({required this.type});
  final TypeDocument type;

  @override
  State<_PosView> createState() => _PosViewState();
}

class _PosViewState extends State<_PosView> {
  final _articleRepo = ArticleRepository();
  final _clientRepo = ClientRepository();
  final _venteRepo = VenteRepository();

  final _rechercheCtrl = TextEditingController();
  final _rechercheFocus = FocusNode();
  Timer? _debounce; // évite une requête SQL à chaque lettre tapée

  List<Article> _articles = [];
  Client? _clientComptoir;
  bool _chargement = true;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _chargerClientParDefaut();
    _chargerArticles();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rechercheCtrl.dispose();
    _rechercheFocus.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  //  Chargement des données
  // --------------------------------------------------------------------------

  Future<void> _chargerClientParDefaut() async {
    _clientComptoir = await _clientRepo.parId(kClientComptoirId);
    if (!mounted || _clientComptoir == null) return;
    context.read<CartProvider>().definirClient(_clientComptoir!);
  }

  Future<void> _chargerArticles([String recherche = '']) async {
    setState(() => _chargement = true);
    final resultat = await _articleRepo.rechercher(recherche);
    if (!mounted) return;
    setState(() {
      _articles = resultat;
      _chargement = false;
    });
  }

  /// Recherche "en direct" : on attend 300 ms après la dernière frappe.
  void _onRechercheChange(String valeur) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _chargerArticles(valeur));
    setState(() {}); // pour afficher/masquer le bouton ✕
  }

  /// Touche Entrée. Les douchettes Bluetooth/USB se comportent comme un
  /// clavier : elles "tapent" le code-barres puis Entrée → ajout direct au panier.
  Future<void> _onRechercheValidee(String valeur) async {
    final article = await _articleRepo.parCodeBarre(valeur);
    if (article != null) {
      _ajouter(article);
      _rechercheCtrl.clear();
      _chargerArticles();
    }
    _rechercheFocus.requestFocus(); // prêt pour le scan suivant
  }

  // --------------------------------------------------------------------------
  //  Actions sur le panier
  // --------------------------------------------------------------------------

  void _ajouter(Article article) {
    final erreur = context.read<CartProvider>().ajouter(article);
    if (erreur != null) _message(erreur, erreur: true);
  }

  Future<void> _ouvrirPanier() async {
    final cart = context.read<CartProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      // La feuille est une nouvelle "route" : elle n'hérite pas du Provider de
      // cet écran. On lui transmet donc le MÊME panier avec .value.
      builder: (_) => ChangeNotifierProvider.value(value: cart, child: const CartSheet()),
    );
  }

  Future<void> _confirmerVider() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Toutes les lignes seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vider')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<CartProvider>().vider();
  }

  Future<void> _choisirClient() async {
    final clients = await _clientRepo.tous();
    if (!mounted) return;
    final choisi = await showModalBottomSheet<Client>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          for (final c in clients)
            ListTile(
              leading: Icon(c.estComptoir ? Icons.storefront : Icons.person_outline),
              title: Text(c.nom),
              subtitle: c.estComptoir
                  ? const Text('Vente anonyme, paiement comptant')
                  : Text('Solde : ${fmtMonnaie(c.solde)}'
                      '${c.encoursDepasse ? '  ⚠ En cours dépassé' : ''}',
                      style: c.encoursDepasse ? TextStyle(color: Theme.of(ctx).colorScheme.error) : null),
              onTap: () => Navigator.pop(ctx, c),
            ),
        ],
      ),
    );
    if (choisi != null && mounted) context.read<CartProvider>().definirClient(choisi);
  }

  // --------------------------------------------------------------------------
  //  Validation du document
  // --------------------------------------------------------------------------

  Future<void> _valider() async {
    final cart = context.read<CartProvider>();
    final client = cart.client;
    if (client == null || cart.estVide) return;
    final totaux = cart.totaux;

    // 1. Paiement (pas de paiement pour une proforma ou un bon de commande)
    var paiement = Paiement.aucun;
    if (widget.type.avecPaiement) {
      final p = await showDialog<Paiement>(
        context: context,
        builder: (_) => PaiementDialog(
          total: totaux.ttc,
          creditAutorise: !client.estComptoir,
          titre: widget.type.effetCompte < 0 ? 'Remboursement' : 'Encaissement',
        ),
      );
      if (p == null) return; // l'utilisateur a annulé
      paiement = p;
    }

    // 2. Enregistrement en base (transaction)
    setState(() => _enregistrement = true);
    try {
      final doc = await _venteRepo.enregistrer(
        type: widget.type,
        client: client,
        lignes: cart.lignes,
        totaux: totaux,
        paiement: paiement,
      );
      if (!mounted) return;

      // 3. Confirmation
      await _afficherSucces(doc, totaux, paiement);

      // 4. Prêt pour la vente suivante : panier vide, client comptoir, stock à jour
      cart.vider();
      if (_clientComptoir != null) cart.definirClient(_clientComptoir!);
      _chargerArticles(_rechercheCtrl.text);
    } catch (e) {
      _message('Erreur : $e', erreur: true);
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  Future<void> _afficherSucces(DocumentEnregistre doc, TotauxPanier t, Paiement p) {
    final rendu = p.rendu(t.ttc);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text('${widget.type.libelle} enregistré(e)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(doc.numero, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total TTC : ${fmtMonnaie(t.ttc)}'),
            if (rendu > 0)
              Text('Rendu monnaie : ${fmtMonnaie(rendu)}',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Colors.green.shade700)),
          ],
        ),
        actions: [
          // ÉTAPE 3 : ajouter ici les boutons "Imprimer", "Partager PDF" et
          // "WhatsApp" (ils recevront doc.id pour générer la facture PDF).
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nouvelle vente')),
        ],
      ),
    );
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texte),
        backgroundColor: erreur ? Theme.of(context).colorScheme.error : null,
      ));
  }

  // --------------------------------------------------------------------------
  //  Interface
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // watch : cet écran se redessine à chaque modification du panier.
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.libelle),
        actions: [
          IconButton(
            tooltip: 'Vider le panier',
            icon: const Icon(Icons.remove_shopping_cart_outlined),
            onPressed: cart.estVide ? null : _confirmerVider,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _BarreClient(client: cart.client, onTap: _choisirClient),
        ),
      ),
      body: Column(
        children: [
          // Champ de recherche / scan
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _rechercheCtrl,
              focusNode: _rechercheFocus,
              textInputAction: TextInputAction.search,
              onChanged: _onRechercheChange,
              onSubmitted: _onRechercheValidee,
              decoration: InputDecoration(
                hintText: 'Rechercher : nom, code ou code-barres…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _rechercheCtrl.text.isEmpty
                    ? const Icon(Icons.qr_code_scanner) // étape suivante : scan caméra (mobile_scanner)
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _rechercheCtrl.clear();
                          _onRechercheChange('');
                        },
                      ),
              ),
            ),
          ),

          // Liste des articles
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _articles.isEmpty
                    ? const Center(child: Text('Aucun article trouvé'))
                    : RefreshIndicator(
                        onRefresh: () => _chargerArticles(_rechercheCtrl.text),
                        child: ListView.separated(
                          itemCount: _articles.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) {
                            final a = _articles[i];
                            return ArticleTile(
                              article: a,
                              quantiteDansPanier: cart.quantiteDe(a.id),
                              onTap: () => _ajouter(a),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _BarreTotaux(
        totaux: cart.totaux,
        nbLignes: cart.nbLignes,
        libelleValider: widget.type.avecPaiement ? 'Encaisser' : 'Enregistrer',
        enCours: _enregistrement,
        onPanier: _ouvrirPanier,
        onValider: cart.estVide || _enregistrement ? null : _valider,
      ),
    );
  }
}

/// Bandeau cliquable sous l'AppBar affichant le client sélectionné.
class _BarreClient extends StatelessWidget {
  const _BarreClient({required this.client, required this.onTap});
  final Client? client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = client;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(c?.estComptoir ?? true ? Icons.storefront : Icons.person, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(c?.nom ?? 'Choisir un client',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (c != null && !c.estComptoir)
              Text('Solde ${fmtMonnaie(c.solde)}',
                  style: TextStyle(fontSize: 12, color: c.encoursDepasse ? scheme.error : null)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Barre du bas : totaux + boutons Panier et Encaisser.
class _BarreTotaux extends StatelessWidget {
  const _BarreTotaux({
    required this.totaux,
    required this.nbLignes,
    required this.libelleValider,
    required this.enCours,
    required this.onPanier,
    required this.onValider,
  });

  final TotauxPanier totaux;
  final int nbLignes;
  final String libelleValider;
  final bool enCours;
  final VoidCallback onPanier;
  final VoidCallback? onValider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              // Totaux
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HT ${fmtMonnaie(totaux.ht)}  ·  TVA ${fmtMonnaie(totaux.tva)}',
                        style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('TTC ${fmtMonnaie(totaux.ttc)}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // Panier (avec badge du nombre de lignes)
              IconButton.filledTonal(
                tooltip: 'Voir le panier',
                onPressed: onPanier,
                icon: Badge(
                  isLabelVisible: nbLignes > 0,
                  label: Text('$nbLignes'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
              const SizedBox(width: 8),
              // Encaisser / Enregistrer
              FilledButton.icon(
                onPressed: onValider,
                icon: enCours
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(libelleValider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
