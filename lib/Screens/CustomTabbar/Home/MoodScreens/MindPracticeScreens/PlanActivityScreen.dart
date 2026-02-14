import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/MindPracticeScreens/WhatIfChallenge/WhatIfChallenge.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';

import '../../../../../ApiServices/FocusService.dart';
import '../../../../../ApiServices/MindPracticeService.dart';
import '../../../../../Manager/MindPracticeManager.dart';
import '../PopupQuestionScreen.dart';

class PlanActivityScreen extends StatefulWidget {

  @override
  _PlanActivityScreenState createState() => _PlanActivityScreenState();
}

class _PlanActivityScreenState extends State<PlanActivityScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _currentLength = 0;
  final int _maxLength = 250;
  int _selectedCategoryIndex = 2; // Social is selected by default (middle one)
  final FocusService _focusService = FocusService(); // Plain activity Firebase integration
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _categories = [
    'Family',
    'Friends',
    'Social',
    'Personal',
    'Relationships'
  ];

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

  Widget _buildCategoryItem(String category, int index) {
    final bool isSelected = index == _selectedCategoryIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? context.primaryTextColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Text(
          category.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isSelected ? 16 : 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected
                ? context.primaryTextColor
                : context.secondaryTextColor,
          ),
        ),
      ),
    );
  }

  // Save plain activity using existing FocusService
  Future<void> _saveActivityPlan() async {
    if (_textController.text.trim().isEmpty) {
      return; // Don't save empty activities
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save plain activity to Firebase using FocusService
      await _focusService.addFocusItem(
        title: 'Activity Plan',
        subtitle: _textController.text.trim(),
        category: _categories[_selectedCategoryIndex],
      );
      print('Plain activity saved successfully');
    } catch (e) {
      print('Error saving activity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save activity. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Save activity as completed mind practice
  Future<void> _saveActivityAsMindPractice() async {
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
          'activityPlan': _textController.text.trim(),
          'category': _categories[_selectedCategoryIndex],
          'completedImmediately': true,
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
        final practiceId = await MindPracticeService.saveActivityPlanPractice(
          activityPlan: _textController.text.trim(),
          category: _categories[_selectedCategoryIndex],
          completedImmediately: true,
        );

        if (practiceId == null) {
          throw Exception('Failed to save practice');
        }
      }

      // Success - show success message
      if (mounted) {
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

        // Navigate back to home - use pushReplacementNamed to ensure home screen rebuilds
        await Future.delayed(Duration(milliseconds: 500));
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
              (route) => false,
        );
      }

    } catch (e) {
      // Handle any exceptions
      if (mounted) {
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showBreathingPopup(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return PopupQuestionScreen(
          title: _textController.text,
          onYes: () async {
            Navigator.of(context).pop(true);
            // Save as completed mind practice
            await _saveActivityAsMindPractice();
          },
          onNo: () {
            Navigator.of(context).pop(false);
            print('User chose to do activity later');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/focus',
                  (Route<dynamic> route) => false,
            );
          },
          yesString: 'Do it now'.tr(),
          noString: 'Later'.tr(),
        );
      },
    ).then((result) {
      if (result != null) {
        print('Activity planning result: $result');
      }
    });
  }

  // Handle next button functionality
  Future<void> _handleNext() async {
    if (_isLoading) return;

    // Save activity to Firebase
    await _saveActivityPlan();

    // Show popup after saving
    if (!_isLoading && mounted) {
      _showBreathingPopup(context);
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
              'Daily activity'.tr(),
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
                        context.isDarkMode ? Colors.white : context.primaryTextColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Title text
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Plan one activity that will make\nyou feel better today'.tr(),
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

                          // Category selection
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryItem(_categories[index], index);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Activity input field
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
                              focusNode: _focusNode,
                              maxLength: _maxLength,
                              maxLines: null,
                              expands: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) async {
                                await _handleNext();
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

                          // Character counter
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
                      onPressed: (_isLoading || _isSaving) ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryTextColor,
                        disabledBackgroundColor: context.primaryTextColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: (_isLoading || _isSaving)
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
        );
      },
    );
  }
}