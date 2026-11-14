import 'package:gestock_pos/core/constants/app_constants.dart';
import 'package:gestock_pos/core/database/database_helper.dart';
import 'package:gestock_pos/data/models/client.dart';

class ClientRepository {
  /// Tous les clients, le client comptoir en premier.
  Future<List<Client>> tous() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'clients',
      where: 'deleted = 0',
      orderBy: "CASE WHEN id = '$kClientComptoirId' THEN 0 ELSE 1 END, nom COLLATE NOCASE",
    );
    return rows.map(Client.fromMap).toList();
  }

  Future<Client?> parId(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('clients', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Client.fromMap(rows.first);
  }
}
