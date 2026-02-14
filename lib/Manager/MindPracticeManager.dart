import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ApiServices/MindPracticeService.dart';
import 'StreaksManager.dart';

class MindPracticeManager extends ChangeNotifier {
  static final MindPracticeManager _instance = MindPracticeManager._internal();
  factory MindPracticeManager() => _instance;
  MindPracticeManager._internal();

  // Current practice session
  String? _currentPracticeId;
  String? _currentPracticeType;
  Map<String, dynamic> _currentPracticeData = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get currentPracticeId => _currentPracticeId;
  String? get currentPracticeType => _currentPracticeType;
  Map<String, dynamic> get currentPracticeData => Map<String, dynamic>.from(_currentPracticeData);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _currentPracticeId != null;

  // Practice types constants
  static const String costBenefitType = 'cost_benefit';
  static const String whatIfChallengeType = 'what_if_challenge';

  /// Start a new practice session
  Future<bool> startPractice({
    required String practiceType,
    Map<String, dynamic>? initialData,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if already completed today for this practice type
      final hasCompleted = await MindPracticeService.hasCompletedPracticeToday(practiceType);
      if (hasCompleted) {
        _setError('You have already completed this practice today');
        return false;
      }

      // Create initial practice session
      _currentPracticeId = await MindPracticeService.createPracticeSession(
        practiceType: practiceType,
        initialData: initialData ?? {},
      );

      if (_currentPracticeId != null) {
        _currentPracticeType = practiceType;
        _currentPracticeData = initialData ?? {};
        notifyListeners();
        return true;
      }

      _setError('Failed to create practice session');
      return false;
    } catch (e) {
      _setError('Failed to start practice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update practice data
  Future<bool> updatePracticeData({
    required Map<String, dynamic> data,
  }) async {
    if (_currentPracticeId == null) {
      _setError('No active practice session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final success = await MindPracticeService.updatePracticeSession(
        practiceId: _currentPracticeId!,
        data: data,
      );

      if (success) {
        _currentPracticeData.addAll(data);
        notifyListeners();
        return true;
      }

      _setError('Failed to update practice data');
      return false;
    } catch (e) {
      _setError('Failed to update practice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete the current practice
  Future<bool> completePractice() async {
    if (_currentPracticeId == null) {
      _setError('No active practice session');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final success = await MindPracticeService.completePracticeSession(
        practiceId: _currentPracticeId!,
      );

      if (success) {
        await StreaksManager().recordMindPracticeCompletion();
        _clearSession();
        notifyListeners();
        return true;
      }

      _setError('Failed to complete practice');
      return false;
    } catch (e) {
      _setError('Failed to complete practice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resume an existing practice session
  Future<bool> resumePractice(String practiceId, String practiceType, Map<String, dynamic> data) async {
    _currentPracticeId = practiceId;
    _currentPracticeType = practiceType;
    _currentPracticeData = data;
    _clearError();
    notifyListeners();
    return true;
  }

  /// Get completion percentage for current practice
  double get completionPercentage {
    if (_currentPracticeType == null) return 0.0;

    switch (_currentPracticeType) {
      case costBenefitType:
        return _getCostBenefitProgress();
      case whatIfChallengeType:
        return _getWhatIfChallengeProgress();
      default:
        return 0.0;
    }
  }

  /// Get cost benefit analysis progress
  double _getCostBenefitProgress() {
    double progress = 0.0;

    // Behavior to evaluate (33%)
    if (_currentPracticeData['behaviorToEvaluate']?.toString().trim().isNotEmpty == true) {
      progress += 0.33;
    }

    // Pros (33%)
    if (_currentPracticeData['pros']?.toString().trim().isNotEmpty == true) {
      progress += 0.33;
    }

    // Cons (34%)
    if (_currentPracticeData['cons']?.toString().trim().isNotEmpty == true) {
      progress += 0.34;
    }

    return progress;
  }

  /// Get what if challenge progress
  double _getWhatIfChallengeProgress() {
    double progress = 0.0;

    // Fear scenario (25%)
    if (_currentPracticeData['fearScenario']?.toString().trim().isNotEmpty == true) {
      progress += 0.25;
    }

    // Initial likelihood (25%)
    if (_currentPracticeData['initialLikelihood'] != null) {
      progress += 0.25;
    }

    // Best outcome (25%)
    if (_currentPracticeData['bestOutcome']?.toString().trim().isNotEmpty == true) {
      progress += 0.25;
    }

    // Final likelihood (25%)
    if (_currentPracticeData['finalLikelihood'] != null) {
      progress += 0.25;
    }

    return progress;
  }

  /// Get current step description for UI
  String get currentStepDescription {
    if (_currentPracticeType == null) return '';

    switch (_currentPracticeType) {
      case costBenefitType:
        return _getCostBenefitStepDescription();
      case whatIfChallengeType:
        return _getWhatIfChallengeStepDescription();
      default:
        return '';
    }
  }

  String _getCostBenefitStepDescription() {
    if (_currentPracticeData['behaviorToEvaluate']?.toString().trim().isEmpty != false) {
      return 'Describe the behavior to evaluate';
    } else if (_currentPracticeData['pros']?.toString().trim().isEmpty != false) {
      return 'List the pros/benefits';
    } else if (_currentPracticeData['cons']?.toString().trim().isEmpty != false) {
      return 'List the cons/drawbacks';
    } else {
      return 'Review and complete';
    }
  }

  String _getWhatIfChallengeStepDescription() {
    if (_currentPracticeData['fearScenario']?.toString().trim().isEmpty != false) {
      return 'Describe your fear scenario';
    } else if (_currentPracticeData['initialLikelihood'] == null) {
      return 'Rate the likelihood';
    } else if (_currentPracticeData['bestOutcome']?.toString().trim().isEmpty != false) {
      return 'Describe the best outcome';
    } else if (_currentPracticeData['finalLikelihood'] == null) {
      return 'Re-rate the likelihood';
    } else {
      return 'Complete the practice';
    }
  }

  /// Check if user has completed today's practice
  Future<bool> hasCompletedTodaysPractice(String practiceType) async {
    try {
      return await MindPracticeService.hasCompletedPracticeToday(practiceType);
    } catch (e) {
      _setError('Failed to check today\'s practice: $e');
      return false;
    }
  }

  /// Get today's incomplete practice if exists
  Future<Map<String, dynamic>?> getTodaysIncompletePractice(String practiceType) async {
    try {
      return await MindPracticeService.getTodaysIncompletePractice(practiceType);
    } catch (e) {
      _setError('Failed to get incomplete practice: $e');
      return null;
    }
  }

  /// Private helper methods
  void _clearSession() {
    _currentPracticeId = null;
    _currentPracticeType = null;
    _currentPracticeData.clear();
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
    _clearSession();
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  @override
  void dispose() {
    _clearSession();
    super.dispose();
  }
}