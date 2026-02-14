import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/ThemeManager.dart';
import '../../ApiServices/AuthService.dart';

class LoginPopupScreen extends StatefulWidget {
  const LoginPopupScreen({Key? key}) : super(key: key);

  @override
  _LoginPopupScreenState createState() => _LoginPopupScreenState();
}

class _LoginPopupScreenState extends State<LoginPopupScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Handle Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google Sign In on ${Platform.operatingSystem}...');
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null) {
        print('Google Sign In successful!');
        if (mounted) {
          Navigator.of(context).pop(); // Close the popup
          Navigator.pushReplacementNamed(context, '/splash');
        }
      }
    } catch (e) {
      print('Google Sign In Error: $e');
      if (mounted) {
        _showErrorDialog('Google Sign In Failed', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle Apple Sign In (iOS only)
  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithApple();

      if (userCredential != null) {
        if (mounted) {
          Navigator.of(context).pop(); // Close the popup
          Navigator.pushReplacementNamed(context, '/splash');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Apple Sign In Failed', e.toString());
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

                    // Welcome text
                    Text(
                      'Welcome to Nocrastinate, let\'s start your journey!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: context.primaryTextColor,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Google login button (available on both platforms)
                    Container(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
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
                              'Continue With Google',
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

                    // Apple login button (iOS only) - with conditional spacing
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAppleSignIn,
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
                                'Continue With Apple',
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

                    // Sign in text
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
                            Navigator.pushNamed(context, '/signin');
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

// Helper function to show the popup
void showLoginPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const LoginPopupScreen(),
  );
}