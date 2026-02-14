import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../Manager/StreaksManager.dart';

class GratificationScreen extends StatefulWidget {
  const GratificationScreen({Key? key}) : super(key: key);

  @override
  _GratificationScreenState createState() => _GratificationScreenState();
}

class _GratificationScreenState extends State<GratificationScreen> {
  final StreaksManager _streaksManager = StreaksManager(); // Add streaks manager
  int streakCount = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      streakCount = _streaksManager.streakCount;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
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
          'Mood Check-in'.tr(),
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Balloon SVG
                    SvgPicture.asset(
                      'assets/svg/baloon.svg',
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        context.primaryTextColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Good Job! text
                    Text(
                      'Good Job!'.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // You've completed Mood Check-in text
                    Text(
                      "You've completed Mood Check-in".tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Streak container
                    Container(
                      decoration: BoxDecoration(
                        color: context.primaryTextColor,
                        borderRadius: BorderRadius.circular(55),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                        '🔥 $streakCount ${'Day Streak'.tr()}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: context.isDarkMode ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section with date and finish button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Current date
                  Text(
                    getCurrentDateTime(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: context.primaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Finish button
                  GestureDetector(
                    onTap: () async {
                      // Goal item action
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                            (Route<dynamic> route) => false, // Remove all previous routes
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
                          'Finish'.tr(),
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}