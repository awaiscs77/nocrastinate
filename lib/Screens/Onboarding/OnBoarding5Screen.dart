import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nocrastinate/Screens/Onboarding/ProcessingPopupScreen.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager

import '../../ApiServices/OnBoardingServices.dart';
import 'Onboarding6Screen.dart';

class Onboarding5Screen extends StatefulWidget {
  const Onboarding5Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding5Screen> createState() => _Onboarding5ScreenState();
}

class _Onboarding5ScreenState extends State<Onboarding5Screen> {
  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];

  final List<String> questions = [
    'felt nervous, anxious?',
    'had trouble relaxing?',
    'felt easily annoyed, irritated?',
    'felt as if something awful would happen?',
    'felt depressed, hopeless?',
    'felt tired or low on energy?',
    'had trouble concentrating?',
  ];

  final List<Map<String, String>> options = [
    {'text': 'Not at all', 'icon': 'assets/svg/notall.svg'},
    {'text': 'Sometimes', 'icon': 'assets/svg/Sometimes.svg'},
    {'text': 'Pretty often', 'icon': 'assets/svg/often.svg'},
    {'text': 'All the time', 'icon': 'assets/svg/all.svg'},
  ];

  @override
  void initState() {
    super.initState();
    selectedAnswers = List.filled(questions.length, null);
  }

  void selectAnswer(int optionIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = optionIndex;
    });
  }

  Future<void> nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      bool success = await OnboardingService.saveMentalHealthAssessment(selectedAnswers);
      if (success) {
        print('Mental health assessment saved successfully');
        print('All questions completed: $selectedAnswers');
      } else {
        print('Failed to save mental health assessment');
        // You might want to show an error dialog here
      }
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.blackSectionColor,
      body: Column(
        children: [
          // Top section with SafeArea
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: previousQuestion,
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent, // Using theme accent color
                          ),
                        ),
                      ),
                      Container(
                        width: 84,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.darkSecondaryBackground
                              : Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(55),
                        ),
                        child: Center(
                          child: Text(
                            '4 of 4',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'Over the last month,\nhow often have you',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      questions[currentQuestionIndex],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent, // Using theme accent color
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom container that extends to the very bottom
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        'We\'re here to understand your mental space better.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),

                      // Dynamic Options
                      ...options.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> option = entry.value;
                        bool isSelected = selectedAnswers[currentQuestionIndex] == index;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          height: 65,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : context.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? null
                                : Border.all(
                              color: context.borderColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => selectAnswer(index),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      option['icon']!,
                                      color: isSelected ? Colors.white : null,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option['text']!,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : context.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      isSelected
                                          ? 'assets/svg/check.svg'
                                          : 'assets/svg/uncheck.svg',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: 40),

                      // Progress Indicator with Dashes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: questions.asMap().entries.map((entry) {
                          int index = entry.key;
                          return Container(
                            width: 16,
                            height: 6,
                            margin: EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: index == currentQuestionIndex
                                  ? AppColors.accent
                                  : index < currentQuestionIndex
                                  ? AppColors.accent
                                  : context.primaryTextColor.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 20),

                      // Next Button
                      SizedBox(
                        width: 138,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: currentQuestionIndex == questions.length - 1
                              ? () async {
                            // Save mental health assessment before showing processing screen
                            bool success = await OnboardingService.saveMentalHealthAssessment(selectedAnswers);
                            if (success) {
                              final result = await showProcessingScreen(context);
                              if (result == true) {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => Onboarding6Screen())
                                );
                              }
                            } else {
                              // Show error message or handle failure
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save assessment. Please try again.')),
                              );
                            }
                          }
                              : selectedAnswers[currentQuestionIndex] != null
                              ? nextQuestion
                              : () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.isDarkMode
                                ? Colors.white
                                :context.blackSectionColor,
                            disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            currentQuestionIndex == questions.length - 1 ? 'Finish' : 'Next',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode ? context.backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Add bottom padding to account for safe area
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}