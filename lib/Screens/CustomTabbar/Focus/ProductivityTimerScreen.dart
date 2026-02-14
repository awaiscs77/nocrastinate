import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();
  int _remainingSeconds = 0;

  Timer? _timer;
  TimerState _timerState = TimerState.stopped;
  SessionType _currentSessionType = SessionType.work;

  double progress = 0.0;
  int currentSession = 1;
  int totalSessions = 8;
  int _totalSecondsForCurrentSession = 0;

  int workSessionMinutes = 25;
  int breakDurationMinutes = 5;
  DateTime? _sessionStartTime;
  DateTime? _pauseTime;
  Function? onUpdate;
  Function? onSessionComplete;
  Function? onAllComplete;

  void dispose() {
    _timer?.cancel();
  }

  void startTimer() {
    if (_timerState == TimerState.stopped) {
      _remainingSeconds = workSessionMinutes * 60;
      _totalSecondsForCurrentSession = workSessionMinutes * 60;
      _currentSessionType = SessionType.work;
      currentSession = 1;
      _sessionStartTime = DateTime.now();
    } else if (_timerState == TimerState.paused && _pauseTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseTime!);
      _sessionStartTime = _sessionStartTime!.add(pauseDuration);
    }

    _timerState = TimerState.running;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        progress = 1.0 - (_remainingSeconds / _totalSecondsForCurrentSession);
        onUpdate?.call();
      } else {
        handleSessionComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _pauseTime = DateTime.now();
    _timerState = TimerState.paused;
    onUpdate?.call();
  }

  void resetTimer() {
    _timer?.cancel();
    _timerState = TimerState.stopped;
    _currentSessionType = SessionType.work;
    currentSession = 1;
    _remainingSeconds = workSessionMinutes * 60;
    _totalSecondsForCurrentSession = workSessionMinutes * 60;
    progress = 0.0;
    _sessionStartTime = null;
    _pauseTime = null;
    onUpdate?.call();
  }

  void handleSessionComplete() {
    if (_currentSessionType == SessionType.work) {
      if (currentSession < totalSessions) {
        _currentSessionType = SessionType.break_;
        _remainingSeconds = breakDurationMinutes * 60;
        _totalSecondsForCurrentSession = breakDurationMinutes * 60;
        progress = 0.0;
        _sessionStartTime = DateTime.now();
        onSessionComplete?.call('Work Session Complete! 🎉', 'Time for a $breakDurationMinutes minute break');
      } else {
        completeAllSessions();
        return;
      }
    } else {
      currentSession++;
      _currentSessionType = SessionType.work;
      _remainingSeconds = workSessionMinutes * 60;
      _totalSecondsForCurrentSession = workSessionMinutes * 60;
      progress = 0.0;
      _sessionStartTime = DateTime.now();
      onSessionComplete?.call('Break Complete! 💪', 'Starting work session $currentSession/$totalSessions');
    }
    onUpdate?.call();
  }

  void completeAllSessions() {
    _timer?.cancel();
    _timerState = TimerState.stopped;
    progress = 1.0;
    _sessionStartTime = null;
    onAllComplete?.call();
    onUpdate?.call();
  }

  void syncTimerWithElapsedTime() {
    if (_sessionStartTime == null || _timerState != TimerState.running) return;

    final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
    final shouldRemain = _totalSecondsForCurrentSession - elapsed;

    if (shouldRemain <= 0) {
      int missedTime = elapsed - _totalSecondsForCurrentSession;

      while (missedTime >= 0) {
        handleSessionComplete();

        if (_timerState == TimerState.stopped) {
          return;
        }

        if (missedTime > 0) {
          if (missedTime >= _totalSecondsForCurrentSession) {
            missedTime -= _totalSecondsForCurrentSession;
          } else {
            _remainingSeconds = _totalSecondsForCurrentSession - missedTime;
            progress = 1.0 - (_remainingSeconds / _totalSecondsForCurrentSession);
            missedTime = 0;
          }
        }
      }
    } else {
      _remainingSeconds = shouldRemain;
      progress = 1.0 - (_remainingSeconds / _totalSecondsForCurrentSession);
    }

    onUpdate?.call();
  }

  String get timeDisplay {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  TimerState get timerState => _timerState;
  SessionType get currentSessionType => _currentSessionType;
  int get remainingSeconds => _remainingSeconds;
}

enum TimerState { stopped, running, paused }
enum SessionType { work, break_ }
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final double radius;
  final double borderOffset;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.radius,
    required this.borderOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final progressRadius = radius - borderOffset / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: progressRadius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ProductivityTimerScreen extends StatefulWidget {
  final int timer;

  const ProductivityTimerScreen({
    Key? key,
    required this.timer,
  }) : super(key: key);

  @override
  _ProductivityTimerScreenState createState() =>
      _ProductivityTimerScreenState();
}

class _ProductivityTimerScreenState extends State<ProductivityTimerScreen> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {  // Timer variables
  @override
  bool get wantKeepAlive => true;
  final TimerService _timerService = TimerService();
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  int selectedSessions = 8;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _requestNotificationPermission();

    // Initialize timer service if stopped
    if (_timerService.timerState == TimerState.stopped) {
      _timerService.workSessionMinutes = widget.timer;
      _timerService.totalSessions = selectedSessions;
      _timerService.resetTimer();
    } else {
      // Load existing state
      selectedSessions = _timerService.totalSessions;
    }

    // Set up callbacks
    _timerService.onUpdate = () {
      if (mounted) {
        setState(() {});
        if (_timerService.timerState == TimerState.running) {
          if (_timerService.remainingSeconds % 5 == 0) {
            _updateNotification();
          }
        }
      }
    };

    _timerService.onSessionComplete = (String title, String message) {
      _showSessionChangeNotification(title, message);
    };

    _timerService.onAllComplete = () {
      WakelockPlus.disable();
      _cancelAllNotifications();
      _showCompletionNotification();
      if (mounted) {
        _showCompletionDialog();
      }
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose the timer service, just cleanup local resources
    WakelockPlus.disable();
    _cancelAllNotifications();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      if (_timerService.timerState == TimerState.running) {
        _showOngoingNotification();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_timerService.timerState == TimerState.running) {
        _timerService.syncTimerWithElapsedTime();
        _cancelNotification(0);
      }
    }
  }



  // Initialize notifications
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Add iOS settings even if not using iOS
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS, // Add this line
    );

    await flutterLocalNotificationsPlugin?.initialize(initializationSettings);
  }

  // Request notification permission
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Show ongoing notification when app is in background
  Future<void> _showOngoingNotification() async {
    final sessionTypeText = _timerService.currentSessionType == SessionType.work
        ? 'Work Session ${_timerService.currentSession}/${_timerService.totalSessions}'
        : 'Break Time';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'productivity_timer',
      'Productivity Timer',
      channelDescription: 'Ongoing productivity timer notification',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      color: _timerService.currentSessionType == SessionType.work
          ? const Color(0xFF023E8A)
          : Colors.green,
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin?.show(
      0,
      sessionTypeText,
      'Time remaining: $_timerService.timeDisplay',
      platformChannelSpecifics,
    );
  }

  // Update notification with current time
  Future<void> _updateNotification() async {
    if (_timerService.timerState == TimerState.running) {
      final sessionTypeText = _timerService.currentSessionType == SessionType.work
          ? 'Work Session ${_timerService.currentSession}/${_timerService.totalSessions}'
          : 'Break Time';

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'productivity_timer',
        'Productivity Timer',
        channelDescription: 'Ongoing productivity timer notification',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        color: _timerService.currentSessionType == SessionType.work
            ? const Color(0xFF023E8A)
            : Colors.green,
      );

      final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin?.show(
        0,
        sessionTypeText,
        'Time remaining: $_timerService.timeDisplay',
        platformChannelSpecifics,
      );
    }
  }

  // Cancel specific notification
  Future<void> _cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin?.cancel(id);
  }

  // Cancel all notifications
  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin?.cancelAll();
  }

  // Show session change notification
  Future<void> _showSessionChangeNotification(String title, String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'productivity_alerts',
      'Productivity Alerts',
      channelDescription: 'Session change notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin?.show(
      1,
      title,
      message,
      platformChannelSpecifics,
    );
  }

  // Show completion notification
  Future<void> _showCompletionNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'productivity_complete',
      'Session Complete',
      channelDescription: 'Session completion notification',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin?.show(
      2,
      '🎉 All Sessions Complete!',
      'Congratulations! You completed all ${_timerService.totalSessions} productivity sessions!',
      platformChannelSpecifics,
    );

  }




  void _resetTimer() {
    _timerService.resetTimer();
    WakelockPlus.disable();
    _cancelAllNotifications();
    setState(() {});
  }
  void _startTimer() {
    _timerService.startTimer();
    WakelockPlus.enable();
    setState(() {});
  }

  void _pauseTimer() {
    _timerService.pauseTimer();
    WakelockPlus.disable();
    _cancelNotification(0);
    setState(() {});
  }





  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🎉 Congratulations!'),
          content: Text('You have completed all ${_timerService.totalSessions} productivity sessions!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetTimer();
              },
              child: Text('Start New Session'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String get _buttonText {
    switch (_timerService.timerState) {
      case TimerState.stopped:
        return 'Start'.tr();
      case TimerState.running:
        return 'Pause'.tr();
      case TimerState.paused:
        return 'Resume'.tr();
    }
  }

  IconData get _buttonIcon {
    switch (_timerService.timerState) {
      case TimerState.stopped:
        return Icons.play_arrow;
      case TimerState.running:
        return Icons.pause;
      case TimerState.paused:
        return Icons.play_arrow;
    }
  }

  void _onButtonPressed() {
    switch (_timerService.timerState) {
      case TimerState.stopped:
        _startTimer();
        break;
      case TimerState.running:
        _pauseTimer();
        break;
      case TimerState.paused:
        _startTimer();
        break;
    }
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: enabled
            ? (context.isDarkMode ? Colors.white : context.blackSectionColor)
            : Colors.grey.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: enabled
              ? (!context.isDarkMode ? Colors.white : context.blackSectionColor)
              : Colors.grey,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSessionCounter() {
    bool canModify = _timerService.timerState == TimerState.stopped;
    double _swipeAccumulator = 0.0; // Add this as class variable at top

    return Container(
      height: 120,
      child: GestureDetector(
        onPanUpdate: canModify ? (details) {
          // Accumulate swipe delta
          _swipeAccumulator += details.delta.dy;

          // Only trigger change when accumulated movement exceeds threshold
          if (_swipeAccumulator < -15) { // Swipe up - increase threshold from 1.5 to 15
            if (selectedSessions < 15) {
              setState(() {
                selectedSessions++;
                _timerService.totalSessions = selectedSessions;
                _swipeAccumulator = 0.0; // Reset accumulator
              });
            }
          } else if (_swipeAccumulator > 15) { // Swipe down - increase threshold from 1.5 to 15
            if (selectedSessions > 1) {
              setState(() {
                selectedSessions--;
                _timerService.totalSessions = selectedSessions;
                _swipeAccumulator = 0.0; // Reset accumulator
              });
            }
          }
        } : null,
        onPanEnd: canModify ? (details) {
          // Reset accumulator when gesture ends
          _swipeAccumulator = 0.0;
        } : null,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: canModify && selectedSessions > 1 ? () {
                setState(() {
                  selectedSessions--;
                  _timerService.totalSessions = selectedSessions;
                });
              } : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                height: 40,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(
                          begin: Offset(0, -0.3),
                          end: Offset.zero,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    selectedSessions > 1 ? (selectedSessions - 1).toString() : '',
                    key: ValueKey('prev_${selectedSessions - 1}'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: context.primaryTextColor.withOpacity(canModify ? 0.5 : 0.3),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 150),
              height: 40,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  selectedSessions.toString(),
                  key: ValueKey('current_$selectedSessions'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: context.primaryTextColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: canModify && selectedSessions < 15 ? () {
                setState(() {
                  selectedSessions++;
                  _timerService.totalSessions = selectedSessions;
                });
              } : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                height: 40,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(
                          begin: Offset(0, 0.3),
                          end: Offset.zero,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    selectedSessions < 15 ? (selectedSessions + 1).toString() : '',
                    key: ValueKey('next_${selectedSessions + 1}'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: context.primaryTextColor.withOpacity(canModify ? 0.5 : 0.3),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Add this line
    bool canModifySettings = _timerService.timerState == TimerState.stopped;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.backgroundColor,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Black section - top half
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.blackSectionColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [
                        // AppBar
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            child: Row(
                              children: [
                                // Back arrow
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                // Title in center
                                Expanded(
                                  child: Text(
                                    _timerService.currentSessionType == SessionType.work
                                        ? 'Productivity Timer'.tr()
                                        : 'Break Time'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Reset button
                                if (_timerService.timerState != TimerState.stopped)
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Reset Timer'),
                                          content: Text('Are you sure you want to reset the timer?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _resetTimer();
                                              },
                                              child: Text('Reset'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Center content in black section - Circular Progress
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Circular Progress Indicator
                                Container(
                                  width: 250,
                                  height: 250,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Background circle (white border)
                                      Container(
                                        width: 250,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 25,
                                          ),
                                        ),
                                      ),
                                      // Progress circle
                                      Container(
                                        width: 250,
                                        height: 250,
                                        child: CustomPaint(
                                          painter: CircularProgressPainter(
                                            progress: _timerService.progress,
                                            strokeWidth: 12,
                                            color: _timerService.currentSessionType == SessionType.work
                                                ? AppColors.accent
                                                : Colors.green,
                                            radius: 125,
                                            borderOffset: 25,
                                          ),
                                        ),
                                      ),
                                      // Center content
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Timer display
                                          Text(
                                            _timerService.timeDisplay,  // No $ needed - it's already a getter
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Session counter
                                          Text(
                                            '${_timerService.currentSession}/${_timerService.totalSessions}' + 'sessions'.tr(),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
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
                  ),

                  // White section - bottom half
                  Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: double.infinity,
                    color: context.cardBackgroundColor,
                    padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 24),
                    child: Column(
                      children: [
                        // Timer Setup title
                        Text(
                          'Timer Setup'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: context.primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Main row with left containers and right sessions
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left column - Work Session and Break Duration
                                  Expanded(
                                    flex: 7,
                                    child: Column(
                                      children: [
                                        // Work Session Duration container
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: context.cardBackgroundColor,
                                            borderRadius: BorderRadius.circular(15),
                                            boxShadow: context.isDarkMode ? [] : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                            border: context.isDarkMode ? Border.all(
                                              color: context.borderColor,
                                              width: 1,
                                            ) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Work Session header
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/svg/worked.svg',
                                                    width: 20,
                                                    height: 20,
                                                    colorFilter: ColorFilter.mode(
                                                      context.primaryTextColor,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Work Session Duration'.tr(),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: context.primaryTextColor,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // Min/Plus buttons with time display
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _buildRoundButton(
                                                    icon: Icons.remove,
                                                    enabled: canModifySettings && _timerService.workSessionMinutes > 1,
                                                    onPressed: () {
                                                      if (_timerService.workSessionMinutes > 1) {
                                                        setState(() {
                                                          _timerService.workSessionMinutes--;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        '${_timerService.workSessionMinutes}:00',
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          color: context.primaryTextColor,
                                                          fontSize: 28,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  _buildRoundButton(
                                                    icon: Icons.add,
                                                    enabled: canModifySettings,
                                                    onPressed: () {
                                                      setState(() {
                                                        _timerService.workSessionMinutes++;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Break Duration container
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode
                                                ? const Color(0x407AE9FF).withOpacity(0.3)
                                                : const Color(0x407AE9FF),
                                            borderRadius: BorderRadius.circular(15),
                                            border: context.isDarkMode ? Border.all(
                                              color: context.borderColor,
                                              width: 1,
                                            ) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // Break Duration header
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // SVG icon
                                                  SvgPicture.asset(
                                                    'assets/svg/break.svg',
                                                    width: 20,
                                                    height: 20,
                                                    colorFilter: ColorFilter.mode(
                                                      context.primaryTextColor,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Break Duration'.tr(),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: context.primaryTextColor,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // Min/Plus buttons with time display
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _buildRoundButton(
                                                    icon: Icons.remove,
                                                    enabled: canModifySettings && _timerService.breakDurationMinutes > 1,
                                                    onPressed: () {
                                                      if (_timerService.breakDurationMinutes > 1) {
                                                        setState(() {
                                                          _timerService.breakDurationMinutes--;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        '${_timerService.breakDurationMinutes}:00',
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          color: context.primaryTextColor,
                                                          fontSize: 28,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  _buildRoundButton(
                                                    icon: Icons.add,
                                                    enabled: canModifySettings,
                                                    onPressed: () {
                                                      setState(() {
                                                        _timerService.breakDurationMinutes++;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Right column - Sessions container
                                  Expanded(
                                    flex: 3,
                                    child: Column(

                                      children: [
                                        Container(
                                          height: 250,
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode
                                                ? const Color(0x40FFAA85).withOpacity(0.3)
                                                : const Color(0x40FFAA85),
                                            borderRadius: BorderRadius.circular(15),
                                            border: context.isDarkMode ? Border.all(
                                              color: context.borderColor,
                                              width: 1,
                                            ) : null,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Sessions header
                                              Column(
                                                children: [
                                                  // SVG icon and text
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      SvgPicture.asset(
                                                        'assets/svg/sessions.svg',
                                                        width: 16,
                                                        height: 16,
                                                        colorFilter: ColorFilter.mode(
                                                          context.primaryTextColor,
                                                          BlendMode.srcIn,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Sessions'.tr(),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          color: context.primaryTextColor,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              // Session counter
                                              _buildSessionCounter(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Positioned button overlapping both sections
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5 - 20,
                left: (MediaQuery.of(context).size.width - 100) / 2,
                child: Container(
                  width: 100,
                  height: 35,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? context.backgroundColor : context.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(55),
                    border: Border.all(
                      color: context.isDarkMode ? context.cardBackgroundColor : context.backgroundColor,
                      width: 4,
                    ),
                  ),
                  child: TextButton(
                    onPressed: _onButtonPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _buttonIcon,
                          color: context.primaryTextColor,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _buttonText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: context.primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}