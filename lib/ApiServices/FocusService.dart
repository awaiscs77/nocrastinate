import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/FocusItem.dart';

class FocusService {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's focus items collection reference
  CollectionReference get _focusItemsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('focusItems');
  }

  // Add a new focus item
  Future<String> addFocusItem({
    required String title,
    required String subtitle,
    required String category,
  }) async {
    try {
      final docRef = await _focusItemsCollection.add({
        'title': title,
        'subtitle': subtitle,
        'category': category,
        'isDone': false,
        'createdAt': DateTime.now().toIso8601String(),
        'completedAt': null,
      });

      print('Focus item added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding focus item: $e');
      throw Exception('Failed to add focus item');
    }
  }

  // Get TODAY'S focus items only - UPDATED METHOD
  Stream<List<FocusItem>> getFocusItems() {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      return _focusItemsCollection
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .orderBy('createdAt', descending: false) // Show oldest first within the day
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => FocusItem.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error getting focus items: $e');
      throw Exception('Failed to get focus items');
    }
  }

  // Get focus items for a specific date
  Stream<List<FocusItem>> getFocusItemsForDate(DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      return _focusItemsCollection
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => FocusItem.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error getting focus items for date: $e');
      throw Exception('Failed to get focus items for date');
    }
  }

  // Mark focus item as done
  Future<void> markFocusItemDone(String itemId) async {
    try {
      await _focusItemsCollection.doc(itemId).update({
        'isDone': true,
        'completedAt': DateTime.now().toIso8601String(),
      });
      print('Focus item marked as done: $itemId');
    } catch (e) {
      print('Error marking focus item as done: $e');
      throw Exception('Failed to mark item as done');
    }
  }

  // Mark focus item as undone
  Future<void> markFocusItemUndone(String itemId) async {
    try {
      await _focusItemsCollection.doc(itemId).update({
        'isDone': false,
        'completedAt': null,
      });
      print('Focus item marked as undone: $itemId');
    } catch (e) {
      print('Error marking focus item as undone: $e');
      throw Exception('Failed to mark item as undone');
    }
  }

  // Update focus item
  Future<void> updateFocusItem({
    required String itemId,
    String? title,
    String? subtitle,
    String? category,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (subtitle != null) updates['subtitle'] = subtitle;
      if (category != null) updates['category'] = category;

      if (updates.isNotEmpty) {
        await _focusItemsCollection.doc(itemId).update(updates);
        print('Focus item updated: $itemId');
      }
    } catch (e) {
      print('Error updating focus item: $e');
      throw Exception('Failed to update focus item');
    }
  }

  // Delete focus item
  Future<void> deleteFocusItem(String itemId) async {
    try {
      await _focusItemsCollection.doc(itemId).delete();
      print('Focus item deleted: $itemId');
    } catch (e) {
      print('Error deleting focus item: $e');
      throw Exception('Failed to delete focus item');
    }
  }

  // Get focus item by ID
  Future<FocusItem?> getFocusItemById(String itemId) async {
    try {
      final doc = await _focusItemsCollection.doc(itemId).get();
      if (doc.exists) {
        return FocusItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting focus item by ID: $e');
      throw Exception('Failed to get focus item');
    }
  }

  // Get completed focus items count for today
  Future<int> getCompletedItemsCountForToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _focusItemsCollection
          .where('isDone', isEqualTo: true)
          .where('completedAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('completedAt', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting completed items count: $e');
      return 0;
    }
  }

  // Get focus items by category
  Stream<List<FocusItem>> getFocusItemsByCategory(String category) {
    try {
      return _focusItemsCollection
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => FocusItem.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error getting focus items by category: $e');
      throw Exception('Failed to get focus items by category');
    }
  }

  // BONUS: Get all focus items (if you need it for other screens)
  Stream<List<FocusItem>> getAllFocusItems() {
    try {
      return _focusItemsCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => FocusItem.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error getting all focus items: $e');
      throw Exception('Failed to get all focus items');
    }
  }

  // Get focus items for a specific month and year
  Stream<List<FocusItem>> getFocusItemsForMonth(int month, int year) {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      return _focusItemsCollection
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => FocusItem.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error getting focus items for month: $e');
      throw Exception('Failed to get focus items for month');
    }
  }

// Get activity percentages by category for a specific month
  Future<Map<String, double>> getActivityPercentagesForMonth(int month, int year) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final snapshot = await _focusItemsCollection
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: endOfMonth.toIso8601String())
          .get();

      Map<String, int> categoryCounts = {};
      int totalItems = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String? ?? 'Personal';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        totalItems++;
      }

      if (totalItems == 0) {
        return {};
      }

      Map<String, double> percentages = {};
      categoryCounts.forEach((category, count) {
        percentages[category] = (count / totalItems) * 100;
      });

      return percentages;
    } catch (e) {
      print('Error getting activity percentages: $e');
      return {};
    }
  }
}