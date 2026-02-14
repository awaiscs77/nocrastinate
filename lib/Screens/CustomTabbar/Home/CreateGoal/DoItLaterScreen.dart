import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/CostBenefit/BenefitAndCostScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfHappy/PositiveExperienceScreen.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
// Import your theme manager
import 'package:nocrastinate/ThemeManager.dart';

class DoItLaterScreen extends StatefulWidget {

  @override
  _DoItLaterScreenState createState() => _DoItLaterScreenState();
}

class _DoItLaterScreenState extends State<DoItLaterScreen> {

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _currentLength = 0;
  final int _maxLength = 250;

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
  @override
  Widget build(BuildContext context) {
    // Get today's date in the format "Feb 28"
    String todayDate = DateFormat('MMM dd').format(DateTime.now());

    return Scaffold(
      resizeToAvoidBottomInset: true, // This is the default setting
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.primaryTextColor),
        title: Text(
          'Life Goals',
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
                      '"Learn Piano"',
                      textAlign: TextAlign.start,
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
                    width: 182,
                    height: 33,
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(35),
                      border: context.isDarkMode
                          ? Border.all(color: context.borderColor, width: 0.5)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/progress.svg',
                          colorFilter: ColorFilter.mode(
                              context.primaryTextColor,
                              BlendMode.srcIn
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last Progress',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          todayDate,
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
                    width: 182,
                    height: 33,
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(35),
                      border: context.isDarkMode
                          ? Border.all(color: context.borderColor, width: 0.5)
                          : null,
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
                              BlendMode.srcIn
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Target Date',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          todayDate,
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
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Why are you not able to do a\ntask on your goal reminder?'),
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
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.borderColor,
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
                        hintText: 'Write something...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: context.secondaryTextColor,
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
                        color: context.secondaryTextColor,
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
                  width: 240,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle confirm mood action
                      // Add your navigation or confirmation logic here
                      Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => BenefitAndCostScreen(behaviorToEvaluate: '',))
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.isDarkMode
                          ? AppColors.darkPrimaryText
                          : const Color(0xFF1F1F1F),
                      disabledBackgroundColor: context.isDarkMode
                          ? AppColors.darkPrimaryText.withOpacity(0.3)
                          : const Color(0xFF1F1F1F).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/backLogo.svg',
                          colorFilter: ColorFilter.mode(
                              context.isDarkMode
                                  ? AppColors.darkBackground
                                  : Colors.white,
                              BlendMode.srcIn
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back to Home',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: context.isDarkMode
                                ? AppColors.darkBackground
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}