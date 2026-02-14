import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../../../ApiServices/AuthProvider.dart';
import '../../../ApiServices/CreateGoalServices.dart';
import '../../../ApiServices/LocalNotificationService.dart';
import '../Settings/LanguageSelectionScreen.dart';
import 'EditProfileScreen.dart';
import 'IconsAppearenceScreen.dart';
import 'package:easy_localization/easy_localization.dart';

// Reminder model with serialization
class ReminderItem {
  final String id;
  int dayIndex;
  TimeOfDay time;
  bool isEnabled;

  ReminderItem({
    required this.id,
    required this.dayIndex,
    required this.time,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayIndex': dayIndex,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled,
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'],
      dayIndex: map['dayIndex'],
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}

class NotificationDetailScreen extends StatefulWidget {
  @override
  _NotificationDetailScreenState createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final CreateGoalServices _goalServices = CreateGoalServices();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lists to hold multiple reminders
  List<ReminderItem> _moodCheckinReminders = [];
  List<ReminderItem> _dailyMindPracticeReminders = [];

  List<String> _dayOptions = [
    'Daily',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // Load reminders from Firebase
  Future<void> _loadReminders() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_settings')
          .doc('reminders')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Load mood check-in reminders
        if (data['moodCheckinReminders'] != null) {
          _moodCheckinReminders = (data['moodCheckinReminders'] as List)
              .map((r) => ReminderItem.fromMap(r))
              .toList();
        }

        // Load mind practice reminders
        if (data['dailyMindPracticeReminders'] != null) {
          _dailyMindPracticeReminders =
              (data['dailyMindPracticeReminders'] as List)
                  .map((r) => ReminderItem.fromMap(r))
                  .toList();
        }
      }

      // Initialize with defaults if empty
      if (_moodCheckinReminders.isEmpty) {
        _moodCheckinReminders.add(ReminderItem(
          id: DateTime
              .now()
              .millisecondsSinceEpoch
              .toString(),
          dayIndex: 0,
          time: TimeOfDay(hour: 18, minute: 0),
          isEnabled: true,
        ));
      }

      if (_dailyMindPracticeReminders.isEmpty) {
        _dailyMindPracticeReminders.add(ReminderItem(
          id: DateTime
              .now()
              .millisecondsSinceEpoch
              .toString() + '_1',
          dayIndex: 1,
          time: TimeOfDay(hour: 18, minute: 0),
          isEnabled: true,
        ));
      }

      setState(() {
        _isLoading = false;
      });

      // Schedule all enabled notifications
      await _scheduleAllNotifications();
    } catch (e) {
      print('Error loading reminders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save reminders to Firebase
  Future<void> _saveReminders() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_settings')
          .doc('reminders')
          .set({
        'moodCheckinReminders': _moodCheckinReminders.map((r) => r.toMap())
            .toList(),
        'dailyMindPracticeReminders': _dailyMindPracticeReminders.map((r) =>
            r.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Re-schedule all notifications
      await _scheduleAllNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminders saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving reminders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminders'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Schedule all notifications
  Future<void> _scheduleAllNotifications() async {
    final notificationService = LocalNotificationService();
    await notificationService.initialize();

    // Cancel all existing notifications first to avoid duplicates
    await notificationService.cancelAllNotifications();

    // Schedule mood check-in reminders
    for (var reminder in _moodCheckinReminders) {
      if (reminder.isEnabled) {
        await _scheduleReminder(
          reminder: reminder,
          type: 'mood_checkin',
          title: 'Mood Check-in Reminder',
          description: 'Time for your daily mood check-in!',
        );
      }
    }

    // Schedule mind practice reminders
    for (var reminder in _dailyMindPracticeReminders) {
      if (reminder.isEnabled) {
        await _scheduleReminder(
          reminder: reminder,
          type: 'mind_practice',
          title: 'Mind Practice Reminder',
          description: 'Time for your daily mind practice!',
        );
      }
    }
  }

  // Schedule individual reminder
  Future<void> _scheduleReminder({
    required ReminderItem reminder,
    required String type,
    required String title,
    required String description,
  }) async {
    final notificationService = LocalNotificationService();

    // Generate unique notification ID
    final notificationId = '${type}_${reminder.id}';

    if (reminder.dayIndex == 0) {
      // Daily reminder - schedule recurring
      await notificationService.scheduleRecurringGoalReminder(
        goalId: type,
        goalTitle: title,
        description: description,
        time: '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time
            .minute.toString().padLeft(2, '0')}',
        day: 'Monday',
        // Will be scheduled for all days
        targetDate: DateTime.now().add(Duration(days: 365)),
        // Schedule for 1 year
        notificationId: notificationId,
      );
    } else {
      // Weekly reminder - schedule for specific day
      await notificationService.scheduleRecurringGoalReminder(
        goalId: type,
        goalTitle: title,
        description: description,
        time: '${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time
            .minute.toString().padLeft(2, '0')}',
        day: _dayOptions[reminder.dayIndex],
        targetDate: DateTime.now().add(Duration(days: 365)),
        notificationId: notificationId,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Function to show day picker wheel
  void _showDayPicker(BuildContext context, int currentIndex,
      Function(int) onDaySelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int selectedIndex = currentIndex;
        return Container(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: context.primaryTextColor,
                        ),
                      ),
                    ),
                    Text(
                      'Select Day'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onDaySelected(selectedIndex);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF023E8A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  diameterRatio: 1.5,
                  physics: FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(
                      initialItem: currentIndex),
                  onSelectedItemChanged: (index) {
                    selectedIndex = index;
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _dayOptions.length,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          _dayOptions[index].tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: context.primaryTextColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Calculate member duration
  String _getMemberDuration(DateTime? registrationDate) {
    if (registrationDate == null) return '0 days';

    final now = DateTime.now();
    final difference = now.difference(registrationDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"}';
    }
  }

  // Add a new reminder
  void _addReminder(List<ReminderItem> reminders, String type) {
    if (reminders.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 3 reminders allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      reminders.add(ReminderItem(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString() + '_' + type,
        dayIndex: 0,
        time: TimeOfDay(hour: 18, minute: 0),
        isEnabled: true,
      ));
    });

    _saveReminders();
  }

  // Delete a reminder
  void _deleteReminder(List<ReminderItem> reminders, String reminderId) {
    if (reminders.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one reminder must remain'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      reminders.removeWhere((r) => r.id == reminderId);
    });

    _saveReminders();
  }

  Widget _buildReminderRow({
    required ReminderItem reminder,
    required List<ReminderItem> remindersList,
    required BuildContext context,
    bool showDelete = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            'Every'.tr(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onTap: () {
                _showDayPicker(context, reminder.dayIndex, (index) {
                  setState(() {
                    reminder.dayIndex = index;
                  });
                  _saveReminders();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF404040)
                      : const Color(0xFFDEDEDE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _dayOptions[reminder.dayIndex],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_up, size: 16,
                            color: context.primaryTextColor),
                        Icon(Icons.keyboard_arrow_down, size: 16,
                            color: context.primaryTextColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'at'.tr(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: context.primaryTextColor,
            ),
          ),
          SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onTap: () {
                showTimePicker(
                  context: context,
                  initialTime: reminder.time,
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: context.isDarkMode
                            ? const ColorScheme.dark(
                          primary: Color(0xFF023E8A),
                          onSurface: Colors.white,
                        )
                            : const ColorScheme.light(
                          primary: Color(0xFF023E8A),
                          onSurface: Color(0xFF1F1F1F),
                        ),
                      ),
                      child: child!,
                    );
                  },
                ).then((selectedTime) {
                  if (selectedTime != null) {
                    setState(() {
                      reminder.time = selectedTime;
                    });
                    _saveReminders();
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF404040)
                      : const Color(0xFFDEDEDE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reminder.time.format(context).tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.primaryTextColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 6),
          Switch(
            value: reminder.isEnabled,
            onChanged: (value) {
              setState(() {
                reminder.isEnabled = value;
              });
              _saveReminders();
            },
            activeColor: Color(0xFF023E8A),
            activeTrackColor: Color(0xFF023E8A).withOpacity(0.3),
            inactiveThumbColor: context.isDarkMode ? Colors.grey[600] : Colors
                .grey[400],
            inactiveTrackColor: context.isDarkMode ? Colors.grey[800] : Colors
                .grey[300],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (showDelete && remindersList.length > 1)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _deleteReminder(remindersList, reminder.id),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationContainer({
    required String title,
    required String iconAsset,
    required List<ReminderItem> reminders,
    required VoidCallback onAddPressed,
    required BuildContext context,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main container
        ThemedContainer(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    iconAsset,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      context.primaryTextColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.primaryTextColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // All reminder rows
              ...reminders.map((reminder) =>
                  _buildReminderRow(
                    reminder: reminder,
                    remindersList: reminders,
                    context: context,
                    showDelete: reminders.length > 1,
                  )).toList(),
            ],
          ),
        ),

        // Add Button positioned to overlap
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: reminders.length < 3 ? onAddPressed : null,
                borderRadius: BorderRadius.circular(55),
                child: Opacity(
                  opacity: reminders.length < 3 ? 1.0 : 0.5,
                  child: Container(
                    width: 79,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFF023E8A),
                      borderRadius: BorderRadius.circular(55),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Add'.tr(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalReminderItem({
    required String goalId,
    required String title,
    required bool hasActiveNotifications,
    required BuildContext context,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: context.primaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Switch(
              value: hasActiveNotifications,
              onChanged: (value) async {
                // Toggle all notifications for this goal
                final goal = await _goalServices.getGoalById(goalId);
                if (goal != null) {
                  List<dynamic> notifications = goal['notifications'] ?? [];
                  for (int i = 0; i < notifications.length; i++) {
                    await _goalServices.toggleNotification(
                      goalId: goalId,
                      notificationIndex: i,
                      isEnabled: value,
                    );
                  }
                  setState(() {}); // Refresh UI
                }
              },
              activeColor: Color(0xFF023E8A),
              activeTrackColor: Color(0xFF023E8A).withOpacity(0.3),
              inactiveThumbColor: context.isDarkMode ? Colors.grey[600] : Colors
                  .grey[400],
              inactiveTrackColor: context.isDarkMode ? Colors.grey[800] : Colors
                  .grey[300],
            ),
          ],
        ),
        if (showDivider)
          Divider(
            color: context.isDarkMode
                ? const Color(0xFF404040)
                : const Color(0xFFE5E5E5),
            thickness: 1,
            height: 10,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.blackSectionColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF023E8A),
          ),
        ),
      );
    }

    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final userName = authProvider.userDisplayName.isNotEmpty
                ? authProvider.userDisplayName
                : 'User'.tr();
            final memberDuration = _getMemberDuration(
                authProvider.userRegistrationDate);

            return Scaffold(
              backgroundColor: context.blackSectionColor,
              appBar: AppBar(
                backgroundColor: context.blackSectionColor,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/svg/BackBlack.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                centerTitle: true,
                title: Text(
                  'Notifications.tr()',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (_isSaving)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              body: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),

                    ],
                  ),
                  SizedBox(height: 5),
                  Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: 'Member since'.tr() + ' '),
                          TextSpan(
                            text: authProvider.getMemberDuration(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? context.cardBackgroundColor
                            : context.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        "Notifications".tr(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    _buildNotificationContainer(
                                      title: 'Mood Check-in'.tr(),
                                      iconAsset: 'assets/svg/Mood Check-in.svg',
                                      reminders: _moodCheckinReminders,
                                      context: context,
                                      onAddPressed: () {
                                        _addReminder(
                                            _moodCheckinReminders, 'mood');
                                      },
                                    ),
                                    SizedBox(height: 26),
                                    _buildNotificationContainer(
                                      title: 'Daily Mind Practice'.tr(),
                                      iconAsset: 'assets/svg/Daily Mind Practice.svg',
                                      reminders: _dailyMindPracticeReminders,
                                      context: context,
                                      onAddPressed: () {
                                        _addReminder(
                                            _dailyMindPracticeReminders,
                                            'mind');
                                      },
                                    ),
                                    SizedBox(height: 26),
                                    // Goal Reminders - Dynamic from Firebase
                                    StreamBuilder<List<Map<String, dynamic>>>(
                                      stream: _goalServices.getUserGoals(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return ThemedContainer(
                                            padding: EdgeInsets.all(20),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF023E8A),
                                              ),
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData ||
                                            snapshot.data == null) {
                                          return ThemedContainer(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment
                                                      .center,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/svg/Goal Reminders.svg',
                                                      fit: BoxFit.contain,
                                                      colorFilter: ColorFilter
                                                          .mode(
                                                        context
                                                            .primaryTextColor,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Goal Reminders'.tr(),
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 16,
                                                        fontWeight: FontWeight
                                                            .w600,
                                                        color: context
                                                            .primaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'No active goals yet'.tr(),
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: context
                                                        .primaryTextColor
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        final activeGoals = snapshot.data!
                                            .where((goal) =>
                                        goal['isCompleted'] != true)
                                            .toList();

                                        if (activeGoals.isEmpty) {
                                          return ThemedContainer(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment
                                                      .center,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/svg/Goal Reminders.svg',
                                                      fit: BoxFit.contain,
                                                      colorFilter: ColorFilter
                                                          .mode(
                                                        context
                                                            .primaryTextColor,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Goal Reminders'.tr(),
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 16,
                                                        fontWeight: FontWeight
                                                            .w600,
                                                        color: context
                                                            .primaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'No active goals'.tr(),
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: context
                                                        .primaryTextColor
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return ThemedContainer(
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/svg/Goal Reminders.svg',
                                                    fit: BoxFit.contain,
                                                    colorFilter: ColorFilter
                                                        .mode(
                                                      context.primaryTextColor,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Goal Reminders'.tr(),
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight
                                                          .w600,
                                                      color: context
                                                          .primaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 16),
                                              // Display all active goals
                                              ...activeGoals
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                int index = entry.key;
                                                Map<String,
                                                    dynamic> goal = entry.value;

                                                String goalTitle = goal['title'] ??
                                                    'Untitled Goal';
                                                String goalId = goal['id'];
                                                List<
                                                    dynamic> notifications = goal['notifications'] ??
                                                    [];

                                                // Check if any notification is enabled
                                                bool hasActiveNotifications = notifications
                                                    .any(
                                                        (notification) =>
                                                    notification['isEnabled'] ==
                                                        true
                                                );

                                                return _buildGoalReminderItem(
                                                  goalId: goalId,
                                                  title: goalTitle,
                                                  hasActiveNotifications: hasActiveNotifications,
                                                  context: context,
                                                  showDivider: index <
                                                      activeGoals.length - 1,
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery
                                .of(context)
                                .padding
                                .bottom + 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 15),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
