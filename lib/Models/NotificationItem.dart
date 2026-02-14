import 'package:flutter/material.dart';

class NotificationItem {
  String id;
  TimeOfDay time;
  String day;
  bool isEnabled;

  NotificationItem({
    required this.id,
    required this.time,
    required this.day,
    required this.isEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'day': day,
      'isEnabled': isEnabled,
    };
  }
}
