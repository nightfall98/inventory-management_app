import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import 'db_service.dart';
import 'firebase_service.dart';

class HybridService {
  static bool get isUserAuthenticated =>
      FirebaseAuth.instance.currentUser != null;

  // Determine which service to use based on authentication status
  static bool get useFirebase => isUserAuthenticated;

  static bool get useSQLite => !useFirebase;

  // Item CRUD operations
  static Future<void> addItem(Item item) async {
    if (useFirebase) {
      await FirebaseService.addItem(item);
    } else {
      await DBService.insertItem(item);
    }
  }

  static Future<void> updateItem(Item item) async {
    if (useFirebase && item.id != null) {
      await FirebaseService.updateItem(item.id!, item);
    } else {
      await DBService.updateItem(item);
    }
  }

  static Future<void> deleteItem(String id) async {
    if (useFirebase) {
      await FirebaseService.deleteItem(id);
    } else {
      await DBService.deleteItem(id);
    }
  }

  static Future<List<Item>> getItems({String? category}) async {
    if (useFirebase) {
      return await FirebaseService.getItems(category: category);
    } else {
      return await DBService.getItems(category: category);
    }
  }

  static Future<List<Item>> searchItems(String query) async {
    if (useFirebase) {
      return await FirebaseService.searchItems(query);
    } else {
      return await DBService.searchItems(query);
    }
  }

  static Future<List<String>> getCategories() async {
    if (useFirebase) {
      return await FirebaseService.getCategories();
    } else {
      return await DBService.getCategories();
    }
  }

  // Stats operations
  static Future<int> getTotalItems() async {
    if (useFirebase) {
      final stats = await FirebaseService.getInventoryStats();
      return stats['totalItems'] ?? 0;
    } else {
      return await DBService.getTotalItems();
    }
  }

  static Future<int> getTotalQuantity() async {
    if (useFirebase) {
      final stats = await FirebaseService.getInventoryStats();
      return stats['totalQuantity'] ?? 0;
    } else {
      return await DBService.getTotalQuantity();
    }
  }

  static Future<Map<String, int>> getCategoryStats() async {
    if (useFirebase) {
      final stats = await FirebaseService.getInventoryStats();
      // Filter out non-category stats
      return Map.fromEntries(
          stats.entries.where((entry) => entry.key.startsWith('category_'))
              .map((entry) => MapEntry(entry.key.substring(9), entry.value))
      );
    } else {
      return await DBService.getCategoryStats();
    }
  }

  // Sync operations
  static Future<void> syncLocalToFirebase() async {
    if (!isUserAuthenticated) return;

    try {
      // Get all local items
      final localItems = await DBService.getItems();

      if (localItems.isNotEmpty) {
        // Sync to Firebase
        await FirebaseService.syncLocalDataToFirebase(localItems);

        // Clear local data after successful sync (optional)
        // await DBService.resetDatabase();
      }
    } catch (e) {
      print('Error syncing local data to Firebase: $e');
      rethrow;
    }
  }

  static Future<void> syncFirebaseToLocal() async {
    if (!isUserAuthenticated) return;

    try {
      // Get all Firebase items
      final firebaseItems = await FirebaseService.getItems();

      // Clear local database
      await DBService.resetDatabase();

      // Insert Firebase items to local database
      for (final item in firebaseItems) {
        await DBService.insertItem(item);
      }
    } catch (e) {
      print('Error syncing Firebase data to local: $e');
      rethrow;
    }
  }

  // Authentication methods
  static Future<bool> signInWithEmailAndPassword(String email,
      String password) async {
    final result = await FirebaseService.signInWithEmailAndPassword(
        email, password);
    if (result != null) {
      // After successful authentication sync data if needed
      await syncLocalToFirebase();
      return true;
    }
    return false;
  }

  static Future<bool> createUserWithEmailAndPassword(String email,
      String password) async {
    final result = await FirebaseService.createUserWithEmailAndPassword(
        email, password);
    if (result != null) {
      // After successful registration, sync local data if any
      await syncLocalToFirebase();
      return true;
    }
    return false;
  }

  static Future<void> signOut() async {
    await FirebaseService.signOut();
    // Optionally clear local data or keep it for offline use
  }

  static User? get currentUser => FirebaseService.currentUser;

  static String? get currentUserId => FirebaseService.currentUserId;

  // Stream operations (Firebase only, falls back to periodic polling for SQLite)
  static Stream<List<Item>> getItemsStream({String? category}) {
    if (useFirebase) {
      return FirebaseService.getItemsStream(category: category);
    } else {
      // For SQLite, we'll return a stream that updates periodically
      return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
        return await DBService.getItems(category: category);
      });
    }
  }
}