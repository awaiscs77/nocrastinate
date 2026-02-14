import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/ThemeManager.dart';
import '../../ApiServices/AuthService.dart';
import '../../ApiServices/OnBoardingServices.dart';
import 'LoginPopupScreen.dart';
import 'Onboarding2Screen.dart';

class SignUpPopupScreen extends StatefulWidget {
  const SignUpPopupScreen({Key? key}) : super(key: key);

  @override
  _SignUpPopupScreenState createState() => _SignUpPopupScreenState();
}

class _SignUpPopupScreenState extends State<SignUpPopupScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Handle Google Sign Up
  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google Sign Up...');
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        print('Google Sign Up successful!');

        // Check if this is a new user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        print('Is new user: $isNewUser');

        if (isNewUser) {
          // Initialize onboarding for new user
          final success = await OnboardingService.initializeUserOnboarding();
          if (success) {
            print('Onboarding initialized for new user');

            // Navigate to onboarding flow
            Navigator.of(context).pop(); // Close the popup
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Onboarding2Screen(),
              ),
            );
          } else {
            throw Exception('Failed to initialize user onboarding');
          }
        } else {
          // Existing user - check if onboarding is completed
          final isOnboardingCompleted = await OnboardingService.isOnboardingCompleted();

          Navigator.of(context).pop(); // Close the popup

          if (isOnboardingCompleted) {
            // Go to main app
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Continue onboarding
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Onboarding2Screen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Google Sign Up Error: $e');
      if (mounted) {
        _showErrorDialog('Google Sign Up Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle Apple Sign Up (iOS only)
  Future<void> _handleAppleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Apple Sign Up...');
      final userCredential = await _authService.signInWithApple();

      if (userCredential != null && mounted) {
        print('Apple Sign Up successful!');

        // Check if this is a new user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        print('Is new user: $isNewUser');

        if (isNewUser) {
          // Initialize onboarding for new user
          final success = await OnboardingService.initializeUserOnboarding();
          if (success) {
            print('Onboarding initialized for new user');

            // Navigate to onboarding flow
            Navigator.of(context).pop(); // Close the popup
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Onboarding2Screen(),
              ),
            );
          } else {
            throw Exception('Failed to initialize user onboarding');
          }
        } else {
          // Existing user - check if onboarding is completed
          final isOnboardingCompleted = await OnboardingService.isOnboardingCompleted();

          Navigator.of(context).pop(); // Close the popup

          if (isOnboardingCompleted) {
            // Go to main app
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Continue onboarding
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Onboarding2Screen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Apple Sign Up Error: $e');
      if (mounted) {
        _showErrorDialog('Apple Sign Up Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: 386 + MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Top handle
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.primaryTextColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logo
                    SvgPicture.asset(
                      context.isDarkMode
                          ? 'assets/svg/whiteLogo.svg'
                          : 'assets/svg/blackLogo.svg',
                    ),

                    const SizedBox(height: 24),

                    // Welcome text (different from sign-in)
                    Text(
                      'Create your Nocrastinate account and start your journey!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Google signup button (available on both platforms)
                    Container(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.isDarkMode
                              ? context.backgroundColor
                              : const Color(0xFF1F1F1F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(55),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/svg/google.svg'),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign Up With Google',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Apple signup button (iOS only) - with conditional spacing
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAppleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.isDarkMode
                                ? context.backgroundColor
                                : const Color(0xFF1F1F1F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(55),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/svg/apple.svg'),
                              const SizedBox(width: 12),
                              const Text(
                                'Sign Up With Apple',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign in text (different from sign-up)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                            Navigator.of(context).pop(); // Close sign-up popup
                            showLoginPopup(context); // Show sign-in popup
                          },
                          child: Text(
                            'Sign in.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isLoading
                                  ? Colors.grey
                                  : const Color(0xFF023E8A),
                              fontFamily: 'Poppins',
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the sign-up popup
void showSignUpPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SignUpPopupScreen(),
  );
}

// Import this function in your LoginPopupScreen.dart
void showLoginPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const LoginPopupScreen(),
  );
}