import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/CostBenefit/BenefitAndCostScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfHappy/PositiveExperienceScreen.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager

import 'Goal4Screen.dart';
import 'package:easy_localization/easy_localization.dart';

class Goal3Screen extends StatefulWidget {
  final Map<String, dynamic> goalData;
  final double? effortLevel; // From Goal2Screen (Yes path)
  final String? noProgressReason; // From Goal6Screen (No path)
  final String? selectedMood; // From Goal6Screen (No path)

  const Goal3Screen({
    Key? key,
    required this.goalData,
    this.effortLevel, // Optional - present if coming from Goal2Screen
    this.noProgressReason, // Optional - present if coming from Goal6Screen
    this.selectedMood, // Optional - present if coming from Goal6Screen
  }) : super(key: key);

  @override
  _Goal3ScreenState createState() => _Goal3ScreenState();
}

class _Goal3ScreenState extends State<Goal3Screen> {


  final TextEditingController _textController = TextEditingController();
  int _currentLength = 0;
  final int _maxLength = 250;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _currentLength = _textController.text.length;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
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

  // Check which path the user came from
  bool get _isFromYesPath => widget.effortLevel != null;
  bool get _isFromNoPath => widget.noProgressReason != null;

  @override
  Widget build(BuildContext context) {
    // Extract goal data
    final String goalTitle = widget.goalData['title'] ?? 'Untitled Goal';
    final dynamic lastProgress = widget.goalData['lastProgress'];
    final dynamic targetDate = widget.goalData['targetDate'];

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
            SizedBox(height: 20,),

            Container(
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
                        TextSpan(text: 'What do you think you could do\nto improve your commitment?'.tr()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  // Combined Progress Indicator and Slider
                  const SizedBox(height: 20),
                  // Text input field
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? context.backgroundColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.primaryTextColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,  // Add this line
                      maxLength: _maxLength,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write something...'.tr(),
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: context.primaryTextColor.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        counterText: '', // Hide the default counter
                      ),
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Character count
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      '$_currentLength/$_maxLength',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // Bottom button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: SizedBox(
                width: 138,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    // Create data object to pass to Goal4Screen
                    Map<String, dynamic> sessionData = {
                      'goalData': widget.goalData,
                      'improvementPlan': _textController.text.trim(),
                    };

                    // Add data based on which path user came from
                    if (_isFromYesPath) {
                      sessionData['effortLevel'] = widget.effortLevel;
                      sessionData['hadProgress'] = true;
                    } else if (_isFromNoPath) {
                      sessionData['noProgressReason'] = widget.noProgressReason;
                      sessionData['selectedMood'] = widget.selectedMood;
                      sessionData['hadProgress'] = false;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Goal4Screen(
                          sessionData: sessionData,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryTextColor,
                    disabledBackgroundColor: context.primaryTextColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Next'.tr(),
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