import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../../../ApiServices/MindPracticeService.dart';
import '../../../../../../Manager/MindPracticeManager.dart';
import '../CostBenefit/BehaviorEvaluateScreen.dart';
import '../../PopupQuestionScreen.dart';

class DidYouThoughScreen extends StatefulWidget {
  final String fearScenario;
  final double initialLikelihood;
  final String bestOutcome;

  const DidYouThoughScreen({
    Key? key,
    required this.fearScenario,
    required this.initialLikelihood,
    required this.bestOutcome,
  }) : super(key: key);

  @override
  _DidYouThoughScreenState createState() => _DidYouThoughScreenState();
}

class _DidYouThoughScreenState extends State<DidYouThoughScreen> {
  double _sliderValue = 15.0; // Default value for the slider
  bool _isSaving = false;

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

  Future<void> _saveWhatIfChallengePractice() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final practiceManager = Provider.of<MindPracticeManager>(context, listen: false);

      // Check if this came from a session-based flow
      if (practiceManager.hasActiveSession) {
        // Session-based flow - update and complete the existing session
        final success = await practiceManager.updatePracticeData(data: {
          'fearScenario': widget.fearScenario,
          'initialLikelihood': widget.initialLikelihood,
          'bestOutcome': widget.bestOutcome,
          'finalLikelihood': _sliderValue,
          'likelihoodReduction': widget.initialLikelihood - _sliderValue,
        });

        if (success) {
          final completed = await practiceManager.completePractice();
          if (!completed) {
            throw Exception('Failed to complete practice session');
          }
        } else {
          throw Exception('Failed to update practice data');
        }
      } else {
        // Legacy direct flow - create new complete record
        final practiceId = await MindPracticeService.saveWhatIfChallengePractice(
          fearScenario: widget.fearScenario,
          initialLikelihood: widget.initialLikelihood,
          bestOutcome: widget.bestOutcome,
          finalLikelihood: _sliderValue,
        );

        if (practiceId == null) {
          throw Exception('Failed to save practice');
        }
      }

      // Success - show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Practice completed successfully!',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to home after a short delay
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      // Handle any exceptions
      final practiceManager = Provider.of<MindPracticeManager>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            practiceManager.error ?? 'An error occurred. Please check your connection and try again.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<MindPracticeManager>(
        builder: (context, practiceManager, child)
    {
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
              if (practiceManager.hasActiveSession)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: practiceManager.completionPercentage,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // How are you feeling text
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          "Now that you've thought it through, how likely does it feel now?".tr(),
                          textAlign: TextAlign.center,
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
                          widget.bestOutcome,
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
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF023E8A),
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
                            color: context.primaryTextColor,
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
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width - 68,
                              animation: true,
                              lineHeight: 8.0,
                              animationDuration: 300,
                              percent: _sliderValue / 100,
                              backgroundColor: context.isDarkMode
                                  ? const Color(0xFF505050)
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
                                thumbColor: const Color(0xFF023E8A),
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12.0),
                                overlayColor: const Color(0xFF023E8A).withAlpha(
                                    32),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 20.0),
                              ),
                              child: SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width - 68,
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
                            onPressed: () {
                              // Handle confirm mood action
                              // Add your navigation or confirmation logic here
                              _saveWhatIfChallengePractice();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryTextColor,
                              disabledBackgroundColor: context.primaryTextColor
                                  .withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Finish'.tr(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.isDarkMode
                                    ? Colors.black
                                    : Colors.white,
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
        ),
      );
    }
    );
  }
}