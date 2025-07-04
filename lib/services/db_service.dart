import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/item.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

class DBService {
  static Database? _db;
  static SharedPreferences? _prefs;
  static List<Item> _webItems = [];
  static bool _webInitialized = false;

  static Future<Database?> get db async {
    if (kIsWeb) return null; // No SQLite on web
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> _initWebStorage() async {
    if (_webInitialized) return;

    final prefsInstance = await prefs;
    final itemsJson = prefsInstance.getString('imm_items');

    if (itemsJson != null) {
      final List<dynamic> itemsList = jsonDecode(itemsJson);
      _webItems = itemsList.map((item) => Item.fromMap(item)).toList();
    } else {
      // Add sample data for testing
      _webItems = [
        Item(
          id: '1',
          name: 'Sample Laptop',
          quantity: 5,
          category: 'Electronics',
          description: 'Sample laptop for testing',
          createdAt: DateTime.now().toIso8601String(),
        ),
        Item(
          id: '2',
          name: 'Office Chairs',
          quantity: 10,
          category: 'Office',
          description: 'Ergonomic office chairs',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
      await _saveWebItems();
    }

    _webInitialized = true;
  }

  static Future<void> _saveWebItems() async {
    final prefsInstance = await prefs;
    final itemsJson =
        jsonEncode(_webItems.map((item) => item.toMap()).toList());
    await prefsInstance.setString('imm_items', itemsJson);
  }

  static Future<Database?> initDB() async {
    if (kIsWeb) {
      await _initWebStorage();
      return null;
    }

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'imm.db');

      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              quantity INTEGER NOT NULL DEFAULT 0,
              category TEXT NOT NULL,
              description TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              user_id TEXT
            )
          ''');

          // Insert some sample data for testing
          await db.insert('items', {
            'name': 'Sample Laptop',
            'quantity': 5,
            'category': 'Electronics',
            'description': 'Sample laptop for testing',
            'created_at': DateTime.now().toIso8601String(),
          });

          await db.insert('items', {
            'name': 'Office Chairs',
            'quantity': 10,
            'category': 'Office',
            'description': 'Ergonomic office chairs',
            'created_at': DateTime.now().toIso8601String(),
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Check if columns exist before adding them
            final tableInfo = await db.rawQuery('PRAGMA table_info(items)');
            final columns =
                tableInfo.map((row) => row['name'] as String).toList();

            if (!columns.contains('description')) {
              await db.execute('ALTER TABLE items ADD COLUMN description TEXT');
            }
            if (!columns.contains('created_at')) {
              await db.execute(
                  'ALTER TABLE items ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP');
            }
          }
          if (oldVersion < 3) {
            // Check if user_id column exists
            final tableInfo = await db.rawQuery('PRAGMA table_info(items)');
            final columns =
                tableInfo.map((row) => row['name'] as String).toList();

            if (!columns.contains('user_id')) {
              await db.execute('ALTER TABLE items ADD COLUMN user_id TEXT');
            }
          }
        },
      );
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  static Future<void> insertItem(Item item) async {
    try {
      // Set user ID if authenticated
      final userId = await AuthService.getCurrentUserId();
      final itemWithUser = item.copyWith(userId: userId);

      if (kIsWeb) {
        await _initWebStorage();
        final newItem = Item(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: itemWithUser.name,
          quantity: itemWithUser.quantity,
          category: itemWithUser.category,
          description: itemWithUser.description,
          createdAt: DateTime.now().toIso8601String(),
          userId: itemWithUser.userId,
        );
        _webItems.add(newItem);
        await _saveWebItems();

        // Sync to Firebase if authenticated
        if (AuthService.isFirebaseAvailable &&
            AuthService.currentUser != null) {
          try {
            await FirebaseService.syncItemToFirestore(newItem);
          } catch (e) {
            print('Failed to sync to Firebase: $e');
          }
        }
      } else {
        final dbClient = await db;
        if (dbClient == null) return;

        final itemData = itemWithUser.toMap();
        // Convert String ID back to int for SQLite auto-increment
        itemData.remove('id');
        itemData['user_id'] =
            itemData.remove('userId'); // Map userId to user_id for SQLite

        await dbClient.insert(
          'items',
          itemData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Sync to Firebase if authenticated
        if (AuthService.isFirebaseAvailable &&
            AuthService.currentUser != null) {
          try {
            await FirebaseService.syncItemToFirestore(itemWithUser);
          } catch (e) {
            print('Failed to sync to Firebase: $e');
          }
        }
      }
    } catch (e) {
      print('Insert item error: $e');
      rethrow;
    }
  }

  static Future<List<Item>> getItems({String? category}) async {
    try {
      List<Item> localItems = [];

      if (kIsWeb) {
        await _initWebStorage();
        if (category != null) {
          localItems = _webItems
              .where((item) => item.category == category)
              .toList()
            ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        } else {
          localItems = List.from(_webItems)
            ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        }
      } else {
        final dbClient = await db;
        if (dbClient == null) return [];

        final maps = await dbClient.query(
          'items',
          where: category != null ? 'category = ?' : null,
          whereArgs: category != null ? [category] : null,
          orderBy: 'created_at DESC',
        );
        localItems = maps.map((map) {
          // Convert SQLite format to Item format
          final itemMap = Map<String, dynamic>.from(map);
          itemMap['userId'] =
              itemMap.remove('user_id'); // Map user_id back to userId
          return Item.fromMap(itemMap);
        }).toList();
      }

      // If user is authenticated with Firebase, merge with Firestore data
      if (AuthService.isFirebaseAvailable && AuthService.currentUser != null) {
        try {
          return await FirebaseService.mergeData(localItems);
        } catch (e) {
          print('Failed to merge Firebase data: $e');
          return localItems;
        }
      }

      return localItems;
    } catch (e) {
      print('Get items error: $e');
      return [];
    }
  }

  static Future<List<Item>> searchItems(String query) async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        return _webItems
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.category.toLowerCase().contains(query.toLowerCase()) ||
                (item.description
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList()
          ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      } else {
        final dbClient = await db;
        if (dbClient == null) return [];

        final maps = await dbClient.query(
          'items',
          where: 'name LIKE ? OR category LIKE ? OR description LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'created_at DESC',
        );
        return maps.map((map) {
          final itemMap = Map<String, dynamic>.from(map);
          itemMap['userId'] = itemMap.remove('user_id');
          return Item.fromMap(itemMap);
        }).toList();
      }
    } catch (e) {
      print('Search items error: $e');
      return [];
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        final categories =
            _webItems.map((item) => item.category).toSet().toList();
        categories.sort();
        return categories;
      } else {
        final dbClient = await db;
        if (dbClient == null) return [];

        final maps = await dbClient.query(
          'items',
          columns: ['DISTINCT category'],
          orderBy: 'category',
        );
        return maps.map((e) => e['category'] as String).toList();
      }
    } catch (e) {
      print('Get categories error: $e');
      return [];
    }
  }

  static Future<void> updateItem(Item item) async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        final index = _webItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _webItems[index] = item;
          await _saveWebItems();
        }
      } else {
        final dbClient = await db;
        if (dbClient == null) return;

        final itemData = item.toMap();
        final id = itemData.remove('id');
        itemData['user_id'] = itemData.remove('userId');

        await dbClient.update(
          'items',
          itemData,
          where: 'id = ?',
          whereArgs: [int.tryParse(id?.toString() ?? '0') ?? 0],
        );
      }
    } catch (e) {
      print('Update item error: $e');
      rethrow;
    }
  }

  static Future<void> deleteItem(String id) async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        _webItems.removeWhere((item) => item.id == id);
        await _saveWebItems();
      } else {
        final dbClient = await db;
        if (dbClient == null) return;

        await dbClient.delete(
          'items',
          where: 'id = ?',
          whereArgs: [int.tryParse(id) ?? 0],
        );
      }
    } catch (e) {
      print('Delete item error: $e');
      rethrow;
    }
  }

  static Future<int> getTotalItems() async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        return _webItems.length;
      } else {
        final dbClient = await db;
        if (dbClient == null) return 0;

        final result =
            await dbClient.rawQuery('SELECT COUNT(*) as count FROM items');
        return (result.first['count'] as int?) ?? 0;
      }
    } catch (e) {
      print('Get total items error: $e');
      return 0;
    }
  }

  static Future<int> getTotalQuantity() async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        return _webItems.fold<int>(0, (sum, item) => sum + item.quantity);
      } else {
        final dbClient = await db;
        if (dbClient == null) return 0;

        final result =
            await dbClient.rawQuery('SELECT SUM(quantity) as total FROM items');
        return (result.first['total'] as int?) ?? 0;
      }
    } catch (e) {
      print('Get total quantity error: $e');
      return 0;
    }
  }

  static Future<Map<String, int>> getCategoryStats() async {
    try {
      if (kIsWeb) {
        await _initWebStorage();
        Map<String, int> stats = {};
        for (var item in _webItems) {
          stats[item.category] = (stats[item.category] ?? 0) + 1;
        }
        return stats;
      } else {
        final dbClient = await db;
        if (dbClient == null) return {};

        final result = await dbClient.rawQuery(
          'SELECT category, COUNT(*) as count FROM items GROUP BY category ORDER BY category',
        );
        Map<String, int> stats = {};
        for (var row in result) {
          stats[row['category'] as String] = row['count'] as int;
        }
        return stats;
      }
    } catch (e) {
      print('Get category stats error: $e');
      return {};
    }
  }

  // Add method to reset database for testing
  static Future<void> resetDatabase() async {
    try {
      if (kIsWeb) {
        _webItems.clear();
        final prefsInstance = await prefs;
        await prefsInstance.remove('imm_items');
        _webInitialized = false;
      } else {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'imm.db');
        await deleteDatabase(path);
        _db = null;
      }
    } catch (e) {
      print('Reset database error: $e');
    }
  }
}
