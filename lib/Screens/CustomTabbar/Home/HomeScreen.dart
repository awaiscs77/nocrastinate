import 'package:flutter/material.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/CBTScreen.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/CreateGoal/NewGoalScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/LifeGoal/Goal1Screen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/AffirmationDayScreen/AffirmationDayScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/TipScreens/TipDayScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Settings/SettingsScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../ApiServices/CreateGoalServices.dart';
import '../../../ApiServices/AuthProvider.dart';
import '../../../Manager/MoodCheckinManager.dart';
import '../../../ApiServices/MindPracticeService.dart';
import '../../../Manager/StreaksManager.dart';
import '../../../Manager/TipsManager.dart';
import '../../../Manager/AffirmationManager.dart';
import '../Focus/BreathingExerciseScreen.dart';
import 'MoodScreens/MindPracticeScreens/ExerciseDayScreen.dart';
import 'MoodScreens/CheckInBahavior/HowFeelingScreen.dart';
import 'TaskPopupScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CreateGoalServices _goalServices = CreateGoalServices();
  final TipsManager _tipsManager = TipsManager();
  final AffirmationManager _affirmationManager = AffirmationManager();
  final StreaksManager _streaksManager = StreaksManager();
  bool _isLoading = true;

  int streakCount = 0;

  final List<Map<String, dynamic>> tasks = [
    {
      'title': 'Mood Check-in',
      'image': 'assets/moodCheckin.png',
      'duration': '3 min',
      'isCompleted': false,
    },
    {
      'title': 'Daily mind practice',
      'image': 'assets/dailyMind.png',
      'duration': '1 min',
      'isCompleted': false,
    },
    {
      'title': 'Tip of the day',
      'image': 'assets/tip.png',
      'duration': '1 min',
      'isCompleted': false,
    },
    {
      'title': 'Affirmation of the day',
      'image': 'assets/affirmation.png',
      'duration': '1 min',
      'isCompleted': false,
    },
  ];

  final List<Map<String, dynamic>> diveDeepItems = [
    {
      'title': 'What is CBT?',
      'subtitle': "Learn more about CBT and it's benefits.",
      'titleColor': Colors.white,
      'descriptionColor': Colors.white70,
      'backgroundImage': 'assets/image.png'
    },
    {
      'title': 'Breathing Exercise',
      'subtitle': 'Calm yourself down with controlled breathing.',
      'titleColor': Colors.black,
      'descriptionColor': Colors.black87,
      'backgroundImage': 'assets/image2.png'
    },
  ];

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTasksStatus();
    });
  }

  Future<void> _checkTasksStatus() async {
    try {
      final results = await Future.wait([
        _getMoodCheckinStatus(),
        _getMindPracticeStatus(),
        _getTipViewStatus(),
        _getAffirmationViewStatus(),
        _initializeStreaks(),
      ]);

      if (mounted) {
        setState(() {
          final moodTaskIndex = tasks.indexWhere((task) => task['title'] == 'Mood Check-in');
          if (moodTaskIndex != -1) {
            tasks[moodTaskIndex]['isCompleted'] = results[0] as bool;
          }

          final mindPracticeTaskIndex = tasks.indexWhere((task) => task['title'] == 'Daily mind practice');
          if (mindPracticeTaskIndex != -1) {
            tasks[mindPracticeTaskIndex]['isCompleted'] = results[1] as bool;
          }

          final tipTaskIndex = tasks.indexWhere((task) => task['title'] == 'Tip of the day');
          if (tipTaskIndex != -1) {
            tasks[tipTaskIndex]['isCompleted'] = results[2] as bool;
          }

          final affirmationTaskIndex = tasks.indexWhere((task) => task['title'] == 'Affirmation of the day');
          if (affirmationTaskIndex != -1) {
            tasks[affirmationTaskIndex]['isCompleted'] = results[3] as bool;
          }

          streakCount = _streaksManager.streakCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking tasks status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _getMoodCheckinStatus() async {
    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
      return await moodManager.hasCompletedToday();
    } catch (e) {
      print('Error checking mood check-in status: $e');
      return false;
    }
  }

  Future<bool> _getMindPracticeStatus() async {
    try {
      return await MindPracticeService.hasCompletedDailyPractice();
    } catch (e) {
      print('Error checking daily mind practice status: $e');
      return false;
    }
  }

  Future<bool> _getTipViewStatus() async {
    try {
      await _tipsManager.initialize();
      return _tipsManager.hasViewedTipToday;
    } catch (e) {
      print('Error checking tip view status: $e');
      return false;
    }
  }

  Future<bool> _getAffirmationViewStatus() async {
    try {
      await _affirmationManager.initialize();
      return _affirmationManager.hasViewedAffirmationToday;
    } catch (e) {
      print('Error checking affirmation view status: $e');
      return false;
    }
  }

  Future<void> _initializeStreaks() async {
    try {
      await _streaksManager.initialize();
      await _streaksManager.updateStreakCount();
    } catch (e) {
      print('Error initializing streaks: $e');
    }
  }

  Future<void> _checkMoodCheckinStatus() async {
    final hasCompleted = await _getMoodCheckinStatus();
    if (mounted) {
      setState(() {
        final moodTaskIndex = tasks.indexWhere((task) => task['title'] == 'Mood Check-in');
        if (moodTaskIndex != -1) {
          tasks[moodTaskIndex]['isCompleted'] = hasCompleted;
        }
      });
    }
  }

  Future<void> _checkMindPracticeStatus() async {
    final hasCompleted = await _getMindPracticeStatus();
    if (mounted) {
      setState(() {
        final mindPracticeTaskIndex = tasks.indexWhere((task) => task['title'] == 'Daily mind practice');
        if (mindPracticeTaskIndex != -1) {
          tasks[mindPracticeTaskIndex]['isCompleted'] = hasCompleted;
        }
      });
    }
  }

  Future<void> _checkTipViewStatus() async {
    final hasViewed = await _getTipViewStatus();
    if (mounted) {
      setState(() {
        final tipTaskIndex = tasks.indexWhere((task) => task['title'] == 'Tip of the day');
        if (tipTaskIndex != -1) {
          tasks[tipTaskIndex]['isCompleted'] = hasViewed;
        }
      });
    }
  }

  Future<void> _checkAffirmationViewStatus() async {
    final hasViewed = await _getAffirmationViewStatus();
    if (mounted) {
      setState(() {
        final affirmationTaskIndex = tasks.indexWhere((task) => task['title'] == 'Affirmation of the day');
        if (affirmationTaskIndex != -1) {
          tasks[affirmationTaskIndex]['isCompleted'] = hasViewed;
        }
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, ';
    } else if (hour < 17) {
      return 'Good Afternoon, ';
    } else {
      return 'Good Evening, ';
    }
  }

  void _handleTaskTap(Map<String, dynamic> task) async {
    // Don't allow tap if still loading
    if (_isLoading) return;

    if (task['title'] == 'Mood Check-in') {
      if (task['isCompleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already completed your mood check-in for today!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HowFeelingScreen(),
        ),
      );

      if (result == true) {
        _checkMoodCheckinStatus();
      }
    } else if (task['title'] == 'Daily mind practice') {
      if (task['isCompleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already completed your daily mind practice for today!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExerciseDayScreen(),
        ),
      );

      if (result == true) {
        _checkMindPracticeStatus();
      }
    } else if (task['title'] == 'Tip of the day') {
      if (task['isCompleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already viewed your tip for today!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TipDayScreen(),
        ),
      );

      if (result == true) {
        _checkTipViewStatus();
      }
    } else if (task['title'] == 'Affirmation of the day') {
      if (task['isCompleted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already viewed your affirmation for today!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AffirmationDayScreen(),
        ),
      );

      if (result == true) {
        _checkAffirmationViewStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.blackSectionColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: context.blackSectionColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final userName = authProvider.userDisplayName.split(' ').first;

                          return Row(
                            children: [
                              Container(
                                width: 51,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(Radius.circular(55)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 10),
                                    Image.asset('assets/15.png'),
                                    const SizedBox(width: 5),
                                    Text(
                                      "$streakCount",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      userName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Image.asset('assets/homeSetting.png'),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NewGoalScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Life Goals'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.isDarkMode ? Colors.white : Colors.white,
                              ),
                            ),
                            Image.asset('assets/add.png'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _goalServices.getUserGoals(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Error loading goals',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            );
                          }

                          List<Map<String, dynamic>> goals = snapshot.data ?? [];

                          if (goals.isEmpty) {
                            return Column(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(25),
                                    onTap: () {
                                      print('New Life Goal button tapped');
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => NewGoalScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 139,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF303030),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(25),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '+ New Life Goal'.tr(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                            );
                          }

                          return Column(
                            children: goals.map((goal) {
                              String lastProgress = 'Never';
                              String targetDate = 'No target';

                              if (goal['lastProgress'] != null) {
                                lastProgress = '${'Last Progress'.tr()} ${CreateGoalServices.formatDate(goal['lastProgress'] as Timestamp)}';
                              }

                              if (goal['targetDate'] != null) {
                                targetDate = '${'Target Date'.tr()} ${CreateGoalServices.formatDate(goal['targetDate'] as Timestamp)}';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GestureDetector(
                                  onTap: () async {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => Goal1Screen(
                                          goalData: goal,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 56,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode
                                          ? AppColors.darkSecondaryBackground
                                          : const Color(0xFF303030),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  goal['title'] ?? 'Untitled Goal',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 16,
                                                    color: context.isDarkMode ? Colors.white : Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        lastProgress,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12,
                                                          color: context.isDarkMode
                                                              ? Colors.white70
                                                              : Colors.grey,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                                      width: 4,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: context.isDarkMode
                                                            ? Colors.white70
                                                            : Colors.grey,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        targetDate,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12,
                                                          color: context.isDarkMode
                                                              ? Colors.white70
                                                              : Colors.grey,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => NewGoalScreen(
                                                    isFromUpdateScreen: true,
                                                    existingGoal: goal,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Image.asset('assets/edit.png'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? context.cardBackgroundColor : context.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? context.backgroundColor : context.cardBackgroundColor,
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/dailyMind.png'),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daily Task'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.primaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              child: Column(
                                children: List.generate(tasks.length, (index) {
                                  final task = tasks[index];
                                  final isLast = index == tasks.length - 1;

                                  return AbsorbPointer(
                                    absorbing: _isLoading, // Disable interaction while loading
                                    child: Opacity(
                                      opacity: _isLoading ? 0.5 : 1.0, // Visual feedback for disabled state
                                      child: GestureDetector(
                                        onTap: () => _handleTaskTap(task),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              children: [
                                                const SizedBox(height: 12),
                                                _isLoading
                                                    ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: context.isDarkMode
                                                        ? Colors.white.withOpacity(0.3)
                                                        : Colors.grey.withOpacity(0.3),
                                                  ),
                                                )
                                                    : Image.asset(
                                                  !context.isDarkMode
                                                      ? (task['isCompleted']
                                                      ? 'assets/filledTick.png'
                                                      : 'assets/unfilledTick.png')
                                                      : (task['isCompleted']
                                                      ? 'assets/tick_white.png'
                                                      : 'assets/untick_white.png'),
                                                ),
                                                if (!isLast)
                                                  Container(
                                                    width: 2,
                                                    height: 20,
                                                    color: context.isDarkMode
                                                        ? (task['isCompleted'] ? Colors.white : context.cardBackgroundColor)
                                                        : context.borderColor.withOpacity(0.3),
                                                    margin: const EdgeInsets.only(top: 6, bottom: 0),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.only(top: 8, bottom: 8),
                                                padding: const EdgeInsets.all(8),
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: context.borderColor.withOpacity(0.45),
                                                    width: 0.5,
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Image.asset(task['image']),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        (task['title'] ?? '').toString().tr(),
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: context.primaryTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      task['duration'],
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w400,
                                                        color: context.primaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Dive Deeper'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.primaryTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: diveDeepItems.length,
                                itemBuilder: (context, index) {
                                  final item = diveDeepItems[index];
                                  return GestureDetector(
                                    onTap: () {
                                      if (index == 0){
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => CBTScreen(),
                                          ),
                                        );
                                      }
                                      else{
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => BreathingExerciseScreen(isRelaxType: false),
                                          ),
                                        );
                                      }

                                    },
                                    child: Container(
                                      width: MediaQuery.of(context).size.width / 2 - 40, // Full width minus left padding (20) + right padding (20) + space for next item (20)
                                      height: MediaQuery.of(context).size.width / 2 - 40,
                                      margin: EdgeInsets.only(
                                        right: index == diveDeepItems.length - 1 ? 0 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        image: DecorationImage(
                                          image: AssetImage(item['backgroundImage']),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: GestureDetector(
                                              onTap: () {
                                                // Handle info tap
                                              },
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: item['titleColor'],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 16,
                                            left: 16,
                                            right: 16,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        (item['title'] ?? '').toString().tr(),
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: item['titleColor'],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        (item['subtitle'] ?? '').toString().tr(),

                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 10,
                                                          color: item['descriptionColor'],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () {
                                                    // Handle arrow forward tap
                                                  },
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    size: 18,
                                                    color: item['titleColor'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 100), // Add some bottom padding
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
      ),
    );
  }
}