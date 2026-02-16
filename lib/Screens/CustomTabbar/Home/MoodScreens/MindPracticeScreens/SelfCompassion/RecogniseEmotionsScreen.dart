import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';

import 'package:easy_localization/easy_localization.dart';

class RecogniseEmotionsScreen extends StatefulWidget {
  const RecogniseEmotionsScreen({Key? key}) : super(key: key);

  @override
  _RecogniseEmotionsScreenState createState() => _RecogniseEmotionsScreenState();
}

class _RecogniseEmotionsScreenState extends State<RecogniseEmotionsScreen> {
  int? selectedMoodIndex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Delay the check to ensure Provider is available

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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DescribeFeelingScreen(
          selectedMoodFromPrevious: index,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
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
              'Mind Daily Practice'.tr(),
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

              ],
            ),
          ),
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