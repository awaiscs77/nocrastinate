import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ApiServices/StreaksService.dart';

class StreaksManager extends ChangeNotifier {
  static final StreaksManager _instance = StreaksManager._internal();
  factory StreaksManager() => _instance;
  StreaksManager._internal();

  // Current state
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _todaysActivityStatus = {};
  Map<String, dynamic> _streakStats = {};
  List<Map<String, dynamic>> _streakHistory = [];

  // Real-time streak count variable - always up to date
  int _currentStreakCount = 0;

  // Activity types - matching StreaksService
  static const String affirmationActivity = 'affirmation';
  static const String tipsActivity = 'tips';
  static const String mindPracticeActivity = 'mind_practice';
  static const String moodCheckinActivity = 'mood_checkin';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, bool> get todaysActivityStatus => Map<String, bool>.from(_todaysActivityStatus);
  Map<String, dynamic> get streakStats => Map<String, dynamic>.from(_streakStats);
  List<Map<String, dynamic>> get streakHistory => List<Map<String, dynamic>>.from(_streakHistory);

  int get currentStreak => _streakStats['currentStreak'] ?? 0;
  int get longestStreak => _streakStats['longestStreak'] ?? 0;
  int get totalCompletedDays => _streakStats['totalCompletedDays'] ?? 0;

  // NEW: Always up-to-date streak count that can be accessed from any screen
  int get streakCount => _currentStreakCount;

  bool get isAllActivitiesCompletedToday => _areAllActivitiesComplete();
  int get todaysCompletedActivities => _todaysActivityStatus.values.where((completed) => completed).length;
  int get todaysRemainingActivities => 4 - todaysCompletedActivities;

  /// Initialize the manager by loading current state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Load today's activity status
      _todaysActivityStatus = await StreaksService.getTodaysActivityStatus();

      // Load streak statistics
      _streakStats = await StreaksService.getStreakStats();

      // Update the real-time streak count
      _currentStreakCount = _streakStats['currentStreak'] ?? 0;

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize streaks manager: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Record activity completion
  Future<bool> recordActivityCompletion(String activityType) async {
    if (!_isValidActivityType(activityType)) {
      _setError('Invalid activity type: $activityType');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final success = await StreaksService.recordActivityCompletion(activityType);

      if (success) {
        // Update local state
        _todaysActivityStatus[activityType] = true;

        // If this completes all activities for today, refresh stats and update streak count
        if (_areAllActivitiesComplete()) {
          await _refreshStreakStats();
          // Update the real-time streak count after completing all activities
          _currentStreakCount = _streakStats['currentStreak'] ?? 0;
        }

        notifyListeners();
        return true;
      }

      _setError('Failed to record activity completion');
      return false;
    } catch (e) {
      _setError('Failed to record activity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update streak count manually (useful for real-time updates)
  Future<void> updateStreakCount() async {
    try {
      final currentStreakFromService = await StreaksService.getCurrentStreak();
      if (_currentStreakCount != currentStreakFromService) {
        _currentStreakCount = currentStreakFromService;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating streak count: $e');
    }
  }

  /// Set streak count directly (for immediate updates)
  void setStreakCount(int count) {
    if (_currentStreakCount != count) {
      _currentStreakCount = count;
      notifyListeners();
    }
  }

  /// Record affirmation completion
  Future<bool> recordAffirmationCompletion() async {
    return await recordActivityCompletion(affirmationActivity);
  }

  /// Record tips completion
  Future<bool> recordTipsCompletion() async {
    return await recordActivityCompletion(tipsActivity);
  }

  /// Record mind practice completion
  Future<bool> recordMindPracticeCompletion() async {
    return await recordActivityCompletion(mindPracticeActivity);
  }

  /// Record mood check-in completion
  Future<bool> recordMoodCheckinCompletion() async {
    return await recordActivityCompletion(moodCheckinActivity);
  }

  /// Get streak history with pagination
  Future<List<Map<String, dynamic>>> getStreakHistory({
    int limit = 30,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      return await StreaksService.getStreakHistory(
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e) {
      _setError('Failed to get streak history: $e');
      return [];
    }
  }

  /// Get completion rate for a specific period
  Future<double> getCompletionRate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await StreaksService.getCompletionRate(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Failed to get completion rate: $e');
      return 0.0;
    }
  }

  /// Calculate streak from history (for verification)
  Future<int> calculateStreakFromHistory() async {
    try {
      final calculatedStreak = await StreaksService.calculateStreakFromHistory();
      // Update the real-time streak count with calculated value
      if (_currentStreakCount != calculatedStreak) {
        _currentStreakCount = calculatedStreak;
        notifyListeners();
      }
      return calculatedStreak;
    } catch (e) {
      _setError('Failed to calculate streak: $e');
      return 0;
    }
  }

  /// Reset streak (admin function)
  Future<bool> resetStreak() async {
    try {
      _setLoading(true);
      _clearError();

      final success = await StreaksService.resetStreak();

      if (success) {
        _currentStreakCount = 0; // Reset the real-time count immediately
        await initialize(); // Refresh all data
        return true;
      }

      _setError('Failed to reset streak');
      return false;
    } catch (e) {
      _setError('Failed to reset streak: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await initialize();
  }

  /// Get activity completion percentage for today
  double get todaysCompletionPercentage {
    return todaysCompletedActivities / 4.0;
  }

  /// Get next activity to complete
  String? get nextActivityToComplete {
    final activities = [
      affirmationActivity,
      tipsActivity,
      mindPracticeActivity,
      moodCheckinActivity,
    ];

    for (String activity in activities) {
      if (!(_todaysActivityStatus[activity] ?? false)) {
        return activity;
      }
    }

    return null; // All activities completed
  }

  /// Get friendly activity name
  String getFriendlyActivityName(String activityType) {
    switch (activityType) {
      case affirmationActivity:
        return 'Affirmation';
      case tipsActivity:
        return 'Daily Tip';
      case mindPracticeActivity:
        return 'Mind Practice';
      case moodCheckinActivity:
        return 'Mood Check-in';
      default:
        return activityType;
    }
  }

  /// Get motivational message based on current progress
  String getMotivationalMessage() {
    final completed = todaysCompletedActivities;
    final streak = _currentStreakCount; // Use the real-time streak count

    if (completed == 0) {
      if (streak == 0) {
        return 'Start your wellness journey today! Complete all 4 activities to begin your streak.';
      } else {
        return 'Your $streak-day streak is waiting! Let\'s keep it going with today\'s activities.';
      }
    } else if (completed == 1) {
      return 'Great start! You\'ve completed 1 out of 4 activities. Keep the momentum going!';
    } else if (completed == 2) {
      return 'Halfway there! You\'ve completed 2 out of 4 activities. You\'re doing amazing!';
    } else if (completed == 3) {
      return 'So close! Just 1 more activity to complete your daily wellness goals.';
    } else {
      final newStreak = streak + 1;
      if (newStreak == 1) {
        return 'Congratulations! You\'ve completed all activities and started your streak!';
      } else if (newStreak < 7) {
        return 'Amazing! You\'ve maintained your streak for $newStreak days. Keep it up!';
      } else if (newStreak < 30) {
        return 'Incredible dedication! $newStreak days of complete wellness practice!';
      } else {
        return 'You\'re a wellness champion! $newStreak days of perfect consistency!';
      }
    }
  }

  /// Get streak status message
  String getStreakStatusMessage() {
    final streak = _currentStreakCount; // Use the real-time streak count
    final longest = longestStreak;

    if (streak == 0) {
      if (longest == 0) {
        return 'Ready to start your first wellness streak!';
      } else {
        return 'Time to rebuild your streak! Your best was $longest days.';
      }
    } else if (streak == longest) {
      return 'Personal best! You\'re on a $streak-day streak!';
    } else {
      return 'Current streak: $streak days (Best: $longest days)';
    }
  }

  /// Get today's progress summary
  Map<String, dynamic> getTodaysProgressSummary() {
    return {
      'completedActivities': todaysCompletedActivities,
      'totalActivities': 4,
      'completionPercentage': todaysCompletionPercentage,
      'isComplete': isAllActivitiesCompletedToday,
      'nextActivity': nextActivityToComplete,
      'activityStatus': Map<String, bool>.from(_todaysActivityStatus),
      'currentStreak': _currentStreakCount, // Include real-time streak count
    };
  }

  /// Get weekly progress (last 7 days)
  Future<Map<String, dynamic>> getWeeklyProgress() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 6));

      final history = await getStreakHistory(limit: 7);
      final completionRate = await getCompletionRate(
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'completionRate': completionRate,
        'daysCompleted': history.where((day) => day['isComplete'] == true).length,
        'totalDays': 7,
        'history': history,
        'currentStreak': _currentStreakCount, // Include current streak
      };
    } catch (e) {
      _setError('Failed to get weekly progress: $e');
      return {};
    }
  }

  /// Get monthly progress
  Future<Map<String, dynamic>> getMonthlyProgress() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 29));

      final history = await getStreakHistory(limit: 30);
      final completionRate = await getCompletionRate(
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'completionRate': completionRate,
        'daysCompleted': history.where((day) => day['isComplete'] == true).length,
        'totalDays': 30,
        'history': history,
        'currentStreak': _currentStreakCount, // Include current streak
      };
    } catch (e) {
      _setError('Failed to get monthly progress: $e');
      return {};
    }
  }

  /// Check if user should receive a reminder
  bool shouldShowReminder() {
    if (isAllActivitiesCompletedToday) return false;

    final now = DateTime.now();
    // Show reminder after 10 AM if activities aren't complete
    return now.hour >= 10;
  }

  /// Get reminder message
  String getReminderMessage() {
    final remaining = todaysRemainingActivities;
    final nextActivity = nextActivityToComplete;

    if (remaining == 4) {
      return 'Start your wellness routine! You have 4 activities to complete today.';
    } else if (remaining == 1 && nextActivity != null) {
      return 'Almost there! Complete your ${getFriendlyActivityName(nextActivity)} to maintain your streak.';
    } else {
      return 'You have $remaining activities left to complete today. Keep going!';
    }
  }

  /// Private helper methods

  bool _areAllActivitiesComplete() {
    return (_todaysActivityStatus[affirmationActivity] ?? false) &&
        (_todaysActivityStatus[tipsActivity] ?? false) &&
        (_todaysActivityStatus[mindPracticeActivity] ?? false) &&
        (_todaysActivityStatus[moodCheckinActivity] ?? false);
  }

  bool _isValidActivityType(String activityType) {
    return [
      affirmationActivity,
      tipsActivity,
      mindPracticeActivity,
      moodCheckinActivity,
    ].contains(activityType);
  }

  Future<void> _refreshStreakStats() async {
    try {
      _streakStats = await StreaksService.getStreakStats();
      // Also update the real-time streak count
      _currentStreakCount = _streakStats['currentStreak'] ?? 0;
    } catch (e) {
      print('Error refreshing streak stats: $e');
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Reset the manager
  void reset() {
    _todaysActivityStatus.clear();
    _streakStats.clear();
    _streakHistory.clear();
    _currentStreakCount = 0; // Reset the real-time streak count
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}