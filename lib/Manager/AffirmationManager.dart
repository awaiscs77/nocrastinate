import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ApiServices/AffirmationService.dart';
import 'StreaksManager.dart';

class AffirmationManager extends ChangeNotifier {
  static final AffirmationManager _instance = AffirmationManager._internal();
  factory AffirmationManager() => _instance;
  AffirmationManager._internal();

  // Current state
  bool _isLoading = false;
  String? _error;
  bool _hasViewedAffirmationToday = false;
  Map<String, dynamic> _affirmationStats = {};
  List<Map<String, dynamic>> _todaysViewedAffirmations = [];
  Map<String, bool> _categoryViewStatus = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasViewedAffirmationToday => _hasViewedAffirmationToday;
  Map<String, dynamic> get affirmationStats => Map<String, dynamic>.from(_affirmationStats);
  List<Map<String, dynamic>> get todaysViewedAffirmations => List<Map<String, dynamic>>.from(_todaysViewedAffirmations);
  int get currentStreak => _affirmationStats['currentStreak'] ?? 0;
  int get totalAffirmationsViewed => _affirmationStats['totalAffirmationsViewed'] ?? 0;

  /// Initialize the manager by loading current state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Load today's affirmation view status
      _hasViewedAffirmationToday = await AffirmationService.hasViewedAffirmationToday();

      // Load affirmation statistics
      _affirmationStats = await AffirmationService.getAffirmationStats();

      // Load today's viewed affirmations
      _todaysViewedAffirmations = await AffirmationService.getTodaysViewedAffirmations();

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize affirmation manager: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save affirmation view when user clicks "Done"
  Future<bool> saveAffirmationView({
    required String affirmationContent,
    required String category,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final affirmationViewId = await AffirmationService.saveAffirmationView(
        affirmationContent: affirmationContent,
        category: category,
      );

      if (affirmationViewId != null) {
        // Update local state
        _hasViewedAffirmationToday = true;
        _categoryViewStatus[category] = true;
        await StreaksManager().recordAffirmationCompletion();
        // Refresh stats and today's affirmations
        await _refreshData();

        notifyListeners();
        return true;
      }

      _setError('Failed to save affirmation view');
      return false;
    } catch (e) {
      _setError('Failed to save affirmation view: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user has viewed an affirmation today for specific category
  Future<bool> hasViewedAffirmationTodayForCategory(String category) async {
    try {
      // Check cache first
      if (_categoryViewStatus.containsKey(category)) {
        return _categoryViewStatus[category]!;
      }

      // Check from service
      final hasViewed = await AffirmationService.hasViewedAffirmationTodayForCategory(category);
      _categoryViewStatus[category] = hasViewed;

      return hasViewed;
    } catch (e) {
      _setError('Failed to check category affirmation view: $e');
      return false;
    }
  }

  /// Get affirmation viewing history with pagination
  Future<List<Map<String, dynamic>>> getAffirmationViewHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      return await AffirmationService.getAffirmationViewHistory(
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e) {
      _setError('Failed to get affirmation history: $e');
      return [];
    }
  }

  /// Get affirmations viewed by category
  Future<Map<String, int>> getAffirmationsByCategory() async {
    try {
      return await AffirmationService.getAffirmationsByCategory();
    } catch (e) {
      _setError('Failed to get affirmations by category: $e');
      return {};
    }
  }

  /// Refresh all data from service
  Future<void> refreshData() async {
    await initialize();
  }

  /// Check if user can view affirmation (hasn't viewed today)
  bool canViewAffirmation() {
    return !_hasViewedAffirmationToday;
  }

  /// Check if user can view affirmation for specific category
  Future<bool> canViewAffirmationForCategory(String category) async {
    final hasViewed = await hasViewedAffirmationTodayForCategory(category);
    return !hasViewed;
  }

  /// Get next available category that hasn't been viewed today
  Future<String?> getNextAvailableCategory(List<String> categories) async {
    for (String category in categories) {
      final hasViewed = await hasViewedAffirmationTodayForCategory(category);
      if (!hasViewed) {
        return category;
      }
    }
    return null; // All categories viewed today
  }

  /// Get affirmation completion status message
  String getAffirmationStatusMessage() {
    if (_hasViewedAffirmationToday) {
      return 'You\'ve viewed your affirmation for today!';
    } else {
      return 'Ready to view today\'s affirmation';
    }
  }

  /// Get streak status message
  String getStreakMessage() {
    final streak = currentStreak;
    if (streak == 0) {
      return 'Start your affirmation viewing streak!';
    } else if (streak == 1) {
      return 'Great start! Keep it up tomorrow.';
    } else if (streak < 7) {
      return '$streak days in a row! You\'re building a positive habit.';
    } else if (streak < 30) {
      return '$streak day streak! Amazing positivity consistency.';
    } else {
      return '$streak day streak! You\'re an affirmation champion!';
    }
  }

  /// Get motivational streak message based on current streak
  String getMotivationalMessage() {
    final streak = currentStreak;
    final total = totalAffirmationsViewed;

    if (streak == 0 && total == 0) {
      return 'Start your journey with positive affirmations today!';
    } else if (streak == 0 && total > 0) {
      return 'Welcome back! Ready to restart your positive streak?';
    } else if (streak < 3) {
      return 'You\'re building momentum! Keep going!';
    } else if (streak < 7) {
      return 'Fantastic! You\'re creating a positive daily habit.';
    } else if (streak < 21) {
      return 'Incredible dedication! You\'re transforming your mindset.';
    } else if (streak < 100) {
      return 'You\'re a positivity powerhouse! Keep inspiring yourself.';
    } else {
      return 'Legendary streak! You\'re a master of positive thinking.';
    }
  }

  /// Delete an affirmation view record
  Future<bool> deleteAffirmationView(String affirmationViewId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await AffirmationService.deleteAffirmationView(affirmationViewId);

      if (success) {
        // Refresh data after deletion
        await _refreshData();
        notifyListeners();
        return true;
      }

      _setError('Failed to delete affirmation view');
      return false;
    } catch (e) {
      _setError('Failed to delete affirmation view: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user's favorite categories based on viewing history
  Future<List<String>> getFavoriteCategories() async {
    try {
      final categoryStats = await getAffirmationsByCategory();

      // Sort categories by view count
      final sortedCategories = categoryStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.map((entry) => entry.key).take(5).toList();
    } catch (e) {
      _setError('Failed to get favorite categories: $e');
      return [];
    }
  }

  /// Get category statistics for analytics
  Future<Map<String, dynamic>> getCategoryAnalytics() async {
    try {
      final categoryStats = await getAffirmationsByCategory();
      final total = totalAffirmationsViewed;

      if (total == 0) return {};

      Map<String, dynamic> analytics = {};

      categoryStats.forEach((category, count) {
        analytics[category] = {
          'count': count,
          'percentage': ((count / total) * 100).round(),
        };
      });

      return analytics;
    } catch (e) {
      _setError('Failed to get category analytics: $e');
      return {};
    }
  }

  /// Get weekly affirmation summary
  Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      // This would require additional Firestore queries to get week-specific data
      // For now, return basic stats
      return {
        'currentStreak': currentStreak,
        'totalViewed': totalAffirmationsViewed,
        'hasViewedToday': _hasViewedAffirmationToday,
        'favoriteCategories': await getFavoriteCategories(),
      };
    } catch (e) {
      _setError('Failed to get weekly summary: $e');
      return {};
    }
  }

  /// Check if it's time for an affirmation reminder
  bool shouldShowReminder() {
    // Logic to determine if user should be reminded to view affirmation
    // Could be based on time of day, streak, etc.
    if (_hasViewedAffirmationToday) return false;

    final now = DateTime.now();
    // Example: Show reminder after 10 AM if not viewed today
    return now.hour >= 10;
  }

  /// Get personalized affirmation recommendation
  Future<String> getPersonalizedRecommendation() async {
    try {
      final favoriteCategories = await getFavoriteCategories();
      final streak = currentStreak;

      if (favoriteCategories.isEmpty) {
        return 'Start with any category that resonates with you today!';
      }

      if (streak == 0) {
        return 'Try starting with ${favoriteCategories.first} - it\'s one of your favorites!';
      }

      return 'Keep your $streak-day streak going with ${favoriteCategories.first}!';
    } catch (e) {
      return 'Choose any category and start your positive day!';
    }
  }

  /// Private helper methods
  Future<void> _refreshData() async {
    try {
      _hasViewedAffirmationToday = await AffirmationService.hasViewedAffirmationToday();
      _affirmationStats = await AffirmationService.getAffirmationStats();
      _todaysViewedAffirmations = await AffirmationService.getTodaysViewedAffirmations();

      // Clear category cache to force refresh
      _categoryViewStatus.clear();
    } catch (e) {
      print('Error refreshing affirmation data: $e');
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
    _hasViewedAffirmationToday = false;
    _affirmationStats.clear();
    _todaysViewedAffirmations.clear();
    _categoryViewStatus.clear();
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