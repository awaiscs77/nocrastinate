import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager

import 'Goal3Screen.dart';
import 'package:easy_localization/easy_localization.dart';

class Goal6Screen extends StatefulWidget {
  final Map<String, dynamic> goalData;
  final String noProgressReason;

  const Goal6Screen({
    Key? key,
    required this.goalData,
    required this.noProgressReason,
  }) : super(key: key);

  @override
  _Goal6ScreenState createState() => _Goal6ScreenState();
}

class _Goal6ScreenState extends State<Goal6Screen> {
  int? selectedMoodIndex;

  @override
  void initState() {
    super.initState();
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

  String _getMoodLabel(int index) {
    switch (index) {
      case 0: return 'Terrible';
      case 1: return 'Sad';
      case 2: return 'Neutral';
      case 3: return 'Happy';
      case 4: return 'Amazing';
      default: return '';
    }
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
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
            // Top content (Goal title and progress info)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
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

            // Center content container (Question and Mood buttons)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // How are you feeling text with bold "feel"
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(text: '${'How do you'.tr()} '),
                            TextSpan(
                              text: 'feel'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' ${'about it?'.tr()}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Mood buttons row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMoodButton(
                            index: 0,
                            imagePath: 'assets/Terrible.png',
                            label: 'Terrible',
                          ),
                          _buildMoodButton(
                            index: 1,
                            imagePath: 'assets/sad.png',
                            label: 'Sad',
                          ),
                          _buildMoodButton(
                            index: 2,
                            imagePath: 'assets/neutral.png',
                            label: 'Neutral',
                          ),
                          _buildMoodButton(
                            index: 3,
                            imagePath: 'assets/happy.png',
                            label: 'Happy',
                          ),
                          _buildMoodButton(
                            index: 4,
                            imagePath: 'assets/amazing.png',
                            label: 'Amazing',
                          ),
                        ],
                      ),
                    ],
                  ),
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
                          noProgressReason: widget.noProgressReason,
                          selectedMood: selectedMoodIndex != null
                              ? _getMoodLabel(selectedMoodIndex!)
                              : null,
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

  Widget _buildMoodButton({
    required int index,
    required String imagePath,
    required String label,
  }) {
    final isSelected = selectedMoodIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMoodIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryTextColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mood image
            Image.asset(
              imagePath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),

            // Mood label
            Text(
              label.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: context.primaryTextColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}