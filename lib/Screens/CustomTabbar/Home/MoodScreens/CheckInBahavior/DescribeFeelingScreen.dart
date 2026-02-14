import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../../../../AppData/FeelingCategoryType.dart';
import '../../../../../Manager/MoodCheckinManager.dart';
import 'CurrentExcitmentScreen.dart';
import 'package:easy_localization/easy_localization.dart';

class DescribeFeelingScreen extends StatefulWidget {
  final int? selectedMoodFromPrevious;

  const DescribeFeelingScreen({Key? key, this.selectedMoodFromPrevious}) : super(key: key);

  @override
  _DescribeFeelingScreenState createState() => _DescribeFeelingScreenState();
}

class _DescribeFeelingScreenState extends State<DescribeFeelingScreen> {
  int? selectedMoodIndex;
  Set<String> selectedTags = {};
  List<String> displayedEmotions = [];
  bool _isLoading = false;

  final List<String> moodLabels = [
    'Terrible',
    'Sad',
    'Neutral',
    'Happy',
    'Amazing'
  ];

  @override
  void initState() {
    super.initState();
    selectedMoodIndex = widget.selectedMoodFromPrevious;

    // Delay loading to ensure Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
      _updateDisplayedEmotions();
    });
  }

  // Load existing mood check-in data if resuming
  void _loadExistingData() {
    if (!mounted) return;

    final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

    if (moodManager.hasActiveSession && moodManager.currentMoodCheckin != null) {
      final currentMood = moodManager.currentMoodCheckin!;
      setState(() {
        selectedMoodIndex = currentMood.moodIndex;
        selectedTags = Set<String>.from(currentMood.selectedEmotionTags);
      });
    }
  }

  void _updateDisplayedEmotions() {
    if (selectedMoodIndex != null) {
      // Map mood index to FeelingCategoryType
      FeelingCategoryType categoryType;
      switch (selectedMoodIndex) {
        case 0: // Terrible
          categoryType = FeelingCategoryType.veryBad;
          break;
        case 1: // Sad
          categoryType = FeelingCategoryType.bad;
          break;
        case 2: // Neutral
          categoryType = FeelingCategoryType.normal;
          break;
        case 3: // Happy
          categoryType = FeelingCategoryType.good;
          break;
        case 4: // Amazing
          categoryType = FeelingCategoryType.amazing;
          break;
        default:
          categoryType = FeelingCategoryType.normal;
      }

      // Get the corresponding FeelingCategory and update displayed emotions
      final category = FeelingCategory.getCategoryByType(categoryType);
      if (category != null) {
        setState(() {
          displayedEmotions = category.emotions;
          // Only clear tags if mood actually changed
          if (widget.selectedMoodFromPrevious != selectedMoodIndex) {
            selectedTags.clear();
          }
        });
      }
    } else {
      setState(() {
        displayedEmotions = [];
        selectedTags.clear();
      });
    }
  }

  Future<void> _onMoodChanged(int index) async {
    if (_isLoading) return;

    setState(() {
      selectedMoodIndex = index;
    });

    final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

    // If this is changing from an existing session, we need to restart
    if (moodManager.hasActiveSession) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Delete the current session and start fresh
        if (moodManager.currentMoodCheckinId != null) {
          await moodManager.deleteMoodCheckin(moodManager.currentMoodCheckinId!);
        }

        // Start new session with new mood
        final success = await moodManager.startMoodCheckin(
          moodIndex: index,
          moodLabel: moodLabels[index],
        );

        if (!success) {
          _showErrorMessage(moodManager.error ?? 'Failed to update mood');
          return;
        }
      } catch (e) {
        _showErrorMessage('An error occurred: $e');
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    _updateDisplayedEmotions();
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  Future<void> _onConfirmMood() async {
    if (_isLoading || selectedMoodIndex == null || selectedTags.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

      // Update mood with feeling tags
      final success = await moodManager.updateWithFeeling(selectedTags.toList());

      if (success) {
        // Navigate to next screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CurrentExcitmentScreen(),
          ),
        );
      } else {
        _showErrorMessage(moodManager.error ?? 'Failed to save feelings');
      }
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            child: Stack(
              children: [
                Column(
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

                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Current date and time
                              Text(
                                getCurrentDateTime(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // how you feeling text
                              Text(
                                "How would you describe\nhow you're feeling?".tr(),
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

                              // Dynamic emotion tags based on selected mood
                              if (displayedEmotions.isNotEmpty) _buildEmotionTags(),

                              // Selection counter
                              if (selectedTags.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF023E8A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF023E8A).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${selectedTags.length} ${'emotion'.tr()}${selectedTags.length > 1 ? 's' : ''} ${'selected'.tr()}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF023E8A),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Confirm button at bottom
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: 217,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: (selectedMoodIndex != null &&
                              selectedTags.isNotEmpty &&
                              !_isLoading &&
                              !moodManager.isLoading)
                              ? _onConfirmMood
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedMoodIndex != null &&
                                selectedTags.isNotEmpty)
                                ? (context.isDarkMode ? Colors.white : context.primaryTextColor)
                                : (context.isDarkMode ? Colors.white.withOpacity(0.3) : context.primaryTextColor.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: (_isLoading || moodManager.isLoading)
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
                            'Confirm Mood'.tr(),
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

                // Loading overlay for mood changes
                if (_isLoading || moodManager.isLoading)
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
                              _isLoading ? 'Updating mood...' : 'Saving feelings...',
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
                if (moodManager.error != null)
                  Positioned(
                    bottom: 90, // Above the confirm button
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodButton({
    required int index,
    required String imagePath,
    required String label,
  }) {
    final isSelected = selectedMoodIndex == index;

    return GestureDetector(
      onTap: () => _onMoodChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryTextColor.withOpacity(0.1) : Colors.transparent,
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

  Widget _buildEmotionTags() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        List<Widget> rows = [];
        List<String> currentRowTags = [];
        double currentRowWidth = 0;
        const double spacing = 8.0;

        for (int i = 0; i < displayedEmotions.length; i++) {
          final tag = displayedEmotions[i];

          // Accurately calculate tag width using TextPainter
          final tagWidth = _calculateTagWidth(tag);

          // Calculate total width needed if we add this tag
          final spacingWidth = currentRowTags.isEmpty ? 0.0 : spacing;
          final neededWidth = currentRowWidth + tagWidth + spacingWidth;

          // Check if we can fit this tag in current row (max 3 tags per row)
          if (currentRowTags.length < 3 && neededWidth <= availableWidth) {
            // Add to current row
            currentRowTags.add(tag);
            currentRowWidth = neededWidth;
          } else {
            // Create row with current tags if any
            if (currentRowTags.isNotEmpty) {
              if (rows.isNotEmpty) {
                rows.add(const SizedBox(height: 8));
              }
              rows.add(_buildTagRow(currentRowTags, availableWidth));
            }

            // Start new row with current tag
            currentRowTags = [tag];
            currentRowWidth = tagWidth;
          }
        }

        // Add remaining tags as final row
        if (currentRowTags.isNotEmpty) {
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: 8));
          }
          rows.add(_buildTagRow(currentRowTags, availableWidth));
        }

        return Column(
          children: rows,
        );
      },
    );
  }

  Widget _buildTagRow(List<String> tags, double availableWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        tags.length * 2 - 1,
            (index) {
          if (index.isEven) {
            // Tag widget
            return _buildMoodTag(tags[index ~/ 2]);
          } else {
            // Spacing
            return const SizedBox(width: 8);
          }
        },
      ),
    );
  }

  double _calculateTagWidth(String text) {
    // Create TextPainter to accurately measure text width
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text.tr(), // Use translated text
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 1,
    );

    // Set textDirection before layout - using enum value
    textPainter.textDirection = ui.TextDirection.ltr;
    textPainter.layout();

    // Tag width = text width + horizontal padding (16 * 2) + border (1 * 2)
    return textPainter.width + 32 + 2;
  }


  Widget _buildMoodTag(String tag) {
    final isSelected = selectedTags.contains(tag);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedTags.remove(tag);
          } else {
            selectedTags.add(tag);
          }
        });
      },
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF023E8A)
              : context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF023E8A)
                : context.borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            tag.tr(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : context.primaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}