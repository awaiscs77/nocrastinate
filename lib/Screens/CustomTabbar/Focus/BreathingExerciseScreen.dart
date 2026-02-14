import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class BreathingPattern {
  final String name;
  final int inhale;
  final int hold;
  final int exhale;
  final String icon;

  BreathingPattern({
    required this.name,
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.icon,
  });
}

class BreathingExerciseScreen extends StatefulWidget {
  final bool isRelaxType;
  final bool isFromMoodCheckin;

  const BreathingExerciseScreen({
    Key? key,
    required this.isRelaxType,
    this.isFromMoodCheckin = false,
  }) : super(key: key);

  @override
  _BreathingExerciseScreenState createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int? selectedMoodIndex;
  int remainingTime = 120; // 2:00 in seconds
  int totalTime = 120; // For the time setter
  Timer? timer;
  Timer? breathingTimer;
  bool isHolding = false;
  bool showCompletionMessage = false;
  int currentPatternIndex = 0;
  bool isExerciseActive = false;
  String currentPhase = 'Inhale'; // 'Inhale', 'Hold', 'Exhale'
  int phaseTime = 0;
  int totalExerciseTime = 0;

  // Animation controller for breathing circle
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;

  // For background timer tracking
  DateTime? exerciseStartTime;
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  // Define all breathing patterns
  final List<BreathingPattern> breathingPatterns = [
    BreathingPattern(
      name: 'Focus'.tr(),
      inhale: 4,
      hold: 4,
      exhale: 4,
      icon: 'assets/svg/focusTarget.svg',
    ),
    BreathingPattern(
      name: 'Relax'.tr(),
      inhale: 4,
      hold: 6,
      exhale: 7,
      icon: 'assets/svg/relaxTarget.svg',
    ),
    BreathingPattern(
      name: 'Lung Health'.tr(),
      inhale: 5,
      hold: 5,
      exhale: 5,
      icon: 'assets/svg/lungTarget.svg',
    ),
    BreathingPattern(
      name: 'Deep Breath'.tr(),
      inhale: 6,
      hold: 4,
      exhale: 8,
      icon: 'assets/svg/lungTarget.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _requestNotificationPermission();

    // Initialize animation controller
    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingAnimation = Tween<double>(begin: 200.0, end: 240.0).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isRelaxType) {
      setState(() {
        currentPatternIndex = 1;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    breathingTimer?.cancel();
    _breathingAnimationController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App went to background
      if (isExerciseActive) {
        _showOngoingNotification();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      if (isExerciseActive && exerciseStartTime != null) {
        _syncTimerWithElapsedTime();
        _cancelNotification();
      }
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'breathing_exercise',
      'Breathing Exercise',
      channelDescription: 'Ongoing breathing exercise notification',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin?.show(
      0,
      'Breathing Exercise in Progress',
      'Current phase: $currentPhase - Keep breathing...',
      platformChannelSpecifics,
    );
  }

  // Update notification with current phase
  Future<void> _updateNotification() async {
    if (isExerciseActive) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'breathing_exercise',
        'Breathing Exercise',
        channelDescription: 'Ongoing breathing exercise notification',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin?.show(
        0,
        'Breathing Exercise in Progress',
        'Current phase: $currentPhase ($phaseTime seconds remaining)',
        platformChannelSpecifics,
      );
    }
  }

  // Cancel notification
  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin?.cancel(0);
  }

  // Show completion notification
  Future<void> _showCompletionNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'breathing_complete',
      'Breathing Complete',
      channelDescription: 'Breathing exercise completion notification',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin?.show(
      1,
      'Breathing Exercise Complete! 🎉',
      'Great job! You completed your breathing session.',
      platformChannelSpecifics,
    );
  }

  // Animate circle based on phase
  void _animateCircle(String phase, int duration) {
    _breathingAnimationController.duration = Duration(seconds: duration);

    if (phase == 'Inhale') {
      // Expand circle
      _breathingAnimationController.forward(from: 0.0);
    } else if (phase == 'Hold') {
      // Keep at current size (expanded or contracted)
      // Do nothing, maintain current animation value
    } else if (phase == 'Exhale') {
      // Contract circle
      _breathingAnimationController.reverse(from: 1.0);
    }
  }

  // Sync timer when returning from background
  void _syncTimerWithElapsedTime() {
    if (exerciseStartTime == null) return;

    final elapsed = DateTime.now().difference(exerciseStartTime!).inSeconds;

    if (elapsed >= totalTime) {
      // Exercise should be complete
      stopBreathingExercise();
      showTaskCompleted();
      return;
    }

    // Update total exercise time
    totalExerciseTime = elapsed;

    // Calculate which phase we should be in
    final cycleTime = currentPattern.inhale + currentPattern.hold + currentPattern.exhale;
    final timeInCycle = elapsed % cycleTime;

    if (timeInCycle < currentPattern.inhale) {
      currentPhase = 'Inhale';
      phaseTime = currentPattern.inhale - timeInCycle;
      _animateCircle('Inhale', phaseTime);
    } else if (timeInCycle < currentPattern.inhale + currentPattern.hold) {
      currentPhase = 'Hold';
      phaseTime = currentPattern.inhale + currentPattern.hold - timeInCycle;
      _animateCircle('Hold', phaseTime);
    } else {
      currentPhase = 'Exhale';
      phaseTime = cycleTime - timeInCycle;
      _animateCircle('Exhale', phaseTime);
    }

    setState(() {});
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        t.cancel();
        showTaskCompleted();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  void startBreathingExercise() {
    setState(() {
      isExerciseActive = true;
      currentPhase = 'Inhale';
      phaseTime = currentPattern.inhale;
      totalExerciseTime = 0;
      exerciseStartTime = DateTime.now();
    });

    // Start inhale animation
    _animateCircle('Inhale', currentPattern.inhale);

    // Enable wakelock to keep screen on
    WakelockPlus.enable();

    breathingTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        phaseTime--;
        totalExerciseTime++;

        // Check if we've reached the total time
        if (totalExerciseTime >= totalTime) {
          stopBreathingExercise();
          showTaskCompleted();
          _showCompletionNotification();
          return;
        }

        // Move to next phase when current phase time is up
        if (phaseTime <= 0) {
          if (currentPhase == 'Inhale') {
            currentPhase = 'Hold';
            phaseTime = currentPattern.hold;
            _animateCircle('Hold', currentPattern.hold);
          } else if (currentPhase == 'Hold') {
            currentPhase = 'Exhale';
            phaseTime = currentPattern.exhale;
            _animateCircle('Exhale', currentPattern.exhale);
          } else if (currentPhase == 'Exhale') {
            currentPhase = 'Inhale';
            phaseTime = currentPattern.inhale;
            _animateCircle('Inhale', currentPattern.inhale);
          }

          // Update notification with new phase
          _updateNotification();
        }
      });
    });
  }

  void stopBreathingExercise() {
    breathingTimer?.cancel();
    _breathingAnimationController.reset();
    WakelockPlus.disable();
    _cancelNotification();

    setState(() {
      isExerciseActive = false;
      currentPhase = 'Inhale';
      phaseTime = 0;
      totalExerciseTime = 0;
      exerciseStartTime = null;
    });
  }

  void showTaskCompleted() {
    setState(() {
      showCompletionMessage = true;
    });

    Timer(const Duration(seconds: 3), () {
      setState(() {
        showCompletionMessage = false;
      });
    });
  }

  void _handleBackNavigation() {
    if (widget.isFromMoodCheckin) {
      // Navigate to Home screen
      Get.offAllNamed('/home'); // or use your home route name
      // Alternative: Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      // Normal back navigation
      Navigator.pop(context);
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void increaseTime() {
    if (!isExerciseActive) {
      setState(() {
        totalTime += 60; // Add 1 minute
        remainingTime = totalTime;
      });
    }
  }

  void decreaseTime() {
    if (!isExerciseActive && totalTime > 60) { // Minimum 1 minute
      setState(() {
        totalTime -= 60; // Subtract 1 minute
        remainingTime = totalTime;
      });
    }
  }

  void nextPattern() {
    if (!isExerciseActive) {
      setState(() {
        currentPatternIndex = (currentPatternIndex + 1) % breathingPatterns.length;
      });
    }
  }

  void previousPattern() {
    if (!isExerciseActive) {
      setState(() {
        currentPatternIndex = (currentPatternIndex - 1 + breathingPatterns.length) % breathingPatterns.length;
      });
    }
  }

  BreathingPattern get currentPattern => breathingPatterns[currentPatternIndex];

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('MMM dd').format(DateTime.now());

    // Get theme-aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFF3F3F3);
    final appBarBackgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFF3F3F3);
    final timerTextColor = isDarkMode ? Colors.white : const Color(0xFF023E8A);
    final holdButtonColor = isDarkMode ? const Color(0xFF303030) : const Color(0xFF1F1F1F);
    final holdButtonTextColor = Colors.white;
    final bottomContainerColor = isDarkMode ? const Color(0xFF303030) : const Color(0xFF1F1F1F);
    final separatorColor = isDarkMode ? const Color(0xFF505050) : const Color(0xFFF3F3F3);
    final timeSetterButtonColor = isDarkMode ? const Color(0xFF505050) : const Color(0xFFF3F3F3);
    final timeSetterIconColor = isDarkMode ? Colors.white : const Color(0xFF1F1F1F);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (isExerciseActive) {
              // Show confirmation dialog if exercise is active
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exercise in Progress'),
                  content: const Text('Are you sure you want to exit? Your progress will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        stopBreathingExercise();
                        Navigator.pop(context);
                        _handleBackNavigation();
                      },
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
            } else {
              _handleBackNavigation();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            child: SvgPicture.asset(
              'assets/svg/WhiteRoundBGBack.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Breathing'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1F1F1F),
          ),
        ),
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: SafeArea(
              child: Stack(
                children: [
                  // Main content centered vertically
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer display - shows phase time during exercise or remaining time
                        Text(
                          isExerciseActive
                              ? phaseTime.toString()
                              : formatTime(totalTime - totalExerciseTime),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: timerTextColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Breathing circle with animation
                        AnimatedBuilder(
                          animation: _breathingAnimation,
                          builder: (context, child) {
                            final size = isExerciseActive
                                ? _breathingAnimation.value
                                : 200.0;

                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: holdButtonColor,
                                borderRadius: BorderRadius.circular(size / 2),
                              ),
                              child: Center(
                                child: Text(
                                  isExerciseActive ? currentPhase.tr() : 'Ready'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: holdButtonTextColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        // Start/Stop button
                        GestureDetector(
                          onTap: () {
                            if (isExerciseActive) {
                              stopBreathingExercise();
                            } else {
                              startBreathingExercise();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            decoration: BoxDecoration(
                              color: isExerciseActive ? Colors.red : Colors.blue,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              isExerciseActive ? 'Stop'.tr() : 'Start'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Completion message
                  if (showCompletionMessage)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Task Done! 🎉',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
          // Bottom container without SafeArea
          Container(
            decoration: BoxDecoration(
              color: bottomContainerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Line separator
                Container(
                  height: 4,
                  width: 32,
                  color: separatorColor,
                ),
                const SizedBox(height: 20),
                // Navigation row with current pattern
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (!isExerciseActive) {
                      // Detect swipe direction
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! > 0) {
                          // Swipe right - go to previous pattern
                          previousPattern();
                        } else if (details.primaryVelocity! < 0) {
                          // Swipe left - go to next pattern
                          nextPattern();
                        }
                      }
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left arrow
                      GestureDetector(
                        onTap: previousPattern,
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: isExerciseActive ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                      ),
                      // Center container with current pattern
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              currentPattern.icon,
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentPattern.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right arrow
                      GestureDetector(
                        onTap: nextPattern,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: isExerciseActive ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Breathing pattern row - now dynamic
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Inhale container
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/inhale.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Inhale'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentPattern.inhale}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Hold container
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/stop.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hold'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentPattern.hold}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Exhale container
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/exhale.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Exhale'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currentPattern.exhale}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Time setter row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minus button
                    GestureDetector(
                      onTap: decreaseTime,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: timeSetterButtonColor,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          Icons.remove,
                          color: isExerciseActive ? Colors.grey : timeSetterIconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Time display
                    Text(
                      formatTime(totalTime),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Plus button
                    GestureDetector(
                      onTap: increaseTime,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: timeSetterButtonColor,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          Icons.add,
                          color: isExerciseActive ? Colors.grey : timeSetterIconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                // Add bottom padding for devices without safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}