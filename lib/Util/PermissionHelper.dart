import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class PermissionHelper {
  static const MethodChannel _channel = MethodChannel('notification_permissions');

  /// Request all necessary permissions from native side
  static Future<bool> requestAllPermissions() async {
    try {
      // First try the native channel approach
      await _channel.invokeMethod('requestPermissions');
      return true;
    } catch (e) {
      print('Native permission request failed, continuing with plugin fallback: $e');
      // The LocalNotificationService will handle permissions as fallback
      return false;
    }
  }

  /// Open notification settings
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      print('Error opening notification settings via native: $e');
      // Fallback: You could use url_launcher to open settings
      // await launchUrl(Uri.parse('app-settings:'));
    }
  }

  /// Check if exact alarms can be scheduled (Android only)
  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    try {
      return await _channel.invokeMethod('canScheduleExactAlarms') ?? false;
    } catch (e) {
      print('Error checking exact alarm permission via native: $e');
      return true; // Assume true if we can't check
    }
  }

  /// Request exact alarm permission (Android only)
  static Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      print('Error requesting exact alarm permission via native: $e');
    }
  }

  /// Check notification status (iOS only)
  static Future<bool> areNotificationsEnabled() async {
    if (!Platform.isIOS) return true;

    try {
      return await _channel.invokeMethod('areNotificationsEnabled') ?? false;
    } catch (e) {
      print('Error checking notification status via native: $e');
      return true; // Assume true if we can't check
    }
  }

  /// Show permission rationale dialog
  static Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enable Notifications'),
          content: Text(
            'Nocrastinate needs notification permissions to send you goal reminders and help you stay productive.\n\n'
                'Please tap "Settings" and enable notifications for the best experience.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                openNotificationSettings();
              },
              child: Text('Settings'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}