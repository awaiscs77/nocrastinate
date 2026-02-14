import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/WhatIfChallenge/HowLikelyThisHappenScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../Manager/MindPracticeManager.dart';
import '../../PopupQuestionScreen.dart';

class AfraidOfWrongScreen extends StatefulWidget {
  @override
  _AfraidOfWrongScreenState createState() => _AfraidOfWrongScreenState();
}

class _AfraidOfWrongScreenState extends State<AfraidOfWrongScreen> {
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

    // Initialize practice session if not already started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _initializePracticeSession();
    });
  }

  Future<void> _initializePracticeSession() async {
    final practiceManager = Provider.of<MindPracticeManager>(context, listen: false);

    if (!practiceManager.hasActiveSession) {
      setState(() {
        _isLoading = true;
      });

      final success = await practiceManager.startPractice(
        practiceType: MindPracticeManager.whatIfChallengeType,
      );

      if (!success && mounted) {
        _showErrorMessage(practiceManager.error ?? 'Failed to start practice session');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  bool _isValidInput() {
    return _textController.text.trim().isNotEmpty;
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
    if (!_isValidInput()) return;

    setState(() {
      _isLoading = true;
    });

    final practiceManager = Provider.of<MindPracticeManager>(context, listen: false);

    // Update practice data with fear scenario
    final success = await practiceManager.updatePracticeData(
      data: {
        'fearScenario': _textController.text.trim(),
      },
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to next screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HowLikelyThisHappenScreen(
            fearScenario: _textController.text.trim(),
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
                                  "What's something you're afraid will go wrong?".tr(),
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
                                  onSubmitted: (_) async {
                                    await _onNext();
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
                          onPressed: (_isValidInput() && !_isLoading) ? _onNext : null,
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
                          child: _isLoading
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
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              practiceManager.error!,
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