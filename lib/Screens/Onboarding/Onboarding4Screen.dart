import 'package:flutter/material.dart';
import 'package:nocrastinate/ThemeManager.dart';
import '../../ApiServices/InAppPurchaseService.dart';
import '../../ApiServices/OnBoardingServices.dart';
import 'OnBoarding5Screen.dart';

class Onboarding4Screen extends StatefulWidget {
  const Onboarding4Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding4Screen> createState() => _Onboarding4ScreenState();
}

class _Onboarding4ScreenState extends State<Onboarding4Screen> {
  final List<String> tags = [
    'TikTok',
    'Instagram',
    'Youtube',
    'Facebook',
    'App Store',
    'Friends',
    'Family',
  ];
  final InAppPurchaseService _iapService = InAppPurchaseService();

  String? selectedTag;
  bool _isLoading = false; // Add the missing loading state variable

  List<List<String>> groupTagsIntoRows(List<String> tags) {
    List<List<String>> rows = [];

    if (tags.length >= 3) {
      rows.add(tags.sublist(0, 3));
    }

    if (tags.length >= 6) {
      rows.add(tags.sublist(3, 6));
    }

    if (tags.length > 6) {
      rows.add(tags.sublist(6));
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
                            '3 of 4',
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
                        // Main question text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Where did you hear\nabout us?',
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

                        // Tags section
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
                    // Next button
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
      _showMessage('Please select where you heard about us');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save referral source
      bool saved = await OnboardingService.saveReferralSource(selectedTag!);

      if (saved) {
        // Navigate to next screen
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const Onboarding5Screen())
        );
      } else {
        _showMessage('Failed to save your selection. Please try again.');
      }
    } catch (e) {
      print('Error saving referral source: $e');
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