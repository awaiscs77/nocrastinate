import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../../../Manager/MindPracticeManager.dart';
import 'BestPossibleOutcomeScreen.dart';
import '../../PopupQuestionScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class HowLikelyThisHappenScreen extends StatefulWidget {
  final String fearScenario;

  const HowLikelyThisHappenScreen({
    Key? key,
    required this.fearScenario,
  }) : super(key: key);

  @override
  _HowLikelyThisHappenScreenState createState() => _HowLikelyThisHappenScreenState();
}

class _HowLikelyThisHappenScreenState extends State<HowLikelyThisHappenScreen> {
  double _sliderValue = 85.0; // Default value for the slider
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getLikelihoodText(double value) {
    if (value <= 20) {
      return "Very Unlikely";
    } else if (value <= 40) {
      return "Unlikely";
    } else if (value <= 60) {
      return "Neutral";
    } else if (value <= 80) {
      return "Likely";
    } else {
      return "Most Likely";
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

  Future<void> _onNext() async {
    setState(() {
      _isLoading = true;
    });

    final practiceManager = Provider.of<MindPracticeManager>(context, listen: false);

    // Update practice data with initial likelihood
    final success = await practiceManager.updatePracticeData(
      data: {
        'initialLikelihood': _sliderValue,
      },
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to next screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BestPossibleOutcomeScreen(
            fearScenario: widget.fearScenario,
            initialLikelihood: _sliderValue,
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // How are you feeling text
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                'How likely is this to happen?'.tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                widget.fearScenario,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: context.primaryTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Percentage display
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "${_sliderValue.round()}%",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Likelihood text
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                _getLikelihoodText(_sliderValue).tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: context.secondaryTextColor,
                                  height: 1.3,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Combined Progress Indicator and Slider
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Linear Percent Indicator
                                  LinearPercentIndicator(
                                    width: MediaQuery.of(context).size.width - 68,
                                    animation: true,
                                    lineHeight: 8.0,
                                    animationDuration: 300,
                                    percent: _sliderValue / 100,
                                    backgroundColor: context.isDarkMode
                                        ? Colors.grey[700]
                                        : const Color(0xFFD9D9D9),
                                    progressColor: context.primaryTextColor,
                                    barRadius: const Radius.circular(4),
                                  ),
                                  // Custom Slider positioned on top
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.transparent,
                                      inactiveTrackColor: Colors.transparent,
                                      trackHeight: 8.0,
                                      thumbColor: AppColors.accent,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                                      overlayColor: AppColors.accent.withAlpha(32),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                                    ),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width - 68,
                                      child: Slider(
                                        value: _sliderValue,
                                        min: 0.0,
                                        max: 100.0,
                                        divisions: 100,
                                        onChanged: (double value) {
                                          setState(() {
                                            _sliderValue = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                              child: SizedBox(
                                width: 138,
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: !_isLoading ? _onNext : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.blackSectionColor,
                                    disabledBackgroundColor: context.blackSectionColor.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                      :  Text(
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
                    ),
                  ],
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
}