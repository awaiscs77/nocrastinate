import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/LifeGoal/Goal1Screen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';

import '../../../../../../ApiServices/MindPracticeService.dart';
import '../../../../../../Manager/MindPracticeManager.dart';
import 'package:easy_localization/easy_localization.dart';

class BenefitAndCostScreen extends StatefulWidget {
  final String behaviorToEvaluate;

  const BenefitAndCostScreen({
    Key? key,
    required this.behaviorToEvaluate,
  }) : super(key: key);

  @override
  _BenefitAndCostScreenState createState() => _BenefitAndCostScreenState();
}

class _BenefitAndCostScreenState extends State<BenefitAndCostScreen> {
  final TextEditingController _textProsController = TextEditingController();
  final TextEditingController _textConsController = TextEditingController();
  final FocusNode _prosFocusNode = FocusNode();
  final FocusNode _consFocusNode = FocusNode();

  int _currentProsLength = 0;
  int _currentConsLength = 0;
  bool _isSaving = false;

  final int _maxLength = 250;

  @override
  void initState() {
    super.initState();
    _textProsController.addListener(() {
      setState(() {
        _currentProsLength = _textProsController.text.length;
      });
    });
    _textConsController.addListener(() {
      setState(() {
        _currentConsLength = _textConsController.text.length;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prosFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _prosFocusNode.dispose();
    _consFocusNode.dispose();
    _textProsController.dispose();
    _textConsController.dispose();
    super.dispose();
  }

  bool get _canProceed => _textProsController.text.trim().isNotEmpty &&
      _textConsController.text.trim().isNotEmpty;

  Future<void> _savePractice() async {
    if (!_canProceed || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await MindPracticeService.saveCostBenefitPractice(
        behaviorToEvaluate: widget.behaviorToEvaluate,
        pros: _textProsController.text.trim(),
        cons: _textConsController.text.trim(),
      );

      if (result != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Practice saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to home or show completion screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save practice. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
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
                'Daily Mind Practice'.tr(),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Question text
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'What are the immediate\nbenefits and costs of this?'.tr(),
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

                          // Pros label
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 20,
                              width: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF023E8A),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child:  Center(
                                child: Text(
                                  'Pros'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pros text input field
                          Container(
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _textProsController,
                              focusNode: _prosFocusNode,
                              maxLength: _maxLength,
                              maxLines: null,
                              expands: true,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                // Move focus to Cons field
                                FocusScope.of(context).requestFocus(_consFocusNode);
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

                          // Pros character count
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              '$_currentProsLength/$_maxLength',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: context.secondaryTextColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Cons label
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 20,
                              width: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF023E8A),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child:  Center(
                                child: Text(
                                  'Cons'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Cons text input field
                          Container(
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _textConsController,
                              focusNode: _consFocusNode,
                              maxLength: _maxLength,
                              maxLines: null,
                              expands: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) async {
                                await _savePractice();
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

                          // Cons character count
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              '$_currentConsLength/$_maxLength',
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

                  // Next button
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: SizedBox(
                      width: 138,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePractice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.blackSectionColor,
                          disabledBackgroundColor: context.blackSectionColor
                              .withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? SizedBox(
                          width: 20,
                          height: 20,
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
          );
        }
    );
  }
}