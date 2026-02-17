import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import '../../../../ApiServices/CreateGoalServices.dart';
import '../../../../ApiServices/LocalNotificationService.dart';
import '../../../../Models/NotificationItem.dart';

import 'package:easy_localization/easy_localization.dart';

class NewGoalScreen extends StatefulWidget {
  final bool isFromUpdateScreen;
  final Map<String, dynamic>? existingGoal;

  const NewGoalScreen({
    Key? key,
    this.isFromUpdateScreen = false,
    this.existingGoal,
  }) : super(key: key);

  @override
  _NewGoalScreenState createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final TextEditingController _goalNameController = TextEditingController();
  List<TextEditingController> _taskControllers = [];
  DateTime _targetDate = DateTime.now().add(Duration(days: 30));

  List<NotificationItem> _notifications = [];
  final LocalNotificationService _notificationService = LocalNotificationService();
  final FocusNode _focusNode = FocusNode();

  final CreateGoalServices _goalService = CreateGoalServices();
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'Everyday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // ─────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    print('🟣 [NewGoalScreen] initState — isFromUpdateScreen=${widget.isFromUpdateScreen}  existingGoal=${widget.existingGoal != null}');

    _initializeNotifications();

    if (widget.isFromUpdateScreen && widget.existingGoal != null) {
      print('🟣 [NewGoalScreen] Loading existing goal data...');
      _loadExistingGoalData();
    } else {
      print('🟣 [NewGoalScreen] New goal — adding defaults');
      _addDefaultNotifications();
      _addTaskField();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟣 [NewGoalScreen] postFrameCallback — requesting focus');
      _focusNode.requestFocus();
    });
  }

  Future<void> _initializeNotifications() async {
    print('🟣 [NewGoalScreen] _initializeNotifications() called');
    await _notificationService.initialize();
    print('🟣 [NewGoalScreen] _initializeNotifications() done');
  }

  @override
  void dispose() {
    print('🟣 [NewGoalScreen] dispose()');
    _goalNameController.dispose();
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // DATA SETUP
  // ─────────────────────────────────────────

  void _addDefaultNotifications() {
    print('🟣 [NewGoalScreen] _addDefaultNotifications()');
    _notifications = [
      NotificationItem(
        id: 'notification_1',
        time: TimeOfDay(hour: 6, minute: 0),
        day: 'Everyday',
        isEnabled: false,
      ),
      NotificationItem(
        id: 'notification_2',
        time: TimeOfDay(hour: 18, minute: 0),
        day: 'Everyday',
        isEnabled: false,
      ),
    ];
    print('🟣 [NewGoalScreen] Default notifications: ${_notifications.length}');
  }

  void _loadExistingGoalData() {
    print('🟣 [NewGoalScreen] _loadExistingGoalData() start');
    final goal = widget.existingGoal!;
    print('🟣 [NewGoalScreen] Raw goal data keys: ${goal.keys.toList()}');

    _goalNameController.text = goal['title'] ?? '';
    print('🟣 [NewGoalScreen] Title: "${_goalNameController.text}"');

    if (goal['targetDate'] != null) {
      _targetDate = goal['targetDate'].toDate();
      print('🟣 [NewGoalScreen] Target date: $_targetDate');
    } else {
      print('⚠️ [NewGoalScreen] targetDate is null — using default');
    }

    // Tasks
    if (goal['tasks'] != null && goal['tasks'].isNotEmpty) {
      List tasks = goal['tasks'];
      print('🟣 [NewGoalScreen] Loading ${tasks.length} tasks from "tasks" field');
      for (var task in tasks) {
        final controller = TextEditingController(text: task);
        _taskControllers.add(controller);
      }
    } else if (goal['description'] != null && goal['description'].toString().isNotEmpty) {
      print('🟣 [NewGoalScreen] No "tasks" field — falling back to "description"');
      List<String> tasks = goal['description'].toString().split('\n')
          .where((task) => task.trim().isNotEmpty)
          .toList();
      print('🟣 [NewGoalScreen] Parsed ${tasks.length} tasks from description');
      for (var task in tasks) {
        final controller = TextEditingController(text: task);
        _taskControllers.add(controller);
      }
    } else {
      print('⚠️ [NewGoalScreen] No tasks or description found');
    }

    if (_taskControllers.isEmpty) {
      print('⚠️ [NewGoalScreen] No tasks loaded — adding empty field');
      _addTaskField();
    }

    // Notifications
    if (goal['notifications'] != null && goal['notifications'].isNotEmpty) {
      _notifications.clear();
      List notifications = goal['notifications'];
      print('🟣 [NewGoalScreen] Loading ${notifications.length} notifications');

      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];
        print('🟣 [NewGoalScreen]   [$i] raw: $notification');
        final timeParts = notification['time'].split(':');

        _notifications.add(NotificationItem(
          id: 'notification_${i + 1}',
          time: TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          ),
          day: notification['day'] ?? 'Everyday',
          isEnabled: notification['isEnabled'] ?? false,
        ));
        print('🟣 [NewGoalScreen]   [$i] loaded: time=${notification['time']}  day=${notification['day']}  enabled=${notification['isEnabled']}');
      }
    } else {
      print('⚠️ [NewGoalScreen] No notifications in goal data — using defaults');
    }

    if (_notifications.isEmpty) {
      print('⚠️ [NewGoalScreen] Notifications empty after load — adding defaults');
      _addDefaultNotifications();
    }

    print('🟣 [NewGoalScreen] _loadExistingGoalData() done — tasks=${_taskControllers.length}  notifications=${_notifications.length}');
  }

  // ─────────────────────────────────────────
  // TASK MANAGEMENT
  // ─────────────────────────────────────────

  void _addTaskField() {
    if (_taskControllers.length < 10) {
      print('🟣 [NewGoalScreen] _addTaskField — count will be ${_taskControllers.length + 1}');
      setState(() {
        _taskControllers.add(TextEditingController());
      });
    } else {
      print('⚠️ [NewGoalScreen] _addTaskField — max 10 reached');
    }
  }

  void _removeTaskField(int index) {
    if (_taskControllers.length > 1) {
      print('🟣 [NewGoalScreen] _removeTaskField index=$index');
      setState(() {
        _taskControllers[index].dispose();
        _taskControllers.removeAt(index);
      });
    } else {
      print('⚠️ [NewGoalScreen] _removeTaskField — cannot remove last task');
    }
  }

  // ─────────────────────────────────────────
  // NOTIFICATION MANAGEMENT
  // ─────────────────────────────────────────

  void _addNotification() {
    if (_notifications.length < 5) {
      print('🟣 [NewGoalScreen] _addNotification — count will be ${_notifications.length + 1}');
      setState(() {
        _notifications.add(NotificationItem(
          id: 'notification_${_notifications.length + 1}',
          time: TimeOfDay(hour: 18, minute: 0),
          day: 'Everyday',
          isEnabled: false,
        ));
      });
    } else {
      print('⚠️ [NewGoalScreen] _addNotification — max 5 reached');
    }
  }

  void _removeNotification(int index) {
    if (_notifications.length > 1) {
      print('🟣 [NewGoalScreen] _removeNotification index=$index');
      setState(() {
        _notifications.removeAt(index);
      });
    } else {
      print('⚠️ [NewGoalScreen] _removeNotification — cannot remove last notification');
    }
  }

  // ─────────────────────────────────────────
  // DATE / TIME / DAY PICKERS
  // ─────────────────────────────────────────

  Future<void> _selectDate(BuildContext context) async {
    print('🟣 [NewGoalScreen] _selectDate — current: $_targetDate');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDarkMode
                ? ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppColors.darkBackground,
              onSurface: Colors.white,
              surface: AppColors.darkCardBackground,
            )
                : ColorScheme.light(
              primary: Color(0xFF1F1F1F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F1F1F),
            ),
            dialogBackgroundColor: context.isDarkMode ? AppColors.darkCardBackground : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _targetDate) {
      print('🟣 [NewGoalScreen] Date picked: $picked');
      setState(() { _targetDate = picked; });
    } else {
      print('🟣 [NewGoalScreen] Date picker dismissed or same date');
    }
  }

  Future<void> _selectTime(int index) async {
    print('🟣 [NewGoalScreen] _selectTime index=$index  current=${_notifications[index].time}');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notifications[index].time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDarkMode
                ? ColorScheme.dark(
              primary: Colors.white,
              onPrimary: AppColors.darkBackground,
              onSurface: Colors.white,
              surface: AppColors.darkCardBackground,
            )
                : ColorScheme.light(
              primary: Color(0xFF1F1F1F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F1F1F),
            ),
            dialogBackgroundColor: context.isDarkMode ? AppColors.darkCardBackground : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      print('🟣 [NewGoalScreen] Time picked: $picked for index=$index');
      setState(() { _notifications[index].time = picked; });
    } else {
      print('🟣 [NewGoalScreen] Time picker dismissed');
    }
  }

  void _selectDay(int index) {
    print('🟣 [NewGoalScreen] _selectDay index=$index  current=${_notifications[index].day}');
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
              SizedBox(height: 20),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _daysOfWeek.map((day) => ListTile(
                    title: Text(
                      day.tr(),
                      style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor),
                    ),
                    trailing: _notifications[index].day == day
                        ? Icon(Icons.check, color: context.primaryTextColor)
                        : null,
                    onTap: () {
                      print('🟣 [NewGoalScreen] Day selected: $day for index=$index');
                      setState(() { _notifications[index].day = day; });
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // SAVE GOAL
  // ─────────────────────────────────────────

  Future<void> _saveGoal() async {
    print('\n════════════ SAVE GOAL ════════════');
    print('🟡 [SaveGoal] _saveGoal() called');
    print('🟡 [SaveGoal] isFromUpdateScreen: ${widget.isFromUpdateScreen}');

    // Validation
    if (_goalNameController.text.trim().isEmpty) {
      print('🟡 [SaveGoal] STOPPED: goal name is empty');
      _showErrorDialog('Please enter a goal name');
      return;
    }

    List<String> tasks = _taskControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (tasks.isEmpty) {
      print('🟡 [SaveGoal] STOPPED: no tasks entered');
      _showErrorDialog('Please add at least one task');
      return;
    }

    print('🟡 [SaveGoal] Goal name: "${_goalNameController.text.trim()}"');
    print('🟡 [SaveGoal] Tasks (${tasks.length}): $tasks');
    print('🟡 [SaveGoal] Target date: $_targetDate');
    print('🟡 [SaveGoal] Notifications (${_notifications.length}):');
    for (var n in _notifications) {
      print('🟡 [SaveGoal]   → id=${n.id}  time=${n.time.hour}:${n.time.minute.toString().padLeft(2,'0')}  day=${n.day}  enabled=${n.isEnabled}');
    }

    final enabledCount = _notifications.where((n) => n.isEnabled).length;
    if (enabledCount == 0) {
      print('⚠️ [SaveGoal] WARNING: 0 notifications are enabled! '
          'Toggle at least one switch ON or no alarms will be scheduled.');
    } else {
      print('🟡 [SaveGoal] Enabled notifications: $enabledCount');
    }

    setState(() { _isLoading = true; });
    print('🟡 [SaveGoal] _isLoading = true');

    try {
      // Build notification data
      List<Map<String, dynamic>> notificationsData = _notifications.map((n) {
        final data = CreateGoalServices.createNotificationData(
          time: '${n.time.hour.toString().padLeft(2, '0')}:${n.time.minute.toString().padLeft(2, '0')}',
          day: n.day,
          isEnabled: n.isEnabled,
        );
        return data;
      }).toList();
      print('🟡 [SaveGoal] notificationsData: $notificationsData');

      bool success;
      String goalId;

      // Firebase call
      if (widget.isFromUpdateScreen && widget.existingGoal != null) {
        goalId = widget.existingGoal!['id'];
        print('🟡 [SaveGoal] Calling updateGoal — goalId=$goalId');

        success = await _goalService.updateGoal(
          goalId: goalId,
          title: _goalNameController.text.trim(),
          tasks: tasks,
          targetDate: _targetDate,
          notifications: notificationsData,
        );
        print('🟡 [SaveGoal] updateGoal result: success=$success');

      } else {
        print('🟡 [SaveGoal] Calling createGoalWithResult...');
        final result = await _goalService.createGoalWithResult(
          title: _goalNameController.text.trim(),
          tasks: tasks,
          targetDate: _targetDate,
          notifications: notificationsData,
        );
        print('🟡 [SaveGoal] createGoalWithResult result: $result');

        success = result['success'] ?? false;
        goalId  = result['goalId'] ?? '';
      }

      print('🟡 [SaveGoal] ─── Firebase done: success=$success  goalId="$goalId"');

      if (success) {
        if (goalId.isEmpty) {
          print('❌ [SaveGoal] goalId is EMPTY — cannot build notification IDs!');
        }

        // Schedule notifications
        print('🟡 [SaveGoal] Starting notification scheduling loop...');
        int scheduled = 0;
        int skipped   = 0;

        for (int i = 0; i < _notifications.length; i++) {
          final notification = _notifications[i];
          print('🟡 [SaveGoal] ── Notification[$i]: id=${notification.id}  enabled=${notification.isEnabled}');

          if (notification.isEnabled) {
            final notifId = '${goalId}_${notification.id}';
            final timeStr = '${notification.time.hour.toString().padLeft(2, '0')}:'
                '${notification.time.minute.toString().padLeft(2, '0')}';

            print('🟡 [SaveGoal]    Cancelling old: $notifId');
            await _notificationService.cancelNotification(notifId);

            print('🟡 [SaveGoal]    Scheduling: $notifId  time=$timeStr  day=${notification.day}  target=$_targetDate');
            final ok = await _notificationService.scheduleRecurringGoalReminder(
              goalId:         goalId,
              goalTitle:      _goalNameController.text.trim(),
              description:    'Time to work on your goal!',
              time:           timeStr,
              day:            notification.day,
              targetDate:     _targetDate,
              notificationId: notifId,
            );
            print('🟡 [SaveGoal]    scheduleRecurringGoalReminder → $ok');
            if (ok) scheduled++; else skipped++;
          } else {
            print('🟡 [SaveGoal]    SKIP (disabled)');
            skipped++;
          }
        }

        print('🟡 [SaveGoal] Scheduling complete — scheduled=$scheduled  skipped=$skipped');

        // Full diagnostics dump
        await _notificationService.printDiagnostics();

        print('✅ [SaveGoal] Showing success dialog');
        _showSuccessDialog(
          widget.isFromUpdateScreen ? 'Goal updated successfully!' : 'Goal created successfully!',
        );

      } else {
        print('❌ [SaveGoal] Save returned success=false — showing error');
        _showErrorDialog('Failed to save goal. Please try again.');
      }

    } catch (e, stack) {
      print('❌ [SaveGoal] EXCEPTION: $e');
      print('❌ [SaveGoal] Stack trace:\n$stack');
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() { _isLoading = false; });
      print('🟡 [SaveGoal] _isLoading = false');
      print('════════════ SAVE GOAL END ════════════\n');
    }
  }

  // ─────────────────────────────────────────
  // DELETE GOAL
  // ─────────────────────────────────────────

  Future<void> _deleteGoal() async {
    print('\n════════════ DELETE GOAL ════════════');
    if (widget.existingGoal == null) {
      print('❌ [DeleteGoal] existingGoal is null — aborting');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String goalId = widget.existingGoal!['id'];
      print('🔴 [DeleteGoal] Deleting goalId=$goalId');

      bool success = await _goalService.deleteGoal(goalId);
      print('🔴 [DeleteGoal] deleteGoal result: $success');

      if (success) {
        print('🔴 [DeleteGoal] Cancelling all notifications for goal');
        await _notificationService.cancelGoalNotifications(goalId);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal deleted successfully'), backgroundColor: Colors.green),
        );
      } else {
        print('❌ [DeleteGoal] deleteGoal returned false');
        _showErrorDialog('Failed to delete goal. Please try again.');
      }
    } catch (e, stack) {
      print('❌ [DeleteGoal] EXCEPTION: $e');
      print('❌ [DeleteGoal] Stack:\n$stack');
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() { _isLoading = false; });
      print('════════════ DELETE GOAL END ════════════\n');
    }
  }

  // ─────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────

  void _showErrorDialog(String message) {
    print('🔴 [Dialog] Error: $message');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text('Error',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.red)),
          content: Text(message,
              style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK',
                  style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    print('✅ [Dialog] Success: $message');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text('Success',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.green)),
          content: Text(message,
              style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor)),
          actions: [
            TextButton(
              onPressed: () {
                print('✅ [Dialog] OK tapped — popping 2 screens');
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('OK',
                  style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    print('🔴 [Dialog] Delete confirmation shown');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text('Delete Goal',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: context.primaryTextColor)),
          content: Text('Are you sure you want to delete this goal? This action cannot be undone.',
              style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor)),
          actions: [
            TextButton(
              onPressed: () {
                print('🔴 [Dialog] Delete cancelled');
                Navigator.of(context).pop();
              },
              child: Text('Cancel',
                  style: TextStyle(fontFamily: 'Poppins', color: context.primaryTextColor)),
            ),
            TextButton(
              onPressed: _isLoading ? null : () {
                print('🔴 [Dialog] Delete confirmed');
                Navigator.of(context).pop();
                _deleteGoal();
              },
              child: Text(
                _isLoading ? 'Deleting...' : 'Delete',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: _isLoading ? Colors.red.withOpacity(0.5) : Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────

  Widget _buildTaskItem(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 15, right: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: context.primaryTextColor, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.isDarkMode ? context.backgroundColor : context.cardBackgroundColor,
                border: Border.all(color: context.borderColor, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _taskControllers[index],
                maxLength: 80,
                maxLines: null,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: context.primaryTextColor),
                decoration: InputDecoration(
                  hintText: 'Add task...'.tr(),
                  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: context.secondaryTextColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  counterText: '',
                ),
                onChanged: (text) { setState(() {}); },
              ),
            ),
          ),
          if (_taskControllers.length > 1)
            IconButton(
              onPressed: () => _removeTaskField(index),
              icon: Icon(Icons.close, color: context.secondaryTextColor, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final notification = _notifications[index];
    final timeString   = notification.time.format(context);

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: notification.isEnabled
            ? context.blackSectionColor
            : (context.isDarkMode ? context.backgroundColor : Color(0x1A1F1F1F)),
        borderRadius: BorderRadius.circular(15),
        border: context.isDarkMode && !notification.isEnabled
            ? Border.all(color: context.borderColor, width: 0.5)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _selectTime(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          timeString,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: notification.isEnabled ? Colors.white : context.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectDay(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: notification.isEnabled ? Colors.white : context.primaryTextColor,
                            ),
                            children: notification.day == 'Everyday'
                                ? [
                              TextSpan(text: 'Everyday'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' ${'until Target Date'.tr()}'),
                            ]
                                : [
                              TextSpan(text: 'Every '),
                              TextSpan(text: notification.day, style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' ${'until Target Date'.tr()}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_notifications.length > 1)
                    IconButton(
                      onPressed: () => _removeNotification(index),
                      icon: Icon(
                        Icons.delete_outline,
                        color: notification.isEnabled ? Colors.white.withOpacity(0.7) : context.secondaryTextColor,
                        size: 20,
                      ),
                    ),
                  Switch(
                    value: notification.isEnabled,
                    onChanged: (value) {
                      print('🟣 [NewGoalScreen] Switch toggled: index=$index  enabled=$value');
                      setState(() { _notifications[index].isEnabled = value; });
                    },
                    activeColor: notification.isEnabled
                        ? Colors.white
                        : (context.isDarkMode ? Colors.white : const Color(0xFF1F1F1F)),
                    activeTrackColor: notification.isEnabled ? Colors.white.withOpacity(0.3) : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.blackSectionColor,
      appBar: AppBar(
        backgroundColor: context.blackSectionColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            print('🟣 [NewGoalScreen] Back tapped — popping');
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            child: SvgPicture.asset('assets/svg/BackBlack.svg', fit: BoxFit.contain),
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.isFromUpdateScreen ? 'Update Goal'.tr() : 'Create a New Goal'.tr(),
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _goalNameController,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3,
                ),
                decoration: InputDecoration(
                  hintText: 'Name your goal'.tr(),
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              width: 200,
              height: 33,
              decoration: BoxDecoration(
                color: context.isDarkMode ? AppColors.darkCardBackground : Color(0xFF303030),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${'Target Date'.tr()} : ',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      TextSpan(
                        text: DateFormat('dd/MM/yyyy').format(_targetDate),
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDarkMode ? context.cardBackgroundColor : context.backgroundColor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                              child: Text("Tasks".tr(),
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
                            ),
                            SizedBox(height: 16),

                            ..._taskControllers.asMap().entries.map((entry) => _buildTaskItem(entry.key)).toList(),

                            if (_taskControllers.length < 10)
                              GestureDetector(
                                onTap: _addTaskField,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline, color: Color(0xFF023E8A), size: 20),
                                      SizedBox(width: 8),
                                      Text('Add another task'.tr(),
                                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF023E8A))),
                                    ],
                                  ),
                                ),
                              ),

                            SizedBox(height: 20),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text("Notifications".tr(),
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
                            ),
                            SizedBox(height: 20),

                            ..._notifications.asMap().entries.map((entry) => _buildNotificationItem(entry.key)).toList(),

                            SizedBox(height: 20),

                            if (_notifications.length < 5)
                              GestureDetector(
                                onTap: _addNotification,
                                child: Container(
                                  width: 79,
                                  height: 32,
                                  decoration: BoxDecoration(color: const Color(0xFF023E8A), borderRadius: BorderRadius.circular(55)),
                                  child: Center(
                                    child: Text('+ add'.tr(),
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.of(context).padding.bottom + 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isFromUpdateScreen) ...[
                          TextButton(
                            onPressed: _isLoading ? null : () => _showDeleteConfirmationDialog(context),
                            child: SvgPicture.asset('assets/svg/delete.svg', fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 15),
                        ],

                        Expanded(
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(55),
                              border: Border.all(color: context.primaryTextColor, width: 1),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () {
                                print('🟣 [NewGoalScreen] Cancel tapped');
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(55)),
                              ),
                              child: Text('Cancel'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500,
                                  color: _isLoading ? context.primaryTextColor.withOpacity(0.5) : context.primaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: context.blackSectionColor,
                              borderRadius: BorderRadius.circular(55),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveGoal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.isDarkMode ? Colors.white : context.blackSectionColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(55)),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.isDarkMode ? context.backgroundColor : Colors.white,
                                ),
                              )
                                  : Text(
                                widget.isFromUpdateScreen ? 'Update'.tr() : 'Create'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500,
                                  color: context.isDarkMode ? context.backgroundColor : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
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
  }
}