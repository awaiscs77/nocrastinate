import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AffirmationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _affirmationsSubCollection = 'affirmations_viewed';

  /// Get user's affirmations subcollection reference
  static CollectionReference? _getUserAffirmationsCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_affirmationsSubCollection);
  }

  /// Get user document reference
  static DocumentReference? _getUserDocRef() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection(_usersCollection).doc(user.uid);
  }

  /// Save affirmation view record
  static Future<String?> saveAffirmationView({
    required String affirmationContent,
    required String category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final affirmationsCollection = _getUserAffirmationsCollection();
      if (affirmationsCollection == null) throw Exception('Could not get affirmations collection');

      final today = _getDateString(DateTime.now());

      final affirmationViewData = {
        'affirmationContent': affirmationContent.trim(),
        'category': category.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
        'viewedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await affirmationsCollection.add(affirmationViewData);

      // Update user stats
      await _updateUserAffirmationStats(user.uid, category);

      return docRef.id;
    } catch (e) {
      print('Error saving affirmation view: $e');
      return null;
    }
  }

  /// Check if user has viewed an affirmation today
  static Future<bool> hasViewedAffirmationToday() async {
    try {
      final affirmationsCollection = _getUserAffirmationsCollection();
      if (affirmationsCollection == null) return false;

      final today = _getDateString(DateTime.now());

      final snapshot = await affirmationsCollection
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily affirmation view: $e');
      return false;
    }
  }

  /// Check if user has viewed an affirmation today for specific category
  static Future<bool> hasViewedAffirmationTodayForCategory(String category) async {
    try {
      final affirmationsCollection = _getUserAffirmationsCollection();
      if (affirmationsCollection == null) return false;

      final today = _getDateString(DateTime.now());

      final snapshot = await affirmationsCollection
          .where('date', isEqualTo: today)
          .where('category', isEqualTo: category)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily affirmation view for category: $e');
      return false;
    }
  }

  /// Get today's viewed affirmations
  static Future<List<Map<String, dynamic>>> getTodaysViewedAffirmations() async {
    try {
      final affirmationsCollection = _getUserAffirmationsCollection();
      if (affirmationsCollection == null) return [];

      final today = _getDateString(DateTime.now());

      final snapshot = await affirmationsCollection
          .where('date', isEqualTo: today)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting today\'s viewed affirmations: $e');
      return [];
    }
  }

  /// Get affirmation viewing history with pagination
  static Future<List<Map<String, dynamic>>> getAffirmationViewHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final affirmationsCollection = _getUserAffirmationsCollection();
      if (affirmationsCollection == null) return [];

      Query query = affirmationsCollection
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
      print('Error getting affirmation view history: $e');
      return [];
    }
  }

  /// Get affirmation statistics
  static Future<Map<String, dynamic>> getAffirmationStats() async {
    try {
      final userDocRef = _getUserDocRef();
      if (userDocRef == null) return {};

      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final stats = data?['affirmationStats'] as Map<String, dynamic>?;
        return stats ?? _getInitialAffirmationStats();
      } else {
        // Initialize user document with affirmation stats if doesn't exist
        final initialStats = _getInitialAffirmationStats();
        await userDocRef.set({
          'affirmationStats': initialStats,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return initialStats;
      }
    } catch (e) {
      print('Error getting affirmation stats: $e');
      return {};
    }
  }

  /// Get current affirmation viewing streak
  static Future<int> getCurrentAffirmationStreak() async {
    try {
      final stats = await getAffirmationStats();
      return stats['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting current affirmation streak: $e');
      return 0;
    }
  }

  /// Get affirmations viewed by category
  static Future<Map<String, int>> getAffirmationsByCategory() async {
    try {
      final stats = await getAffirmationStats();
      final categoryStats = stats['categoryStats'] as Map<String, dynamic>? ?? {};

      return categoryStats.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error getting affirmations by category: $e');
      return {};
    }
  }

  /// Delete an affirmation view record
  static Future<bool> deleteAffirmationView(String affirmationViewId) async {
    try {
      final affirmationsCollection = _getUserAffirmationsCollection();
      if (affirmationsCollection == null) return false;

      // Get affirmation data before deletion for stats update
      final affirmationDoc = await affirmationsCollection.doc(affirmationViewId).get();

      if (!affirmationDoc.exists) return false;

      final affirmationData = affirmationDoc.data() as Map<String, dynamic>;

      // Delete the affirmation view
      await affirmationsCollection.doc(affirmationViewId).delete();

      // Update stats (decrease counters)
      final user = _auth.currentUser;
      if (user != null) {
        await _decrementUserAffirmationStats(user.uid, affirmationData['category']);
      }

      return true;
    } catch (e) {
      print('Error deleting affirmation view: $e');
      return false;
    }
  }

  /// Private helper methods

  static Map<String, dynamic> _getInitialAffirmationStats() {
    return {
      'totalAffirmationsViewed': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastAffirmationViewDate': null,
      'categoryStats': <String, int>{},
    };
  }

  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _updateUserAffirmationStats(String userId, String category) async {
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      final today = _getDateString(DateTime.now());

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        Map<String, dynamic> userData;
        Map<String, dynamic> affirmationStatsData;

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          affirmationStatsData = userData['affirmationStats'] as Map<String, dynamic>? ?? _getInitialAffirmationStats();
        } else {
          userData = {
            'createdAt': FieldValue.serverTimestamp(),
          };
          affirmationStatsData = _getInitialAffirmationStats();
        }

        // Update counters
        affirmationStatsData['totalAffirmationsViewed'] = (affirmationStatsData['totalAffirmationsViewed'] ?? 0) + 1;

        // Update category stats
        Map<String, dynamic> categoryStats = affirmationStatsData['categoryStats'] as Map<String, dynamic>? ?? {};
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        affirmationStatsData['categoryStats'] = categoryStats;

        // Update streak
        final lastAffirmationViewDate = affirmationStatsData['lastAffirmationViewDate'];
        final currentStreak = affirmationStatsData['currentStreak'] ?? 0;

        if (lastAffirmationViewDate == null) {
          // First affirmation view ever
          affirmationStatsData['currentStreak'] = 1;
          affirmationStatsData['longestStreak'] = 1;
        } else if (lastAffirmationViewDate == today) {
          // Same day, don't change streak
        } else {
          final lastDate = DateTime.parse(lastAffirmationViewDate);
          final todayDate = DateTime.parse(today);
          final difference = todayDate.difference(lastDate).inDays;

          if (difference == 1) {
            // Consecutive day
            affirmationStatsData['currentStreak'] = currentStreak + 1;
            if (affirmationStatsData['currentStreak'] > (affirmationStatsData['longestStreak'] ?? 0)) {
              affirmationStatsData['longestStreak'] = affirmationStatsData['currentStreak'];
            }
          } else if (difference > 1) {
            // Streak broken
            affirmationStatsData['currentStreak'] = 1;
          }
        }

        affirmationStatsData['lastAffirmationViewDate'] = today;

        // Update user document with affirmation stats
        userData['affirmationStats'] = affirmationStatsData;
        userData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(userDocRef, userData, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error updating user affirmation stats: $e');
    }
  }

  static Future<void> _decrementUserAffirmationStats(String userId, String category) async {
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) return;

        final userData = userDoc.data() as Map<String, dynamic>;
        final affirmationStatsData = userData['affirmationStats'] as Map<String, dynamic>? ?? {};

        // Decrease counters
        affirmationStatsData['totalAffirmationsViewed'] = (affirmationStatsData['totalAffirmationsViewed'] ?? 1) - 1;

        // Update category stats
        Map<String, dynamic> categoryStats = affirmationStatsData['categoryStats'] as Map<String, dynamic>? ?? {};
        if (categoryStats.containsKey(category)) {
          categoryStats[category] = ((categoryStats[category] ?? 1) - 1).clamp(0, double.infinity).toInt();
          if (categoryStats[category] == 0) {
            categoryStats.remove(category);
          }
        }
        affirmationStatsData['categoryStats'] = categoryStats;

        // Note: We don't recalculate streak on deletion as it would be complex
        // and potentially inaccurate without full history analysis

        userData['affirmationStats'] = affirmationStatsData;
        userData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(userDocRef, userData, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error decrementing user affirmation stats: $e');
    }
  }
}