import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';

import '../../../../../Manager/MoodCheckinManager.dart';
import '../../../../../Models/MoodCheckinModel.dart';
import 'package:easy_localization/easy_localization.dart';

class HowFeelingScreen extends StatefulWidget {
  const HowFeelingScreen({Key? key}) : super(key: key);

  @override
  _HowFeelingScreenState createState() => _HowFeelingScreenState();
}

class _HowFeelingScreenState extends State<HowFeelingScreen> {
  int? selectedMoodIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Delay the check to ensure Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingMoodCheckin();
    });
  }

  // Check if user has already completed today's -in
  Future<void> _checkExistingMoodCheckin() async {
    if (!mounted) return;

    final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

    try {
      final hasCompleted = await moodManager.hasCompletedToday();

      if (hasCompleted) {
        // Show dialog or navigate back since they already completed today
        if (mounted) {
          _showAlreadyCompletedDialog();
        }
        return;
      }

      // Check if there's an existing incomplete mood check-in
      final todaysMood = await moodManager.getTodaysMoodCheckin();
      if (todaysMood != null && !todaysMood.isCompleted) {
        // Resume existing session
        await moodManager.resumeMoodCheckin(todaysMood);
        if (mounted) {
          _showResumeDialog(todaysMood);
        }
      }
    } catch (e) {
      print('Error checking existing mood check-in: $e');
      if (mounted) {
        _showErrorMessage('Failed to check existing mood data: $e');
      }
    }
  }

  void _showAlreadyCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.backgroundColor,
          title: Text(
            'Already Completed',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          content: Text(
            'You have already completed your mood check-in for today. Come back tomorrow!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode ? Colors.white : context.primaryTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResumeDialog(MoodCheckinModel incompleteMood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.backgroundColor,
          title: Text(
            'Resume Mood Check-in'.tr(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.primaryTextColor,
            ),
          ),
          content: Text(
            'You have an incomplete mood check-in from today. Would you like to continue where you left off or start fresh?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Start fresh by clearing the session
                final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
                moodManager.reset();
              },
              child: Text(
                'Start Fresh',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to the appropriate screen based on completion
                _navigateBasedOnProgress(incompleteMood);
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.isDarkMode ? Colors.white : context.primaryTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateBasedOnProgress(MoodCheckinModel mood) {
    // Navigate to the appropriate screen based on what's already filled
    if (mood.selectedEmotionTags.isEmpty) {
      // Go to DescribeFeelingScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DescribeFeelingScreen(
            selectedMoodFromPrevious: mood.moodIndex,
          ),
        ),
      );
    } else {
      // Navigate to next screen in the flow based on what's missing
      // You can add more conditions here based on your complete flow
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DescribeFeelingScreen(
            selectedMoodFromPrevious: mood.moodIndex,
          ),
        ),
      );
    }
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  void _onMoodSelected(int index) async {
    if (_isLoading) return;

    setState(() {
      selectedMoodIndex = index;
      _isLoading = true;
    });

    // Map index to mood label
    final moodLabels = ['Terrible', 'Sad', 'Neutral', 'Happy', 'Amazing'];
    final moodLabel = moodLabels[index];

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

      // Start mood check-in session with Firebase
      final success = await moodManager.startMoodCheckin(
        moodIndex: index,
        moodLabel: moodLabel,
      );

      if (success) {
        // Navigate to next screen after a short delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DescribeFeelingScreen(
                selectedMoodFromPrevious: index,
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          _showErrorMessage(moodManager.error ?? 'Failed to start mood check-in');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodCheckinManager>(
      builder: (context, moodManager, child) {
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
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),

                    // Progress indicator (optional)
                    if (moodManager.hasActiveSession)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: LinearProgressIndicator(
                          value: moodManager.completionPercentage,
                          backgroundColor: context.isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.isDarkMode ? Colors.white : context.primaryTextColor,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Center content container
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current date and time
                              Text(
                                getCurrentDateTime(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // How are you feeling text
                              Text(
                                'How are you\nfeeling?'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: context.primaryTextColor,
                                  height: 1.3,
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
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Loading overlay
                if (_isLoading || moodManager.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.isDarkMode ? Colors.white : context.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Starting mood check-in...'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Error display at bottom
                if (moodManager.error != null)
                  Positioned(
                    bottom: 20,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              moodManager.error!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodButton({
    required int index,
    required String imagePath,
    required String label,
  }) {
    final isSelected = selectedMoodIndex == index;

    return GestureDetector(
      onTap: () => _onMoodSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryTextColor.withOpacity(0.1)
              : Colors.transparent,
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
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}