import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';

import '../../../../../../Manager/MoodCheckinManager.dart';
import '../../../../Focus/BreathingExerciseScreen.dart';
import '../../PopupQuestionScreen.dart';
import '../GratificationScreen.dart';

class ChallengeThoughScreen extends StatefulWidget {
  final List<Map<String, String>> selectedDistortions;
  const ChallengeThoughScreen({Key? key, required this.selectedDistortions}) : super(key: key);

  @override
  _ChallengeThoughScreenState createState() => _ChallengeThoughScreenState();
}

class _ChallengeThoughScreenState extends State<ChallengeThoughScreen> {
  final TextEditingController _textController = TextEditingController();
  int _currentLength = 0;
  final int _maxLength = 250;
  bool _isUpdating = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _currentLength = _textController.text.length;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  Widget _buildDistortionTag(Map<String, String> distortion) {
    return ThemedContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            distortion['svg']!,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              context.primaryTextColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            (distortion['title'] ?? '').toString().tr(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showBreathingPopup(BuildContext context) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

      // First save the challenging thoughts
      final success = await moodManager.updateWithChallengingThoughts(
        challengingThoughts: _textController.text.trim(),
        wantsBreathingExercise: false, // Will be updated based on user choice
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(moodManager.error ?? 'Failed to save thoughts')),
        );
        return;
      }

      // Complete the mood check-in before showing the popup
      final currentStreak = await _calculateCurrentStreak(moodManager);
      final completionSuccess = await moodManager.completeMoodCheckin(currentStreak);

      if (!completionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(moodManager.error ?? 'Failed to complete mood check-in')),
        );
        return;
      }

      // Now show the breathing exercise popup
      showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return PopupQuestionScreen(
            title: 'Would you like a quick breathing exercise to help you feel even better?'.tr(),
            onYes: () async {
              Navigator.of(context).pop(true);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => BreathingExerciseScreen(isRelaxType: true,isFromMoodCheckin: true)),
              );
            },
            onNo: () async {
              Navigator.of(context).pop(false);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => GratificationScreen()),
              );
            },
            yesString: 'Yes'.tr(),
            noString: 'No'.tr(),
          );
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<int> _calculateCurrentStreak(MoodCheckinManager moodManager) async {
    try {
      final stats = await moodManager.getMoodStats();
      return stats?.currentStreak ?? 1; // Default to 1 if no previous streak
    } catch (e) {
      return 1; // Default streak
    }
  }

  Widget _buildDistortionTags() {
    if (widget.selectedDistortions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: widget.selectedDistortions
          .map((distortion) => _buildDistortionTag(distortion))
          .toList(),
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
              child: Column(
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
                          context.isDarkMode ? Colors.white : context
                              .primaryTextColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  // Center content container
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
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
                                'How can you challenge\nyour thought?'.tr(),
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

                            // Selected distortions tags
                            Align(
                              alignment: Alignment.topLeft,
                              child: _buildDistortionTags(),
                            ),

                            // Add spacing if there are tags
                            if (widget.selectedDistortions.isNotEmpty)
                              const SizedBox(height: 20),

                            // Text input field
                            ThemedContainer(
                              height: 180,
                              padding: const EdgeInsets.all(20),
                              borderRadius: BorderRadius.circular(12),
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
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  _showBreathingPopup(context);
                                },
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next button
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: SizedBox(
                      width: 138,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          _showBreathingPopup(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.blackSectionColor,
                          disabledBackgroundColor: context.blackSectionColor
                              .withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child:  Text(
                          'Next'.tr(),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          );
        }
    );
  }
}