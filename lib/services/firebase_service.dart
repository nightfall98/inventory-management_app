import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import 'auth_service.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;

  static FirebaseFirestore? get _db {
    try {
      _firestore ??= FirebaseFirestore.instance;
      return _firestore;
    } catch (e) {
      print('Firestore not available: $e');
      return null;
    }
  }

  // Check if Firestore is available
  static bool get isAvailable => _db != null;

  // Get current user's collection reference
  static CollectionReference<Map<String, dynamic>>? get _userItemsCollection {
    final userId = currentUserId;
    if (!isAvailable || userId == null) return null;

    return _db!.collection('users').doc(userId).collection('items');
  }

  // Authentication methods
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static String? get currentUserId => currentUser?.uid;

  static Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await initializeUserCollection();
      return credential.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  static Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await initializeUserCollection();
      return credential.user;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Item CRUD operations
  static Future<void> addItem(Item item) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      final data = item.toFirestore();
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _userItemsCollection!.add(data);
      print('Item added to Firestore');
    } catch (e) {
      print('Error adding item to Firestore: $e');
      rethrow;
    }
  }

  static Future<void> updateItem(String id, Item item) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      final data = item.toFirestore();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _userItemsCollection!.doc(id).set(data, SetOptions(merge: true));
      print('Item updated in Firestore');
    } catch (e) {
      print('Error updating item in Firestore: $e');
      rethrow;
    }
  }

  static Future<void> deleteItem(String id) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      await _userItemsCollection!.doc(id).delete();
      print('Item deleted from Firestore: $id');
    } catch (e) {
      print('Error deleting item from Firestore: $e');
      rethrow;
    }
  }

  static Future<List<Item>> getItems({String? category}) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return [];
    }

    try {
      Query<Map<String, dynamic>> query =
          _userItemsCollection!.orderBy('created_at', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Item.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error getting items from Firestore: $e');
      return [];
    }
  }

  static Future<List<Item>> searchItems(String query) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return [];
    }

    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - for production, consider using Algolia or similar
      final snapshot = await _userItemsCollection!.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Item.fromFirestore(data);
      }).where((item) {
        final searchLower = query.toLowerCase();
        return item.name.toLowerCase().contains(searchLower) ||
            item.category.toLowerCase().contains(searchLower) ||
            (item.description?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching items in Firestore: $e');
      return [];
    }
  }

  static Future<List<String>> getCategories() async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return [];
    }

    try {
      final snapshot = await _userItemsCollection!.get();
      final categories = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories from Firestore: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getInventoryStats() async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return {};
    }

    try {
      final snapshot = await _userItemsCollection!.get();
      final stats = <String, dynamic>{};
      final categoryStats = <String, int>{};
      int totalItems = 0;
      int totalQuantity = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalItems++;

        final quantity = data['quantity'] as int? ?? 0;
        totalQuantity += quantity;

        final category = data['category'] as String? ?? 'Uncategorized';
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }

      stats['totalItems'] = totalItems;
      stats['totalQuantity'] = totalQuantity;

      // Add category stats with prefix
      for (var entry in categoryStats.entries) {
        stats['category_${entry.key}'] = entry.value;
      }

      return stats;
    } catch (e) {
      print('Error getting inventory stats from Firestore: $e');
      return {};
    }
  }

  static Future<void> syncLocalDataToFirebase(List<Item> localItems) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      for (var item in localItems) {
        final data = item.toFirestore();
        data['created_at'] = item.createdAt ?? DateTime.now().toIso8601String();
        data['updated_at'] = DateTime.now().toIso8601String();

        if (item.id != null && item.id!.isNotEmpty) {
          await _userItemsCollection!
              .doc(item.id)
              .set(data, SetOptions(merge: true));
        } else {
          await _userItemsCollection!.add(data);
        }
      }
      print('Local data synced to Firestore: ${localItems.length} items');
    } catch (e) {
      print('Error syncing local data to Firestore: $e');
      rethrow;
    }
  }

  // Stream operations
  static Stream<List<Item>> getItemsStream({String? category}) {
    if (!isAvailable || _userItemsCollection == null) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query =
        _userItemsCollection!.orderBy('created_at', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Item.fromFirestore(data);
      }).toList();
    });
  }

  // Sync local item to Firestore
  static Future<void> syncItemToFirestore(Item item) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      final data = item.toFirestore();
      data['created_at'] = item.createdAt ?? DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      if (item.id != null && item.id!.isNotEmpty) {
        // Update existing item
        await _userItemsCollection!
            .doc(item.id)
            .set(data, SetOptions(merge: true));
      } else {
        // Create new item
        final docRef = await _userItemsCollection!.add(data);
        print('Item synced to Firestore with ID: ${docRef.id}');
      }
    } catch (e) {
      print('Error syncing item to Firestore: $e');
      rethrow;
    }
  }

  // Sync all local items to Firestore
  static Future<void> syncAllItemsToFirestore(List<Item> items) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      final batch = _db!.batch();

      for (var item in items) {
        final data = item.toFirestore();
        data['created_at'] = item.createdAt ?? DateTime.now().toIso8601String();
        data['updated_at'] = DateTime.now().toIso8601String();

        if (item.id != null && item.id!.isNotEmpty) {
          batch.set(_userItemsCollection!.doc(item.id), data,
              SetOptions(merge: true));
        } else {
          // For new items without ID, we need to use add() which can't be batched
          // So we'll handle these separately
          await _userItemsCollection!.add(data);
        }
      }

      await batch.commit();
      print('Batch sync completed for ${items.length} items');
    } catch (e) {
      print('Error batch syncing items to Firestore: $e');
      rethrow;
    }
  }

  // Get all items from Firestore
  static Future<List<Item>> getItemsFromFirestore() async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return [];
    }

    try {
      final snapshot = await _userItemsCollection!
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add the document ID
        return Item.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error getting items from Firestore: $e');
      return [];
    }
  }

  // Delete item from Firestore
  static Future<void> deleteItemFromFirestore(String itemId) async {
    if (!isAvailable || _userItemsCollection == null) {
      print('Firestore not available or user not authenticated');
      return;
    }

    try {
      await _userItemsCollection!.doc(itemId).delete();
      print('Item deleted from Firestore: $itemId');
    } catch (e) {
      print('Error deleting item from Firestore: $e');
      rethrow;
    }
  }

  // Initialize user's Firestore collection (called on first login)
  static Future<void> initializeUserCollection() async {
    if (!isAvailable) return;

    final userId = currentUserId;
    if (userId == null) return;

    try {
      final userDoc = _db!.collection('users').doc(userId);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create user document
        await userDoc.set({
          'created_at': DateTime.now().toIso8601String(),
          'email': currentUser?.email,
        });
        print('User collection initialized for: $userId');
      }
    } catch (e) {
      print('Error initializing user collection: $e');
    }
  }

  // Check if user has data in Firestore
  static Future<bool> hasFirestoreData() async {
    if (!isAvailable || _userItemsCollection == null) return false;

    try {
      final snapshot = await _userItemsCollection!.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking Firestore data: $e');
      return false;
    }
  }

  // Merge local and Firestore data (for initial sync)
  static Future<List<Item>> mergeData(List<Item> localItems) async {
    if (!isAvailable || _userItemsCollection == null) {
      return localItems;
    }

    try {
      final firestoreItems = await getItemsFromFirestore();

      // Create a map for easy lookup
      final Map<String, Item> mergedItems = {};

      // Add Firestore items first (they're the source of truth)
      for (var item in firestoreItems) {
        if (item.id != null) {
          mergedItems[item.id!] = item;
        }
      }

      // Add local items that don't exist in Firestore
      for (var localItem in localItems) {
        if (localItem.id == null || !mergedItems.containsKey(localItem.id)) {
          // This is a local-only item, sync it to Firestore
          await syncItemToFirestore(localItem);
        }
      }

      // Return the merged list
      return mergedItems.values.toList()
        ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    } catch (e) {
      print('Error merging data: $e');
      return localItems;
    }
  }
}