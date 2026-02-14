import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager

import '../../../../ApiServices/CreateGoalServices.dart';
import 'Goal2Screen.dart';
import 'Goal5Screen.dart';

class Goal1Screen extends StatefulWidget {
  final Map<String, dynamic> goalData;

  const Goal1Screen({
    Key? key,
    required this.goalData,
  }) : super(key: key);

  @override
  _Goal1ScreenState createState() => _Goal1ScreenState();
}

class _Goal1ScreenState extends State<Goal1Screen> {
  final CreateGoalServices _goalService = CreateGoalServices();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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

  void _handleCompleteGoal() async {
    try {
      final goalId = widget.goalData['id'];
      if (goalId != null) {
        bool success = await _goalService.completeGoal(goalId);
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back or to a completion screen
          Navigator.of(context).pop();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to mark goal as completed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error completing goal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleUpdateProgress() async {
    try {
      final goalId = widget.goalData['id'];
      if (goalId != null) {
        bool success = await _goalService.updateLastProgress(goalId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract goal data
    final String goalTitle = widget.goalData['title'] ?? 'Untitled Goal';
    final String goalDescription = widget.goalData['description'] ?? '';
    final dynamic lastProgress = widget.goalData['lastProgress'];
    final dynamic targetDate = widget.goalData['targetDate'];
    final bool isCompleted = widget.goalData['isCompleted'] ?? false;

    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting
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
                    height: 33,
                    width: 220,
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
                    height: 33,
                    width: 188,
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
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor,
                          height: 1.4,
                        ),
                        children: [
                           TextSpan(text: '${'Over the'.tr()} '),
                          TextSpan(
                            text: 'past week'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.primaryTextColor,
                            ),
                          ),
                           TextSpan(text: ', have you done\nanything towards your goal?'.tr()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Yes/No buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // No button
                        Container(
                          width: 118,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(55),
                            border: Border.all(
                              color: context.borderColor,
                              width: 1,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle No button action - pass goal data to Goal5Screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Goal5Screen(
                                    goalData: widget.goalData,
                                  ),
                                ),
                              );
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
                              'No'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.primaryTextColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Yes button
                        Container(
                          width: 118,
                          height: 45,
                          decoration: BoxDecoration(
                            color: context.primaryTextColor,
                            borderRadius: BorderRadius.circular(55),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // Update progress when user says Yes
                              _handleUpdateProgress();

                              // Handle Yes button action - pass goal data to Goal2Screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Goal2Screen(
                                    goalData: widget.goalData,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryTextColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(55),
                              ),
                            ),
                            child: Text(
                              'Yes'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.backgroundColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: isCompleted ? null : _handleCompleteGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? Colors.green
                        : const Color(0xFF023E8A),
                    disabledBackgroundColor: Colors.green.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(55),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.check,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isCompleted
                            ? 'Goal Completed'.tr()
                            : 'Mark goal as completed'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
    );
  }
}