import 'package:flutter/material.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/WhatIfChallenge/AfraidOfWrongScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';

import '../CostBenefit/BehaviorEvaluateScreen.dart';

class WhatIfChallengeScreen extends StatefulWidget {
  const WhatIfChallengeScreen({Key? key}) : super(key: key);

  @override
  State<WhatIfChallengeScreen> createState() => _WhatIfChallengeScreenState();
}

class _WhatIfChallengeScreenState extends State<WhatIfChallengeScreen> {

  bool isExerciseOptionsVisible = false;

  void _toggleExerciseView() {
    setState(() {
      isExerciseOptionsVisible = !isExerciseOptionsVisible;
    });
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting

      body: Stack(
        children: [
          Column(
            children: [
              // Top section - uses blackSectionColor
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.blackSectionColor, // Use theme black section color
                    borderRadius: const BorderRadius.only(
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
                                onTap: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: context.isDarkMode ? Colors.white : Colors.white, // Always white for contrast
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
                                    color: Colors.white, // Always white for contrast
                                    fontSize: 18,
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

                      // Center content in top section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                               Text(
                                'What If Challenge'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white, // Always white for contrast
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                               Text(
                                'Challenge catastrophic thinking by confronting worst-case scenarios, analyzing their likelihood, and developing coping strategies.'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white, // Always white for contrast
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
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
              ),

              Container(
                width: double.infinity,
                height: screenHeight * 0.5,
                color: context.backgroundColor,
                child: IndexedStack(
                  index: isExerciseOptionsVisible ? 1 : 0,
                  children: [
                    _buildOriginalContent(screenHeight),
                    _buildExerciseOptions(),
                  ],
                ),
              ),
            ],
          ),

          // Positioned button overlapping both sections
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5 - 20, // Half height minus half button height
            left: (MediaQuery.of(context).size.width - 200) / 2, // Center horizontally
            child: Container(
              width: 200,
              height: 40,
              decoration: BoxDecoration(
                color: context.cardBackgroundColor, // Use theme card background
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.backgroundColor, // Use theme background as border color
                  width: 4,
                ),
                boxShadow: context.isDarkMode
                    ? [
                  // Add subtle shadow for dark theme visibility
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [
                  // Light shadow for light theme
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  // Add your change exercise logic here
                  _toggleExerciseView();

                },
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
                      color: context.primaryTextColor, // Use theme text color
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Change Exercise".tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: context.primaryTextColor, // Use theme text color
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
    );
  }

  Widget _buildOriginalContent(double screenHeight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Explicitly center horizontally
        children: [
          SizedBox(height: screenHeight * 0.15), // Dynamic spacing

          // Centered text with consistent alignment
          Center(
            child: Text(
              'Avoiding something because\nof fear? Let’s challenge it'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: context.primaryTextColor,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.15), // Dynamic spacing

          // Centered button container
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => AfraidOfWrongScreen()
                    )
                );
              },
              child: Container(
                width: 148,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primaryTextColor,
                  borderRadius: BorderRadius.circular(55),
                ),
                child: Center(
                  child: Text(
                    'Continue'.tr(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: context.isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExerciseOptions() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // First horizontal image
            Image.asset("assets/gratitude_journal.png"),
            const SizedBox(height: 16),

            // First row of cells
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Clicking on exercise cells does nothing
                    // Only the "Change Exercise" button toggles the view

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BehaviorEvaluateScreen(),
                      ),
                    );
                  },
                  child: Image.asset('assets/cost_benefit_analysis.png'),
                ),
                GestureDetector(
                  onTap: () {
                    // Clicking on exercise cells does nothing
                    // Only the "Change Exercise" button toggles the view
                  },
                  child: Image.asset('assets/self_compression.png'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Second horizontal image
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WhatIfChallengeScreen(),
                  ),
                );
              },
              child: Image.asset('assets/whatifChallenge.png'),
            ),
            const SizedBox(height: 16),

            // Second row of cells
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Clicking on exercise cells does nothing
                    // Only the "Change Exercise" button toggles the view
                  },
                  child: Image.asset('assets/growthMindset.png'),
                ),
                GestureDetector(
                  onTap: () {
                    // Clicking on exercise cells does nothing
                    // Only the "Change Exercise" button toggles the view
                  },
                  child:Image.asset('assets/selfEfficacy.png'),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}