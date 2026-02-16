import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import '../../../../../../Manager/MindPracticeManager.dart';
import '../../../../../../ApiServices/MindPracticeService.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../Focus/BreathingExerciseScreen.dart';
import '../../CheckInBahavior/GratificationScreen.dart';
import '../../PopupQuestionScreen.dart';

class ShowKindnessScreen extends StatefulWidget {
  final String selfCriticism;
  final String emotion;

  const ShowKindnessScreen({
    Key? key,
    required this.selfCriticism,
    required this.emotion,
  }) : super(key: key);

  @override
  _ShowKindnessScreenState createState() => _ShowKindnessScreenState();
}

class _ShowKindnessScreenState extends State<ShowKindnessScreen> {
  final TextEditingController _textController = TextEditingController();
  int _currentLength = 0;
  final int _maxLength = 250;
  bool _isSaving = false;
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
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool _isValidInput() {
    return _textController.text.trim().isNotEmpty;
  }

  Future<void> _saveSelfCompassionPractice() async {
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
          'selfCriticism': widget.selfCriticism,
          'emotion': widget.emotion,
          'kindness': _textController.text.trim(),
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
        final practiceId = await MindPracticeService.saveSelfCompassionPractice(
          selfCriticism: widget.selfCriticism,
          emotion: widget.emotion,
          kindness: _textController.text.trim(),
        );

        if (practiceId == null) {
          throw Exception('Failed to save practice');
        }
      }

      // Success - show breathing popup
      if (mounted) {
        _showBreathingPopup(context);
      }

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
      if (result != null && mounted) {
        if (result) {
          // Navigate to breathing exercise
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BreathingExerciseScreen(isRelaxType: false),
            ),
          );
        } else {
          // Navigate directly to gratification screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GratificationScreen(),
            ),
          );
        }
      }
    });
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
            child: Column(
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
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Question text
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "How can you show yourself kindness in this moment?".tr(),
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
                              color: context.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.borderColor,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              maxLength: _maxLength,
                              maxLines: null,
                              expands: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                _saveSelfCompassionPractice();
                              },
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
                                counterText: '',
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
                        ],
                      ),
                    ),
                  ),
                ),

                // Finish button
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: SizedBox(
                    width: 138,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: (_isValidInput() && !_isSaving)
                          ? _saveSelfCompassionPractice
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isValidInput()
                            ? context.primaryTextColor
                            : context.primaryTextColor.withOpacity(0.3),
                        disabledBackgroundColor: context.primaryTextColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.isDarkMode ? Colors.black : Colors.white,
                          ),
                        ),
                      )
                          : Text(
                        'Finish'.tr(),
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
        );
      },
    );
  }
}