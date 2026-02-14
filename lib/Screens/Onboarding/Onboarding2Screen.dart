import 'package:flutter/material.dart';
import 'package:nocrastinate/Screens/Onboarding/Onboarding3Screen.dart';
import 'package:nocrastinate/ThemeManager.dart';

import '../../ApiServices/InAppPurchaseService.dart';
import '../../ApiServices/OnBoardingServices.dart';
import 'package:easy_localization/easy_localization.dart';

class Onboarding2Screen extends StatefulWidget {
  const Onboarding2Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding2Screen> createState() => _Onboarding2ScreenState();
}

class _Onboarding2ScreenState extends State<Onboarding2Screen> {
  final List<String> tags = [
    'Improve Mood'.tr(),
    'Improve Relationship'.tr(),
    'Increase Productivity'.tr(),
    'Reduce Stress'.tr(),
    'Reduce Anxiety'.tr(),
    'Personal Growth'.tr(),
    'Something else'.tr(),
  ];

  final Set<String> selectedTags = <String>{};
  bool _isLoading = false; // Track loading state
  final InAppPurchaseService _iapService = InAppPurchaseService();

  // Group tags into rows based on text length
  List<List<String>> groupTagsIntoRows(List<String> tags) {
    List<List<String>> rows = [];
    List<String> currentRow = [];
    int currentRowCharCount = 0;

    for (String tag in tags) {
      // Estimate if adding this tag would exceed reasonable row width
      // Using character count as approximation (adjust threshold as needed)
      int tagCharCount = tag.length;

      // If current row is empty, add the tag
      if (currentRow.isEmpty) {
        currentRow.add(tag);
        currentRowCharCount = tagCharCount;
      }
      // If adding this tag would make row too long, start new row
      else if (currentRowCharCount + tagCharCount > 35 || currentRow.length >= 3) {
        rows.add(List.from(currentRow));
        currentRow = [tag];
        currentRowCharCount = tagCharCount;
      }
      // Otherwise, add to current row
      else {
        currentRow.add(tag);
        currentRowCharCount += tagCharCount;
      }
    }

    // Add the last row if it's not empty
    if (currentRow.isNotEmpty) {
      rows.add(currentRow);
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
                            '1 of 4',
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
                            'What do you want to improve in your life?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: context.primaryTextColor,
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
                                    final isSelected = selectedTags.contains(tag);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: GestureDetector(
                                        onTap: _isLoading ? null : () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedTags.remove(tag);
                                            } else {
                                              selectedTags.add(tag);
                                            }
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
                    // Science-backed methods text - themed
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
    if (selectedTags.isEmpty) {
      _showMessage('Please select at least one improvement goal');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save improvement goals
      bool saved = await OnboardingService.saveImprovementGoals(selectedTags);

      if (saved) {
        // Navigate to next screen
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const Onboarding3Screen())
        );
      } else {
        _showMessage('Failed to save your preferences. Please try again.');
      }
    } catch (e) {
      print('Error saving improvement goals: $e');
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