// Accès aux articles. Les écrans ne parlent JAMAIS directement à SQLite :
// ils passent par un repository. Le jour où l'on change de base, seul ce
// fichier change.

import 'package:gestock_pos/core/database/database_helper.dart';
import 'package:gestock_pos/data/models/article.dart';

class ArticleRepository {
  /// Recherche par désignation, code ou code-barres exact.
  /// Requête vide → tous les articles actifs, triés par nom.
  Future<List<Article>> rechercher(String saisie, {int limite = 200}) async {
    final db = await DatabaseHelper.instance.database;
    final q = saisie.trim();

    final rows = await db.query(
      'articles',
      where: q.isEmpty
          ? 'deleted = 0 AND actif = 1'
          : 'deleted = 0 AND actif = 1 AND (designation LIKE ? OR code LIKE ? OR code_barre = ?)',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', q],
      orderBy: 'designation COLLATE NOCASE', // tri insensible à la casse
      limit: limite,
    );
    return rows.map(Article.fromMap).toList();
  }

  /// Recherche exacte par code-barres (ou code article) — utilisée par la
  /// douchette / le lecteur de codes-barres.
  Future<Article?> parCodeBarre(String code) async {
    if (code.trim().isEmpty) return null;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'articles',
      where: 'deleted = 0 AND actif = 1 AND (code_barre = ? OR code = ?)',
      whereArgs: [code.trim(), code.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Article.fromMap(rows.first);
  }
}
