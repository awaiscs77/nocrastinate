import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfHappy/MoreExperienceScreen.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../Manager/MoodCheckinManager.dart';

class ExperienceMeaningfulScreen extends StatefulWidget {
  const ExperienceMeaningfulScreen({Key? key}) : super(key: key);

  @override
  _ExperienceMeaningfulScreenState createState() => _ExperienceMeaningfulScreenState();
}

class _ExperienceMeaningfulScreenState extends State<ExperienceMeaningfulScreen> {
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

    // Load existing meaningful experience if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadExistingData();
    });

  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
    final currentMood = moodManager.currentMoodCheckin;

    if (currentMood?.meaningfulExperience != null && currentMood!.meaningfulExperience!.isNotEmpty) {
      _textController.text = currentMood.meaningfulExperience!;
    }
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  Future<void> _handleNext() async {
    if (_isLoading) return;

    final meaningfulExperience = _textController.text.trim();

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

      // Update with meaningful experience
      final success = await moodManager.updateWithMeaningfulExperience(
        meaningfulExperience.isEmpty ? '' : meaningfulExperience,
      );

      if (success) {
        // Navigate to next screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MoreExperienceScreen(),
            ),
          );
        }
      } else {
        _showErrorMessage(
          moodManager.error ?? 'Failed to save meaningful experience',
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
              'Mood Check-in',
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
                                'Why was this experience\nmeaningful to you?'.tr(),
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
                                    'Next',
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
}