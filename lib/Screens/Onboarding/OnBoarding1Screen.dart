import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';

import 'LoginPopupScreen.dart';
import 'Onboarding2Screen.dart';
import 'SignUpPopupScreen.dart' hide showLoginPopup;

class OnBoarding1Screen extends StatefulWidget {
  const OnBoarding1Screen({Key? key}) : super(key: key);

  @override
  _OnBoarding1ScreenState createState() => _OnBoarding1ScreenState();
}

class _OnBoarding1ScreenState extends State<OnBoarding1Screen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Show sign-up popup (different from sign-in)
  void _showSignUpPopup() {
    showSignUpPopup(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/onboarding 1.png'
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Add overlay for better text readability in dark mode
          color: context.isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.transparent,
          child: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top spacing
                  SizedBox(
                    width: 150,
                    height: 33,
                    child: ElevatedButton(
                        onPressed: () {
                          // Add your navigation logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.isDarkMode
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(55),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              child: SvgPicture.asset(
                                context.isDarkMode
                                    ? 'assets/svg/logo_white.svg' // Create white version
                                    : 'assets/svg/logo.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'nocrastinate',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1F1F1F),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                    ),
                  ),
                  Spacer(),
                  // Main content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome title - keep blue accent but ensure visibility
                      Text(
                        'Welcome to your mental\nhealth companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode
                              ? AppColors.accent.withOpacity(0.9) // Slightly transparent for dark mode
                              : const Color(0xFF023E8A),
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description text - themed
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Log & reflect on your mood with proven CBT Methodology and Self-Improvement exercises. Starting Today, let\'s focus better and accomplish your goals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF1F1F1F),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom buttons section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Get Started button - now shows sign-up popup
                        SizedBox(
                          width: 195,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _showSignUpPopup, // Changed to show sign-up popup
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.isDarkMode
                                  ? AppColors.darkSecondaryBackground
                                  : const Color(0xFF1F1F1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(55),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sign in text - shows sign-in popup
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: context.isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : const Color(0xFF1F1F1F),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showLoginPopup(context); // This shows sign-in popup
                              },
                              child: Text(
                                'Sign in.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1F1F1F),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}