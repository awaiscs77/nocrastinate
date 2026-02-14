import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'LocalNotificationService.dart';

class CreateGoalServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalNotificationService _notificationService = LocalNotificationService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new goal with notifications
  Future<bool> createGoal({
    required String title,
    required List<String> tasks, // Changed from String description
    required DateTime targetDate,
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Create description from tasks for notifications
      String description = tasks.map((task) => '• $task').join('\n');

      // Create the goal document
      DocumentReference goalRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .add({
        'title': title,
        'description': description, // Keep for backwards compatibility
        'tasks': tasks, // Store tasks as array
        'targetDate': Timestamp.fromDate(targetDate),
        'notifications': notifications,
        'createdAt': Timestamp.now(),
        'lastProgress': Timestamp.now(),
        'isCompleted': false,
      });

      // Schedule notifications if any are enabled
      await _scheduleGoalNotifications(
        goalId: goalRef.id,
        title: title,
        description: description,
        targetDate: targetDate,
        notifications: notifications,
      );

      return true;
    } catch (e) {
      print('Error creating goal: $e');
      return false;
    }
  }
  // Get all completed goals for current user
  // Get all completed goals for current user
  Stream<List<Map<String, dynamic>>> getCompletedGoals() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('goals')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> goals = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort in memory by completedAt date (descending)
      goals.sort((a, b) {
        Timestamp? aTime = a['completedAt'] as Timestamp?;
        Timestamp? bTime = b['completedAt'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      return goals;
    });
  }

// Get goal statistics (total and completed count)
  Future<Map<String, int>> getGoalStatistics() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get total goals count
      QuerySnapshot totalSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .get();

      // Get completed goals count
      QuerySnapshot completedSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .where('isCompleted', isEqualTo: true)
          .get();

      return {
        'total': totalSnapshot.docs.length,
        'completed': completedSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting goal statistics: $e');
      return {'total': 0, 'completed': 0};
    }
  }

  // Save goal progress session data
  Future<bool> saveGoalProgressSession({
    required String goalId,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare progress data
      Map<String, dynamic> progressData = {
        'goalId': goalId,
        'timestamp': Timestamp.now(),
        'sessionType': sessionData['hadProgress'] == true ? 'progress' : 'no_progress',
      };

      // Add data based on session type
      if (sessionData['hadProgress'] == true) {
        // Progress session (Yes path)
        progressData.addAll({
          'effortLevel': sessionData['effortLevel'],
          'improvementPlan': sessionData['improvementPlan'],
        });
      } else {
        // No progress session (No path)
        progressData.addAll({
          'noProgressReason': sessionData['noProgressReason'],
          'selectedMood': sessionData['selectedMood'],
          'improvementPlan': sessionData['improvementPlan'],
        });
      }

      // Add reminders if present
      if (sessionData.containsKey('reminders')) {
        progressData['reminders'] = sessionData['reminders'];
      }

      // Save to progress_sessions subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .collection('progress_sessions')
          .add(progressData);

      // Update goal's last progress date if it was a progress session
      if (sessionData['hadProgress'] == true) {
        await updateLastProgress(goalId);
      }

      return true;
    } catch (e) {
      print('Error saving progress session: $e');
      return false;
    }
  }

  // Get all progress sessions for a specific goal
  Stream<List<Map<String, dynamic>>> getGoalProgressSessions(String goalId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('goals')
        .doc(goalId)
        .collection('progress_sessions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get all progress sessions for all user's goals
  Future<List<Map<String, dynamic>>> getAllProgressSessions() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      List<Map<String, dynamic>> allSessions = [];

      // Get all user's goals
      QuerySnapshot goalsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .get();

      // For each goal, get all progress sessions
      for (QueryDocumentSnapshot goalDoc in goalsSnapshot.docs) {
        Map<String, dynamic> goalData = goalDoc.data() as Map<String, dynamic>;
        goalData['id'] = goalDoc.id;

        QuerySnapshot sessionsSnapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('goals')
            .doc(goalDoc.id)
            .collection('progress_sessions')
            .orderBy('timestamp', descending: true)
            .get();

        for (QueryDocumentSnapshot sessionDoc in sessionsSnapshot.docs) {
          Map<String, dynamic> sessionData = sessionDoc.data() as Map<String, dynamic>;
          sessionData['id'] = sessionDoc.id;
          sessionData['goalTitle'] = goalData['title'];
          sessionData['goalDescription'] = goalData['description'];
          allSessions.add(sessionData);
        }
      }

      // Sort all sessions by timestamp
      allSessions.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      return allSessions;
    } catch (e) {
      print('Error getting all progress sessions: $e');
      return [];
    }
  }

  // Get all active alarms/reminders for user
  Future<List<Map<String, dynamic>>> getAllActiveAlarms() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      List<Map<String, dynamic>> allAlarms = [];

      // Get all user's goals
      QuerySnapshot goalsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .where('isCompleted', isEqualTo: false) // Only active goals
          .get();

      for (QueryDocumentSnapshot goalDoc in goalsSnapshot.docs) {
        Map<String, dynamic> goalData = goalDoc.data() as Map<String, dynamic>;
        String goalId = goalDoc.id;
        String goalTitle = goalData['title'] ?? 'Untitled Goal';

        List<dynamic> notifications = goalData['notifications'] ?? [];

        for (int i = 0; i < notifications.length; i++) {
          Map<String, dynamic> notification = notifications[i];

          if (notification['isEnabled'] == true) {
            allAlarms.add({
              'goalId': goalId,
              'goalTitle': goalTitle,
              'notificationIndex': i,
              'time': notification['time'],
              'day': notification['day'],
              'isEnabled': notification['isEnabled'],
              'notificationId': '${goalId}_notification_$i',
              'targetDate': goalData['targetDate'],
              'createdAt': notification['createdAt'] ?? goalData['createdAt'],
            });
          }
        }
      }

      // Sort by day of week and time
      allAlarms.sort((a, b) {
        // First sort by day
        int dayComparison = _getDayIndex(a['day']).compareTo(_getDayIndex(b['day']));
        if (dayComparison != 0) return dayComparison;

        // Then sort by time
        return a['time'].compareTo(b['time']);
      });

      return allAlarms;
    } catch (e) {
      print('Error getting all active alarms: $e');
      return [];
    }
  }

  // Helper method to get day index for sorting
  int _getDayIndex(String day) {
    const days = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return days[day] ?? 0;
  }

  // Delete a specific progress session
  Future<bool> deleteProgressSession(String goalId, String sessionId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .collection('progress_sessions')
          .doc(sessionId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting progress session: $e');
      return false;
    }
  }

  // Update an existing goal with notifications
  Future<bool> updateGoal({
    required String goalId,
    required String title,
    required List<String> tasks,
    required DateTime targetDate,
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Updating goal: $goalId');

      // Step 1: Cancel ALL existing notifications for this goal
      print('🗑️ Canceling existing notifications...');
      await _notificationService.cancelGoalNotifications(goalId);

      // Small delay to ensure cancellation is complete
      await Future.delayed(Duration(milliseconds: 300));

      String description = tasks.map((task) => '• $task').join('\n');

      // Step 2: Update the goal document
      print('💾 Updating goal document...');
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .update({
        'title': title,
        'description': description,
        'tasks': tasks,
        'targetDate': Timestamp.fromDate(targetDate),
        'notifications': notifications,
        'updatedAt': Timestamp.now(),
      });

      print('✅ Goal document updated');

      // Step 3: Schedule new notifications
      print('📅 Scheduling new notifications...');
      await _scheduleGoalNotifications(
        goalId: goalId,
        title: title,
        description: description,
        targetDate: targetDate,
        notifications: notifications,
      );

      print('✅ Goal update complete');
      return true;
    } catch (e) {
      print('❌ Error updating goal: $e');
      return false;
    }
  }

  // Delete a goal and its notifications
  Future<bool> deleteGoal(String goalId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Cancel all notifications for this goal
      await _notificationService.cancelGoalNotifications(goalId);

      // Delete all progress sessions first
      QuerySnapshot progressSessions = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .collection('progress_sessions')
          .get();

      for (QueryDocumentSnapshot doc in progressSessions.docs) {
        await doc.reference.delete();
      }

      // Delete the goal document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting goal: $e');
      return false;
    }
  }

  // Schedule notifications for a goal
  Future<void> _scheduleGoalNotifications({
    required String goalId,
    required String title,
    required String description,
    required DateTime targetDate,
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      print('📅 Scheduling ${notifications.length} notification sets for goal: $goalId');

      int totalScheduled = 0;
      List<String> errors = [];

      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];

        if (notification['isEnabled'] == true) {
          // Create unique notification ID: goalId_notification_index
          final notificationId = '${goalId}_notification_$i';

          print('⏰ Scheduling notification $notificationId at ${notification['time']} on ${notification['day']}');

          try {
            // Schedule recurring notification
            bool success = await _notificationService.scheduleRecurringGoalReminder(
              goalId: goalId,
              goalTitle: title,
              description: description.isNotEmpty
                  ? description
                  : 'Time to work on your goal: $title',
              time: notification['time'] ?? '18:00',
              day: notification['day'] ?? 'Monday',
              targetDate: targetDate,
              notificationId: notificationId,
            );

            if (success) {
              totalScheduled++;
              print('✅ Notification $notificationId scheduled successfully');
            } else {
              errors.add('Failed to schedule notification $i');
              print('❌ Failed to schedule notification $notificationId');
            }
          } catch (e) {
            errors.add('Error scheduling notification $i: $e');
            print('❌ Exception scheduling notification $notificationId: $e');
          }

          // Small delay between scheduling different notification sets
          if (i < notifications.length - 1) {
            await Future.delayed(Duration(milliseconds: 200));
          }
        } else {
          print('⏭️ Skipping disabled notification $i');
        }
      }

      print('📊 Scheduling complete: $totalScheduled/${notifications.where((n) => n['isEnabled'] == true).length} notification sets scheduled');

      if (errors.isNotEmpty) {
        print('⚠️ Errors encountered: ${errors.join(', ')}');
      }
    } catch (e) {
      print('❌ Error scheduling goal notifications: $e');
      // Don't throw - we still want the goal to be created even if notifications fail
    }
  }


  // Toggle notification status
  Future<bool> toggleNotification({
    required String goalId,
    required int notificationIndex,
    required bool isEnabled,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Toggling notification $notificationIndex for goal $goalId to ${isEnabled ? "enabled" : "disabled"}');

      // Get current goal data
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .get();

      if (!doc.exists) {
        throw Exception('Goal not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> notifications = List.from(data['notifications'] ?? []);

      if (notificationIndex >= notifications.length) {
        throw Exception('Invalid notification index');
      }

      // Update notification status
      notifications[notificationIndex]['isEnabled'] = isEnabled;

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .update({'notifications': notifications});

      // Handle notification scheduling
      final notificationId = '${goalId}_notification_$notificationIndex';

      if (isEnabled) {
        // Schedule the notification
        print('📅 Scheduling notification $notificationId');
        await _notificationService.scheduleRecurringGoalReminder(
          goalId: goalId,
          goalTitle: data['title'] ?? '',
          description: data['description'] ?? '',
          time: notifications[notificationIndex]['time'] ?? '18:00',
          day: notifications[notificationIndex]['day'] ?? 'Monday',
          targetDate: (data['targetDate'] as Timestamp).toDate(),
          notificationId: notificationId,
        );
      } else {
        // Cancel the notification
        print('🗑️ Canceling notification $notificationId');
        await _notificationService.cancelNotification(notificationId);
      }

      print('✅ Notification toggle complete');
      return true;
    } catch (e) {
      print('❌ Error toggling notification: $e');
      return false;
    }
  }

  // Add a new notification to an existing goal
  Future<bool> addNotification({
    required String goalId,
    required String time,
    required String day,
    bool isEnabled = true,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get current goal data
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .get();

      if (!doc.exists) {
        throw Exception('Goal not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> notifications = List.from(data['notifications'] ?? []);

      // Add new notification
      final newNotification = createNotificationData(
        time: time,
        day: day,
        isEnabled: isEnabled,
      );

      notifications.add(newNotification);

      // Update Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .update({'notifications': notifications});

      // Schedule notification if enabled
      if (isEnabled) {
        final notificationId = '${goalId}_notification_${notifications.length - 1}';
        await _notificationService.scheduleRecurringGoalReminder(
          goalId: goalId,
          goalTitle: data['title'] ?? '',
          description: data['description'] ?? '',
          time: time,
          day: day,
          targetDate: (data['targetDate'] as Timestamp).toDate(),
          notificationId: notificationId,
        );
      }

      return true;
    } catch (e) {
      print('Error adding notification: $e');
      return false;
    }
  }

  // Remove a notification from a goal
  Future<bool> removeNotification({
    required String goalId,
    required int notificationIndex,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Cancel the notification first
      final notificationId = '${goalId}_notification_$notificationIndex';
      await _notificationService.cancelNotification(notificationId);

      // Get current goal data
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .get();

      if (!doc.exists) {
        throw Exception('Goal not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> notifications = List.from(data['notifications'] ?? []);

      if (notificationIndex < notifications.length) {
        notifications.removeAt(notificationIndex);

        // Update Firestore
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('goals')
            .doc(goalId)
            .update({'notifications': notifications});
      }

      return true;
    } catch (e) {
      print('Error removing notification: $e');
      return false;
    }
  }

  // Get all goals for current user
  Stream<List<Map<String, dynamic>>> getUserGoals() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    });
  }

  // Update last progress date
  Future<bool> updateLastProgress(String goalId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .update({
        'lastProgress': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating last progress: $e');
      return false;
    }
  }

  // Mark goal as completed
  Future<bool> completeGoal(String goalId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Cancel all notifications for completed goal
      await _notificationService.cancelGoalNotifications(goalId);

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error completing goal: $e');
      return false;
    }
  }

  // Get a specific goal by ID
  Future<Map<String, dynamic>?> getGoalById(String goalId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .doc(goalId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting goal: $e');
      return null;
    }
  }

  // Helper method to format date for display
  static String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${_getMonthName(date.month)} ${date.day}';
  }

  static String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // Helper method to format notification data
  static Map<String, dynamic> createNotificationData({
    required String time,
    required String day,
    required bool isEnabled,
  }) {
    return {
      'time': time,
      'day': day,
      'isEnabled': isEnabled,
      'createdAt': Timestamp.now(),
    };
  }

  // Test notification method
  Future<void> testNotification(String goalTitle) async {
    await _notificationService.showImmediateNotification(
      title: 'Goal Reminder',
      body: 'Time to work on: $goalTitle',
    );
  }

  // Initialize notification service
  Future<void> initializeNotifications() async {
    await _notificationService.initialize();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  Future<Map<String, dynamic>> createGoalWithResult({
    required String title,
    required List<String> tasks,
    required DateTime targetDate,
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      String description = tasks.map((task) => '• $task').join('\n');

      // Create the goal document
      DocumentReference goalRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('goals')
          .add({
        'title': title,
        'description': description,
        'tasks': tasks,
        'targetDate': Timestamp.fromDate(targetDate),
        'notifications': notifications,
        'createdAt': Timestamp.now(),
        'lastProgress': Timestamp.now(),
        'isCompleted': false,
      });

      final goalId = goalRef.id;
      print('✅ Goal created with ID: $goalId');

      // Schedule notifications asynchronously
      _scheduleGoalNotifications(
        goalId: goalId,
        title: title,
        description: description,
        targetDate: targetDate,
        notifications: notifications,
      ).catchError((error) {
        print('⚠️ Background notification scheduling failed: $error');
      });

      return {
        'success': true,
        'goalId': goalId,
      };
    } catch (e) {
      print('❌ Error creating goal: $e');
      return {
        'success': false,
        'goalId': null,
        'error': e.toString(),
      };
    }
  }
}