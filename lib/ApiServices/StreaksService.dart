import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreaksService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _usersCollection = 'users';
  static const String _streaksSubCollection = 'daily_streaks';

  // Activity types
  static const String affirmationActivity = 'affirmation';
  static const String tipsActivity = 'tips';
  static const String mindPracticeActivity = 'mind_practice';
  static const String moodCheckinActivity = 'mood_checkin';

  /// Get user's streaks subcollection reference
  static CollectionReference? _getUserStreaksCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_streaksSubCollection);
  }

  /// Get user document reference
  static DocumentReference? _getUserDocRef() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection(_usersCollection).doc(user.uid);
  }

  /// Record activity completion for today
  static Future<bool> recordActivityCompletion(String activityType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) throw Exception('Could not get streaks collection');

      final today = _getDateString(DateTime.now());

      // Get or create today's streak record
      final todayDoc = streaksCollection.doc(today);
      final docSnapshot = await todayDoc.get();

      Map<String, dynamic> todayData;
      bool wasAlreadyComplete = false;

      if (docSnapshot.exists) {
        todayData = docSnapshot.data() as Map<String, dynamic>;
        wasAlreadyComplete = todayData['isComplete'] ?? false;
      } else {
        todayData = {
          'date': today,
          'activities': <String, bool>{},
          'isComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
      }

      // Update the specific activity
      Map<String, dynamic> activities = Map<String, dynamic>.from(todayData['activities'] ?? {});
      activities[activityType] = true;

      // Check if all activities are completed
      bool isComplete = _areAllActivitiesComplete(activities);

      // Debug logging
      print('=== STREAK DEBUG ===');
      print('Activity Type: $activityType');
      print('Current Activities: $activities');
      print('All activities check result: $isComplete');
      print('Was already complete: $wasAlreadyComplete');
      print('Date: $today');

      todayData['activities'] = activities;
      todayData['isComplete'] = isComplete;
      todayData['updatedAt'] = FieldValue.serverTimestamp();

      // Save today's record
      await todayDoc.set(todayData);

      // If this completes the day for the first time, update overall streak
      if (isComplete && !wasAlreadyComplete) {
        print('Updating overall streak...');
        await _updateOverallStreak(user.uid);
      }

      return true;
    } catch (e) {
      print('Error recording activity completion: $e');
      return false;
    }
  }

  /// Check if all activities are completed for today
  static Future<bool> areAllActivitiesCompletedToday() async {
    try {
      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) return false;

      final today = _getDateString(DateTime.now());
      final todayDoc = await streaksCollection.doc(today).get();

      if (!todayDoc.exists) return false;

      final data = todayDoc.data() as Map<String, dynamic>?;
      return data?['isComplete'] ?? false;
    } catch (e) {
      print('Error checking daily completion: $e');
      return false;
    }
  }

  /// Get today's activity completion status
  static Future<Map<String, bool>> getTodaysActivityStatus() async {
    try {
      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) return {};

      final today = _getDateString(DateTime.now());
      final todayDoc = await streaksCollection.doc(today).get();

      if (!todayDoc.exists) {
        return {
          affirmationActivity: false,
          tipsActivity: false,
          mindPracticeActivity: false,
          moodCheckinActivity: false,
        };
      }

      final data = todayDoc.data() as Map<String, dynamic>;
      final activities = data['activities'] as Map<String, dynamic>? ?? {};

      return {
        affirmationActivity: activities[affirmationActivity] ?? false,
        tipsActivity: activities[tipsActivity] ?? false,
        mindPracticeActivity: activities[mindPracticeActivity] ?? false,
        moodCheckinActivity: activities[moodCheckinActivity] ?? false,
      };
    } catch (e) {
      print('Error getting today\'s activity status: $e');
      return {};
    }
  }

  /// Get current overall streak
  static Future<int> getCurrentStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Read from user_stats collection instead of users collection
      final userStatsDoc = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .get();

      if (!userStatsDoc.exists) return 0;

      final data = userStatsDoc.data() as Map<String, dynamic>?;
      return data?['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  /// Get longest streak
  static Future<int> getLongestStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Read from user_stats collection instead of users collection
      final userStatsDoc = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .get();

      if (!userStatsDoc.exists) return 0;

      final data = userStatsDoc.data() as Map<String, dynamic>?;
      return data?['longestStreak'] ?? 0;
    } catch (e) {
      print('Error getting longest streak: $e');
      return 0;
    }
  }


  /// Get streak statistics
  static Future<Map<String, dynamic>> getStreakStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _getInitialStreakStats();

      // Read from user_stats collection instead of users collection
      final userStatsDoc = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .get();

      if (userStatsDoc.exists) {
        final data = userStatsDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          // Map the user_stats structure to the expected streak stats structure
          return {
            'currentStreak': data['currentStreak'] ?? 0,
            'longestStreak': data['longestStreak'] ?? 0,
            'totalCompletedDays': data['totalPractices'] ?? 0, // Assuming this maps to total practices
            'lastCompletedDate': data['lastPracticeDate'],
            'streakStartDate': null, // This field doesn't exist in user_stats, could calculate or add
          };
        }
      }

      // If no stats exist, create initial stats in user_stats collection
      final initialStats = _getInitialStreakStats();
      await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .set({
        'currentStreak': initialStats['currentStreak'],
        'longestStreak': initialStats['longestStreak'],
        'totalPractices': initialStats['totalCompletedDays'],
        'lastPracticeDate': initialStats['lastCompletedDate'],
      }, SetOptions(merge: true));

      return initialStats;
    } catch (e) {
      print('Error getting streak stats: $e');
      return _getInitialStreakStats();
    }
  }

  /// Get streak history with pagination
  static Future<List<Map<String, dynamic>>> getStreakHistory({
    int limit = 30,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) return [];

      Query query = streaksCollection
          .orderBy('date', descending: true)
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
      print('Error getting streak history: $e');
      return [];
    }
  }

  /// Get completion rate for a specific period
  static Future<double> getCompletionRate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) return 0.0;

      final startDateStr = _getDateString(startDate);
      final endDateStr = _getDateString(endDate);

      final snapshot = await streaksCollection
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      int completedDays = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isComplete'] == true) {
          completedDays++;
        }
      }

      return completedDays / snapshot.docs.length;
    } catch (e) {
      print('Error getting completion rate: $e');
      return 0.0;
    }
  }

  /// Calculate streak manually (for verification or recovery)
  static Future<int> calculateStreakFromHistory() async {
    try {
      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) return 0;

      final today = DateTime.now();
      int currentStreak = 0;

      // Start from today and go backwards
      for (int i = 0; i < 365; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final dateStr = _getDateString(checkDate);

        final doc = await streaksCollection.doc(dateStr).get();

        if (!doc.exists) {
          if (i == 0) {
            // If today doesn't exist, streak is 0
            break;
          } else {
            // Gap in history, streak is broken
            break;
          }
        }

        final data = doc.data() as Map<String, dynamic>;
        if (data['isComplete'] == true) {
          currentStreak++;
        } else {
          // Streak is broken
          break;
        }
      }

      return currentStreak;
    } catch (e) {
      print('Error calculating streak from history: $e');
      return 0;
    }
  }

  /// Reset streak (admin function or for testing)
  static Future<bool> resetStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update user_stats collection
      await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .update({
        'currentStreak': 0,
        'longestStreak': 0,
        'totalPractices': 0,
        'lastPracticeDate': null,
      });

      return true;
    } catch (e) {
      print('Error resetting streak: $e');
      return false;
    }
  }

  /// Fix existing streak by recalculating from history
  static Future<bool> recalculateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final correctStreak = await calculateStreakFromHistory();

      await _firestore.runTransaction((transaction) async {
        final userStatsRef = _firestore.collection('user_stats').doc(user.uid);
        final userStatsDoc = await transaction.get(userStatsRef);

        Map<String, dynamic> statsData;

        if (userStatsDoc.exists) {
          statsData = userStatsDoc.data() as Map<String, dynamic>;
        } else {
          statsData = {
            'currentStreak': 0,
            'longestStreak': 0,
            'totalPractices': 0,
            'lastPracticeDate': null,
          };
        }

        // Update with calculated streak
        statsData['currentStreak'] = correctStreak;

        // Update longest streak if current is higher
        if (correctStreak > (statsData['longestStreak'] ?? 0)) {
          statsData['longestStreak'] = correctStreak;
        }

        transaction.set(userStatsRef, statsData, SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      print('Error recalculating streak: $e');
      return false;
    }
  }

  /// Test method to manually complete all activities (for debugging)
  static Future<void> testCompleteAllActivities() async {
    print('=== TESTING ALL ACTIVITIES COMPLETION ===');

    // Record each activity
    print('Recording affirmation...');
    await recordActivityCompletion(affirmationActivity);

    print('Recording tips...');
    await recordActivityCompletion(tipsActivity);

    print('Recording mind practice...');
    await recordActivityCompletion(mindPracticeActivity);

    print('Recording mood checkin...');
    await recordActivityCompletion(moodCheckinActivity);

    print('=== FINAL STATUS ===');
    await debugTodaysStatus();
  }
  static Future<void> debugTodaysStatus() async {
    try {
      final streaksCollection = _getUserStreaksCollection();
      if (streaksCollection == null) {
        print('DEBUG: No user authenticated');
        return;
      }

      final today = _getDateString(DateTime.now());
      final todayDoc = await streaksCollection.doc(today).get();

      print('=== TODAY\'S DEBUG STATUS ===');
      print('Date: $today');

      if (!todayDoc.exists) {
        print('No document exists for today');
        return;
      }

      final data = todayDoc.data() as Map<String, dynamic>;
      final activities = data['activities'] as Map<String, dynamic>? ?? {};
      final isComplete = data['isComplete'] ?? false;

      print('Activities: $activities');
      print('Is Complete: $isComplete');

      // Check each activity individually
      print('Affirmation: ${activities[affirmationActivity] ?? false}');
      print('Tips: ${activities[tipsActivity] ?? false}');
      print('Mind Practice: ${activities[mindPracticeActivity] ?? false}');
      print('Mood Checkin: ${activities[moodCheckinActivity] ?? false}');

      // Test the logic
      bool shouldBeComplete = _areAllActivitiesComplete(activities);
      print('Should be complete: $shouldBeComplete');

    } catch (e) {
      print('Debug error: $e');
    }
  }

  /// Private helper methods

  static Map<String, dynamic> _getInitialStreakStats() {
    return {
      'currentStreak': 0,
      'longestStreak': 0,
      'totalCompletedDays': 0,
      'lastCompletedDate': null,
      'streakStartDate': null,
    };
  }

  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool _areAllActivitiesComplete(Map<String, dynamic> activities) {
    return (activities[affirmationActivity] ?? false) &&
        (activities[tipsActivity] ?? false) &&
        (activities[mindPracticeActivity] ?? false) &&
        (activities[moodCheckinActivity] ?? false);
  }

  static Future<void> _updateOverallStreak(String userId) async {
    try {
      final today = _getDateString(DateTime.now());

      await _firestore.runTransaction((transaction) async {
        // Read from user_stats collection
        final userStatsRef = _firestore.collection('user_stats').doc(userId);
        final userStatsDoc = await transaction.get(userStatsRef);

        Map<String, dynamic> statsData;

        if (userStatsDoc.exists) {
          statsData = userStatsDoc.data() as Map<String, dynamic>;
        } else {
          statsData = {
            'currentStreak': 0,
            'longestStreak': 0,
            'totalPractices': 0,
            'lastPracticeDate': null,
          };
        }

        final lastCompletedDate = statsData['lastPracticeDate'];
        final currentStreak = statsData['currentStreak'] ?? 0;

        if (lastCompletedDate == null) {
          // First completed day ever
          statsData['currentStreak'] = 1;
          statsData['longestStreak'] = 1;
          statsData['totalPractices'] = (statsData['totalPractices'] ?? 0) + 1;
        } else if (lastCompletedDate == today) {
          // Same day, don't change streak (this should not happen with proper logic)
          print('Warning: Attempting to complete the same day twice: $today');
          return;
        } else {
          final lastDate = DateTime.parse(lastCompletedDate);
          final todayDate = DateTime.parse(today);
          final difference = todayDate.difference(lastDate).inDays;

          if (difference == 1) {
            // Consecutive day
            final newStreak = currentStreak + 1;
            statsData['currentStreak'] = newStreak;
            if (newStreak > (statsData['longestStreak'] ?? 0)) {
              statsData['longestStreak'] = newStreak;
            }
          } else if (difference > 1) {
            // Streak broken, start new one
            statsData['currentStreak'] = 1;
          }

          statsData['totalPractices'] = (statsData['totalPractices'] ?? 0) + 1;
        }

        statsData['lastPracticeDate'] = today;

        // Update user_stats document
        transaction.set(userStatsRef, statsData, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error updating overall streak: $e');
    }
  }
}