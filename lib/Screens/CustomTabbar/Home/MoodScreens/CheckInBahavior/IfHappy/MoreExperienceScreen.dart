import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Focus/BreathingExerciseScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/GratificationScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';

import '../../PopupQuestionScreen.dart';
import '../../../../../../Manager/MoodCheckinManager.dart';
import 'package:easy_localization/easy_localization.dart';

class MoreExperienceScreen extends StatefulWidget {
  const MoreExperienceScreen({Key? key}) : super(key: key);

  @override
  _MoreExperienceScreenState createState() => _MoreExperienceScreenState();
}

class _MoreExperienceScreenState extends State<MoreExperienceScreen> {
  final TextEditingController _textController = TextEditingController();
  int _currentLength = 0;
  final int _maxLength = 250;
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _currentLength = _textController.text.length;
      });
    });

    // Load existing more experiences data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
    final currentMood = moodManager.currentMoodCheckin;

    if (currentMood?.moreExperiences != null && currentMood!.moreExperiences!.isNotEmpty) {
      _textController.text = currentMood.moreExperiences!;
    }
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  Future<void> _handleNext() async {
    if (_isLoading) return;

    final moreExperiences = _textController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

      // Check if there's an active session
      if (!moodManager.hasActiveSession) {
        _showErrorMessage('No active mood check-in session. Please start from the beginning.');
        return;
      }

      // Update with more experiences (temporarily set breathing exercise to false, will be updated after popup)
      final success = await moodManager.updateWithMoreExperiences(
        moreExperiences: moreExperiences.isEmpty ? '' : moreExperiences,
        wantsBreathingExercise: false, // Will be updated based on user choice
      );

      if (success) {
        // Complete the mood check-in (you can adjust streak calculation as needed)
        final streakDays = await _calculateStreakDays(moodManager);
        final completionSuccess = await moodManager.completeMoodCheckin(streakDays);

        if (completionSuccess) {
          // Show breathing exercise popup
          if (mounted) {
            _showBreathingPopup(context);
          }
        } else {
          _showErrorMessage(
            moodManager.error ?? 'Failed to complete mood check-in',
          );
        }
      } else {
        _showErrorMessage(
          moodManager.error ?? 'Failed to save more experiences',
        );
      }
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Calculate streak days (you can customize this logic based on your requirements)
  Future<int> _calculateStreakDays(MoodCheckinManager moodManager) async {
    try {
      // Get mood stats to determine current streak
      final stats = await moodManager.getMoodStats();
      return stats?.currentStreak ?? 1; // Default to 1 if no previous data
    } catch (e) {
      print('Error calculating streak: $e');
      return 1; // Default streak
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

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

                    // Progress indicator
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Current date and time
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                getCurrentDateTime(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Question text
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'What can you do for more\nexperiences like this?'.tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: context.primaryTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Text input field
                            Container(
                              height: 180,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? context.backgroundColor
                                    : context.cardBackgroundColor,
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
                                  hintText: 'Write something...'.tr(),
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

                            const Spacer(),

                            // Next button
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                              child: SizedBox(
                                width: 138,
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: _isLoading || moodManager.isLoading
                                      ? null
                                      : _handleNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.primaryTextColor,
                                    disabledBackgroundColor:
                                    context.primaryTextColor.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading || moodManager.isLoading
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.isDarkMode ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  )
                                      : Text(
                                    'Next'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: context.isDarkMode ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Error display
                if (moodManager.error != null)
                  Positioned(
                    bottom: 100,
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

  void _showBreathingPopup(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return PopupQuestionScreen(
          title: 'Would you like a quick breathing exercise to help you feel even better?',
          onYes: () {
            Navigator.of(context).pop(true);
          },
          onNo: () {
            Navigator.of(context).pop(false);
          },
          yesString: 'Yes',
          noString: 'No',
        );
      },
    ).then((result) async {
      if (result != null) {
        print('Dialog result: $result');

        // Update breathing exercise preference
        final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
        final currentExperiences = _textController.text.trim();

        await moodManager.updateWithMoreExperiences(
          moreExperiences: currentExperiences.isEmpty ? '' : currentExperiences,
          wantsBreathingExercise: result,
        );

        if (mounted) {
          if (result) {
            // Navigate to breathing exercise
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => BreathingExerciseScreen(isRelaxType: false)
              ),
            );
          } else {
            // Navigate directly to gratification screen
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => GratificationScreen()
              ),
            );
          }
        }
      }
    });
  }
}