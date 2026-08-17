import '../../../core/database/db_provider.dart';
import '../models/saved_item_model.dart';

class ItemService {
  ItemService._();

  /// Fetch all saved items, optionally filtered by category and/or search query.
  static Future<List<SavedItemModel>> getAllItems({
    String? category,
    String? search,
    String orderBy = 'name ASC',
  }) async {
    String? where;
    final List<dynamic> whereArgs = [];

    final conditions = <String>[];

    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      whereArgs.add(category);
    }

    if (search != null && search.isNotEmpty) {
      conditions.add('(name LIKE ? OR description LIKE ? OR hsn_code LIKE ?)');
      final q = '%$search%';
      whereArgs.addAll([q, q, q]);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }

    final rows = await DbProvider.query(
      DbProvider.tableSavedItems,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
    );

    return rows.map(SavedItemModel.fromMap).toList();
  }

  /// Fetch a single saved item by ID.
  static Future<SavedItemModel?> getItem(String id) async {
    final rows = await DbProvider.query(
      DbProvider.tableSavedItems,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SavedItemModel.fromMap(rows.first);
  }

  /// Create a new saved item.
  static Future<String> createItem(SavedItemModel item) async {
    return DbProvider.insert(DbProvider.tableSavedItems, item.toMap());
  }

  /// Update an existing saved item.
  static Future<int> updateItem(SavedItemModel item) async {
    return DbProvider.update(
      DbProvider.tableSavedItems,
      item.toMap(),
      'id = ?',
      [item.id],
    );
  }

  /// Delete a saved item by ID.
  static Future<int> deleteItem(String id) async {
    return DbProvider.delete(
      DbProvider.tableSavedItems,
      'id = ?',
      [id],
    );
  }

  /// Fetch all distinct categories from saved items.
  static Future<List<String>> getCategories() async {
    final rows = await DbProvider.rawQuery(
      'SELECT DISTINCT category FROM ${DbProvider.tableSavedItems} '
      'WHERE category IS NOT NULL AND category != \'\' '
      'ORDER BY category ASC',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Total count of saved items.
  static Future<int> getItemCount() async {
    final rows = await DbProvider.rawQuery(
      'SELECT COUNT(*) FROM ${DbProvider.tableSavedItems}',
    );
    return (rows.first.values.first as int?) ?? 0;
  }
}
