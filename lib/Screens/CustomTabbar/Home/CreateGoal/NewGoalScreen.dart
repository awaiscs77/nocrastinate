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

  // Notification management
  List<NotificationItem> _notifications = [];
  final LocalNotificationService _notificationService = LocalNotificationService();
  final FocusNode _focusNode = FocusNode();

  // Firebase service instance
  final CreateGoalServices _goalService = CreateGoalServices();
  bool _isLoading = false;

  // Days of the week - UPDATED with Everyday option
  final List<String> _daysOfWeek = [
    'Everyday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();

    if (widget.isFromUpdateScreen && widget.existingGoal != null) {
      _loadExistingGoalData();
    } else {
      _addDefaultNotifications();
      _addTaskField();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  void _addDefaultNotifications() {
    _notifications = [
      NotificationItem(
        id: 'notification_1',
        time: TimeOfDay(hour: 6, minute: 0),
        day: 'Everyday', // Changed default to Everyday
        isEnabled: false,
      ),
      NotificationItem(
        id: 'notification_2',
        time: TimeOfDay(hour: 18, minute: 0),
        day: 'Everyday', // Changed default to Everyday
        isEnabled: false,
      ),
    ];
  }

  void _loadExistingGoalData() {
    final goal = widget.existingGoal!;
    _goalNameController.text = goal['title'] ?? '';

    if (goal['targetDate'] != null) {
      _targetDate = goal['targetDate'].toDate();
    }

    // Load existing tasks
    if (goal['tasks'] != null && goal['tasks'].isNotEmpty) {
      List tasks = goal['tasks'];
      for (var task in tasks) {
        final controller = TextEditingController(text: task);
        _taskControllers.add(controller);
      }
    } else if (goal['description'] != null && goal['description'].toString().isNotEmpty) {
      List<String> tasks = goal['description'].toString().split('\n')
          .where((task) => task.trim().isNotEmpty)
          .toList();
      for (var task in tasks) {
        final controller = TextEditingController(text: task);
        _taskControllers.add(controller);
      }
    }

    if (_taskControllers.isEmpty) {
      _addTaskField();
    }

    // Load existing notifications
    if (goal['notifications'] != null && goal['notifications'].isNotEmpty) {
      _notifications.clear();
      List notifications = goal['notifications'];

      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];
        final timeParts = notification['time'].split(':');

        _notifications.add(NotificationItem(
          id: 'notification_${i + 1}',
          time: TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          ),
          day: notification['day'] ?? 'Everyday'.tr(),
          isEnabled: notification['isEnabled'] ?? false,
        ));
      }
    }

    if (_notifications.isEmpty) {
      _addDefaultNotifications();
    }
  }

  void _addTaskField() {
    if (_taskControllers.length < 10) {
      setState(() {
        _taskControllers.add(TextEditingController());
      });
    }
  }

  void _removeTaskField(int index) {
    if (_taskControllers.length > 1) {
      setState(() {
        _taskControllers[index].dispose();
        _taskControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    for (var controller in _taskControllers) {
      controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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
            dialogBackgroundColor: context.isDarkMode
                ? AppColors.darkCardBackground
                : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _selectTime(int index) async {
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
            dialogBackgroundColor: context.isDarkMode
                ? AppColors.darkCardBackground
                : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _notifications[index].time = picked;
      });
    }
  }

  void _selectDay(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      isScrollControlled: true, // Add this
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Add max height
          ),
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
              Flexible( // Wrap ListView in Flexible
                child: ListView(
                  shrinkWrap: true,
                  children: _daysOfWeek.map((day) => ListTile(
                    title: Text(
                      day.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: context.primaryTextColor,
                      ),
                    ),
                    trailing: _notifications[index].day == day
                        ? Icon(Icons.check, color: context.primaryTextColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _notifications[index].day = day;
                      });
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

  void _addNotification() {
    if (_notifications.length < 5) {
      setState(() {
        _notifications.add(NotificationItem(
          id: 'notification_${_notifications.length + 1}',
          time: TimeOfDay(hour: 18, minute: 0),
          day: 'Everyday', // Changed default to Everyday
          isEnabled: false,
        ));
      });
    }
  }

  void _removeNotification(int index) {
    if (_notifications.length > 1) {
      setState(() {
        _notifications.removeAt(index);
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_goalNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a goal name');
      return;
    }

    List<String> tasks = _taskControllers
        .map((controller) => controller.text.trim())
        .where((task) => task.isNotEmpty)
        .toList();

    if (tasks.isEmpty) {
      _showErrorDialog('Please add at least one task');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> notificationsData = _notifications.map((notification) {
        return CreateGoalServices.createNotificationData(
          time: '${notification.time.hour.toString().padLeft(2, '0')}:${notification.time.minute.toString().padLeft(2, '0')}',
          day: notification.day,
          isEnabled: notification.isEnabled,
        );
      }).toList();

      bool success;
      String goalId;

      if (widget.isFromUpdateScreen && widget.existingGoal != null) {
        goalId = widget.existingGoal!['id'];

        success = await _goalService.updateGoal(
          goalId: goalId,
          title: _goalNameController.text.trim(),
          tasks: tasks,
          targetDate: _targetDate,
          notifications: notificationsData,
        );
      } else {
        final result = await _goalService.createGoalWithResult(
          title: _goalNameController.text.trim(),
          tasks: tasks,
          targetDate: _targetDate,
          notifications: notificationsData,
        );

        success = result['success'];
        goalId = result['goalId'] ?? '';
      }

      if (success) {
        _showSuccessDialog(
            widget.isFromUpdateScreen ? 'Goal updated successfully!' : 'Goal created successfully!'
        );
      } else {
        _showErrorDialog('Failed to save goal. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGoal() async {
    if (widget.existingGoal == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String goalId = widget.existingGoal!['id'];
      bool success = await _goalService.deleteGoal(goalId);

      if (success) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErrorDialog('Failed to delete goal. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Error',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: context.primaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: context.primaryTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Success',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: context.primaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: context.primaryTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
              decoration: BoxDecoration(
                color: context.primaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.isDarkMode ? context.backgroundColor : context.cardBackgroundColor,
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _taskControllers[index],
                maxLength: 80,
                maxLines: null,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: context.primaryTextColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Add task...'.tr(),
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: context.secondaryTextColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  counterText: '',
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
            ),
          ),
          if (_taskControllers.length > 1)
            IconButton(
              onPressed: () => _removeTaskField(index),
              icon: Icon(
                Icons.close,
                color: context.secondaryTextColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final notification = _notifications[index];
    final timeString = notification.time.format(context);

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
                            color: notification.isEnabled
                                ? Colors.white
                                : context.primaryTextColor,
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
                              color: notification.isEnabled
                                  ? Colors.white
                                  : context.primaryTextColor,
                            ),
                            children: notification.day == 'Everyday'
                                ? [
                              TextSpan(
                                text: 'Everyday'.tr(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' ${'until Target Date'.tr()}'),
                            ]
                                : [
                              TextSpan(text: 'Every '),
                              TextSpan(
                                text: notification.day,
                                style: TextStyle(fontWeight: FontWeight.bold),
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
              Row(
                children: [
                  if (_notifications.length > 1)
                    IconButton(
                      onPressed: () => _removeNotification(index),
                      icon: Icon(
                        Icons.delete_outline,
                        color: notification.isEnabled
                            ? Colors.white.withOpacity(0.7)
                            : context.secondaryTextColor,
                        size: 20,
                      ),
                    ),
                  Switch(
                    value: notification.isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notifications[index].isEnabled = value;
                      });
                    },
                    activeColor: notification.isEnabled
                        ? Colors.white
                        : (context.isDarkMode ? Colors.white : const Color(0xFF1F1F1F)),
                    activeTrackColor: notification.isEnabled
                        ? Colors.white.withOpacity(0.3)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          widget.isFromUpdateScreen ? 'Update Goal'.tr() : 'Create a New Goal'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  hintText: 'Name your goal'.tr(),
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
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
                color: context.isDarkMode
                    ? AppColors.darkCardBackground
                    : Color(0xFF303030),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${'Target Date'.tr()} : ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: DateFormat('dd/MM/yyyy').format(_targetDate),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
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
          const SizedBox(height: 30),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDarkMode ? context.cardBackgroundColor : context.backgroundColor,
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
                                "Tasks".tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryTextColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            ..._taskControllers.asMap().entries.map((entry) {
                              return _buildTaskItem(entry.key);
                            }).toList(),

                            if (_taskControllers.length < 10)
                              GestureDetector(
                                onTap: _addTaskField,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Color(0xFF023E8A),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add another task'.tr(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF023E8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            SizedBox(height: 20),
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

                            ..._notifications.asMap().entries.map((entry) {
                              return _buildNotificationItem(entry.key);
                            }).toList(),

                            SizedBox(height: 20),

                            if (_notifications.length < 5)
                              GestureDetector(
                                onTap: _addNotification,
                                child: Container(
                                  width: 79,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF023E8A),
                                    borderRadius: BorderRadius.circular(55),
                                  ),
                                  child:  Center(
                                    child: Text(
                                      '+ add'.tr(),
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
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.of(context).padding.bottom + 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isFromUpdateScreen) ...[
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              _showDeleteConfirmationDialog(context);
                            },
                            child: SvgPicture.asset(
                              'assets/svg/delete.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 15),
                        ],
                        // Remove duplicate Cancel button - you have TWO identical Cancel buttons
                        // Keep only ONE Cancel button
                        Expanded(
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(55),
                              border: Border.all(
                                color: context.primaryTextColor,
                                width: 1,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(55),
                                ),
                              ),
                              child: Text(
                                'Cancel'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(55),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.isDarkMode ? context.backgroundColor : Colors.white,
                                ),
                              )
                                  : Text(
                                widget.isFromUpdateScreen ? 'Update'.tr() : 'Create'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: context.isDarkMode ? context.backgroundColor : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for delete
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Delete Goal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this goal? This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: context.primaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: context.primaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : () {
                _deleteGoal();
              },
              child: Text(
                _isLoading ? 'Deleting...' : 'Delete',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: _isLoading ? Colors.red.withOpacity(0.5) : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}