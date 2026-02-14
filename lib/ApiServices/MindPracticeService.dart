import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MindPracticeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _mindPracticeSubCollection = 'mind_practices';

  // Practice types
  static const String costBenefitType = 'cost_benefit';
  static const String whatIfChallengeType = 'what_if_challenge';
  static const String activityPlanType = 'activity_plan';

  /// Get user's mind practices subcollection reference
  static CollectionReference? _getUserPracticesCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_mindPracticeSubCollection);
  }

  /// Get user document reference
  static DocumentReference? _getUserDocRef() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection(_usersCollection).doc(user.uid);
  }

  /// Create a new practice session (in progress)
  static Future<String?> createPracticeSession({
    required String practiceType,
    Map<String, dynamic>? initialData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) throw Exception('Could not get practices collection');

      final practiceData = {
        'practiceType': practiceType,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'data': initialData ?? {},
        'completed': false,
        'status': 'in_progress',
        'date': _getDateString(DateTime.now()),
      };

      final docRef = await practicesCollection.add(practiceData);
      return docRef.id;
    } catch (e) {
      print('Error creating practice session: $e');
      return null;
    }
  }

  /// Update practice session data
  static Future<bool> updatePracticeSession({
    required String practiceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) throw Exception('Could not get practices collection');

      await practicesCollection.doc(practiceId).update({
        'data': data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating practice session: $e');
      return false;
    }
  }

  /// Complete practice session
  static Future<bool> completePracticeSession({
    required String practiceId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) throw Exception('Could not get practices collection');

      // Get practice data to determine type for stats update
      final practiceDoc = await practicesCollection.doc(practiceId).get();
      if (!practiceDoc.exists) throw Exception('Practice session not found');

      final practiceData = practiceDoc.data() as Map<String, dynamic>;
      final practiceType = practiceData['practiceType'] as String;

      // Update practice as completed
      await practicesCollection.doc(practiceId).update({
        'completed': true,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user stats
      await _updateUserStats(user.uid, practiceType);

      return true;
    } catch (e) {
      print('Error completing practice session: $e');
      return false;
    }
  }

  /// Check if user has completed practice today for specific type
  static Future<bool> hasCompletedPracticeToday(String practiceType) async {
    try {
      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) return false;

      final today = _getDateString(DateTime.now());

      final snapshot = await practicesCollection
          .where('date', isEqualTo: today)
          .where('practiceType', isEqualTo: practiceType)
          .where('completed', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily practice: $e');
      return false;
    }
  }

  /// Get today's incomplete practice of specific type
  static Future<Map<String, dynamic>?> getTodaysIncompletePractice(String practiceType) async {
    try {
      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) return null;

      final today = _getDateString(DateTime.now());

      final snapshot = await practicesCollection
          .where('date', isEqualTo: today)
          .where('practiceType', isEqualTo: practiceType)
          .where('completed', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting incomplete practice: $e');
      return null;
    }
  }

  /// Save Cost Benefit Analysis practice (legacy method - now uses session-based approach)
  static Future<String?> saveCostBenefitPractice({
    required String behaviorToEvaluate,
    required String pros,
    required String cons,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) throw Exception('Could not get practices collection');

      final practiceData = {
        'practiceType': costBenefitType,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'data': {
          'behaviorToEvaluate': behaviorToEvaluate.trim(),
          'pros': pros.trim(),
          'cons': cons.trim(),
        },
        'completed': true,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'date': _getDateString(DateTime.now()),
      };

      final docRef = await practicesCollection.add(practiceData);

      // Update user stats
      await _updateUserStats(user.uid, costBenefitType);

      return docRef.id;
    } catch (e) {
      print('Error saving Cost Benefit practice: $e');
      return null;
    }
  }

  /// Save What If Challenge practice (legacy method - now uses session-based approach)
  static Future<String?> saveWhatIfChallengePractice({
    required String fearScenario,
    required double initialLikelihood,
    required String bestOutcome,
    required double finalLikelihood,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) throw Exception('Could not get practices collection');

      final practiceData = {
        'practiceType': whatIfChallengeType,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'data': {
          'fearScenario': fearScenario.trim(),
          'initialLikelihood': initialLikelihood,
          'bestOutcome': bestOutcome.trim(),
          'finalLikelihood': finalLikelihood,
          'likelihoodReduction': initialLikelihood - finalLikelihood,
        },
        'completed': true,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'date': _getDateString(DateTime.now()),
      };

      final docRef = await practicesCollection.add(practiceData);

      // Update user stats
      await _updateUserStats(user.uid, whatIfChallengeType);

      return docRef.id;
    } catch (e) {
      print('Error saving What If Challenge practice: $e');
      return null;
    }
  }

  /// Save Activity Plan practice (legacy method - now uses session-based approach)
  static Future<String?> saveActivityPlanPractice({
    required String activityPlan,
    required String category,
    bool completedImmediately = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) throw Exception('Could not get practices collection');

      final practiceData = {
        'practiceType': activityPlanType,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'data': {
          'activityPlan': activityPlan.trim(),
          'category': category,
          'completedImmediately': completedImmediately,
        },
        'completed': true,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'date': _getDateString(DateTime.now()),
      };

      final docRef = await practicesCollection.add(practiceData);

      // Update user stats
      await _updateUserStats(user.uid, activityPlanType);

      return docRef.id;
    } catch (e) {
      print('Error saving Activity Plan practice: $e');
      return null;
    }
  }

  /// Check if user has completed daily practice (any type)
  static Future<bool> hasCompletedDailyPractice() async {
    try {
      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) return false;

      final today = _getDateString(DateTime.now());

      final snapshot = await practicesCollection
          .where('date', isEqualTo: today)
          .where('completed', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily practice: $e');
      return false;
    }
  }

  /// Get today's completed practices
  static Future<List<Map<String, dynamic>>> getTodaysPractices() async {
    try {
      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) return [];

      final today = _getDateString(DateTime.now());

      final snapshot = await practicesCollection
          .where('date', isEqualTo: today)
          .where('completed', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting today\'s practices: $e');
      return [];
    }
  }

  /// Get practice history with pagination
  static Future<List<Map<String, dynamic>>> getPracticeHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) return [];

      Query query = practicesCollection
          .where('completed', isEqualTo: true)
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
      print('Error getting practice history: $e');
      return [];
    }
  }

  /// Get practice statistics
  static Future<Map<String, dynamic>> getPracticeStats() async {
    try {
      final userDocRef = _getUserDocRef();
      if (userDocRef == null) return {};

      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final stats = data?['stats'] as Map<String, dynamic>?;
        return stats ?? _getInitialStats();
      } else {
        // Initialize user document with stats if doesn't exist
        final initialStats = _getInitialStats();
        await userDocRef.set({
          'stats': initialStats,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return initialStats;
      }
    } catch (e) {
      print('Error getting practice stats: $e');
      return {};
    }
  }

  /// Get current streak
  static Future<int> getCurrentStreak() async {
    try {
      final stats = await getPracticeStats();
      return stats['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  /// Delete a practice session
  static Future<bool> deletePractice(String practiceId) async {
    try {
      final practicesCollection = _getUserPracticesCollection();
      if (practicesCollection == null) return false;

      // Get practice data before deletion for stats update
      final practiceDoc = await practicesCollection.doc(practiceId).get();

      if (!practiceDoc.exists) return false;

      final practiceData = practiceDoc.data() as Map<String, dynamic>;

      // Delete the practice
      await practicesCollection.doc(practiceId).delete();

      // Update stats (decrease counters)
      final user = _auth.currentUser;
      if (user != null) {
        await _decrementUserStats(user.uid, practiceData['practiceType']);
      }

      return true;
    } catch (e) {
      print('Error deleting practice: $e');
      return false;
    }
  }

  /// Private helper methods

  static Map<String, dynamic> _getInitialStats() {
    return {
      'totalPractices': 0,
      'costBenefitCount': 0,
      'whatIfChallengeCount': 0,
      'activityPlanCount': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'lastPracticeDate': null,
    };
  }

  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _updateUserStats(String userId, String practiceType) async {
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      final today = _getDateString(DateTime.now());

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        Map<String, dynamic> userData;
        Map<String, dynamic> statsData;

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>;
          statsData = userData['stats'] as Map<String, dynamic>? ?? _getInitialStats();
        } else {
          userData = {
            'createdAt': FieldValue.serverTimestamp(),
          };
          statsData = _getInitialStats();
        }

        // Update counters
        statsData['totalPractices'] = (statsData['totalPractices'] ?? 0) + 1;

        if (practiceType == costBenefitType) {
          statsData['costBenefitCount'] = (statsData['costBenefitCount'] ?? 0) + 1;
        } else if (practiceType == whatIfChallengeType) {
          statsData['whatIfChallengeCount'] = (statsData['whatIfChallengeCount'] ?? 0) + 1;
        } else if (practiceType == activityPlanType) {
          statsData['activityPlanCount'] = (statsData['activityPlanCount'] ?? 0) + 1;
        }

        // Update streak
        final lastPracticeDate = statsData['lastPracticeDate'];
        final currentStreak = statsData['currentStreak'] ?? 0;

        if (lastPracticeDate == null) {
          // First practice ever
          statsData['currentStreak'] = 1;
          statsData['longestStreak'] = 1;
        } else if (lastPracticeDate == today) {
          // Same day, don't change streak
        } else {
          final lastDate = DateTime.parse(lastPracticeDate);
          final todayDate = DateTime.parse(today);
          final difference = todayDate.difference(lastDate).inDays;

          if (difference == 1) {
            // Consecutive day
            statsData['currentStreak'] = currentStreak + 1;
            if (statsData['currentStreak'] > (statsData['longestStreak'] ?? 0)) {
              statsData['longestStreak'] = statsData['currentStreak'];
            }
          } else if (difference > 1) {
            // Streak broken
            statsData['currentStreak'] = 1;
          }
        }

        statsData['lastPracticeDate'] = today;

        // Update user document with stats
        userData['stats'] = statsData;
        userData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(userDocRef, userData);
      });
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  static Future<void> _decrementUserStats(String userId, String practiceType) async {
    try {
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) return;

        final userData = userDoc.data() as Map<String, dynamic>;
        final statsData = userData['stats'] as Map<String, dynamic>? ?? {};

        // Decrease counters
        statsData['totalPractices'] = (statsData['totalPractices'] ?? 1) - 1;

        if (practiceType == costBenefitType) {
          statsData['costBenefitCount'] = ((statsData['costBenefitCount'] ?? 1) - 1).clamp(0, double.infinity).toInt();
        } else if (practiceType == whatIfChallengeType) {
          statsData['whatIfChallengeCount'] = ((statsData['whatIfChallengeCount'] ?? 1) - 1).clamp(0, double.infinity).toInt();
        } else if (practiceType == activityPlanType) {
          statsData['activityPlanCount'] = ((statsData['activityPlanCount'] ?? 1) - 1).clamp(0, double.infinity).toInt();
        }

        // Note: We don't recalculate streak on deletion as it would be complex
        // and potentially inaccurate without full history analysis

        userData['stats'] = statsData;
        userData['updatedAt'] = FieldValue.serverTimestamp();

        transaction.set(userDocRef, userData);
      });
    } catch (e) {
      print('Error decrementing user stats: $e');
    }
  }
}