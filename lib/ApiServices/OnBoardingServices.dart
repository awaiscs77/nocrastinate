import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String _onboardingCollection = 'user_onboarding';
  static const String _usersCollection = 'users';

  /// Get current user ID with better error handling
  static String? get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      print('Warning: No authenticated user found');
      return null;
    }
    return user.uid;
  }

  /// Initialize user onboarding record when they first sign up
  static Future<bool> initializeUserOnboarding() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if onboarding record already exists
      final existingDoc = await _firestore
          .collection(_onboardingCollection)
          .doc(userId)
          .get();

      if (!existingDoc.exists) {
        // Create initial onboarding record
        await _firestore
            .collection(_onboardingCollection)
            .doc(userId)
            .set({
          'isCompleted': false,
          'isSkipped': false, // Add skip flag
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': userId,
          'userEmail': _auth.currentUser?.email,
        });

        print('Onboarding record initialized for user: $userId');
      }

      // Also ensure user profile exists
      await _initializeUserProfile();

      return true;
    } catch (e) {
      print('Error initializing user onboarding: $e');
      return false;
    }
  }

  /// Initialize user profile if it doesn't exist
  static Future<void> _initializeUserProfile() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set({
        'uid': userId,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'onboardingCompleted': false,
        'onboardingSkipped': false, // Add skip flag to user profile
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'providers': user.providerData.map((p) => p.providerId).toList(),
      }, SetOptions(merge: true));

      print('User profile initialized/updated for: ${user.email}');
    } catch (e) {
      print('Error initializing user profile: $e');
    }
  }

  /// Mark onboarding as skipped
  static Future<bool> skipOnboarding() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();

      // Update onboarding skip status
      final onboardingRef = _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId);

      batch.set(onboardingRef, {
        'isSkipped': true,
        'isCompleted': false, // Keep as false since they didn't complete it
        'skippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
        'userEmail': _auth.currentUser?.email,
      }, SetOptions(merge: true));

      // Update user profile
      final userRef = _firestore
          .collection(_usersCollection)
          .doc(_currentUserId);

      batch.set(userRef, {
        'onboardingSkipped': true,
        'onboardingSkippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      print('Onboarding skipped successfully for user: $_currentUserId');

      return true;
    } catch (e) {
      print('Error skipping onboarding: $e');
      return false;
    }
  }

  /// Save improvement goals from Onboarding2Screen
  static Future<bool> saveImprovementGoals(Set<String> selectedTags) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'improvementGoals': selectedTags.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving improvement goals: $e');
      return false;
    }
  }

  /// Save age group from Onboarding3Screen
  static Future<bool> saveAgeGroup(String selectedAge) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'ageGroup': selectedAge,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving age group: $e');
      return false;
    }
  }

  /// Save referral source from Onboarding4Screen
  static Future<bool> saveReferralSource(String selectedSource) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'referralSource': selectedSource,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving referral source: $e');
      return false;
    }
  }

  /// Save mental health assessment from Onboarding5Screen
  static Future<bool> saveMentalHealthAssessment(List<int?> answers) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate scores based on answers
      final scores = _calculateMentalHealthScores(answers);

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'mentalHealthAssessment': {
          'answers': answers,
          'scores': scores,
          'completedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving mental health assessment: $e');
      return false;
    }
  }

  /// Save time preferences from Onboarding9Screen & Onboarding10Screen
  static Future<bool> saveTimePreferences({
    required String preferredTimeSlot,
    required String timeValue,
    String? screenType,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> timePreferenceData = {
        'preferredTimeSlot': preferredTimeSlot,
        'timeValue': timeValue,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (screenType != null) {
        timePreferenceData['screenType'] = screenType;
      }

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'timePreferences': timePreferenceData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving time preferences: $e');
      return false;
    }
  }

  /// Save subscription preferences from Onboarding11Screen
  static Future<bool> saveSubscriptionPreferences({
    required bool isYearlySelected,
    required double price,
    required String currency,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      String planType = isYearlySelected ? 'yearly' : 'monthly';
      double discount = isYearlySelected ? 58.0 : 0.0;

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'subscriptionPreferences': {
          'planType': planType,
          'price': price,
          'currency': currency,
          'discount': discount,
          'isYearlySelected': isYearlySelected,
          'selectedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving subscription preferences: $e');
      return false;
    }
  }

  /// Save processing screen completion status
  static Future<bool> saveProcessingCompletion({
    required List<String> completedTasks,
    required double progressPercentage,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .set({
        'processingResults': {
          'completedTasks': completedTasks,
          'progressPercentage': progressPercentage,
          'completedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving processing completion: $e');
      return false;
    }
  }

  /// Mark onboarding as completed with comprehensive user update
  static Future<bool> completeOnboarding() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();

      // Update onboarding completion status
      final onboardingRef = _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId);

      batch.update(onboardingRef, {
        'isCompleted': true,
        'isSkipped': false, // Reset skip flag when completing
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user profile
      final userRef = _firestore
          .collection(_usersCollection)
          .doc(_currentUserId);

      batch.update(userRef, {
        'onboardingCompleted': true,
        'onboardingSkipped': false, // Reset skip flag when completing
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('Onboarding completed successfully for user: $_currentUserId');

      return true;
    } catch (e) {
      print('Error completing onboarding: $e');
      return false;
    }
  }

  /// Get onboarding data for current user
  static Future<Map<String, dynamic>?> getOnboardingData() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting onboarding data: $e');
      return null;
    }
  }

  /// Check if onboarding is completed for current user
  static Future<bool> isOnboardingCompleted() async {
    try {
      if (_currentUserId == null) {
        return false; // Not authenticated = not completed
      }

      final data = await getOnboardingData();
      return data?['isCompleted'] ?? false;
    } catch (e) {
      print('Error checking onboarding completion: $e');
      return false;
    }
  }

  /// Check if onboarding was skipped for current user
  static Future<bool> isOnboardingSkipped() async {
    try {
      if (_currentUserId == null) {
        return false;
      }

      final data = await getOnboardingData();
      return data?['isSkipped'] ?? false;
    } catch (e) {
      print('Error checking onboarding skip status: $e');
      return false;
    }
  }

  /// Check if user should see onboarding (not completed AND not skipped)
  static Future<bool> shouldShowOnboarding() async {
    try {
      if (_currentUserId == null) {
        return true; // Show onboarding for unauthenticated users
      }

      final data = await getOnboardingData();
      final isCompleted = data?['isCompleted'] ?? false;
      final isSkipped = data?['isSkipped'] ?? false;

      // Don't show onboarding if either completed or skipped
      return !(isCompleted || isSkipped);
    } catch (e) {
      print('Error checking if should show onboarding: $e');
      return true; // Default to showing onboarding if error
    }
  }

  /// Get onboarding status with more details
  static Future<Map<String, dynamic>> getOnboardingStatus() async {
    try {
      if (_currentUserId == null) {
        return {
          'isAuthenticated': false,
          'isCompleted': false,
          'isSkipped': false,
          'shouldShowOnboarding': true,
          'needsOnboarding': true,
          'error': 'User not authenticated'
        };
      }

      final data = await getOnboardingData();
      final isCompleted = data?['isCompleted'] ?? false;
      final isSkipped = data?['isSkipped'] ?? false;
      final shouldShow = !(isCompleted || isSkipped);

      return {
        'isAuthenticated': true,
        'isCompleted': isCompleted,
        'isSkipped': isSkipped,
        'shouldShowOnboarding': shouldShow,
        'needsOnboarding': shouldShow,
        'hasData': data != null,
        'userId': _currentUserId,
        'userEmail': _auth.currentUser?.email,
      };
    } catch (e) {
      return {
        'isAuthenticated': _currentUserId != null,
        'isCompleted': false,
        'isSkipped': false,
        'shouldShowOnboarding': true,
        'needsOnboarding': true,
        'error': e.toString()
      };
    }
  }

  /// Save all onboarding data at once
  static Future<bool> saveCompleteOnboardingData({
    required Set<String> improvementGoals,
    required String ageGroup,
    required String referralSource,
    required List<int?> mentalHealthAnswers,
    String? preferredTimeSlot,
    String? timeValue,
    bool? isYearlySelected,
    double? subscriptionPrice,
    String? currency,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final scores = _calculateMentalHealthScores(mentalHealthAnswers);
      final user = _auth.currentUser;

      Map<String, dynamic> onboardingData = {
        'improvementGoals': improvementGoals.toList(),
        'ageGroup': ageGroup,
        'referralSource': referralSource,
        'mentalHealthAssessment': {
          'answers': mentalHealthAnswers,
          'scores': scores,
          'completedAt': FieldValue.serverTimestamp(),
        },
        'isCompleted': true,
        'isSkipped': false, // Reset skip flag when completing
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
        'userEmail': user?.email,
      };

      // Add optional time preferences
      if (preferredTimeSlot != null && timeValue != null) {
        onboardingData['timePreferences'] = {
          'preferredTimeSlot': preferredTimeSlot,
          'timeValue': timeValue,
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }

      // Add optional subscription preferences
      if (isYearlySelected != null && subscriptionPrice != null) {
        String planType = isYearlySelected ? 'yearly' : 'monthly';
        double discount = isYearlySelected ? 58.0 : 0.0;

        onboardingData['subscriptionPreferences'] = {
          'planType': planType,
          'price': subscriptionPrice,
          'currency': currency ?? 'GBP',
          'discount': discount,
          'isYearlySelected': isYearlySelected,
          'selectedAt': FieldValue.serverTimestamp(),
        };
      }

      final batch = _firestore.batch();

      // Save onboarding data
      final onboardingRef = _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId);
      batch.set(onboardingRef, onboardingData);

      // Update user profile
      final userRef = _firestore
          .collection(_usersCollection)
          .doc(_currentUserId);
      batch.update(userRef, {
        'onboardingCompleted': true,
        'onboardingSkipped': false, // Reset skip flag when completing
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('Complete onboarding data saved for user: $_currentUserId');

      return true;
    } catch (e) {
      print('Error saving complete onboarding data: $e');
      return false;
    }
  }

  /// Calculate mental health scores based on answers
  static Map<String, dynamic> _calculateMentalHealthScores(List<int?> answers) {
    List<int> validAnswers = answers.where((answer) => answer != null).cast<int>().toList();

    if (validAnswers.isEmpty) {
      return {
        'anxietyLevel': 0,
        'depressionLevel': 0,
        'stressLevel': 0,
        'overallScore': 0,
      };
    }

    double totalScore = validAnswers.reduce((a, b) => a + b).toDouble();
    double maxPossibleScore = validAnswers.length * 3.0;
    double overallPercentage = (totalScore / maxPossibleScore) * 100;

    double anxietyScore = _calculateDomainScore(validAnswers, [0, 1, 3]);
    double depressionScore = _calculateDomainScore(validAnswers, [4, 5]);
    double stressScore = _calculateDomainScore(validAnswers, [2, 6]);

    return {
      'anxietyLevel': anxietyScore.round(),
      'depressionLevel': depressionScore.round(),
      'stressLevel': stressScore.round(),
      'overallScore': overallPercentage.round(),
      'totalQuestions': validAnswers.length,
      'rawAnswers': validAnswers,
    };
  }

  /// Calculate domain-specific scores
  static double _calculateDomainScore(List<int> answers, List<int> questionIndices) {
    List<int> domainAnswers = [];
    for (int index in questionIndices) {
      if (index < answers.length) {
        domainAnswers.add(answers[index]);
      }
    }

    if (domainAnswers.isEmpty) return 0;

    double domainTotal = domainAnswers.reduce((a, b) => a + b).toDouble();
    double domainMax = domainAnswers.length * 3.0;
    return (domainTotal / domainMax) * 100;
  }

  /// Delete onboarding data (cleanup method)
  static Future<bool> deleteOnboardingData() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();

      // Delete onboarding data
      final onboardingRef = _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId);
      batch.delete(onboardingRef);

      // Update user profile to reflect onboarding not completed and not skipped
      final userRef = _firestore
          .collection(_usersCollection)
          .doc(_currentUserId);
      batch.update(userRef, {
        'onboardingCompleted': false,
        'onboardingSkipped': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('Onboarding data deleted for user: $_currentUserId');

      return true;
    } catch (e) {
      print('Error deleting onboarding data: $e');
      return false;
    }
  }

  /// Get onboarding analytics (admin function)
  static Future<Map<String, dynamic>> getOnboardingAnalytics() async {
    try {
      QuerySnapshot completedSnapshot = await _firestore
          .collection(_onboardingCollection)
          .where('isCompleted', isEqualTo: true)
          .get();

      QuerySnapshot skippedSnapshot = await _firestore
          .collection(_onboardingCollection)
          .where('isSkipped', isEqualTo: true)
          .get();

      Map<String, int> ageGroupCounts = {};
      Map<String, int> referralSourceCounts = {};
      Map<String, int> improvementGoalsCounts = {};
      Map<String, int> timePreferenceCounts = {};
      Map<String, int> subscriptionTypeCounts = {};
      int totalCompleted = completedSnapshot.docs.length;
      int totalSkipped = skippedSnapshot.docs.length;

      for (var doc in completedSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String? ageGroup = data['ageGroup'];
        if (ageGroup != null) {
          ageGroupCounts[ageGroup] = (ageGroupCounts[ageGroup] ?? 0) + 1;
        }

        String? referralSource = data['referralSource'];
        if (referralSource != null) {
          referralSourceCounts[referralSource] = (referralSourceCounts[referralSource] ?? 0) + 1;
        }

        List<dynamic>? goals = data['improvementGoals'];
        if (goals != null) {
          for (String goal in goals) {
            improvementGoalsCounts[goal] = (improvementGoalsCounts[goal] ?? 0) + 1;
          }
        }

        Map<String, dynamic>? timePrefs = data['timePreferences'];
        if (timePrefs != null && timePrefs['preferredTimeSlot'] != null) {
          String timeSlot = timePrefs['preferredTimeSlot'];
          timePreferenceCounts[timeSlot] = (timePreferenceCounts[timeSlot] ?? 0) + 1;
        }

        Map<String, dynamic>? subPrefs = data['subscriptionPreferences'];
        if (subPrefs != null && subPrefs['planType'] != null) {
          String planType = subPrefs['planType'];
          subscriptionTypeCounts[planType] = (subscriptionTypeCounts[planType] ?? 0) + 1;
        }
      }

      return {
        'totalCompleted': totalCompleted,
        'totalSkipped': totalSkipped,
        'totalUsers': totalCompleted + totalSkipped,
        'completionRate': totalCompleted + totalSkipped > 0
            ? (totalCompleted / (totalCompleted + totalSkipped)) * 100
            : 0,
        'skipRate': totalCompleted + totalSkipped > 0
            ? (totalSkipped / (totalCompleted + totalSkipped)) * 100
            : 0,
        'ageGroupDistribution': ageGroupCounts,
        'referralSourceDistribution': referralSourceCounts,
        'improvementGoalsDistribution': improvementGoalsCounts,
        'timePreferenceDistribution': timePreferenceCounts,
        'subscriptionTypeDistribution': subscriptionTypeCounts,
      };
    } catch (e) {
      print('Error getting onboarding analytics: $e');
      return {};
    }
  }

  /// Get specific user preferences
  static Future<Map<String, dynamic>?> getUserTimePreferences() async {
    try {
      final data = await getOnboardingData();
      return data?['timePreferences'];
    } catch (e) {
      print('Error getting user time preferences: $e');
      return null;
    }
  }

  /// Get user subscription preferences
  static Future<Map<String, dynamic>?> getUserSubscriptionPreferences() async {
    try {
      final data = await getOnboardingData();
      return data?['subscriptionPreferences'];
    } catch (e) {
      print('Error getting user subscription preferences: $e');
      return null;
    }
  }

  /// Update time preferences (for settings updates)
  static Future<bool> updateTimePreferences({
    required String preferredTimeSlot,
    required String timeValue,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection(_onboardingCollection)
          .doc(_currentUserId)
          .update({
        'timePreferences.preferredTimeSlot': preferredTimeSlot,
        'timePreferences.timeValue': timeValue,
        'timePreferences.updatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating time preferences: $e');
      return false;
    }
  }
}