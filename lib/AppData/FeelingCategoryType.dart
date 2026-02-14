import 'package:easy_localization/easy_localization.dart';

enum FeelingCategoryType {
  veryBad,
  bad,
  normal,
  good,
  amazing,
}

class FeelingCategory {
  final FeelingCategoryType type;
  final String name;
  final List<String> emotions;
  final int severity; // 1-5 scale

  const FeelingCategory({
    required this.type,
    required this.name,
    required this.emotions,
    required this.severity,
  });

  // Static instances for each category
  static const FeelingCategory veryBad = FeelingCategory(
    type: FeelingCategoryType.veryBad,
    name: 'Very Bad',
    severity: 1,
    emotions: [
      'Angry',
      'Anxious',
      'Despairing',
      'Disgusted',
      'Disrespected',
      'Embarrassed',
      'Fearful',
      'Frustrated',
      'Grieved',
      'Rejected',
      'Ashamed',
    ],
  );

  static const FeelingCategory bad = FeelingCategory(
    type: FeelingCategoryType.bad,
    name: 'Bad',
    severity: 2,
    emotions: [
      'Annoyed',
      'Guilty',
      'Insecure',
      'Jealous',
      'Disappointed',
      'Lonely',
      'Nervous',
      'Overwhelmed',
      'Pessimistic',
      'Sad',
      'Shocked',
      'Unfulfilled',
      'Unmotivated',
      'Vulnerable',
      'Nostalgic',
    ],
  );

  static const FeelingCategory normal = FeelingCategory(
    type: FeelingCategoryType.normal,
    name: 'Normal',
    severity: 3,
    emotions: [
      'Awkward',
      'Bored',
      'Busy',
      'Confused',
      'Judged',
      'Distracted',
      'Impatient',
      'Suspicious',
      'Tired',
      'Unsure',
      'Nostalgic',
    ],
  );

  static const FeelingCategory good = FeelingCategory(
    type: FeelingCategoryType.good,
    name: 'Good',
    severity: 4,
    emotions: [
      'Appreciated',
      'Calm',
      'Comfortable',
      'Curious',
      'Grateful',
      'Inspired',
      'Motivated',
      'Nostalgic',
      'Optimistic',
      'Relieved',
      'Satisfied',
      'Pleasantly surprised',
    ],
  );

  static const FeelingCategory amazing = FeelingCategory(
    type: FeelingCategoryType.amazing,
    name: 'Amazing',
    severity: 5,
    emotions: [
      'Brave',
      'Confident',
      'Creative',
      'Excited',
      'Liberated',
      'Happy',
      'Loved',
      'Proud',
      'Respected',
    ],
  );

  // Static list of all categories
  static const List<FeelingCategory> allCategories = [
    veryBad,
    bad,
    normal,
    good,
    amazing,
  ];

  // Helper methods
  static FeelingCategory? getCategoryByType(FeelingCategoryType type) {
    return allCategories.firstWhere(
          (category) => category.type == type,
    );
  }

  static FeelingCategory? getCategoryByEmotion(String emotion) {
    for (final category in allCategories) {
      if (category.emotions.any((e) => e.toLowerCase() == emotion.toLowerCase())) {
        return category;
      }
    }
    return null;
  }

  static List<String> getAllEmotions() {
    return allCategories
        .expand((category) => category.emotions)
        .toList();
  }

  // Instance methods
  bool containsEmotion(String emotion) {
    return emotions.any((e) => e.toLowerCase() == emotion.toLowerCase());
  }

  @override
  String toString() {
    return 'FeelingCategory(type: $type, name: $name, severity: $severity, emotions: ${emotions.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeelingCategory &&
        other.type == type &&
        other.name == name &&
        other.severity == severity;
  }

  @override
  int get hashCode {
    return type.hashCode ^ name.hashCode ^ severity.hashCode;
  }
}