import 'package:cloud_firestore/cloud_firestore.dart';

class MoodCheckinModel {
  final String? id;
  final int moodIndex;
  final String moodLabel;
  final DateTime timestamp;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String status; // 'in_progress', 'completed'
  final String date;
  final List<String> selectedEmotionTags;
  final List<String> excitementCategories;
  final String? positiveExperience;
  final String? meaningfulExperience;
  final String? moreExperiences;
  final bool? wantsBreathingExercise;
  final int? streakDays;
  final String? unhelpfulThoughts;
  final List<String> thoughtDistortions;
  final String? challengingThoughts;

  MoodCheckinModel({
    this.id,
    required this.moodIndex,
    required this.moodLabel,
    required this.timestamp,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.status = 'in_progress',
    required this.date,
    this.selectedEmotionTags = const [],
    this.excitementCategories = const [],
    this.positiveExperience,
    this.meaningfulExperience,
    this.moreExperiences,
    this.wantsBreathingExercise,
    this.streakDays,
    this.unhelpfulThoughts,
    this.thoughtDistortions = const [],
    this.challengingThoughts,
  });

  // Create from Firestore document
  factory MoodCheckinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MoodCheckinModel(
      id: doc.id,
      moodIndex: data['mood_index'] ?? 0,
      moodLabel: data['mood_label'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'in_progress',
      date: data['date'] ?? '',
      selectedEmotionTags: List<String>.from(data['selected_emotion_tags'] ?? []),
      excitementCategories: List<String>.from(data['excitement_categories'] ?? []),
      positiveExperience: data['positive_experience'],
      meaningfulExperience: data['meaningful_experience'],
      moreExperiences: data['more_experiences'],
      wantsBreathingExercise: data['wants_breathing_exercise'],
      streakDays: data['streak_days'],
      unhelpfulThoughts: data['unhelpful_thoughts'],
      thoughtDistortions: List<String>.from(data['thought_distortions'] ?? []),
      challengingThoughts: data['challenging_thoughts'],
    );
  }

  // Create from Map
  factory MoodCheckinModel.fromMap(Map<String, dynamic> data) {
    return MoodCheckinModel(
      id: data['id'],
      moodIndex: data['mood_index'] ?? 0,
      moodLabel: data['mood_label'] ?? '',
      timestamp: data['timestamp'] is DateTime
          ? data['timestamp']
          : (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: data['created_at'] is DateTime
          ? data['created_at']
          : (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: data['updated_at'] is DateTime
          ? data['updated_at']
          : (data['updated_at'] as Timestamp?)?.toDate(),
      completedAt: data['completed_at'] is DateTime
          ? data['completed_at']
          : (data['completed_at'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'in_progress',
      date: data['date'] ?? '',
      selectedEmotionTags: List<String>.from(data['selected_emotion_tags'] ?? []),
      excitementCategories: List<String>.from(data['excitement_categories'] ?? []),
      positiveExperience: data['positive_experience'],
      meaningfulExperience: data['meaningful_experience'],
      moreExperiences: data['more_experiences'],
      wantsBreathingExercise: data['wants_breathing_exercise'],
      streakDays: data['streak_days'],
      unhelpfulThoughts: data['unhelpful_thoughts'],
      thoughtDistortions: List<String>.from(data['thought_distortions'] ?? []),
      challengingThoughts: data['challenging_thoughts'],
    );
  }


  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mood_index': moodIndex,
      'mood_label': moodLabel,
      'timestamp': timestamp,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
      'status': status,
      'date': date,
      'selected_emotion_tags': selectedEmotionTags,
      'excitement_categories': excitementCategories,
      'positive_experience': positiveExperience,
      'meaningful_experience': meaningfulExperience,
      'more_experiences': moreExperiences,
      'wants_breathing_exercise': wantsBreathingExercise,
      'streak_days': streakDays,
      'unhelpful_thoughts': unhelpfulThoughts,
      'thought_distortions': thoughtDistortions,
      'challenging_thoughts': challengingThoughts,
    };
  }

  // Copy with method for updates
  MoodCheckinModel copyWith({
    String? id,
    int? moodIndex,
    String? moodLabel,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? status,
    String? date,
    List<String>? selectedEmotionTags,
    List<String>? excitementCategories,
    String? positiveExperience,
    String? meaningfulExperience,
    String? moreExperiences,
    bool? wantsBreathingExercise,
    int? streakDays,
    // Add new parameters
    String? unhelpfulThoughts,
    List<String>? thoughtDistortions,
    String? challengingThoughts,
  }) {
    return MoodCheckinModel(
      id: id ?? this.id,
      moodIndex: moodIndex ?? this.moodIndex,
      moodLabel: moodLabel ?? this.moodLabel,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      date: date ?? this.date,
      selectedEmotionTags: selectedEmotionTags ?? this.selectedEmotionTags,
      excitementCategories: excitementCategories ?? this.excitementCategories,
      positiveExperience: positiveExperience ?? this.positiveExperience,
      meaningfulExperience: meaningfulExperience ?? this.meaningfulExperience,
      moreExperiences: moreExperiences ?? this.moreExperiences,
      wantsBreathingExercise: wantsBreathingExercise ?? this.wantsBreathingExercise,
      streakDays: streakDays ?? this.streakDays,
      unhelpfulThoughts: unhelpfulThoughts ?? this.unhelpfulThoughts,
      thoughtDistortions: thoughtDistortions ?? this.thoughtDistortions,
      challengingThoughts: challengingThoughts ?? this.challengingThoughts,
    );
  }

  // Check if mood check-in is completed
  bool get isCompleted => status == 'completed';

  // Check if mood check-in is in progress
  bool get isInProgress => status == 'in_progress';

  // Get mood description based on index
  String get moodDescription {
    switch (moodIndex) {
      case 0:
        return 'Terrible';
      case 1:
        return 'Sad';
      case 2:
        return 'Neutral';
      case 3:
        return 'Happy';
      case 4:
        return 'Amazing';
      default:
        return 'Unknown';
    }
  }

  // Get mood color based on index
  String get moodColor {
    switch (moodIndex) {
      case 0:
        return '#FF4444'; // Red
      case 1:
        return '#FF8800'; // Orange
      case 2:
        return '#FFDD00'; // Yellow
      case 3:
        return '#88CC00'; // Light Green
      case 4:
        return '#00AA00'; // Green
      default:
        return '#CCCCCC'; // Gray
    }
  }

  // Get completion percentage
  double get completionPercentage {
    if (isCompleted) return 1.0;

    double progress = 0.0;

    // Initial mood selection (15%)
    progress += 0.15;

    // Emotion tags selection (15%)
    if (selectedEmotionTags.isNotEmpty) progress += 0.15;

    // Excitement categories (15%)
    if (excitementCategories.isNotEmpty) progress += 0.15;

    if (moodIndex >= 2) {
      // Happy path (mood index 2, 3, 4)
      // Positive experience (20%)
      if (positiveExperience != null && positiveExperience!.isNotEmpty) progress += 0.20;

      // Meaningful experience (15%)
      if (meaningfulExperience != null && meaningfulExperience!.isNotEmpty) progress += 0.15;

      // More experiences (20%)
      if (moreExperiences != null && moreExperiences!.isNotEmpty) progress += 0.20;
    } else {
      // Bad mood path (mood index 0, 1)
      // Unhelpful thoughts (20%)
      if (unhelpfulThoughts != null && unhelpfulThoughts!.isNotEmpty) progress += 0.20;

      // Thought distortions (15%)
      if (thoughtDistortions.isNotEmpty) progress += 0.15;

      // Challenging thoughts (20%)
      if (challengingThoughts != null && challengingThoughts!.isNotEmpty) progress += 0.20;
    }

    return progress;
  }

  @override
  String toString() {
    return 'MoodCheckinModel(id: $id, moodLabel: $moodLabel, status: $status, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MoodCheckinModel &&
        other.id == id &&
        other.moodIndex == moodIndex &&
        other.moodLabel == moodLabel &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    moodIndex.hashCode ^
    moodLabel.hashCode ^
    date.hashCode;
  }
}

// Statistics model for mood analytics
class MoodStats {
  final int totalCheckins;
  final int currentStreak;
  final int bestStreak;
  final double averageMood;
  final Map<String, int> moodDistribution;
  final List<String> mostCommonEmotions;
  final List<String> mostExcitingCategories;

  MoodStats({
    required this.totalCheckins,
    required this.currentStreak,
    required this.bestStreak,
    required this.averageMood,
    required this.moodDistribution,
    required this.mostCommonEmotions,
    required this.mostExcitingCategories,
  });

  factory MoodStats.fromMap(Map<String, dynamic> data) {
    return MoodStats(
      totalCheckins: data['total_checkins'] ?? 0,
      currentStreak: data['current_streak'] ?? 0,
      bestStreak: data['best_streak'] ?? 0,
      averageMood: (data['average_mood'] ?? 0.0).toDouble(),
      moodDistribution: Map<String, int>.from(data['mood_distribution'] ?? {}),
      mostCommonEmotions: List<String>.from(data['most_common_emotions'] ?? []),
      mostExcitingCategories: List<String>.from(data['most_exciting_categories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_checkins': totalCheckins,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'average_mood': averageMood,
      'mood_distribution': moodDistribution,
      'most_common_emotions': mostCommonEmotions,
      'most_exciting_categories': mostExcitingCategories,
    };
  }
}