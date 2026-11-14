# GeStock POS — Architecture (étape 1)

## 1. Principe général : « hors ligne d'abord »

```
 ┌────────────── Téléphone Android ──────────────┐          ┌──────── Cloud ────────┐
 │  Écrans Flutter (features/)                   │          │                       │
 │        │                                      │          │  Firebase Auth        │
 │        ▼                                      │          │  (comptes utilisateurs)│
 │  Repositories (data/repositories/)            │  sync    │                       │
 │        │                                      │ ◄──────► │  Cloud Firestore      │
 │        ▼                                      │ (étape 5)│  /societes/{id}/...   │
 │  SQLite local (gestock.db) ← source principale│          │                       │
 └───────────────────────────────────────────────┘          └───────────────────────┘
```

* Toutes les lectures et écritures passent par **SQLite** : l'application fonctionne sans internet.
* Chaque ligne modifiée porte `sync_status = 1`. Le futur `SyncService` envoie ces lignes vers Firestore dès que le réseau revient, puis les repasse à `0`.
* Les conflits se règlent par `updated_at` : la modification la plus récente l'emporte.
* **Stock multi-appareils** : on synchronise le journal `mouvements_stock` (on ne fait qu'y ajouter des lignes) et on recalcule `articles.stock = Σ(sens × quantité)`. Le stock reste juste même si deux caisses vendent le même article hors ligne.

## 2. Arborescence

```
gestock_pos/
├── pubspec.yaml
├── ARCHITECTURE.md
├── README.md                          ← compilation de l'APK
└── lib/
    ├── main.dart                      ← initialisation + MaterialApp
    ├── core/
    │   ├── constants/
    │   │   ├── app_constants.dart     ← client comptoir, code du point de vente
    │   │   ├── type_document.dart     ← 13 types de documents + effets stock/compte
    │   │   └── mode_paiement.dart
    │   ├── database/
    │   │   ├── database_helper.dart   ← ouverture SQLite (singleton) + migrations
    │   │   ├── database_schema.dart   ← CREATE TABLE commentés
    │   │   └── database_seed.dart     ← données de démonstration
    │   ├── theme/app_theme.dart
    │   └── utils/ (formatters.dart, ids.dart)
    ├── data/
    │   ├── models/        (article, client, ligne_panier, paiement)
    │   └── repositories/  (article, client, vente, dashboard)
    ├── features/
    │   ├── home/          ← accueil : barre à 6 onglets, menus, tableau de bord
    │   │   ├── home_shell.dart
    │   │   ├── modules.dart           ← TOUTE la navigation décrite ici
    │   │   ├── module_menu_page.dart
    │   │   ├── dashboard_header.dart
    │   │   └── placeholder_page.dart
    │   ├── vente/         ← ✅ étape 1
    │   │   ├── pos_page.dart
    │   │   ├── cart_provider.dart     ← calcul HT / remise / TVA / TTC
    │   │   └── widgets/ (article_tile, cart_sheet, paiement_dialog)
    │   ├── achat/         ← à venir
    │   ├── article/       ← étape 2 (alertes de rupture)
    │   ├── tresorerie/    ← à venir
    │   ├── parametres/    ← à venir
    │   └── outils/        ← à venir
    └── services/          ← étape 3 : pdf_service, messaging_service ; étape 5 : sync_service
```

## 3. Tables SQLite

Colonnes communes à toutes les tables métier : `id` (UUID), `created_at`, `updated_at`, `deleted`, `sync_status`.

| Table | Module | Rôle | Colonnes clés |
|---|---|---|---|
| `societe` | Paramètres | En-tête des factures | raison_sociale, nif, nis, rc, art, rib, logo_path |
| `taxes` | Paramètres | Taux de TVA | libelle, taux, par_defaut |
| `commerciaux` | Paramètres | Vendeurs | nom, taux_commission |
| `points_vente` | Paramètres | Magasins / caisses | code (PV1), libelle |
| `familles` | Article | Familles (arborescence) | libelle, parent_id |
| `articles` | Article | Fiche + stock | code, code_barre, prix_achat_ht, prix_vente_ht, taux_tva, **stock**, **stock_min** |
| `clients` | Vente / Trésorerie | Fiche client | telephone, **whatsapp**, **email**, solde, plafond_credit |
| `fournisseurs` | Achat | Fiche fournisseur | telephone, whatsapp, email, solde |
| `documents` | Tous | En-tête de **tous** les bons et factures | numero, type_doc, tiers_id, document_source_id, total_ht, total_tva, total_ttc, montant_paye, statut |
| `document_lignes` | Tous | Lignes (prix copiés) | article_id, quantite, prix_unitaire_ht, remise_pct, taux_tva, montants |
| `mouvements_stock` | Article | Journal des entrées et sorties | article_id, sens (+1/−1), quantite, document_id |
| `reglements` | Trésorerie | Paiements client / fournisseur | tiers_type, tiers_id, document_id, sens, montant, mode |
| `mouvements_caisse` | Trésorerie | Espèces | sens, montant, libelle, source_id |
| `messages` | Messagerie | Historique WhatsApp / SMS / Email (+ relances) | canal, objet, destinataire, contenu, piece_jointe |
| `compteurs` | technique | Numérotation des documents | type_doc, point_vente, annee, dernier |
| `parametres` | Outils > Options | Clé / valeur | cle, valeur |

### Types de documents (`documents.type_doc`)

| Code | Document | Stock | Compte tiers |
|---|---|---|---|
| VC | Vente comptoir (POS) | −1 | +1 |
| BL | Bon de livraison | −1 | +1 |
| FV | Facture (sans effet sur le stock si elle vient d'un BL) | −1 | +1 |
| RC | Retour client | +1 | −1 |
| CC | Commande client | 0 | 0 |
| PF | Proforma | 0 | 0 |
| AV | Avoir | +1 | −1 |
| BR | Réception fournisseur | +1 | +1 |
| RF | Retour fournisseur | −1 | −1 |
| FA | Facture d'achat | +1 | +1 |
| CF | Commande fournisseur | 0 | 0 |
| BE / BS | Bon d'entrée / de sortie | +1 / −1 | 0 |

### Requêtes des futurs états (exemples)

* **État de caisse** : `SELECT SUM(sens * montant) FROM mouvements_caisse WHERE deleted = 0`
* **Articles en rupture** : `SELECT * FROM articles WHERE stock <= stock_min`
* **En cours dépassé** : `SELECT * FROM clients WHERE plafond_credit > 0 AND solde > plafond_credit`
* **Vente par article** : `SELECT article_id, SUM(quantite), SUM(montant_ttc) FROM document_lignes l JOIN documents d ON d.id = l.document_id WHERE d.type_doc IN ('VC','BL','FV') GROUP BY article_id`

## 4. Structure Firestore (étape 5)

Plusieurs entreprises peuvent partager le même projet Firebase : chaque entreprise a ses propres données.

```
users/{uid}                         → { societeId, role: 'admin' | 'vendeur', pointVenteId }
societes/{societeId}
   ├── articles/{articleId}         → mêmes champs que SQLite + updatedAt
   ├── clients/{clientId}
   ├── fournisseurs/{id}
   ├── familles/{id}  taxes/{id}  commerciaux/{id}  points_vente/{id}
   ├── documents/{documentId}       → en-tête
   │     └── lignes/{ligneId}       → sous-collection
   ├── mouvements_stock/{id}        → on ne fait qu'ajouter (append-only)
   ├── reglements/{id}
   ├── mouvements_caisse/{id}
   └── messages/{id}
```

Règle de sécurité (principe) : un utilisateur ne lit et n'écrit que dans `societes/{son societeId}`.
