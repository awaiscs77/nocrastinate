import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import '../../../../../../Manager/MindPracticeManager.dart';
import 'package:easy_localization/easy_localization.dart';

class WhyMakesGratefulScreen extends StatefulWidget {


  const WhyMakesGratefulScreen({
    Key? key,

  }) : super(key: key);

  @override
  _WhyMakesGratefulScreenState createState() => _WhyMakesGratefulScreenState();
}

class _WhyMakesGratefulScreenState extends State<WhyMakesGratefulScreen> {
  final TextEditingController _textController = TextEditingController();
  int _currentLength = 0;
  final int _maxLength = 250;
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

  void _handleNext() {
    if (_isValidInput()) {

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
                            // Question text
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                "Why does it makes you feel grateful.".tr(),
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
                              ),
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                maxLength: _maxLength,
                                maxLines: null,
                                expands: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  _handleNext();
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
                        onPressed: _isValidInput() ? _handleNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isValidInput()
                              ? context.blackSectionColor
                              : context.blackSectionColor.withOpacity(0.3),
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