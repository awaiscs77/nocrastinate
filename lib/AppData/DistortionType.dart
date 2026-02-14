enum CognitiveDistortionType {
  mindReading,
  magnificationOfNegative,
  selfBlaming,
  shouldStatements,
  fortuneTelling,
  filteringOutPositive,
  allOrNothingThinking,
  labelling,
  catastrophizing,
  minimizationOfPositive,
  overgeneralizing,
  otherBlaming,
  jumpingToConclusions,
  emotionalReasoning,
}

class CognitiveDistortion {
  final CognitiveDistortionType type;
  final String name;
  final String example;
  final String description;

  const CognitiveDistortion({
    required this.type,
    required this.name,
    required this.example,
    required this.description,
  });

  // Static instances for each distortion type
  static const CognitiveDistortion mindReading = CognitiveDistortion(
    type: CognitiveDistortionType.mindReading,
    name: 'Mind Reading',
    example: "They're quiet because they don't like me.",
    description: 'Assuming you know what others are thinking without evidence, often presuming negative intentions',
  );

  static const CognitiveDistortion magnificationOfNegative = CognitiveDistortion(
    type: CognitiveDistortionType.magnificationOfNegative,
    name: 'Magnification of the Negative',
    example: 'This one mistake ruins all my hard work.',
    description: 'Exaggerating the importance or impact of a negative event or flaw, blowing it out of proportion',
  );

  static const CognitiveDistortion selfBlaming = CognitiveDistortion(
    type: CognitiveDistortionType.selfBlaming,
    name: 'Self-blaming',
    example: "The team lost because I didn't step up.",
    description: 'Taking excessive personal responsibility for outcomes, even when other factors are involved',
  );

  static const CognitiveDistortion shouldStatements = CognitiveDistortion(
    type: CognitiveDistortionType.shouldStatements,
    name: 'Should Statements',
    example: 'I should always do this',
    description: 'Holding rigid, unrealistic expectations about how things *should* be, often leading to guilt or frustration',
  );

  static const CognitiveDistortion fortuneTelling = CognitiveDistortion(
    type: CognitiveDistortionType.fortuneTelling,
    name: 'Fortune-telling',
    example: "I'll never get through this meeting.",
    description: 'Predicting negative outcomes with certainty, despite lacking evidence',
  );

  static const CognitiveDistortion filteringOutPositive = CognitiveDistortion(
    type: CognitiveDistortionType.filteringOutPositive,
    name: 'Filtering Out Positive',
    example: "I had some wins, but they don't matter.",
    description: 'Ignoring or dismissing positive aspects of a situation and focusing only on the negatives',
  );

  static const CognitiveDistortion allOrNothingThinking = CognitiveDistortion(
    type: CognitiveDistortionType.allOrNothingThinking,
    name: 'All-or-Nothing Thinking',
    example: "I'm either the best or a total nobody.",
    description: 'Viewing situations in extreme, black-and-white terms with no middle ground',
  );

  static const CognitiveDistortion labelling = CognitiveDistortion(
    type: CognitiveDistortionType.labelling,
    name: 'Labelling',
    example: 'I am an idiot',
    description: 'Assigning a fixed, negative label to yourself or others based on a single action or event',
  );

  static const CognitiveDistortion catastrophizing = CognitiveDistortion(
    type: CognitiveDistortionType.catastrophizing,
    name: 'Catastrophizing',
    example: 'What if this turns into a complete disaster?',
    description: 'Imagining the worst possible outcome and treating it as likely or inevitable',
  );

  static const CognitiveDistortion minimizationOfPositive = CognitiveDistortion(
    type: CognitiveDistortionType.minimizationOfPositive,
    name: 'Minimization of the Positive',
    example: 'That compliment was just them being nice.',
    description: 'Downplaying or discounting positive achievements or feedback as insignificant',
  );

  static const CognitiveDistortion overgeneralizing = CognitiveDistortion(
    type: CognitiveDistortionType.overgeneralizing,
    name: 'Overgeneralizing',
    example: "I didn't get the job, so I'll never succeed at anything.",
    description: 'Drawing broad, negative conclusions based on a single event, applying it to all situations',
  );

  static const CognitiveDistortion otherBlaming = CognitiveDistortion(
    type: CognitiveDistortionType.otherBlaming,
    name: 'Other-blaming',
    example: "We're late because they didn't plan ahead.",
    description: 'Attributing problems entirely to others, avoiding personal accountability',
  );

  static const CognitiveDistortion jumpingToConclusions = CognitiveDistortion(
    type: CognitiveDistortionType.jumpingToConclusions,
    name: 'Jumping to Conclusions',
    example: "He didn't reply, so he's mad at me.",
    description: 'Making assumptions about a situation or someone\'s feelings without evidence',
  );

  static const CognitiveDistortion emotionalReasoning = CognitiveDistortion(
    type: CognitiveDistortionType.emotionalReasoning,
    name: 'Emotional Reasoning',
    example: "I'm anxious, so something bad must be coming.",
    description: 'Believing that your emotions reflect objective reality. You assume your emotions reflect the way things are.',
  );

  // Static list of all distortions
  static const List<CognitiveDistortion> allDistortions = [
    mindReading,
    magnificationOfNegative,
    selfBlaming,
    shouldStatements,
    fortuneTelling,
    filteringOutPositive,
    allOrNothingThinking,
    labelling,
    catastrophizing,
    minimizationOfPositive,
    overgeneralizing,
    otherBlaming,
    jumpingToConclusions,
    emotionalReasoning,
  ];

  // Helper methods
  static CognitiveDistortion? getDistortionByType(CognitiveDistortionType type) {
    return allDistortions.firstWhere(
          (distortion) => distortion.type == type,
    );
  }

  static CognitiveDistortion? getDistortionByName(String name) {
    for (final distortion in allDistortions) {
      if (distortion.name.toLowerCase() == name.toLowerCase()) {
        return distortion;
      }
    }
    return null;
  }

  static List<CognitiveDistortion> searchDistortions(String query) {
    final lowerQuery = query.toLowerCase();
    return allDistortions.where((distortion) =>
    distortion.name.toLowerCase().contains(lowerQuery) ||
        distortion.description.toLowerCase().contains(lowerQuery) ||
        distortion.example.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  static List<String> getAllDistortionNames() {
    return allDistortions.map((d) => d.name).toList();
  }

  // Categorize distortions by common themes
  static List<CognitiveDistortion> get selfFocusedDistortions => [
    selfBlaming,
    labelling,
    shouldStatements,
    emotionalReasoning,
  ];

  static List<CognitiveDistortion> get futurePredictingDistortions => [
    fortuneTelling,
    catastrophizing,
  ];

  static List<CognitiveDistortion> get positiveFilteringDistortions => [
    filteringOutPositive,
    minimizationOfPositive,
  ];

  static List<CognitiveDistortion> get assumptionBasedDistortions => [
    mindReading,
    jumpingToConclusions,
  ];

  static List<CognitiveDistortion> get extremeThinkingDistortions => [
    allOrNothingThinking,
    magnificationOfNegative,
    overgeneralizing,
  ];

  // Instance methods
  bool matchesKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return name.toLowerCase().contains(lowerKeyword) ||
        description.toLowerCase().contains(lowerKeyword) ||
        example.toLowerCase().contains(lowerKeyword);
  }

  @override
  String toString() {
    return 'CognitiveDistortion(name: $name, type: $type)';
  }

  String toDetailedString() {
    return '''
$name
Example: "$example"
Description: $description
''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CognitiveDistortion &&
        other.type == type &&
        other.name == name;
  }

  @override
  int get hashCode {
    return type.hashCode ^ name.hashCode;
  }
}