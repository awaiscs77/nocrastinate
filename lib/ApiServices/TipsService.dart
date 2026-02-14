import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TipsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _tipsSubCollection = 'tips_viewed';

  /// Get user's tips subcollection reference
  static CollectionReference? _getUserTipsCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_tipsSubCollection);
  }

  /// Get user document reference
  static DocumentReference? _getUserDocRef() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection(_usersCollection).doc(user.uid);
  }

  /// Save tip view record
  static Future<String?> saveTipView({
    required String tipContent,
    required String category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final tipsCollection = _getUserTipsCollection();
      if (tipsCollection == null) throw Exception('Could not get tips collection');

      final today = _getDateString(DateTime.now());

      final tipViewData = {
        'tipContent': tipContent.trim(),
        'category': category.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
        'viewedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await tipsCollection.add(tipViewData);

      // Update user stats
      await _updateUserTipStats(user.uid, category);

      return docRef.id;
    } catch (e) {
      print('Error saving tip view: $e');
      return null;
    }
  }

  /// Check if user has viewed a tip today
  static Future<bool> hasViewedTipToday() async {
    try {
      final tipsCollection = _getUserTipsCollection();
      if (tipsCollection == null) return false;

      final today = _getDateString(DateTime.now());

      final snapshot = await tipsCollection
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily tip view: $e');
      return false;
    }
  }

  /// Check if user has viewed a tip today for specific category
  static Future<bool> hasViewedTipTodayForCategory(String category) async {
    try {
      final tipsCollection = _getUserTipsCollection();
      if (tipsCollection == null) return false;

      final today = _getDateString(DateTime.now());

      final snapshot = await tipsCollection
          .where('date', isEqualTo: today)
          .where('category', isEqualTo: category)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily tip view for category: $e');
      return false;
    }
  }

  /// Get today's viewed tips
  static Future<List<Map<String, dynamic>>> getTodaysViewedTips() async {
    try {
      final tipsCollection = _getUserTipsCollection();
      if (tipsCollection == null) return [];

      final today = _getDateString(DateTime.now());

      final snapshot = await tipsCollection
          .where('date', isEqualTo: today)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting today\'s viewed tips: $e');
      return [];
    }
  }

  /// Get tip viewing history with pagination
  static Future<List<Map<String, dynamic>>> getTipViewHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final tipsCollection = _getUserTipsCollection();
      if (tipsCollection == null) return [];

      Query query = tipsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['documentSnapshot'] = doc; // For pagination
        return data;
      }).toList();
    } catch (e) {
      print('Error getting tip view history: $e');
      return [];
    }
  }

  /// Get tip statistics
  static Future<Map<String, dynamic>> getTipStats() async {
    try {
      final userDocRef = _getUserDocRef();
      if (userDocRef == null) return {};

      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final stats = data?['tipStats'] as Map<String, dynamic>?;
        return stats ?? _getInitialTipStats();
      } else {
        // Initialize user document with tip stats if doesn't exist
        final initialStats = _getInitialTipStats();
        await userDocRef.set({
          'tipStats': initialStats,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return initialStats;
      }
    } catch (e) {
      print('Error getting tip stats: $e');
      return {};
    }
  }

  /// Get current tip viewing streak
  static Future<int> getCurrentTipStreak() async {
    try {
      final stats = await getTipStats();
      return stats['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting current tip streak: $e');
      return 0;
    }
  }

  /// Get tips viewed by category
  static Future<Map<String, int>> getTipsByCategory() async {
    try {
      final stats = await getTipStats();
      final categoryStats = stats['categoryStats'] as Map<String, dynamic>? ?? {};

      return categoryStats.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error getting tips by category: $e');
      return {};
    }
  }

  /// Delete a tip view record
  static Future<bool> deleteTipView(String tipViewId) async {
    try {
      final tipsCollection = _getUserTipsCollection();
      if (tipsCollection == null) return false;

      // Get tip data before deletion for stats update
      final tipDoc = await tipsCollection.doc(tipViewId).get();

      if (!tipDoc.exists) return false;

      final tipData = tipDoc.data() as Map<String, dynamic>;

      // Delete the tip view
      await tipsCollection.doc(tipViewId).delete();

      // Update stats (decrease counters)
      final user = _auth.currentUser;
      if (user != null) {
        await _decrementUserTipStats(user.uid, tipData['category']);
      }

      return true;
    } catch (e) {
      print('Error deleting tip view: $e');
      return false;
    }
  }

  /// Private helper methods

  static Map<String, dynamic> _getInitialTipStats() {
    return {
      'totalTipsViewed': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastTipViewDate': null,
      'categoryStats': <String, int>{},
    };
  }

  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _updateUserTipStats(String userId, String category) async {
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      final today = _getDateString(DateTime.now());

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        Map<String, dynamic> userData;
        Map<String, dynamic> tipStatsData;

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          tipStatsData = userData['tipStats'] as Map<String, dynamic>? ?? _getInitialTipStats();
        } else {
          userData = {
            'createdAt': FieldValue.serverTimestamp(),
          };
          tipStatsData = _getInitialTipStats();
        }

        // Update counters
        tipStatsData['totalTipsViewed'] = (tipStatsData['totalTipsViewed'] ?? 0) + 1;

        // Update category stats
        Map<String, dynamic> categoryStats = tipStatsData['categoryStats'] as Map<String, dynamic>? ?? {};
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        tipStatsData['categoryStats'] = categoryStats;

        // Update streak
        final lastTipViewDate = tipStatsData['lastTipViewDate'];
        final currentStreak = tipStatsData['currentStreak'] ?? 0;

        if (lastTipViewDate == null) {
          // First tip view ever
          tipStatsData['currentStreak'] = 1;
          tipStatsData['longestStreak'] = 1;
        } else if (lastTipViewDate == today) {
          // Same day, don't change streak
        } else {
          final lastDate = DateTime.parse(lastTipViewDate);
          final todayDate = DateTime.parse(today);
          final difference = todayDate.difference(lastDate).inDays;

          if (difference == 1) {
            // Consecutive day
            tipStatsData['currentStreak'] = currentStreak + 1;
            if (tipStatsData['currentStreak'] > (tipStatsData['longestStreak'] ?? 0)) {
              tipStatsData['longestStreak'] = tipStatsData['currentStreak'];
            }
          } else if (difference > 1) {
            // Streak broken
            tipStatsData['currentStreak'] = 1;
          }
        }

        tipStatsData['lastTipViewDate'] = today;

        // Update user document with tip stats
        userData['tipStats'] = tipStatsData;
        userData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(userDocRef, userData, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error updating user tip stats: $e');
    }
  }

  static Future<void> _decrementUserTipStats(String userId, String category) async {
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) return;

        final userData = userDoc.data() as Map<String, dynamic>;
        final tipStatsData = userData['tipStats'] as Map<String, dynamic>? ?? {};

        // Decrease counters
        tipStatsData['totalTipsViewed'] = (tipStatsData['totalTipsViewed'] ?? 1) - 1;

        // Update category stats
        Map<String, dynamic> categoryStats = tipStatsData['categoryStats'] as Map<String, dynamic>? ?? {};
        if (categoryStats.containsKey(category)) {
          categoryStats[category] = ((categoryStats[category] ?? 1) - 1).clamp(0, double.infinity).toInt();
          if (categoryStats[category] == 0) {
            categoryStats.remove(category);
          }
        }
        tipStatsData['categoryStats'] = categoryStats;

        // Note: We don't recalculate streak on deletion as it would be complex
        // and potentially inaccurate without full history analysis

        userData['tipStats'] = tipStatsData;
        userData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(userDocRef, userData, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error decrementing user tip stats: $e');
    }
  }
}