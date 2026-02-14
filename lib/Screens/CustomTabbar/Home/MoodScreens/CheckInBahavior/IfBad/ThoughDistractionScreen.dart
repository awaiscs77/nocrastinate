import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';

import '../../../../../../Manager/MoodCheckinManager.dart';
import 'ChallengeThoughScreen.dart';
import 'package:easy_localization/easy_localization.dart';
class ThoughDistractionScreen extends StatefulWidget {
  const ThoughDistractionScreen({Key? key}) : super(key: key);

  @override
  _ThoughDistractionScreenState createState() => _ThoughDistractionScreenState();
}

class _ThoughDistractionScreenState extends State<ThoughDistractionScreen> {
  Set<int> selectedIndices = <int>{};
  bool _isUpdating = false;

  final List<Map<String, String>> distortions = [
    {
      'svg': 'assets/svg/Mind Reading.svg',
      'title': 'Mind Reading',
      'subtitle': "They're quiet because they don't like me",
      'info': 'Assuming you know what others are thinking without evidence, often presuming negative intentions'
    },
    {
      'svg': 'assets/svg/Magnification of the Negative.svg',
      'title': 'Magnification of the Negative',
      'subtitle': "This one mistake ruins all my hard work.",
      'info': 'Exaggerating the importance or impact of a negative event or flaw, blowing it out of proportion'
    },
    {
      'svg': 'assets/svg/Self-blaming.svg',
      'title': 'Self-blaming',
      'subtitle': "The team lost because I didn't step up.",
      'info': 'Taking excessive personal responsibility for outcomes, even when other factors are involved'
    },
    {
      'svg': 'assets/svg/Should Statements.svg',
      'title': 'Should Statements',
      'subtitle': "I should always do this",
      'info': 'Holding rigid, unrealistic expectations about how things should be, often leading to guilt or frustration'
    },
    {
      'svg': 'assets/svg/Fortune-telling.svg',
      'title': 'Fortune-telling',
      'subtitle': "I'll never get through this meeting.",
      'info': 'Predicting negative outcomes with certainty, despite lacking evidence'
    },
    {
      'svg': 'assets/svg/Filtering Out Positive.svg',
      'title': 'Filtering Out Positive',
      'subtitle': "I had some wins, but they don't matter.",
      'info': 'Ignoring or dismissing positive aspects of a situation and focusing only on the negatives'
    },
    {
      'svg': 'assets/svg/Labelling.svg',
      'title': 'Labelling',
      'subtitle': "I am an idiot",
      'info': 'Assigning a fixed, negative label to yourself or others based on a single action or event'
    },
    {
      'svg': 'assets/svg/Catastrophizing.svg',
      'title': 'Catastrophizing',
      'subtitle': "What if this turns into a complete disaster?",
      'info': 'Imagining the worst possible outcome and treating it as likely or inevitable'
    },
    {
      'svg': 'assets/svg/Minimization of the Positive.svg',
      'title': 'Minimization of the Positive',
      'subtitle': "That compliment was just them being nice.",
      'info': 'Downplaying or discounting positive achievements or feedback as insignificant'
    },
    {
      'svg': 'assets/svg/Overgeneralizing.svg',
      'title': 'Overgeneralizing',
      'subtitle': "I didn't get the job, so I'll never succeed at anything.",
      'info': 'Drawing broad, negative conclusions based on a single event, applying it to all situations'
    },
    {
      'svg': 'assets/svg/Other-blaming.svg',
      'title': 'Other-blaming',
      'subtitle': "We're late because they didn't plan ahead.",
      'info': 'Attributing problems entirely to others, avoiding personal accountability'
    },
    {
      'svg': 'assets/svg/Jumping to Conclusions.svg',
      'title': 'Jumping to Conclusions',
      'subtitle': "He didn't reply, so he's mad at me.",
      'info': 'Making assumptions about a situation or someone\'s feelings without evidence'
    },
    {
      'svg': 'assets/svg/Emotional Reasoning.svg',
      'title': 'Emotional Reasoning',
      'subtitle': "I'm anxious, so something bad must be coming.",
      'info': 'Believing that your emotions reflect objective reality. You assume your emotions reflect the way things are.'
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  void _showInfoModal(BuildContext context, String title, String info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.tr(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: context.primaryTextColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                info.tr(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: context.primaryTextColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
                        context.isDarkMode ? Colors.white : context.primaryTextColor,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Header content container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
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
                          'Does your thought contain\ndistortions?'.tr(),
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
                    ],
                  ),
                ),

                // ListView for distortions
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ListView.builder(
                      itemCount: distortions.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedIndices.contains(index);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selectedIndices.contains(index)) {
                                  selectedIndices.remove(index);
                                } else {
                                  selectedIndices.add(index);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (context.isDarkMode
                                    ? AppColors.accent.withOpacity(0.2)
                                    : context.primaryTextColor.withOpacity(0.10))
                                    : context.cardBackgroundColor,
                                border: isSelected
                                    ? Border.all(
                                  color: context.isDarkMode ? AppColors.accent : context.primaryTextColor,
                                  width: 1.5,
                                )
                                    : Border.all(
                                  color: context.borderColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  // SVG Icon
                                  SvgPicture.asset(
                                    distortions[index]['svg']!,
                                  ),
                                  const SizedBox(width: 16),

                                  // Title and Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (distortions[index]['title'] ?? '').toString().tr(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: context.primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (distortions[index]['subtitle'] ?? '').toString().tr(),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: context.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Info button
                                  GestureDetector(
                                    onTap: () {
                                      _showInfoModal(
                                        context,
                                        distortions[index]['title']!,
                                        distortions[index]['info']!,
                                      );
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.accent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'i',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Next Button
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: SizedBox(
                    width: 138,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: (!_isUpdating && !moodManager.isLoading) ? () async {
                        setState(() {
                          _isUpdating = true;
                        });

                        List<String> distortionTitles = selectedIndices
                            .map((index) => distortions[index]['title']!)
                            .toList();

                        final success = await moodManager.updateWithThoughtDistortions(distortionTitles);

                        setState(() {
                          _isUpdating = false;
                        });

                        if (success) {
                          List<Map<String, String>> selectedDistortions = selectedIndices
                              .map((index) => distortions[index])
                              .toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChallengeThoughScreen(
                                selectedDistortions: selectedDistortions,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(moodManager.error ?? 'Failed to update')),
                          );
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.blackSectionColor,
                        disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: (_isUpdating || moodManager.isLoading)
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
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

                // Error display at bottom
                if (moodManager.error != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
              ],
            ),
          ),
        );
      },
    );
  }
}