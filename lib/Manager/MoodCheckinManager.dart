import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../ApiServices/MoodCheckinService.dart';
import '../Models/MoodCheckinModel.dart';
import 'StreaksManager.dart';


class MoodCheckinManager extends ChangeNotifier {
  static final MoodCheckinManager _instance = MoodCheckinManager._internal();
  factory MoodCheckinManager() => _instance;
  MoodCheckinManager._internal();

  final MoodCheckinService _service = MoodCheckinService();

  // Current mood check-in session
  String? _currentMoodCheckinId;
  MoodCheckinModel? _currentMoodCheckin;
  bool _isLoading = false;
  String? _error;

  // Mood statistics cache
  MoodStats? _cachedStats;
  List<MoodCheckinModel>? _cachedHistory;
  DateTime? _lastStatsUpdate;

  // Graph data cache
  List<Map<String, dynamic>>? _cachedWeeklyGraphData;
  List<Map<String, dynamic>>? _cachedMonthlyGraphData;
  Map<String, dynamic>? _cachedGraphStats;
  DateTime? _lastGraphDataUpdate;

  // Getters
  String? get currentMoodCheckinId => _currentMoodCheckinId;
  MoodCheckinModel? get currentMoodCheckin => _currentMoodCheckin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MoodStats? get cachedStats => _cachedStats;
  List<MoodCheckinModel>? get cachedHistory => _cachedHistory;

  // Check if user has completed today's mood check-in
  Future<bool> hasCompletedToday() async {
    try {
      _setLoading(true);
      final hasCompleted = await _service.hasCompletedTodaysMoodCheckin();
      return hasCompleted;
    } catch (e) {
      _setError('Failed to check today\'s mood status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  Future<Map<String, int>> getDailyMoodsDictByDate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _setLoading(true);
      final moodsDict = await _service.getDailyMoodsDictByDate(
        startDate: startDate,
        endDate: endDate,
      );

      notifyListeners();
      return moodsDict;
    } catch (e) {
      _setError('Failed to get daily moods dictionary: $e');
      return {};
    } finally {
      _setLoading(false);
    }
  }
  // Start a new mood check-in session
  Future<bool> startMoodCheckin({
    required int moodIndex,
    required String moodLabel,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if already completed today
      final hasCompleted = await _service.hasCompletedTodaysMoodCheckin();
      if (hasCompleted) {
        _setError('You have already completed your mood check-in for today');
        return false;
      }

      // Save initial mood
      final timestamp = DateTime.now();
      _currentMoodCheckinId = await _service.saveInitialMood(
        moodIndex: moodIndex,
        moodLabel: moodLabel,
        timestamp: timestamp,
      );

      // Create local model
      _currentMoodCheckin = MoodCheckinModel(
        id: _currentMoodCheckinId,
        moodIndex: moodIndex,
        moodLabel: moodLabel,
        timestamp: timestamp,
        date: _getDateString(timestamp),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start mood check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update with unhelpful thoughts
  Future<bool> updateWithUnhelpfulThoughts(String unhelpfulThoughts) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithUnhelpfulThoughts(
        moodCheckinId: _currentMoodCheckinId!,
        unhelpfulThoughts: unhelpfulThoughts,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        unhelpfulThoughts: unhelpfulThoughts,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with unhelpful thoughts: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateWithThoughtDistortions(List<String> selectedDistortions) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithThoughtDistortions(
        moodCheckinId: _currentMoodCheckinId!,
        selectedDistortions: selectedDistortions,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        thoughtDistortions: selectedDistortions,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with thought distortions: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateWithChallengingThoughts({
    required String challengingThoughts,
    required bool wantsBreathingExercise,
  }) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithChallengingThoughts(
        moodCheckinId: _currentMoodCheckinId!,
        challengingThoughts: challengingThoughts,
        wantsBreathingExercise: wantsBreathingExercise,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        challengingThoughts: challengingThoughts,
        wantsBreathingExercise: wantsBreathingExercise,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with challenging thoughts: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update with feeling description
  Future<bool> updateWithFeeling(List<String> selectedTags) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithFeeling(
        moodCheckinId: _currentMoodCheckinId!,
        selectedTags: selectedTags,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        selectedEmotionTags: selectedTags,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with feeling: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update with excitement categories
  Future<bool> updateWithExcitement(List<String> selectedCategories) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithExcitement(
        moodCheckinId: _currentMoodCheckinId!,
        selectedCategories: selectedCategories,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        excitementCategories: selectedCategories,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with excitement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update with positive experience
  Future<bool> updateWithPositiveExperience(String positiveExperience) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithPositiveExperience(
        moodCheckinId: _currentMoodCheckinId!,
        positiveExperience: positiveExperience,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        positiveExperience: positiveExperience,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with positive experience: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update with meaningful experience
  Future<bool> updateWithMeaningfulExperience(String meaningfulExperience) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithMeaningfulExperience(
        moodCheckinId: _currentMoodCheckinId!,
        meaningfulExperience: meaningfulExperience,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        meaningfulExperience: meaningfulExperience,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with meaningful experience: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update with more experiences
  Future<bool> updateWithMoreExperiences({
    required String moreExperiences,
    required bool wantsBreathingExercise,
  }) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.updateMoodWithMoreExperiences(
        moodCheckinId: _currentMoodCheckinId!,
        moreExperiences: moreExperiences,
        wantsBreathingExercise: wantsBreathingExercise,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        moreExperiences: moreExperiences,
        wantsBreathingExercise: wantsBreathingExercise,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mood with more experiences: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Complete the mood check-in
  Future<bool> completeMoodCheckin(int streakDays) async {
    if (_currentMoodCheckinId == null) {
      _setError('No active mood check-in session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      await _service.completeMoodCheckin(
        moodCheckinId: _currentMoodCheckinId!,
        streakDays: streakDays,
      );

      // Update local model
      _currentMoodCheckin = _currentMoodCheckin?.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
        streakDays: streakDays,
      );

      // Clear the session
      _clearSession();
      await StreaksManager().recordMoodCheckinCompletion();

      // Invalidate cached stats and graph data
      _invalidateCache();
      _invalidateGraphCache();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to complete mood check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get today's mood check-in if exists
  Future<MoodCheckinModel?> getTodaysMoodCheckin() async {
    try {
      _setLoading(true);
      final doc = await _service.getTodaysMoodCheckin();

      if (doc != null) {
        return MoodCheckinModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _setError('Failed to get today\'s mood check-in: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Resume an existing mood check-in session
  Future<bool> resumeMoodCheckin(MoodCheckinModel moodCheckin) async {
    if (moodCheckin.isCompleted) {
      _setError('Cannot resume a completed mood check-in');
      return false;
    }

    _currentMoodCheckinId = moodCheckin.id;
    _currentMoodCheckin = moodCheckin;
    _clearError();

    notifyListeners();
    return true;
  }

  // Get mood history with caching
  Future<List<MoodCheckinModel>?> getMoodHistory({
    int limit = 30,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedHistory != null && _isRecentCache()) {
      return _cachedHistory;
    }

    try {
      _setLoading(true);
      final historyData = await _service.getMoodHistory(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      _cachedHistory = historyData
          .map((data) => MoodCheckinModel.fromMap(data))
          .toList();

      _lastStatsUpdate = DateTime.now();

      notifyListeners();
      return _cachedHistory;
    } catch (e) {
      _setError('Failed to get mood history: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get mood statistics with caching
  Future<MoodStats?> getMoodStats({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedStats != null && _isRecentCache()) {
      return _cachedStats;
    }

    try {
      _setLoading(true);
      final statsData = await _service.getMoodStats();

      _cachedStats = MoodStats.fromMap(statsData);
      _lastStatsUpdate = DateTime.now();

      notifyListeners();
      return _cachedStats;
    } catch (e) {
      _setError('Failed to get mood statistics: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get mood trends
  Future<List<MoodCheckinModel>?> getMoodTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _setLoading(true);
      final trendsData = await _service.getMoodTrends(
        startDate: startDate,
        endDate: endDate,
      );

      final trends = trendsData
          .map((data) => MoodCheckinModel.fromMap(data))
          .toList();

      return trends;
    } catch (e) {
      _setError('Failed to get mood trends: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Graph Methods - NEW ADDITIONS

  /// Get mood data formatted for graphing
  Future<List<Map<String, dynamic>>?> getMoodDataForGraph({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
    bool forceRefresh = false,
  }) async {
    // Check cache based on period
    if (!forceRefresh && _isRecentGraphCache()) {
      if (period == 'weekly' && _cachedWeeklyGraphData != null) {
        return _cachedWeeklyGraphData;
      } else if (period == 'monthly' && _cachedMonthlyGraphData != null) {
        return _cachedMonthlyGraphData;
      }
    }

    try {
      _setLoading(true);
      final graphData = await _service.getMoodDataForGraph(
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      // Cache the data based on period
      if (period == 'weekly') {
        _cachedWeeklyGraphData = graphData;
      } else if (period == 'monthly') {
        _cachedMonthlyGraphData = graphData;
      }

      _lastGraphDataUpdate = DateTime.now();

      notifyListeners();
      return graphData;
    } catch (e) {
      _setError('Failed to get mood data for graph: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get mood graph statistics
  Future<Map<String, dynamic>?> getMoodGraphStats({
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedGraphStats != null && _isRecentGraphCache()) {
      return _cachedGraphStats;
    }

    try {
      _setLoading(true);
      final statsData = await _service.getMoodGraphStats(
        startDate: startDate,
        endDate: endDate,
      );

      _cachedGraphStats = statsData;
      _lastGraphDataUpdate = DateTime.now();

      notifyListeners();
      return statsData;
    } catch (e) {
      _setError('Failed to get mood graph statistics: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Convenience method - Get this week's mood graph data
  Future<List<Map<String, dynamic>>?> getThisWeekMoodGraphData({
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);
      final graphData = await _service.getThisWeekMoodData();

      // Cache weekly data
      _cachedWeeklyGraphData = graphData;
      _lastGraphDataUpdate = DateTime.now();

      notifyListeners();
      return graphData;
    } catch (e) {
      _setError('Failed to get this week\'s mood graph data: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Convenience method - Get this month's mood graph data
  Future<List<Map<String, dynamic>>?> getThisMonthMoodGraphData({
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);
      final graphData = await _service.getThisMonthMoodData();

      // Cache monthly data
      _cachedMonthlyGraphData = graphData;
      _lastGraphDataUpdate = DateTime.now();

      notifyListeners();
      return graphData;
    } catch (e) {
      _setError('Failed to get this month\'s mood graph data: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Convenience method - Get last 30 days mood graph data
  Future<List<Map<String, dynamic>>?> getLast30DaysMoodGraphData({
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);
      final graphData = await _service.getLast30DaysMoodData();

      // Cache as monthly data
      _cachedMonthlyGraphData = graphData;
      _lastGraphDataUpdate = DateTime.now();

      notifyListeners();
      return graphData;
    } catch (e) {
      _setError('Failed to get last 30 days mood graph data: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a mood check-in
  Future<bool> deleteMoodCheckin(String moodCheckinId) async {
    try {
      _setLoading(true);
      _clearError();

      await _service.deleteMoodCheckin(moodCheckinId);

      // If deleting current session, clear it
      if (_currentMoodCheckinId == moodCheckinId) {
        _clearSession();
      }

      // Invalidate cache
      _invalidateCache();
      _invalidateGraphCache();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete mood check-in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get current completion percentage
  double get completionPercentage {
    return _currentMoodCheckin?.completionPercentage ?? 0.0;
  }

  // Check if current session is active
  bool get hasActiveSession => _currentMoodCheckinId != null;

  // Clear current session
  void _clearSession() {
    _currentMoodCheckinId = null;
    _currentMoodCheckin = null;
  }

  // Clear error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Helper method to get date string
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Check if cached data is recent (within 5 minutes)
  bool _isRecentCache() {
    if (_lastStatsUpdate == null) return false;
    return DateTime.now().difference(_lastStatsUpdate!).inMinutes < 5;
  }

  // Check if cached graph data is recent (within 5 minutes)
  bool _isRecentGraphCache() {
    if (_lastGraphDataUpdate == null) return false;
    return DateTime.now().difference(_lastGraphDataUpdate!).inMinutes < 5;
  }

  // Invalidate cached data
  void _invalidateCache() {
    _cachedStats = null;
    _cachedHistory = null;
    _lastStatsUpdate = null;
  }

  // Invalidate graph cached data
  void _invalidateGraphCache() {
    _cachedWeeklyGraphData = null;
    _cachedMonthlyGraphData = null;
    _cachedGraphStats = null;
    _lastGraphDataUpdate = null;
  }

  // Reset the manager (useful for testing or logout)
  void reset() {
    _clearSession();
    _invalidateCache();
    _invalidateGraphCache();
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _clearSession();
    _invalidateCache();
    _invalidateGraphCache();
    super.dispose();
  }
}