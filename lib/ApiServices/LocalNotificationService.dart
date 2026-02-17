import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// 🐛 DEBUG LOGGER — remove or gate behind a
//    kDebugMode flag before releasing to prod
// ─────────────────────────────────────────────
class _Log {
  static void info(String msg)    => print('ℹ️  [Notif] $msg');
  static void ok(String msg)      => print('✅ [Notif] $msg');
  static void warn(String msg)    => print('⚠️  [Notif] $msg');
  static void error(String msg)   => print('❌ [Notif] $msg');
  static void section(String msg) => print('\n════════════ $msg ════════════');
}

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final Map<String, bool> _schedulingInProgress = {};
  final Map<String, DateTime> _lastScheduleTime = {};
  static const Duration _schedulingDebounce = Duration(seconds: 2);

  static const String _goalChannelId          = 'goal_reminders';
  static const String _goalChannelName        = 'Goal Reminders';
  static const String _goalChannelDescription = 'Notifications for goal reminders';
  static const String _scheduledNotificationsKey = 'scheduled_notifications_v3';

  // ──────────────────────────────────────────
  // INIT
  // ──────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _Log.section('INITIALIZE');

    clearSchedulingLocks();

    tz.initializeTimeZones();
    final String timeZoneName = await _getTimeZoneName();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    _Log.info('Timezone set to: $timeZoneName');
    _Log.info('tz.local is now: ${tz.local.name}');
    _Log.info('Current TZDateTime.now: ${tz.TZDateTime.now(tz.local)}');
    _Log.info('System DateTime.now:    ${DateTime.now()}');

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
    _Log.ok('FlutterLocalNotificationsPlugin initialized');

    if (Platform.isAndroid) {
      await _createNotificationChannels();
      await AndroidAlarmManager.initialize();
      _Log.ok('AndroidAlarmManager initialized');
    }

    final granted = await _requestPermissions();
    _Log.info('Permissions granted: $granted');

    _initialized = true;
    _Log.ok('Service initialization complete');
  }

  Future<String> _getTimeZoneName() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      _Log.info('Device timezone identifier: ${info.identifier}');
      return info.identifier;
    } catch (e) {
      _Log.warn('Could not get local timezone, falling back to UTC: $e');
      return 'UTC';
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel goalChannel = AndroidNotificationChannel(
      _goalChannelId,
      _goalChannelName,
      description: _goalChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(goalChannel);
      _Log.ok('Notification channel "$_goalChannelId" created/updated');
    } else {
      _Log.warn('Could not resolve AndroidFlutterLocalNotificationsPlugin — channel NOT created');
    }
  }

  Future<bool> _requestPermissions() async {
    _Log.section('REQUEST PERMISSIONS');
    if (Platform.isAndroid) {
      bool allGranted = true;

      final notifStatus = await Permission.notification.request();
      _Log.info('POST_NOTIFICATIONS: $notifStatus');
      if (!notifStatus.isGranted) allGranted = false;

      try {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        _Log.info('SCHEDULE_EXACT_ALARM: $alarmStatus');
        if (!alarmStatus.isGranted) {
          allGranted = false;
          _Log.warn('⚠️ SCHEDULE_EXACT_ALARM not granted — alarms will NOT fire reliably!');
        }
      } catch (e) {
        _Log.warn('scheduleExactAlarm permission request failed: $e');
      }

      try {
        final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
        _Log.info('IGNORE_BATTERY_OPTIMIZATIONS: $batteryStatus');
        if (!batteryStatus.isGranted) {
          _Log.warn('Battery optimization is active — alarms may be delayed or killed!');
        }
      } catch (e) {
        _Log.warn('Battery optimization permission request failed: $e');
      }

      return allGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true, critical: false);
      _Log.info('iOS permissions result: $result');
      return result ?? false;
    }
    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    _Log.info('Notification tapped — actionId: ${response.actionId}, payload: ${response.payload}');
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _handleNotificationNavigation(data);
      } catch (e) {
        _Log.error('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    _Log.info('Navigate to: ${data['type']} - ${data['goalId']}');
  }

  void clearSchedulingLocks() {
    _schedulingInProgress.clear();
    _lastScheduleTime.clear();
    _Log.info('All scheduling locks cleared');
  }

  // ──────────────────────────────────────────
  // ID GENERATION
  // ──────────────────────────────────────────
  int _generateUniqueId(String goalId, DateTime scheduledTime, int sequenceNumber) {
    final combined =
        '${goalId}_'
        '${scheduledTime.year}'
        '${scheduledTime.month.toString().padLeft(2, '0')}'
        '${scheduledTime.day.toString().padLeft(2, '0')}'
        '${scheduledTime.hour.toString().padLeft(2, '0')}'
        '${scheduledTime.minute.toString().padLeft(2, '0')}'
        '_$sequenceNumber';
    final id = combined.hashCode.abs() % 2147483647;
    _Log.info('Generated system ID: $id  (from "$combined")');
    return id;
  }

  // ──────────────────────────────────────────
  // DUPLICATE CHECK
  // ──────────────────────────────────────────
  Future<bool> _isNotificationAlreadyScheduled(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);
      if (notificationsJson == null) return false;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
      if (notifications.containsKey(notificationId)) {
        final notificationData = notifications[notificationId];
        final scheduledTime = DateTime.parse(notificationData['scheduledTime']);
        if (scheduledTime.isBefore(DateTime.now())) {
          _Log.info('Stale entry for $notificationId (was $scheduledTime) — allowing reschedule');
          return false;
        }
        _Log.warn('Duplicate skip: $notificationId already saved for $scheduledTime');
        return true;
      }
      return false;
    } catch (e) {
      _Log.error('Error checking notification: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────
  // SCHEDULE SINGLE REMINDER
  // ──────────────────────────────────────────
  Future<bool> scheduleGoalReminder({
    required String goalId,
    required String goalTitle,
    required String description,
    required DateTime scheduledTime,
    required String notificationId,
    required int sequenceNumber,
  }) async {
    _Log.section('SCHEDULE SINGLE: $notificationId');
    _Log.info('Goal:          $goalTitle  (id: $goalId)');
    _Log.info('Requested time (local): $scheduledTime');

    try {
      await initialize();

      // ── Timezone diagnostics ──────────────────
      _Log.info('tz.local at schedule time: ${tz.local.name}');
      final nowTZ  = tz.TZDateTime.now(tz.local);
      final nowSys = DateTime.now();
      _Log.info('tz.TZDateTime.now: $nowTZ');
      _Log.info('DateTime.now:      $nowSys');
      _Log.info('Offset difference: ${nowTZ.timeZoneOffset}');

      final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledTime, tz.local);
      _Log.info('Converted scheduledTZ: $scheduledTZ');

      // ── Past-time guard ───────────────────────
      if (scheduledTZ.isBefore(nowTZ)) {
        _Log.warn('SKIP (past): $scheduledTime  |  now=$nowTZ');
        return false;
      }

      // ── Duplicate guard ───────────────────────
      if (await _isNotificationAlreadyScheduled(notificationId)) {
        _Log.warn('SKIP (already scheduled): $notificationId');
        return true;
      }

      // ── Generate system ID ─────────────────────
      final int id = _generateUniqueId(goalId, scheduledTime, sequenceNumber);

      // ── Permission sanity-check ────────────────
      if (Platform.isAndroid) {
        final exactAlarm = await Permission.scheduleExactAlarm.status;
        _Log.info('scheduleExactAlarm status at schedule call: $exactAlarm');
        if (!exactAlarm.isGranted) {
          _Log.warn('SCHEDULE_EXACT_ALARM not granted — notification may not fire at exact time!');
        }
      }

      // ── Build payload ──────────────────────────
      final Map<String, dynamic> payload = {
        'type':           'goal_reminder',
        'goalId':         goalId,
        'goalTitle':      goalTitle,
        'notificationId': notificationId,
        'scheduledTime':  scheduledTime.toIso8601String(),
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
          contentTitle:            goalTitle,
          htmlFormatBigText:       true,
          htmlFormatContentTitle:  true,
        ),
        color:             const Color(0xFF023E8A),
        enableVibration:   true,
        vibrationPattern:  Int64List.fromList([0, 1000, 500, 1000]),
        playSound:         true,
        category:          AndroidNotificationCategory.reminder,
        visibility:        NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'goal_reminder',
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS:     iosDetails,
      );

      // ── zonedSchedule call ─────────────────────
      _Log.info('Calling zonedSchedule — systemId=$id  scheduledTZ=$scheduledTZ  mode=exactAllowWhileIdle');
      await _notifications.zonedSchedule(
        id,
        goalTitle,
        description,
        scheduledTZ,
        notificationDetails,
        payload:             jsonEncode(payload),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      await _saveNotificationData(notificationId, payload, scheduledTime, id);

      // ── Post-schedule verification ─────────────
      final pending = await _notifications.pendingNotificationRequests();
      final match   = pending.where((p) => p.id == id).toList();
      if (match.isNotEmpty) {
        _Log.ok('VERIFIED in pending list — systemId=$id  title="${match.first.title}"');
      } else {
        _Log.warn('NOT FOUND in pending list after scheduling! systemId=$id  '
            '(total pending: ${pending.length})');
      }

      _Log.ok('Scheduled "$goalTitle" at $scheduledTime  (systemId=$id, seq=$sequenceNumber)');
      return true;
    } catch (e, stack) {
      _Log.error('Error scheduling goal reminder: $e');
      _Log.error('Stack trace:\n$stack');
      return false;
    }
  }

  // ──────────────────────────────────────────
  // SCHEDULE RECURRING REMINDER
  // ──────────────────────────────────────────
  Future<bool> scheduleRecurringGoalReminder({
    required String goalId,
    required String goalTitle,
    required String description,
    required String time,
    required String day,
    required DateTime targetDate,
    required String notificationId,
  }) async {
    _Log.section('SCHEDULE RECURRING: $notificationId');
    _Log.info('Goal: $goalTitle  |  time=$time  |  day=$day  |  target=$targetDate');

    try {
      // ── Debounce ───────────────────────────────
      final lastSchedule = _lastScheduleTime[notificationId];
      if (lastSchedule != null &&
          DateTime.now().difference(lastSchedule) < _schedulingDebounce) {
        _Log.warn('Debounced: $notificationId');
        return true;
      }

      if (_schedulingInProgress[notificationId] == true) {
        _Log.warn('Already in progress: $notificationId — skip');
        return true;
      }

      _schedulingInProgress[notificationId] = true;
      _lastScheduleTime[notificationId] = DateTime.now();

      try {
        await _cancelNotificationsForId(notificationId);

        final timeParts = time.split(':');
        final hour   = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        _Log.info('Parsed time → hour=$hour  minute=$minute');

        final now             = tz.TZDateTime.now(tz.local).toLocal();
        _Log.info('Local now for first-occurrence calc: $now');
        DateTime nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
        _Log.info('First candidate occurrence: $nextOccurrence');

        if (nextOccurrence.isBefore(now)) {
          nextOccurrence = nextOccurrence.add(const Duration(days: 1));
          _Log.info('Time already passed today → bumped to tomorrow: $nextOccurrence');
        }

        final isEveryday  = day.toLowerCase() == 'everyday';
        final dayNumber   = isEveryday ? null : _getDayNumber(day);
        _Log.info('isEveryday=$isEveryday  dayNumber=$dayNumber');

        DateTime currentDate = nextOccurrence;
        if (!isEveryday && dayNumber != null) {
          int shifted = 0;
          while (currentDate.weekday != dayNumber) {
            currentDate = currentDate.add(const Duration(days: 1));
            shifted++;
          }
          if (shifted > 0) _Log.info('Shifted $shifted day(s) to first $day: $currentDate');
        }

        final daysBetween         = isEveryday ? 1 : 7;
        final daysUntilTarget     = targetDate.difference(currentDate).inDays;
        final maxNotifications    = isEveryday
            ? daysUntilTarget.clamp(1, 365)
            : 52;

        _Log.info('daysUntilTarget=$daysUntilTarget  maxNotifications=$maxNotifications  '
            'daysBetween=$daysBetween');

        if (daysUntilTarget <= 0) {
          _Log.warn('Target date is in the past or today — no notifications will be scheduled!');
        }

        int successCount  = 0;
        int sequenceNumber = 0;

        while (currentDate.isBefore(targetDate) && sequenceNumber < maxNotifications) {
          final uniqueId = '${notificationId}_$sequenceNumber';
          _Log.info('── Occurrence #$sequenceNumber → $currentDate  (id: $uniqueId)');

          final success = await scheduleGoalReminder(
            goalId:         goalId,
            goalTitle:      goalTitle,
            description:    description,
            scheduledTime:  currentDate,
            notificationId: uniqueId,
            sequenceNumber: sequenceNumber,
          );

          if (success) successCount++;

          currentDate    = currentDate.add(Duration(days: daysBetween));
          sequenceNumber++;

          if (sequenceNumber % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

        _Log.ok('Recurring schedule done: $successCount/$sequenceNumber succeeded for $notificationId');

        // ── Pending summary ────────────────────────
        final pending = await _notifications.pendingNotificationRequests();
        _Log.info('Total pending notifications on device: ${pending.length}');
        if (pending.isNotEmpty) {
          _Log.info('Next few pending:');
          pending.take(5).forEach((p) => _Log.info('  id=${p.id}  title="${p.title}"'));
        }

        return successCount > 0;
      } finally {
        await Future.delayed(const Duration(milliseconds: 500));
        _schedulingInProgress[notificationId] = false;
      }
    } catch (e, stack) {
      _Log.error('Error scheduling recurring goal reminder: $e');
      _Log.error('Stack trace:\n$stack');
      _schedulingInProgress[notificationId] = false;
      return false;
    }
  }

  // ──────────────────────────────────────────
  // CANCEL & RESCHEDULE HELPER
  // ──────────────────────────────────────────
  Future<void> cancelAndRescheduleForGoal({
    required String goalId,
    required String goalTitle,
    required List<Map<String, dynamic>> notifications,
    required DateTime targetDate,
  }) async {
    _Log.section('CANCEL & RESCHEDULE: $goalId');
    await cancelGoalNotifications(goalId);

    for (final notif in notifications) {
      final isEnabled = notif['isEnabled'] ?? false;
      if (!isEnabled) {
        _Log.info('Skip disabled notification: ${notif['id']}');
        continue;
      }

      final notifId = '${goalId}_${notif['id']}';
      _Log.info('Rescheduling: $notifId');
      await scheduleRecurringGoalReminder(
        goalId:         goalId,
        goalTitle:      goalTitle,
        description:    'Time to work on your goal!',
        time:           notif['time'],
        day:            notif['day'] ?? 'Everyday',
        targetDate:     targetDate,
        notificationId: notifId,
      );
    }
  }

  // ──────────────────────────────────────────
  // DIAGNOSTIC DUMP
  // ──────────────────────────────────────────
  /// Call this after scheduling to print a full status report.
  Future<void> printDiagnostics() async {
    _Log.section('DIAGNOSTICS');

    // Timezone
    _Log.info('tz.local:            ${tz.local.name}');
    _Log.info('tz.TZDateTime.now:   ${tz.TZDateTime.now(tz.local)}');
    _Log.info('DateTime.now:        ${DateTime.now()}');

    // Permissions
    if (Platform.isAndroid) {
      _Log.info('POST_NOTIFICATIONS:          ${await Permission.notification.status}');
      _Log.info('SCHEDULE_EXACT_ALARM:        ${await Permission.scheduleExactAlarm.status}');
      _Log.info('IGNORE_BATTERY_OPTIMIZATIONS: ${await Permission.ignoreBatteryOptimizations.status}');
    }

    // Pending notifications
    final pending = await _notifications.pendingNotificationRequests();
    _Log.info('Pending notifications: ${pending.length}');
    for (final p in pending) {
      _Log.info('  → id=${p.id}  title="${p.title}"  body="${p.body}"');
    }

    // Saved data
    final saved = await getAllScheduledNotifications();
    _Log.info('Saved in SharedPreferences: ${saved.length}');
    for (final s in saved.take(10)) {
      _Log.info('  → ${s['notificationId']}  @ ${s['data']['scheduledTime']}');
    }

    _Log.section('END DIAGNOSTICS');
  }

  // ──────────────────────────────────────────
  // DATA HELPERS
  // ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);
      if (notificationsJson == null) return [];

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
      final List<Map<String, dynamic>> result = [];
      notifications.forEach((key, value) {
        result.add({'notificationId': key, 'data': value});
      });

      result.sort((a, b) {
        final aTime = DateTime.parse(a['data']['scheduledTime']);
        final bTime = DateTime.parse(b['data']['scheduledTime']);
        return aTime.compareTo(bTime);
      });

      return result;
    } catch (e) {
      _Log.error('Error getting all scheduled notifications: $e');
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

      notifications.removeWhere((key, value) {
        try {
          final scheduledTime = DateTime.parse(value['scheduledTime']);
          if (scheduledTime.isBefore(now.subtract(const Duration(hours: 1)))) {
            removedCount++;
            return true;
          }
          return false;
        } catch (e) {
          return true;
        }
      });

      if (removedCount > 0) {
        await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
        _Log.info('Cleaned up $removedCount past notifications');
      }
    } catch (e) {
      _Log.error('Error cleaning up past notifications: $e');
    }
  }

  Future<void> _cancelNotificationsForId(String notificationIdPattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);
      if (notificationsJson == null) return;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
      final List<String> toRemove = [];

      for (var entry in notifications.entries) {
        if (entry.key.startsWith(notificationIdPattern)) {
          final notificationData = entry.value as Map<String, dynamic>;
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

      if (toRemove.isNotEmpty) {
        _Log.info('Cancelled ${toRemove.length} notifications matching: $notificationIdPattern');
      }
    } catch (e) {
      _Log.error('Error canceling notifications for ID: $e');
    }
  }

  Future<bool> cancelNotification(String notificationId) async {
    try {
      await _cancelNotificationsForId(notificationId);
      return true;
    } catch (e) {
      _Log.error('Error canceling notification: $e');
      return false;
    }
  }

  Future<bool> cancelGoalNotifications(String goalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);
      if (notificationsJson == null) return true;

      final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
      final List<String> toRemove = [];

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
      _Log.info('Cancelled ${toRemove.length} notifications for goal: $goalId');
      return true;
    } catch (e) {
      _Log.error('Error canceling goal notifications: $e');
      return false;
    }
  }

  Future<bool> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      await _clearAllNotificationData();
      clearSchedulingLocks();
      _Log.ok('All notifications cancelled');
      return true;
    } catch (e) {
      _Log.error('Error canceling all notifications: $e');
      return false;
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled() ?? false;
      _Log.info('areNotificationsEnabled (Android): $enabled');
      return enabled;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
      _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _Log.info('areNotificationsEnabled (iOS): $settings');
      return settings ?? false;
    }
    return false;
  }

  int _getDayNumber(String day) {
    switch (day.toLowerCase()) {
      case 'monday':    return DateTime.monday;
      case 'tuesday':   return DateTime.tuesday;
      case 'wednesday': return DateTime.wednesday;
      case 'thursday':  return DateTime.thursday;
      case 'friday':    return DateTime.friday;
      case 'saturday':  return DateTime.saturday;
      case 'sunday':    return DateTime.sunday;
      default:
        _Log.warn('Unknown day "$day" — defaulting to Monday');
        return DateTime.monday;
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
      data['systemId']      = systemId;
      data['savedAt']       = DateTime.now().toIso8601String();
      notifications[notificationId] = data;

      await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
    } catch (e) {
      _Log.error('Error saving notification data: $e');
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
      _Log.error('Error getting notification data: $e');
    }
    return {};
  }

  Future<void> _clearAllNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scheduledNotificationsKey);
    } catch (e) {
      _Log.error('Error clearing notification data: $e');
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();
      _Log.info('Showing immediate notification: "$title"');

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
        iOS:     iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch % 100000;
      await _notifications.show(id, title, body, notificationDetails, payload: payload);
      _Log.ok('Immediate notification shown (id=$id)');
    } catch (e) {
      _Log.error('Error showing immediate notification: $e');
    }
  }

  Future<void> performMaintenance() async {
    _Log.section('MAINTENANCE');
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson != null) {
        final notifications = Map<String, dynamic>.from(jsonDecode(notificationsJson));
        final sevenDaysAgo  = DateTime.now().subtract(const Duration(days: 7));
        int removed = 0;

        notifications.removeWhere((key, value) {
          try {
            if (DateTime.parse(value['scheduledTime']).isBefore(sevenDaysAgo)) {
              removed++;
              return true;
            }
            return false;
          } catch (e) {
            return true;
          }
        });

        if (removed > 0) {
          await prefs.setString(_scheduledNotificationsKey, jsonEncode(notifications));
          _Log.info('Removed $removed stale entries from SharedPreferences');
        }
      }

      final pending = await getPendingNotifications();
      _Log.ok('Maintenance complete. Pending notifications: ${pending.length}');
    } catch (e) {
      _Log.error('Error performing maintenance: $e');
    }
  }

  Map<String, dynamic> getSchedulingStatus() {
    return {
      'locksInProgress': _schedulingInProgress.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      'recentSchedules': _lastScheduleTime.entries
          .map((e) => {
        'notificationId': e.key,
        'scheduledAt':    e.value.toIso8601String(),
        'secondsAgo':     DateTime.now().difference(e.value).inSeconds,
      })
          .toList(),
    };
  }
}