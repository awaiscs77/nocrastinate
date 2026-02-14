import 'package:flutter/material.dart';
import 'package:nocrastinate/ThemeManager.dart';

import '../../ApiServices/OnBoardingServices.dart';
import '../../ApiServices/InAppPurchaseService.dart';
import 'Onboarding4Screen.dart';

class Onboarding3Screen extends StatefulWidget {
  const Onboarding3Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding3Screen> createState() => _Onboarding3ScreenState();
}

class _Onboarding3ScreenState extends State<Onboarding3Screen> {
  final List<String> tags = [
    '<18',
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    'Over 64',
  ];

  String? selectedTag;
  bool _isLoading = false;
  final InAppPurchaseService _iapService = InAppPurchaseService();

  // Group tags into rows: first row has 4 tags, second row has 3 tags
  List<List<String>> groupTagsIntoRows(List<String> tags) {
    List<List<String>> rows = [];

    // First row: 4 tags
    if (tags.length >= 4) {
      rows.add(tags.sublist(0, 4));
    }

    // Second row: remaining tags (3 tags)
    if (tags.length > 4) {
      rows.add(tags.sublist(4));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final tagRows = groupTagsIntoRows(tags);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top section with progress indicator and skip button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 64,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(55),
                        ),
                        child: Center(
                          child: Text(
                            '2 of 4',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _handleSkip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLoading
                                ? const Color(0xFF023E8A).withOpacity(0.5)
                                : const Color(0xFF023E8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Main question text - themed
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'How old are you?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle - themed
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'So we can suggest the best setup for you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Tags section - now with controlled rows and themed
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: tagRows.map((rowTags) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: rowTags.map((tag) {
                                    final isSelected = selectedTag == tag;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: GestureDetector(
                                        onTap: _isLoading ? null : () {
                                          setState(() {
                                            selectedTag = tag;
                                          });
                                        },
                                        child: Container(
                                          height: 25,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF023E8A)
                                                : context.cardBackgroundColor,
                                            borderRadius: BorderRadius.circular(55),
                                            border: context.isDarkMode && !isSelected
                                                ? Border.all(color: context.borderColor, width: 0.5)
                                                : null,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Center(
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : context.primaryTextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom section
                Column(
                  children: [
                    // Next button - themed
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: SizedBox(
                        width: 138,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.isDarkMode
                                ? Colors.white
                                : const Color(0xFF1F1F1F),
                            disabledBackgroundColor: (context.isDarkMode
                                ? Colors.white
                                : const Color(0xFF1F1F1F)).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.isDarkMode ? context.backgroundColor : Colors.white,
                              ),
                            ),
                          )
                              : Text(
                            'Next',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode ? context.backgroundColor : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNext() async {
    if (selectedTag == null) {
      _showMessage('Please select your age group');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save age group
      bool saved = await OnboardingService.saveAgeGroup(selectedTag!);

      if (saved) {
        // Navigate to next screen
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const Onboarding4Screen())
        );
      } else {
        _showMessage('Failed to save your age group. Please try again.');
      }
    } catch (e) {
      print('Error saving age group: $e');
      _showMessage('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSkip() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the skip onboarding service
      bool skipped = await OnboardingService.skipOnboarding();

      if (skipped) {
        // Check subscription status before navigating
        final subscriptionStatus = await _iapService.currentSubscription;

        if (subscriptionStatus != null &&
            subscriptionStatus.isActive &&
            !subscriptionStatus.isExpired) {
          // Has active subscription, go to home
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
                (route) => false,
          );
        } else {
          // No active subscription, go to purchase
          // Navigator.of(context).pushNamedAndRemoveUntil(
          //   '/purchase',
          //       (route) => false,
          // );

          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
                (route) => false,
          );
        }
      } else {
        _showMessage('Failed to skip onboarding. Please try again.');
      }
    } catch (e) {
      print('Error skipping onboarding: $e');
      _showMessage('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
          backgroundColor: context.isDarkMode
              ? const Color(0xFF2D2D2D)
              : const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}