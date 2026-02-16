import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/SelfCompassion/ShowKindnessScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../../Manager/MindPracticeManager.dart';

class RecogniseEmotionsScreen extends StatefulWidget {
  final String selfCriticism;

  const RecogniseEmotionsScreen({
    Key? key,
    required this.selfCriticism,
  }) : super(key: key);

  @override
  _RecogniseEmotionsScreenState createState() => _RecogniseEmotionsScreenState();
}

class _RecogniseEmotionsScreenState extends State<RecogniseEmotionsScreen> {
  int? selectedMoodIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _onMoodSelected(int index) async {
    if (_isLoading) return;

    setState(() {
      selectedMoodIndex = index;
      _isLoading = true;
    });

    // Map index to mood label
    final moodLabels = ['Terrible', 'Sad', 'Neutral', 'Happy', 'Amazing'];
    final moodLabel = moodLabels[index];

    final practiceManager = Provider.of<MindPracticeManager>(context, listen: false);

    // Update practice data with emotion
    final success = await practiceManager.updatePracticeData(
      data: {
        'emotion': moodLabel,
      },
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to next screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShowKindnessScreen(
            selfCriticism: widget.selfCriticism,
            emotion: moodLabel,
          ),
        ),
      );
    } else {
      _showErrorMessage(practiceManager.error ?? 'Failed to update practice data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindPracticeManager>(
      builder: (context, practiceManager, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
              'Daily mind practice'.tr(),
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
                    if (practiceManager.hasActiveSession)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: LinearProgressIndicator(
                          value: practiceManager.completionPercentage,
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
                              Text(
                                'Recognise the emotion behind it'.tr(),
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
                if (_isLoading || practiceManager.isLoading)
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
                              'Processing...',
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
                if (practiceManager.error != null)
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
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              practiceManager.error!,
                              style: const TextStyle(
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