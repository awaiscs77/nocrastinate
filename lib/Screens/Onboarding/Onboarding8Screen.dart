import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nocrastinate/ThemeManager.dart'; // Import your theme manager
import 'Onboarding9Screen.dart';

class Onboarding8Screen extends StatefulWidget {
  const Onboarding8Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding8Screen> createState() => _Onboarding8ScreenState();
}

class _Onboarding8ScreenState extends State<Onboarding8Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main question text with styled spans
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                          ),
                          children: [
                            const TextSpan(text: 'You are '),
                            TextSpan(
                              text: '3x times',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                            const TextSpan(text: ' more likely to '),
                            TextSpan(
                              text: 'overcome procrastination',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.primaryTextColor,
                              ),
                            ),
                            const TextSpan(text: ' if you understand the reason behind it'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom section
            Column(
              children: [
                // Science-backed methods SVG with theme adaptation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? context.cardBackgroundColor.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SvgPicture.asset(
                      'assets/svg/review.svg',
                      // Add color filter for dark theme if needed
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Our science-backed methods are designed to help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ),

                // Next button
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: SizedBox(
                    width: 176,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => Onboarding9Screen())
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.isDarkMode
                            ? Colors.white
                            : context.blackSectionColor,
                        disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                        // Add subtle shadow for better visibility
                        shadowColor: context.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                      child:  Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode
                              ? context.backgroundColor
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}