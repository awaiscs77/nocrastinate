import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ApiServices/TipsService.dart';
import 'StreaksManager.dart';

class TipsManager extends ChangeNotifier {
  static final TipsManager _instance = TipsManager._internal();
  factory TipsManager() => _instance;
  TipsManager._internal();

  // Current state
  bool _isLoading = false;
  String? _error;
  bool _hasViewedTipToday = false;
  Map<String, dynamic> _tipStats = {};
  List<Map<String, dynamic>> _todaysViewedTips = [];
  Map<String, bool> _categoryViewStatus = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasViewedTipToday => _hasViewedTipToday;
  Map<String, dynamic> get tipStats => Map<String, dynamic>.from(_tipStats);
  List<Map<String, dynamic>> get todaysViewedTips => List<Map<String, dynamic>>.from(_todaysViewedTips);
  int get currentStreak => _tipStats['currentStreak'] ?? 0;
  int get totalTipsViewed => _tipStats['totalTipsViewed'] ?? 0;

  /// Initialize the manager by loading current state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Load today's tip view status
      _hasViewedTipToday = await TipsService.hasViewedTipToday();

      // Load tip statistics
      _tipStats = await TipsService.getTipStats();

      // Load today's viewed tips
      _todaysViewedTips = await TipsService.getTodaysViewedTips();

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize tips manager: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save tip view when user clicks "Done"
  Future<bool> saveTipView({
    required String tipContent,
    required String category,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final tipViewId = await TipsService.saveTipView(
        tipContent: tipContent,
        category: category,
      );

      if (tipViewId != null) {
        // Update local state
        _hasViewedTipToday = true;
        _categoryViewStatus[category] = true;

        // Refresh stats and today's tips
        await StreaksManager().recordTipsCompletion();
        await _refreshData();

        notifyListeners();
        return true;
      }

      _setError('Failed to save tip view');
      return false;
    } catch (e) {
      _setError('Failed to save tip view: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user has viewed a tip today for specific category
  Future<bool> hasViewedTipTodayForCategory(String category) async {
    try {
      // Check cache first
      if (_categoryViewStatus.containsKey(category)) {
        return _categoryViewStatus[category]!;
      }

      // Check from service
      final hasViewed = await TipsService.hasViewedTipTodayForCategory(category);
      _categoryViewStatus[category] = hasViewed;

      return hasViewed;
    } catch (e) {
      _setError('Failed to check category tip view: $e');
      return false;
    }
  }

  /// Get tip viewing history with pagination
  Future<List<Map<String, dynamic>>> getTipViewHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      return await TipsService.getTipViewHistory(
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e) {
      _setError('Failed to get tip history: $e');
      return [];
    }
  }

  /// Get tips viewed by category
  Future<Map<String, int>> getTipsByCategory() async {
    try {
      return await TipsService.getTipsByCategory();
    } catch (e) {
      _setError('Failed to get tips by category: $e');
      return {};
    }
  }

  /// Refresh all data from service
  Future<void> refreshData() async {
    await initialize();
  }

  /// Check if user can view tip (hasn't viewed today)
  bool canViewTip() {
    return !_hasViewedTipToday;
  }

  /// Check if user can view tip for specific category
  Future<bool> canViewTipForCategory(String category) async {
    final hasViewed = await hasViewedTipTodayForCategory(category);
    return !hasViewed;
  }

  /// Get next available category that hasn't been viewed today
  Future<String?> getNextAvailableCategory(List<String> categories) async {
    for (String category in categories) {
      final hasViewed = await hasViewedTipTodayForCategory(category);
      if (!hasViewed) {
        return category;
      }
    }
    return null; // All categories viewed today
  }

  /// Get tip completion status message
  String getTipStatusMessage() {
    if (_hasViewedTipToday) {
      return 'You\'ve viewed your tip for today!';
    } else {
      return 'Ready to view today\'s tip';
    }
  }

  /// Get streak status message
  String getStreakMessage() {
    final streak = currentStreak;
    if (streak == 0) {
      return 'Start your tip viewing streak!';
    } else if (streak == 1) {
      return 'Great start! Keep it up tomorrow.';
    } else if (streak < 7) {
      return '$streak days in a row! You\'re building a habit.';
    } else if (streak < 30) {
      return '$streak day streak! Amazing consistency.';
    } else {
      return '$streak day streak! You\'re a tip viewing champion!';
    }
  }

  /// Delete a tip view record
  Future<bool> deleteTipView(String tipViewId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await TipsService.deleteTipView(tipViewId);

      if (success) {
        // Refresh data after deletion
        await _refreshData();
        notifyListeners();
        return true;
      }

      _setError('Failed to delete tip view');
      return false;
    } catch (e) {
      _setError('Failed to delete tip view: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user's favorite categories based on viewing history
  Future<List<String>> getFavoriteCategories() async {
    try {
      final categoryStats = await getTipsByCategory();

      // Sort categories by view count
      final sortedCategories = categoryStats.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.map((entry) => entry.key).take(5).toList();
    } catch (e) {
      _setError('Failed to get favorite categories: $e');
      return [];
    }
  }

  /// Private helper methods
  Future<void> _refreshData() async {
    try {
      _hasViewedTipToday = await TipsService.hasViewedTipToday();
      _tipStats = await TipsService.getTipStats();
      _todaysViewedTips = await TipsService.getTodaysViewedTips();

      // Clear category cache to force refresh
      _categoryViewStatus.clear();
    } catch (e) {
      print('Error refreshing tips data: $e');
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
    _hasViewedTipToday = false;
    _tipStats.clear();
    _todaysViewedTips.clear();
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