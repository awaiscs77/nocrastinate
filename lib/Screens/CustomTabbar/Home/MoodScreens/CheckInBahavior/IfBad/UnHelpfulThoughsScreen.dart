import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfBad/ThoughDistractionScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';

import '../../../../../../Manager/MoodCheckinManager.dart';
import 'package:easy_localization/easy_localization.dart';

class UnHelpfulThoughsScreen extends StatefulWidget {
  const UnHelpfulThoughsScreen({Key? key}) : super(key: key);

  @override
  _UnHelpfulThoughsScreenState createState() => _UnHelpfulThoughsScreenState();
}

class _UnHelpfulThoughsScreenState extends State<UnHelpfulThoughsScreen> {
  final TextEditingController _textController = TextEditingController();
  int _currentLength = 0;
  final int _maxLength = 250;
  bool _isUpdating = false;
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

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodCheckinManager>(
      builder: (context, moodManager, child) {
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

                // Center content container - now scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
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
                            'What unhelpful thought do\nyou have?'.tr(),
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

                        // Text input field - changed to flexible height with constraints
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 180,
                            maxHeight: 250,
                          ),
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
                            minLines: 6,
                            textInputAction: TextInputAction.done,
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
                            onSubmitted: (_textController.text.trim().isNotEmpty && !_isUpdating && !moodManager.isLoading)
                                ? (value) async {
                              setState(() {
                                _isUpdating = true;
                              });

                              final success = await moodManager.updateWithUnhelpfulThoughts(
                                _textController.text.trim(),
                              );

                              setState(() {
                                _isUpdating = false;
                              });

                              if (success) {
                                Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => ThoughDistractionScreen())
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(moodManager.error ?? 'Failed to update')),
                                );
                              }
                            }
                                : null,
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

                // Next button
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: SizedBox(
                    width: 138,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: (_textController.text.trim().isNotEmpty &&
                          !_isUpdating &&
                          !moodManager.isLoading) ? () async {
                        setState(() {
                          _isUpdating = true;
                        });

                        final success = await moodManager.updateWithUnhelpfulThoughts(
                          _textController.text.trim(),
                        );

                        setState(() {
                          _isUpdating = false;
                        });

                        if (success) {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => ThoughDistractionScreen())
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