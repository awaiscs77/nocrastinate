import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/PlanActivityScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/WhatIfChallenge/WhatIfChallenge.dart';
import 'package:nocrastinate/ThemeManager.dart';

import '../../../../../ApiServices/MindPracticeService.dart';
import 'CostBenefit/BehaviorEvaluateScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class ExerciseDayScreen extends StatefulWidget {
  const ExerciseDayScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseDayScreen> createState() => _ExerciseDayScreenState();
}

class _ExerciseDayScreenState extends State<ExerciseDayScreen> {
  bool isExerciseOptionsVisible = false;
  final ScrollController _scrollController = ScrollController();
  bool hasCompletedDaily = false;
  bool isLoadingStatus = false;

  void _toggleExerciseView() {
    setState(() {
      isExerciseOptionsVisible = !isExerciseOptionsVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    // _checkDailyCompletion();
  }

  Future<void> _checkDailyCompletion() async {
    try {
      final completed = await MindPracticeService.hasCompletedDailyPractice();
      if (mounted) {
        setState(() {
          hasCompletedDaily = completed;
          isLoadingStatus = false;
        });
      }
    } catch (e) {
      print('Error checking daily completion: $e');
      if (mounted) {
        setState(() {
          isLoadingStatus = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final topSectionHeight = isSmallScreen ? screenHeight * 0.45 : screenHeight * 0.5;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Black section - top half (responsive height)
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: topSectionHeight,
                    ),
                    decoration: BoxDecoration(
                      color: context.blackSectionColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // AppBar
                        SafeArea(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: 16.0,
                            ),
                            child: Row(
                              children: [
                                // Back arrow
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                // Title in center
                                Expanded(
                                  child: Text(
                                    'Daily Mind Practice'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: screenWidth < 360 ? 16 : 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Placeholder for symmetry
                                const SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ),

                        // Center content in black section
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: 20.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Behavioral Activation'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 24 : 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Text(
                                  'An exercise to activate your daily behavior and help you achieve more with your goals and relationships.'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 13 : 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // White section - bottom half (fully flexible)
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: screenHeight - topSectionHeight,
                    ),
                    color: context.backgroundColor,
                    child: isExerciseOptionsVisible
                        ? _buildExerciseOptions(screenWidth, isSmallScreen)
                        : _buildOriginalContent(screenHeight, screenWidth, isSmallScreen),
                  ),
                ],
              ),

              // Positioned button overlapping both sections (responsive)
              Positioned(
                top: topSectionHeight - 20,
                left: (screenWidth - 200) / 2,
                child: Container(
                  width: screenWidth < 360 ? 180 : 200,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.backgroundColor,
                      width: 4,
                    ),
                  ),
                  child: TextButton(
                    onPressed: _toggleExerciseView,
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
                          Icons.refresh,
                          color: context.primaryTextColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Change Exercise".tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: context.primaryTextColor,
                            fontSize: screenWidth < 360 ? 12 : 13,
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

  Widget _buildOriginalContent(double screenHeight, double screenWidth, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isSmallScreen ? screenHeight * 0.08 : screenHeight * 0.15),

          Center(
            child: isLoadingStatus
                ? CircularProgressIndicator(color: context.primaryTextColor)
                : Text(
              hasCompletedDaily
                  ? "Great job! You've completed\nyour daily practice!".tr()
                  : 'Plan one small action today\nto boost your mood!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: context.primaryTextColor,
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? screenHeight * 0.08 : screenHeight * 0.15),

          Center(
            child: GestureDetector(
              onTap: hasCompletedDaily
                  ? null
                  : () {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => PlanActivityScreen()
                    )
                );
              },
              child: Container(
                width: 148,
                height: 40,
                decoration: BoxDecoration(
                  color: hasCompletedDaily
                      ? context.primaryTextColor.withOpacity(0.3)
                      : context.primaryTextColor,
                  borderRadius: BorderRadius.circular(55),
                ),
                child: Center(
                  child: Text(
                    hasCompletedDaily ? 'Completed'.tr() : 'Continue'.tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: hasCompletedDaily
                          ? (context.isDarkMode ? Colors.grey : Colors.grey)
                          : (context.isDarkMode ? Colors.black : Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 40 : 80),
        ],
      ),
    );
  }

  Widget _buildExerciseOptions(double screenWidth, bool isSmallScreen) {
    final horizontalPadding = screenWidth * 0.05;
    final spacing = isSmallScreen ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          SizedBox(height: isSmallScreen ? 30 : 40),

          // First horizontal image
          GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9,
                maxHeight: screenWidth * 0.4,
              ),
              child: SvgPicture.asset(
                'assets/svg/cbt.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: spacing),

          // First row of cells
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BehaviorEvaluateScreen(),
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/svg/cbt1.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: GestureDetector(
                  onTap: () {


                  },
                  child: Image.asset(
                    'assets/self_compression.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 24 : 32),

          // Second horizontal image
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WhatIfChallengeScreen(),
                ),
              );
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9,
                maxHeight: screenWidth * 0.4,
              ),
              child: Image.asset(
                'assets/whatifChallenge.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: spacing - 8),

          // Second row of cells
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Image.asset(
                    'assets/growthMindset.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Image.asset(
                    'assets/selfEfficacy.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 40 : 80),
        ],
      ),
    );
  }
}