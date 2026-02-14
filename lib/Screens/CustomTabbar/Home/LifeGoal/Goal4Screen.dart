import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';

import '../../../../ApiServices/CreateGoalServices.dart';
import '../../../../ApiServices/LocalNotificationService.dart';
import 'package:easy_localization/easy_localization.dart';

class Goal4Screen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const Goal4Screen({
    Key? key,
    required this.sessionData,
  }) : super(key: key);

  @override
  _Goal4ScreenState createState() => _Goal4ScreenState();
}

class _Goal4ScreenState extends State<Goal4Screen> {
  List<Map<String, dynamic>> _reminders = [];
  final CreateGoalServices _goalServices = CreateGoalServices();
  final LocalNotificationService _notificationService = LocalNotificationService();
  bool _isLoading = false;

  // Days of the week (matching NewGoalScreen)
  final List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeReminders();
  }

  void _initializeReminders() {
    // Check if goalData is passed in sessionData
    if (widget.sessionData.containsKey('goalData') && widget.sessionData['goalData'] != null) {
      _loadExistingGoalData(widget.sessionData['goalData']);
    } else {
      _initializeDefaultReminders();
    }
  }

  void _initializeDefaultReminders() {
    // Initialize with default reminders for new goals
    setState(() {
      _reminders = [
        {
          'time': '18:00',
          'day': 'Tuesday',
          'isEnabled': false,
        },
        {
          'time': '18:00',
          'day': 'Tuesday',
          'isEnabled': false,
        },
      ];
    });
  }

  Future<void> _loadExistingReminders() async {
    try {
      String goalId = widget.sessionData['goalId'];
      Map<String, dynamic>? goalData = await _goalServices.getGoalById(goalId);

      if (goalData != null) {
        _loadExistingGoalData(goalData);
      } else {
        _initializeDefaultReminders();
      }
    } catch (e) {
      print('Error loading existing reminders: $e');
      _initializeDefaultReminders();
    }
  }

  void _loadExistingGoalData(Map<String, dynamic> goal) {
    // Load existing notifications
    if (goal['notifications'] != null && goal['notifications'].isNotEmpty) {
      setState(() {
        _reminders.clear();
        List notifications = goal['notifications'];

        for (int i = 0; i < notifications.length; i++) {
          final notification = notifications[i];

          _reminders.add({
            'time': notification['time'] ?? '18:00',
            'day': notification['day'] ?? 'Tuesday',
            'isEnabled': notification['isEnabled'] ?? false,
            'createdAt': notification['createdAt'] ?? Timestamp.now(),
          });
        }
      });
    }

    if (_reminders.isEmpty) {
      _initializeDefaultReminders();
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not Set';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Invalid Date';
    }

    return DateFormat('MMM dd').format(dateTime);
  }

  // Format time to display format (matching NewGoalScreen)
  String _formatTimeDisplay(String time24) {
    try {
      final timeParts = time24.split(':');
      int hour = int.parse(timeParts[0]);
      String minute = timeParts[1];

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time24;
    }
  }

  // Convert time string to TimeOfDay
  TimeOfDay _stringToTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 18, minute: 0);
    }
  }

  // Convert TimeOfDay to string
  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _toggleReminder(int index) {
    setState(() {
      _reminders[index]['isEnabled'] = !_reminders[index]['isEnabled'];
    });
  }

  // Time picker (matching NewGoalScreen)
  Future<void> _selectTime(int index) async {
    final TimeOfDay currentTime = _stringToTimeOfDay(_reminders[index]['time']);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDarkMode
                ? ColorScheme.dark(
              primary: Colors.white,
              onPrimary: context.backgroundColor,
              onSurface: Colors.white,
              surface: context.cardBackgroundColor,
            )
                : ColorScheme.light(
              primary: Color(0xFF1F1F1F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F1F1F),
            ),
            dialogBackgroundColor: context.isDarkMode
                ? context.cardBackgroundColor
                : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminders[index]['time'] = _timeOfDayToString(picked);
      });
    }
  }

  // Day picker (matching NewGoalScreen)
  void _selectDay(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Day'.tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              ..._daysOfWeek.map((day) => ListTile(
                title: Text(
                  day.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: context.primaryTextColor,
                  ),
                ),
                trailing: _reminders[index]['day'] == day
                    ? Icon(Icons.check, color: context.primaryTextColor)
                    : null,
                onTap: () {
                  setState(() {
                    _reminders[index]['day'] = day;
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  void _addNewReminder() {
    if (_reminders.length < 5) { // Limit to 5 like in NewGoalScreen
      setState(() {
        _reminders.add({
          'time': '18:00',
          'day': 'Monday',
          'isEnabled': true,
          'createdAt': Timestamp.now(),
        });
      });
    }
  }

  void _removeReminder(int index) {
    if (_reminders.length > 1) { // Keep at least one like in NewGoalScreen
      setState(() {
        _reminders.removeAt(index);
      });
    }
  }

  // Schedule local notifications for enabled reminders
  Future<void> _scheduleNotifications(String goalId, String goalTitle, List<String> tasks, DateTime targetDate) async {
    try {
      // Cancel any existing notifications for this goal first
      await _notificationService.cancelGoalNotifications(goalId);

      // Create description from tasks
      String description = tasks.map((task) => '• $task').join('\n');
      if (description.isEmpty) {
        description = 'Time to work on your goal: $goalTitle';
      }

      // Schedule new notifications for enabled reminders
      for (int i = 0; i < _reminders.length; i++) {
        final reminder = _reminders[i];
        if (reminder['isEnabled'] == true) {
          final String notificationId = '${goalId}_reminder_$i';

          bool success = await _notificationService.scheduleRecurringGoalReminder(
            goalId: goalId,
            goalTitle: goalTitle,
            description: description,
            time: reminder['time'],
            day: reminder['day'],
            targetDate: targetDate,
            notificationId: notificationId,
          );

          if (success) {
            print('Successfully scheduled notification for $goalTitle on ${reminder['day']} at ${reminder['time']}');
          } else {
            print('Failed to schedule notification for $goalTitle');
          }
        }
      }
    } catch (e) {
      print('Error scheduling notifications: $e');
      // Don't throw error - let the goal save even if notifications fail
    }
  }

  Future<void> _saveGoalData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract goal data from session
      final Map<String, dynamic> goalData = widget.sessionData['goalData'] ?? {};
      final String goalTitle = goalData['title'] ?? 'Untitled Goal';

      // ✅ FIXED: Get tasks from goalData
      List<String> tasks = [];
      if (goalData['tasks'] != null && goalData['tasks'] is List) {
        tasks = List<String>.from(goalData['tasks']);
      } else if (goalData['description'] != null && goalData['description'].toString().isNotEmpty) {
        // Fallback: Parse from description if tasks field doesn't exist
        tasks = goalData['description'].toString().split('\n')
            .where((task) => task.trim().isNotEmpty)
            .toList();
      }

      final dynamic targetDate = goalData['targetDate'];

      DateTime targetDateTime;
      if (targetDate is Timestamp) {
        targetDateTime = targetDate.toDate();
      } else if (targetDate is DateTime) {
        targetDateTime = targetDate;
      } else {
        targetDateTime = DateTime.now().add(const Duration(days: 30));
      }

      // Prepare notifications data for Firebase
      List<Map<String, dynamic>> notificationsData = _reminders.map((reminder) {
        return CreateGoalServices.createNotificationData(
          time: reminder['time'],
          day: reminder['day'],
          isEnabled: reminder['isEnabled'],
        );
      }).toList();

      bool success;
      String? goalId;

      // Check if we're updating an existing goal or creating a new one
      if (widget.sessionData['goalData'] != null &&
          widget.sessionData['goalData']['id'] != null) {
        // ✅ FIXED: Update existing goal with tasks array
        goalId = widget.sessionData['goalData']['id'];
        success = await _goalServices.updateGoal(
          goalId: goalId ?? "",
          title: goalTitle,
          tasks: tasks, // Pass tasks array instead of description
          targetDate: targetDateTime,
          notifications: notificationsData,
        );
      } else {
        // ✅ FIXED: Create new goal with tasks array
        final result = await _goalServices.createGoalWithResult(
          title: goalTitle,
          tasks: tasks, // Pass tasks array instead of description
          targetDate: targetDateTime,
          notifications: notificationsData,
        );
        success = result['success'] ?? false;
        goalId = result['goalId'];
      }

      if (success && goalId != null) {
        // Schedule local notifications with tasks
        await _scheduleNotifications(goalId, goalTitle, tasks, targetDateTime);

        // Save progress session data
        await _saveProgressSession(goalId);

        // Navigate to home
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
              (Route<dynamic> route) => false,
        );
      } else {
        throw Exception('Failed to save goal');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving goal: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save progress session
  Future<void> _saveProgressSession(String goalId) async {
    try {
      // Prepare session data based on what path the user took
      Map<String, dynamic> sessionData = {
        'improvementPlan': widget.sessionData['improvementPlan'] ?? '',
        'reminders': _reminders,
      };

      // Check if user came from "Yes" path (had progress)
      if (widget.sessionData.containsKey('effortLevel')) {
        sessionData['hadProgress'] = true;
        sessionData['effortLevel'] = widget.sessionData['effortLevel'];
      }
      // Check if user came from "No" path (no progress)
      else if (widget.sessionData.containsKey('noProgressReason')) {
        sessionData['hadProgress'] = false;
        sessionData['noProgressReason'] = widget.sessionData['noProgressReason'] ?? '';
        sessionData['selectedMood'] = widget.sessionData['selectedMood'] ?? '';
      }

      // Save the progress session
      await _goalServices.saveGoalProgressSession(
        goalId: goalId,
        sessionData: sessionData,
      );
    } catch (e) {
      print('Error saving progress session: $e');
      // Don't throw - we still want the goal to be saved even if session fails
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract goal data from session
    final Map<String, dynamic> goalData = widget.sessionData['goalData'] ?? {};
    final String goalTitle = goalData['title'] ?? 'Untitled Goal';
    final dynamic lastProgress = goalData['lastProgress'];
    final dynamic targetDate = goalData['targetDate'];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.primaryTextColor),
        title: Text(
          'Life Goals'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Top section with goal title and progress info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Goal title
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '"$goalTitle"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress Container
                  Container(
                    width: 210,
                    height: 33,
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? context.cardBackgroundColor : Colors.white,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/progress.svg',
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            context.primaryTextColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last Progress'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(lastProgress),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Target Date Container
                  Container(
                    width: 188,
                    height: 33,
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? context.cardBackgroundColor : Colors.white,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/target.svg',
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(
                            context.primaryTextColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Target Date'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(targetDate),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Center content (question and buttons) - vertically centered
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Question text
                    Text(
                      'Goal Reminder'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Dynamic reminder list
                    ...List.generate(_reminders.length, (index) {
                      final reminder = _reminders[index];
                      final isEnabled = reminder['isEnabled'] as bool;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? context.primaryTextColor
                              : context.primaryTextColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Clickable time
                                  GestureDetector(
                                    onTap: () => _selectTime(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Text(
                                        _formatTimeDisplay(reminder['time']),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isEnabled
                                              ? context.backgroundColor
                                              : context.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Clickable day
                                  GestureDetector(
                                    onTap: () => _selectDay(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: isEnabled
                                                ? context.backgroundColor
                                                : context.primaryTextColor,
                                          ),
                                          children: [
                                             TextSpan(text: '${'Every'.tr()} '),
                                            TextSpan(
                                              text: (reminder['day'] ?? '').toString().tr(),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                             TextSpan(text: ' ${'until Target Date'.tr()}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Delete button (only show if more than 1 reminder)
                            if (_reminders.length > 1)
                              IconButton(
                                onPressed: () => _removeReminder(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isEnabled
                                      ? context.backgroundColor.withOpacity(0.7)
                                      : context.primaryTextColor.withOpacity(0.7),
                                  size: 20,
                                ),
                              ),
                            Switch(
                              value: isEnabled,
                              onChanged: (value) => _toggleReminder(index),
                              activeColor: isEnabled
                                  ? context.backgroundColor
                                  : context.primaryTextColor,
                              activeTrackColor: isEnabled
                                  ? context.backgroundColor.withOpacity(0.3)
                                  : context.primaryTextColor.withOpacity(0.3),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 15),

                    // Add New Reminder Container
                    if (_reminders.length < 5)
                      GestureDetector(
                        onTap: _addNewReminder,
                        child: Container(
                          width: 79,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF023E8A),
                            borderRadius: BorderRadius.circular(55),
                          ),
                          child:  Center(
                            child: Text(
                              '+ Add'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: SizedBox(
                width: 138,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoalData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryTextColor,
                    disabledBackgroundColor: context.primaryTextColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.backgroundColor,
                      ),
                    ),
                  )
                      : Text(
                    'Done'.tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}