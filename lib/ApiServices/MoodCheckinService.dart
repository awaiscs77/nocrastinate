import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

  class MoodCheckinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Collection reference for mood check-ins
  CollectionReference get _moodCheckinCollection =>
      _firestore.collection('users').doc(_userId).collection('mood_checkins');

  /// Save initial mood selection (from HowFeelingScreen)
  Future<String> saveInitialMood({
    required int moodIndex,
    required String moodLabel,
    required DateTime timestamp,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Create a new document for today's mood check-in
      DocumentReference docRef = await _moodCheckinCollection.add({
        'mood_index': moodIndex,
        'mood_label': moodLabel,
        'timestamp': timestamp,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'status': 'in_progress', // Track completion status
        'date': _getDateString(timestamp), // Store date as string for easy querying
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save initial mood: $e');
    }
  }



  /// Get daily moods with date string as key
  /// Returns Map<String, int> where key is date (YYYY-MM-DD) and value is mood_index
  Future<Map<String, int>> getDailyMoodsDictByDate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));

      final startDateString = _getDateString(start);
      final endDateString = _getDateString(end);

      Query query = _moodCheckinCollection
          .where('status', isEqualTo: 'completed')
          .where('date', isGreaterThanOrEqualTo: startDateString)
          .where('date', isLessThanOrEqualTo: endDateString)
          .orderBy('date');

      final querySnapshot = await query.get();

      final Map<String, int> moodDict = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? dateString = data['date'] as String?;
        final int moodIndex = data['mood_index'] as int? ?? 0;

        if (dateString != null) {
          moodDict[dateString] = moodIndex;
        }
      }

      return moodDict;
    } catch (e) {
      throw Exception('Failed to get daily moods dictionary by date: $e');
    }
  }


  Future<Map<String, int>> getDailyMoodsDict({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Default to last 30 days if no dates provided
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));

      Query query = _moodCheckinCollection
          .where('status', isEqualTo: 'completed')
          .where('created_at', isGreaterThanOrEqualTo: start)
          .where('created_at', isLessThanOrEqualTo: end)
          .orderBy('created_at');

      final querySnapshot = await query.get();

      // Create dictionary with timestamp as key and mood_index as value
      final Map<String, int> moodDict = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Get timestamp (use created_at or timestamp field)
        final Timestamp? firestoreTimestamp =
            data['created_at'] as Timestamp? ??
                data['timestamp'] as Timestamp?;

        if (firestoreTimestamp != null) {
          final DateTime dateTime = firestoreTimestamp.toDate();
          final String timestampKey = dateTime.millisecondsSinceEpoch.toString();
          final int moodIndex = data['mood_index'] as int? ?? 0;

          moodDict[timestampKey] = moodIndex;
        }
      }

      return moodDict;
    } catch (e) {
      throw Exception('Failed to get daily moods dictionary: $e');
    }
  }
  /// Update mood with feeling description (from DescribeFeelingScreen)
  Future<void> updateMoodWithFeeling({
    required String moodCheckinId,
    required List<String> selectedTags,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'selected_emotion_tags': selectedTags,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with feeling: $e');
    }
  }
  Future<List<Map<String, dynamic>>> getMoodDataForGraph({
    required DateTime startDate,
    required DateTime endDate,
    required String period, // 'weekly' or 'monthly'
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get mood trends for the specified period
      final moodData = await getMoodTrends(
        startDate: startDate,
        endDate: endDate,
      );

      if (period == 'weekly') {
        return _formatWeeklyMoodData(moodData, startDate, endDate);
      } else if (period == 'monthly') {
        return _formatMonthlyMoodData(moodData, startDate, endDate);
      } else {
        throw Exception('Invalid period. Use "weekly" or "monthly"');
      }
    } catch (e) {
      throw Exception('Failed to get mood data for graph: $e');
    }
  }

  /// Format mood data for weekly view (7 data points)
  List<Map<String, dynamic>> _formatWeeklyMoodData(
      List<Map<String, dynamic>> moodData,
      DateTime startDate,
      DateTime endDate,
      ) {
    final List<Map<String, dynamic>> weeklyData = [];

    // Create 7 days of data points
    for (int i = 0; i < 7; i++) {
      final currentDay = startDate.add(Duration(days: i));
      final dayString = _getDateString(currentDay);

      // Find mood data for this day
      final dayMood = moodData.firstWhere(
            (mood) => mood['date'] == dayString,
        orElse: () => <String, dynamic>{},
      );

      weeklyData.add({
        'date': currentDay,
        'dateString': dayString,
        'dayName': _getDayName(currentDay.weekday),
        'moodScore': dayMood['mood_index'] ?? 0, // 0 if no data
        'moodLabel': dayMood['mood_label'] ?? 'No Data',
        'hasData': dayMood.isNotEmpty,
        'timestamp': currentDay.millisecondsSinceEpoch,
      });
    }

    return weeklyData;
  }


  /// Format mood data for monthly view (aggregate by weeks or days)
  List<Map<String, dynamic>> _formatMonthlyMoodData(
      List<Map<String, dynamic>> moodData,
      DateTime startDate,
      DateTime endDate,
      ) {
    final List<Map<String, dynamic>> monthlyData = [];
    final daysInPeriod = endDate.difference(startDate).inDays + 1;

    if (daysInPeriod <= 31) {
      // Daily view for month
      for (int i = 0; i < daysInPeriod; i++) {
        final currentDay = startDate.add(Duration(days: i));
        final dayString = _getDateString(currentDay);

        final dayMood = moodData.firstWhere(
              (mood) => mood['date'] == dayString,
          orElse: () => <String, dynamic>{},
        );

        monthlyData.add({
          'date': currentDay,
          'dateString': dayString,
          'dayOfMonth': currentDay.day,
          'moodScore': dayMood['mood_index'] ?? 0,
          'moodLabel': dayMood['mood_label'] ?? 'No Data',
          'hasData': dayMood.isNotEmpty,
          'timestamp': currentDay.millisecondsSinceEpoch,
        });
      }
    } else {
      // Weekly aggregation for longer periods
      final weeks = <int, List<Map<String, dynamic>>>{};

      // Group data by weeks
      for (final mood in moodData) {
        final moodDate = (mood['created_at'] as Timestamp).toDate();
        final weekNumber = _getWeekNumber(moodDate);

        weeks[weekNumber] ??= [];
        weeks[weekNumber]!.add(mood);
      }

      // Calculate weekly averages
      weeks.forEach((weekNumber, weekMoods) {
        final totalScore = weekMoods.fold<double>(
          0,
              (sum, mood) => sum + (mood['mood_index'] as int).toDouble(),
        );
        final averageScore = weekMoods.isNotEmpty ? totalScore / weekMoods.length : 0;

        // Get the start of the week
        final firstMoodDate = (weekMoods.first['created_at'] as Timestamp).toDate();
        final weekStart = _getStartOfWeek(firstMoodDate);

        monthlyData.add({
          'date': weekStart,
          'dateString': _getDateString(weekStart),
          'weekNumber': weekNumber,
          'moodScore': averageScore.round(),
          'averageMoodScore': averageScore,
          'moodLabel': _getMoodLabelFromScore(averageScore.round()),
          'hasData': weekMoods.isNotEmpty,
          'dataPointsCount': weekMoods.length,
          'timestamp': weekStart.millisecondsSinceEpoch,
        });
      });

      // Sort by date
      monthlyData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    }

    return monthlyData;
  }

  Future<Map<String, dynamic>> getMoodGraphStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final moodData = await getMoodTrends(
        startDate: startDate,
        endDate: endDate,
      );

      if (moodData.isEmpty) {
        return {
          'averageMood': 0.0,
          'highestMood': 0,
          'lowestMood': 0,
          'moodTrend': 'stable', // 'improving', 'declining', 'stable'
          'totalDays': 0,
          'daysWithData': 0,
          'moodDistribution': {},
        };
      }

      final moodScores = moodData.map((m) => m['mood_index'] as int).toList();
      final averageMood = moodScores.reduce((a, b) => a + b) / moodScores.length;
      final highestMood = moodScores.reduce((a, b) => a > b ? a : b);
      final lowestMood = moodScores.reduce((a, b) => a < b ? a : b);

      // Calculate trend (compare first half with second half)
      String trend = 'stable';
      if (moodScores.length >= 4) {
        final halfPoint = moodScores.length ~/ 2;
        final firstHalf = moodScores.sublist(0, halfPoint);
        final secondHalf = moodScores.sublist(halfPoint);

        final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

        if (secondAvg > firstAvg + 0.3) {
          trend = 'improving';
        } else if (secondAvg < firstAvg - 0.3) {
          trend = 'declining';
        }
      }

      // Mood distribution
      final moodDistribution = <int, int>{};
      for (final score in moodScores) {
        moodDistribution[score] = (moodDistribution[score] ?? 0) + 1;
      }

      final totalDays = endDate.difference(startDate).inDays + 1;

      return {
        'averageMood': double.parse(averageMood.toStringAsFixed(1)),
        'highestMood': highestMood,
        'lowestMood': lowestMood,
        'moodTrend': trend,
        'totalDays': totalDays,
        'daysWithData': moodData.length,
        'moodDistribution': moodDistribution,
      };
    } catch (e) {
      throw Exception('Failed to get mood graph stats: $e');
    }
  }


  /// Helper method to get day name from weekday number
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Helper method to get mood label from score
  String _getMoodLabelFromScore(int score) {
    switch (score) {
      case 1:
        return 'Very Bad';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'No Data';
    }
  }

  /// Helper method to get week number
  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return (dayOfYear / 7).ceil();
  }

  /// Helper method to get start of week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  /// Convenience methods for common time periods

  /// Get this week's mood data
  Future<List<Map<String, dynamic>>> getThisWeekMoodData() async {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getMoodDataForGraph(
      startDate: startOfWeek,
      endDate: endOfWeek,
      period: 'weekly',
    );
  }

  /// Get this month's mood data
  Future<List<Map<String, dynamic>>> getThisMonthMoodData() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return getMoodDataForGraph(
      startDate: startOfMonth,
      endDate: endOfMonth,
      period: 'monthly',
    );
  }

  /// Get last 30 days mood data
  Future<List<Map<String, dynamic>>> getLast30DaysMoodData() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 29));

    return getMoodDataForGraph(
      startDate: startDate,
      endDate: now,
      period: 'monthly',
    );
  }
  /// Update mood with excitement categories (from CurrentExcitementScreen)
  Future<void> updateMoodWithExcitement({
    required String moodCheckinId,
    required List<String> selectedCategories,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'excitement_categories': selectedCategories,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with excitement: $e');
    }
  }

  /// Update mood with positive experience (from PositiveExperienceScreen)
  Future<void> updateMoodWithPositiveExperience({
    required String moodCheckinId,
    required String positiveExperience,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'positive_experience': positiveExperience,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with positive experience: $e');
    }
  }

  /// Update mood with meaningful experience (from ExperienceMeaningfulScreen)
  Future<void> updateMoodWithMeaningfulExperience({
    required String moodCheckinId,
    required String meaningfulExperience,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'meaningful_experience': meaningfulExperience,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with meaningful experience: $e');
    }
  }

  /// Update mood with more experiences (from MoreExperienceScreen)
  Future<void> updateMoodWithMoreExperiences({
    required String moodCheckinId,
    required String moreExperiences,
    required bool wantsBreathingExercise,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'more_experiences': moreExperiences,
        'wants_breathing_exercise': wantsBreathingExercise,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with more experiences: $e');
    }
  }

  /// Complete mood check-in (from GratificationScreen)
  Future<void> completeMoodCheckin({
    required String moodCheckinId,
    required int streakDays,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'streak_days': streakDays,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user's mood check-in streak
      await _updateUserStreakData(streakDays);
    } catch (e) {
      throw Exception('Failed to complete mood check-in: $e');
    }
  }

  /// Get today's mood check-in if exists
  Future<DocumentSnapshot?> getTodaysMoodCheckin() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final today = _getDateString(DateTime.now());
      final querySnapshot = await _moodCheckinCollection
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get today\'s mood check-in: $e');
    }
  }

  /// Check if user has already completed mood check-in today
  Future<bool> hasCompletedTodaysMoodCheckin() async {
    try {
      final todaysMood = await getTodaysMoodCheckin();
      if (todaysMood == null) return false;

      final data = todaysMood.data() as Map<String, dynamic>?;
      return data?['status'] == 'completed';
    } catch (e) {
      return false;
    }
  }

  /// Get mood check-in history for analytics
  Future<List<Map<String, dynamic>>> getMoodHistory({
    int limit = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      Query query = _moodCheckinCollection
          .where('status', isEqualTo: 'completed')
          .orderBy('created_at', descending: true);

      if (startDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get mood history: $e');
    }
  }

  /// Get mood statistics
  Future<Map<String, dynamic>> getMoodStats() async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final history = await getMoodHistory(limit: 100);

      if (history.isEmpty) {
        return {
          'total_checkins': 0,
          'current_streak': 0,
          'best_streak': 0,
          'average_mood': 0.0,
          'mood_distribution': {},
          'most_common_emotions': [],
          'most_exciting_categories': [],
        };
      }

      // Calculate statistics
      final totalCheckins = history.length;
      final currentStreak = await _calculateCurrentStreak();
      final bestStreak = await _calculateBestStreak();

      // Mood distribution
      final moodCounts = <String, int>{};
      double totalMoodScore = 0;
      final emotionCounts = <String, int>{};
      final categoryCounts = <String, int>{};

      for (final mood in history) {
        final moodLabel = mood['mood_label'] as String? ?? 'Unknown';
        final moodIndex = mood['mood_index'] as int? ?? 0;

        moodCounts[moodLabel] = (moodCounts[moodLabel] ?? 0) + 1;
        totalMoodScore += moodIndex;

        // Count emotions
        final emotions = mood['selected_emotion_tags'] as List<dynamic>? ?? [];
        for (final emotion in emotions) {
          emotionCounts[emotion.toString()] = (emotionCounts[emotion.toString()] ?? 0) + 1;
        }

        // Count excitement categories
        final categories = mood['excitement_categories'] as List<dynamic>? ?? [];
        for (final category in categories) {
          categoryCounts[category.toString()] = (categoryCounts[category.toString()] ?? 0) + 1;
        }
      }

      final averageMood = totalMoodScore / totalCheckins;

      // Get top emotions and categories
      final sortedEmotions = emotionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'total_checkins': totalCheckins,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'average_mood': averageMood,
        'mood_distribution': moodCounts,
        'most_common_emotions': sortedEmotions.take(5).map((e) => e.key).toList(),
        'most_exciting_categories': sortedCategories.take(5).map((e) => e.key).toList(),
      };
    } catch (e) {
      throw Exception('Failed to get mood stats: $e');
    }
  }

  /// Update user's streak data
  Future<void> _updateUserStreakData(int currentStreak) async {
    if (_userId == null) return;

    try {
      final userDoc = _firestore.collection('users').doc(_userId);
      await userDoc.update({
        'mood_streak_current': currentStreak,
        'mood_streak_last_updated': FieldValue.serverTimestamp(),
      });

      // Update best streak if current is higher
      final userSnapshot = await userDoc.get();
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final bestStreak = userData?['mood_streak_best'] as int? ?? 0;

      if (currentStreak > bestStreak) {
        await userDoc.update({
          'mood_streak_best': currentStreak,
        });
      }
    } catch (e) {
      print('Failed to update user streak data: $e');
    }
  }

  /// Calculate current streak
  Future<int> _calculateCurrentStreak() async {
    if (_userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['mood_streak_current'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate best streak
  Future<int> _calculateBestStreak() async {
    if (_userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['mood_streak_best'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Helper method to get date string
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Delete a mood check-in (if needed for testing or user request)
  Future<void> deleteMoodCheckin(String moodCheckinId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).delete();
    } catch (e) {
      throw Exception('Failed to delete mood check-in: $e');
    }
  }

  /// Get mood trends for a specific time period
  Future<List<Map<String, dynamic>>> getMoodTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _moodCheckinCollection
          .where('status', isEqualTo: 'completed')
          .where('created_at', isGreaterThanOrEqualTo: startDate)
          .where('created_at', isLessThanOrEqualTo: endDate)
          .orderBy('created_at')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get mood trends: $e');
    }
  }
  /// Update mood with unhelpful thoughts (from UnHelpfulThoughsScreen)
  Future<void> updateMoodWithUnhelpfulThoughts({
    required String moodCheckinId,
    required String unhelpfulThoughts,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'unhelpful_thoughts': unhelpfulThoughts,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with unhelpful thoughts: $e');
    }
  }

  /// Update mood with thought distortions (from ThoughDistractionScreen)
  Future<void> updateMoodWithThoughtDistortions({
    required String moodCheckinId,
    required List<String> selectedDistortions,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'thought_distortions': selectedDistortions,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with thought distortions: $e');
    }
  }


  /// Update mood with challenging thoughts (from ChallengeThoughScreen)
  Future<void> updateMoodWithChallengingThoughts({
    required String moodCheckinId,
    required String challengingThoughts,
    required bool wantsBreathingExercise,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _moodCheckinCollection.doc(moodCheckinId).update({
        'challenging_thoughts': challengingThoughts,
        'wants_breathing_exercise': wantsBreathingExercise,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update mood with challenging thoughts: $e');
    }
  }
}