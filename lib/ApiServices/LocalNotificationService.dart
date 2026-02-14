import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Debouncing and locking mechanism
  final Map<String, bool> _schedulingInProgress = {};
  final Map<String, DateTime> _lastScheduleTime = {};
  static const Duration _schedulingDebounce = Duration(seconds: 2);

  static const String _goalChannelId = 'goal_reminders';
  static const String _goalChannelName = 'Goal Reminders';
  static const String _goalChannelDescription = 'Notifications for goal reminders';
  static const String _scheduledNotificationsKey = 'scheduled_notifications_v3';

  Future<void> initialize() async {
    if (_initialized) return;

    // Clear any stale locks from previous sessions
    clearSchedulingLocks();

    tz.initializeTimeZones();
    final String timeZoneName = await _getTimeZoneName();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannels();
      await AndroidAlarmManager.initialize();
    }

    await _requestPermissions();
    _initialized = true;
  }

  Future<String> _getTimeZoneName() async {
    try {
      return 'Asia/Karachi';
    } catch (e) {
      return 'UTC';
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel goalChannel = AndroidNotificationChannel(
      _goalChannelId,
      _goalChannelName,
      description: _goalChannelDescription,
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(goalChannel);
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      bool allPermissionsGranted = true;

      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        allPermissionsGranted = false;
      }

      try {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (!alarmStatus.isGranted) {
          allPermissionsGranted = false;
        }
      } catch (e) {
        print('Schedule exact alarm permission not available: $e');
      }

      try {
        await Permission.ignoreBatteryOptimizations.request();
      } catch (e) {
        print('Battery optimization permission request failed: $e');
      }

      return allPermissionsGranted;
    } else if (Platform.isIOS) {
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: false,
      );
      return result ?? false;
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationNavigation(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('Navigate to: ${data['type']} - ${data['goalId']}');
  }

  // Clear all scheduling locks (useful after crashes or initialization)
  void clearSchedulingLocks() {
    _schedulingInProgress.clear();
    _lastScheduleTime.clear();
    print('🔓 Cleared all scheduling locks');
  }

  // Generate unique notification ID that's deterministic and collision-free
  int _generateUniqueId(String goalId, DateTime scheduledTime, int sequenceNumber) {
    // Use year, month, day, hour, minute as base
    final year = scheduledTime.year % 100; // Last 2 digits of year
    final month = scheduledTime.month;
    final day = scheduledTime.day;
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute;

    // Create a compact hash from goalId (use last 3 chars for uniqueness)
    final goalHash = goalId.length >= 3
        ? goalId.substring(goalId.length - 3).hashCode.abs() % 1000
        : goalId.hashCode.abs() % 1000;

    // Combine: YYMMDDHHMM + goalHash + sequence
    // Format: 2601062258999001 (26-01-06 22:58 + goal999 + seq001)
    final timeComponent = year * 100000000 +
        month * 1000000 +
        day * 10000 +
        hour * 100 +
        minute;

    final id = (timeComponent * 1000000 + goalHash * 1000 + sequenceNumber) % 2147483647;

    return id;
  }

  // Check if this EXACT notification is already scheduled
  Future<bool> _isNotificationAlreadyScheduled(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson == null) return false;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));

      // Check if this exact notification ID exists
      if (notifications.containsKey(notificationId)) {
        final notificationData = notifications[notificationId];
        final scheduledTime = DateTime.parse(notificationData['scheduledTime']);

        // If it's in the past, consider it as not scheduled (needs refresh)
        if (scheduledTime.isBefore(DateTime.now())) {
          return false;
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Error checking notification: $e');
      return false;
    }
  }

  Future<bool> scheduleGoalReminder({
    required String goalId,
    required String goalTitle,
    required String description,
    required DateTime scheduledTime,
    required String notificationId,
  }) async {
    try {
      await initialize();

      final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledTime, tz.local);

      // Skip past notifications
      if (scheduledTZ.isBefore(tz.TZDateTime.now(tz.local))) {
        print('⏭️ Skipping past notification: $scheduledTime');
        return false;
      }

      // Check if this EXACT notification is already scheduled
      if (await _isNotificationAlreadyScheduled(notificationId)) {
        print('⚠️ Notification already scheduled: $notificationId at $scheduledTime');
        return true; // Not an error, it's already there
      }

      // Generate unique ID based on goal, time, and sequence
      final int id = _generateUniqueId(goalId, scheduledTime, notificationId.hashCode);

      final Map<String, dynamic> payload = {
        'type': 'goal_reminder',
        'goalId': goalId,
        'goalTitle': goalTitle,
        'notificationId': notificationId,
        'scheduledTime': scheduledTime.toIso8601String(),
      };

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _goalChannelId,
        _goalChannelName,
        channelDescription: _goalChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          description,
          contentTitle: goalTitle,
          htmlFormatBigText: true,
          htmlFormatContentTitle: true,
        ),
        color: const Color(0xFF023E8A),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
        categoryIdentifier: 'goal_reminder',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        goalTitle,
        description,
        scheduledTZ,
        notificationDetails,
        payload: jsonEncode(payload),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await _saveNotificationData(notificationId, payload, scheduledTime, id);

      print('✅ Scheduled notification: $goalTitle at $scheduledTime (ID: $id, NotifID: $notificationId)');
      return true;
    } catch (e) {
      print('❌ Error scheduling goal reminder: $e');
      return false;
    }
  }

  Future<bool> scheduleRecurringGoalReminder({
    required String goalId,
    required String goalTitle,
    required String description,
    required String time,
    required String day,
    required DateTime targetDate,
    required String notificationId,
  }) async {
    try {
      await initialize();

      // DEBOUNCING: Check if we recently scheduled this notification
      final lastSchedule = _lastScheduleTime[notificationId];
      if (lastSchedule != null &&
          DateTime.now().difference(lastSchedule) < _schedulingDebounce) {
        print('⚠️ Skipping duplicate schedule request for $notificationId (debounced within ${_schedulingDebounce.inSeconds}s)');
        return true;
      }

      // LOCKING: Check if already scheduling
      if (_schedulingInProgress[notificationId] == true) {
        print('⚠️ Already scheduling $notificationId, skipping to prevent duplicates...');
        return true;
      }

      // Set lock and timestamp
      _schedulingInProgress[notificationId] = true;
      _lastScheduleTime[notificationId] = DateTime.now();

      try {
        // Cancel any existing notifications for this pattern
        await _cancelNotificationsForId(notificationId);

        final timeParts = time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        DateTime now = tz.TZDateTime.now(tz.local).toLocal();
        DateTime nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);

        // If time has passed today, start from tomorrow
        if (nextOccurrence.isBefore(now)) {
          nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        }

        int successCount = 0;
        int sequenceNumber = 0;
        DateTime currentDate = nextOccurrence;

        // NEW: Handle "Everyday" vs specific day
        final isEveryday = day.toLowerCase() == 'everyday';
        final dayNumber = isEveryday ? null : _getDayNumber(day);

        // For specific days, advance to the next occurrence of that day
        if (!isEveryday && dayNumber != null) {
          while (currentDate.weekday != dayNumber || currentDate.isBefore(now)) {
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }

        // Calculate how many days between occurrences
        final daysBetweenOccurrences = isEveryday ? 1 : 7;

        // Calculate max notifications (limit to avoid excessive scheduling)
        final maxNotifications = isEveryday
            ? targetDate.difference(currentDate).inDays.clamp(0, 365) // Max 1 year for daily
            : 52; // Max 52 weeks for weekly

        print('📅 Scheduling ${isEveryday ? "daily" : "weekly"} notifications until $targetDate');

        // Schedule notifications
        while (currentDate.isBefore(targetDate) && sequenceNumber < maxNotifications) {
          final uniqueId = '${notificationId}_${sequenceNumber}';

          // Schedule this specific occurrence
          final success = await scheduleGoalReminder(
            goalId: goalId,
            goalTitle: goalTitle,
            description: description,
            scheduledTime: currentDate,
            notificationId: uniqueId,
          );

          if (success) {
            successCount++;
          }

          // Move to next occurrence
          currentDate = currentDate.add(Duration(days: daysBetweenOccurrences));
          sequenceNumber++;

          // Small delay every 10 notifications to prevent overwhelming the system
          if (sequenceNumber % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

        print('✅ Scheduled $successCount/$sequenceNumber recurring notifications for $notificationId');
        return successCount > 0;
      } finally {
        // Release lock after a delay
        await Future.delayed(const Duration(milliseconds: 500));
        _schedulingInProgress[notificationId] = false;
      }
    } catch (e) {
      print('❌ Error scheduling recurring goal reminder: $e');
      _schedulingInProgress[notificationId] = false;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson == null) return [];

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));

      List<Map<String, dynamic>> result = [];
      notifications.forEach((key, value) {
        result.add({
          'notificationId': key,
          'data': value,
        });
      });

      // Sort by scheduled time
      result.sort((a, b) {
        final aTime = DateTime.parse(a['data']['scheduledTime']);
        final bTime = DateTime.parse(b['data']['scheduledTime']);
        return aTime.compareTo(bTime);
      });

      return result;
    } catch (e) {
      print('❌ Error getting all scheduled notifications: $e');
      return [];
    }
  }

  Future<void> cleanupPastNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson == null) return;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
      final now = DateTime.now();
      int removedCount = 0;

      // Remove notifications older than 1 hour
      notifications.removeWhere((key, value) {
        try {
          final scheduledTime = DateTime.parse(value['scheduledTime']);
          if (scheduledTime.isBefore(now.subtract(Duration(hours: 1)))) {
            removedCount++;
            return true;
          }
          return false;
        } catch (e) {
          return true; // Remove invalid entries
        }
      });

      if (removedCount > 0) {
        await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
        print('🧹 Cleaned up $removedCount past notifications');
      }
    } catch (e) {
      print('❌ Error cleaning up past notifications: $e');
    }
  }

  // Cancel all notifications matching a specific notification ID pattern
  Future<void> _cancelNotificationsForId(String notificationIdPattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson == null) return;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));

      // Find and cancel all notifications matching the pattern
      List<String> toRemove = [];
      for (var entry in notifications.entries) {
        if (entry.key.startsWith(notificationIdPattern)) {
          final notificationData = entry.value as Map<String, dynamic>;
          if (notificationData.containsKey('systemId')) {
            await _notifications.cancel(notificationData['systemId']);
          }
          toRemove.add(entry.key);
        }
      }

      // Remove from storage
      for (var key in toRemove) {
        notifications.remove(key);
      }

      await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));

      if (toRemove.isNotEmpty) {
        print('🗑️ Cancelled ${toRemove.length} notifications for pattern: $notificationIdPattern');
      }
    } catch (e) {
      print('❌ Error canceling notifications for ID: $e');
    }
  }

  Future<bool> cancelNotification(String notificationId) async {
    try {
      await _cancelNotificationsForId(notificationId);
      return true;
    } catch (e) {
      print('❌ Error canceling notification: $e');
      return false;
    }
  }

  Future<bool> cancelGoalNotifications(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson == null) return true;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));

      List<String> toRemove = [];
      for (var entry in notifications.entries) {
        final notificationData = entry.value as Map<String, dynamic>;
        if (notificationData['goalId'] == goalId) {
          if (notificationData.containsKey('systemId')) {
            await _notifications.cancel(notificationData['systemId']);
          }
          toRemove.add(entry.key);
        }
      }

      for (var key in toRemove) {
        notifications.remove(key);
      }

      await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
      print('🗑️ Cancelled ${toRemove.length} notifications for goal: $goalId');
      return true;
    } catch (e) {
      print('❌ Error canceling goal notifications: $e');
      return false;
    }
  }

  Future<bool> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      await _clearAllNotificationData();
      clearSchedulingLocks();
      print('🗑️ All notifications cancelled');
      return true;
    } catch (e) {
      print('❌ Error canceling all notifications: $e');
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
      _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }
    return false;
  }

  int _getDayNumber(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }

  Future<void> _saveNotificationData(
      String notificationId,
      Map<String, dynamic> data,
      DateTime scheduledTime,
      int systemId,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await _getAllNotificationData();

      data['scheduledTime'] = scheduledTime.toIso8601String();
      data['systemId'] = systemId; // Store the actual system notification ID
      data['savedAt'] = DateTime.now().toIso8601String();
      notifications[notificationId] = data;

      await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
    } catch (e) {
      print('❌ Error saving notification data: $e');
    }
  }

  Future<Map<String, dynamic>> _getAllNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_scheduledNotificationsKey);
      if (data != null) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
    } catch (e) {
      print('❌ Error getting notification data: $e');
    }
    return {};
  }

  Future<void> _clearAllNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scheduledNotificationsKey);
    } catch (e) {
      print('❌ Error clearing notification data: $e');
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _goalChannelId,
        _goalChannelName,
        channelDescription: _goalChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFF023E8A),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('❌ Error showing immediate notification: $e');
    }
  }

  Future<void> performMaintenance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson != null) {
        final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        notifications.removeWhere((key, value) {
          try {
            final scheduledTime = DateTime.parse(value['scheduledTime']);
            return scheduledTime.isBefore(sevenDaysAgo);
          } catch (e) {
            return true;
          }
        });

        await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
      }

      final pending = await getPendingNotifications();
      print('🔧 Maintenance complete. Pending notifications: ${pending.length}');
    } catch (e) {
      print('❌ Error performing maintenance: $e');
    }
  }

  // Debug helper: Get detailed status of scheduling locks
  Map<String, dynamic> getSchedulingStatus() {
    return {
      'locksInProgress': _schedulingInProgress.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      'recentSchedules': _lastScheduleTime.entries
          .map((e) => {
        'notificationId': e.key,
        'scheduledAt': e.value.toIso8601String(),
        'secondsAgo': DateTime.now().difference(e.value).inSeconds,
      })
          .toList(),
    };
  }
}