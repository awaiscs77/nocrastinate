import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/CostBenefit/BenefitAndCostScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfHappy/PositiveExperienceScreen.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager
import 'package:easy_localization/easy_localization.dart';

import 'Goal3Screen.dart';

class Goal2Screen extends StatefulWidget {
  final Map<String, dynamic> goalData;

  const Goal2Screen({
    Key? key,
    required this.goalData,
  }) : super(key: key);

  @override
  _Goal2ScreenState createState() => _Goal2ScreenState();
}

class _Goal2ScreenState extends State<Goal2Screen> {

  double _sliderValue = 85.0; // Default value for the slider

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
                           TextSpan(text: '${'How much'.tr()} '),
                          TextSpan(
                            text: 'effort'.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.primaryTextColor,
                            ),
                          ),
                           TextSpan(text: ' ${'did you put into it?'.tr()}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    // Combined Progress Indicator and Slider
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 68,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Linear Percent Indicator
                                IgnorePointer(
                                  child: LinearPercentIndicator(
                                    width: MediaQuery.of(context).size.width - 68,
                                    animation: false,
                                    lineHeight: 8.0,
                                    animationDuration: 0,
                                    percent: _sliderValue / 100,
                                    backgroundColor: context.isDarkMode
                                        ? const Color(0xFF505050)
                                        : const Color(0xFFD9D9D9),
                                    progressColor: context.primaryTextColor,
                                    barRadius: const Radius.circular(4),
                                  ),
                                ),
                                // Custom Slider positioned on top
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.transparent,
                                    inactiveTrackColor: Colors.transparent,
                                    trackHeight: 8.0,
                                    thumbColor: const Color(0xFF023E8A),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                                    overlayColor: const Color(0xFF023E8A).withOpacity(0.12),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                                  ),
                                  child: Slider(
                                    value: _sliderValue,
                                    min: 0.0,
                                    max: 100.0,
                                    onChanged: (double value) {
                                      setState(() {
                                        _sliderValue = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Slider labels
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 68,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'A little'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF023E8A),
                                  ),
                                ),
                                Text(
                                  'A lot'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF023E8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    // Handle confirm mood action
                    // Add your navigation or confirmation logic here
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Goal3Screen(
                          goalData: widget.goalData,
                          effortLevel: _sliderValue,
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