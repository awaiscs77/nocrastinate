import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfHappy/PositiveExperienceScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/IfBad/UnHelpfulThoughsScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../Manager/MoodCheckinManager.dart';
import '../AddActivityPopupScreen.dart';

class CurrentExcitmentScreen extends StatefulWidget {
  const CurrentExcitmentScreen({Key? key}) : super(key: key);

  @override
  _CurrentExcitmentScreenState createState() => _CurrentExcitmentScreenState();
}

class _CurrentExcitmentScreenState extends State<CurrentExcitmentScreen> {
  Set<String> selectedCategories = {};
  bool _isUpdating = false; // Track update state
  late MoodCheckinManager moodManager;
  String moodText = "";
  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // Load existing excitement categories if resuming a session
  void _loadExistingData() {
    moodManager = Provider.of<MoodCheckinManager>(context, listen: false);
    final currentMood = moodManager.currentMoodCheckin;
    setState(() {
      moodText = "${"What's currently making you\nfeel".tr()} ${currentMood?.selectedEmotionTags.join(', ') ?? ""}?";
    });

    if (currentMood != null && currentMood.excitementCategories.isNotEmpty) {
      setState(() {
        selectedCategories = Set<String>.from(currentMood.excitementCategories);
      });
    }
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy \'at\' HH:mm');
    return formatter.format(now);
  }

  final List<Map<String, String>> categories = [
    {'asset': 'assets/svg/Work.svg', 'label': 'Work'},
    {'asset': 'assets/svg/Relax.svg', 'label': 'Relax'},
    {'asset': 'assets/svg/Family.svg', 'label': 'Family'},
    {'asset': 'assets/svg/Friends.svg', 'label': 'Friends'},
    {'asset': 'assets/svg/Date.svg', 'label': 'Date'},
    {'asset': 'assets/svg/Pets.svg', 'label': 'Pets'},
    {'asset': 'assets/svg/Fitness.svg', 'label': 'Fitness'},
    {'asset': 'assets/svg/Self-care.svg', 'label': 'Self-care'},
    {'asset': 'assets/svg/Partner.svg', 'label': 'Partner'},
    {'asset': 'assets/svg/Gaming.svg', 'label': 'Gaming'},
    {'asset': 'assets/svg/Travel.svg', 'label': 'Travel'},
    {'asset': 'assets/svg/New.svg', 'label': '+ New'},
  ];

  void handleCategoryTap(String label) {
    if (label == '+ New') {
      // Open ActivityPopupScreen as a modal bottom sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => ActivityPopupScreen(),
      );
    } else {
      // Handle multiple category selection
      setState(() {
        if (selectedCategories.contains(label)) {
          selectedCategories.remove(label); // Deselect if already selected
        } else {
          selectedCategories.add(label); // Select if not selected
        }
      });
      print('Selected categories: $selectedCategories');
    }
  }

  // Handle next button press
  Future<void> _handleNext() async {
    if (selectedCategories.isEmpty || _isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final moodManager = Provider.of<MoodCheckinManager>(context, listen: false);

      // Update the mood check-in with selected excitement categories
      final success = await moodManager.updateWithExcitement(
        selectedCategories.toList(),
      );

      if (success) {
        // Navigate to the next screen
        final currentMood = moodManager.currentMoodCheckin;
        if (currentMood != null){
          if(currentMood.moodIndex == 0 || currentMood.moodIndex == 1){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UnHelpfulThoughsScreen(),
              ),
            );
          }
          else{
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PositiveExperienceScreen(),
              ),
            );
          }
        }
        else{
          _showErrorSnackBar(moodManager.error ?? 'Failed to update excitement categories');
        }



      } else {
        // Show error message
        _showErrorSnackBar(moodManager.error ?? 'Failed to update excitement categories');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget buildCategoryItem(String assetPath, String label) {
    bool isSelected = selectedCategories.contains(label);

    return GestureDetector(
      onTap: () => handleCategoryTap(label),
      child: ThemedContainer(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        borderRadius: BorderRadius.circular(12),
        useSecondaryBackground: !isSelected,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                color: context.isDarkMode
                    ? AppColors.accent
                    : context.primaryTextColor,
                width: 2
            )
                : Border.all(
                color: context.borderColor.withOpacity(0.3),
                width: 1
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SvgPicture.asset(
                    assetPath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? (context.isDarkMode ? AppColors.accent : context.primaryTextColor)
                        : context.primaryTextColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
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
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Progress indicator (optional)
                if (moodManager.hasActiveSession)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(
                      value: moodManager.completionPercentage,
                      backgroundColor: context.isDarkMode
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.isDarkMode ? AppColors.accent : context.primaryTextColor,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Center content container
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
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
                        const SizedBox(height: 12),

                        // Question text
                        Text(
                          moodText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: context.primaryTextColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Selection counter
                        if (selectedCategories.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? AppColors.accent.withOpacity(0.2)
                                  : AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${selectedCategories.length} ${selectedCategories.length > 1 ? 's' : ''} ${'selected'.tr()}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.isDarkMode ? AppColors.accent : context.primaryTextColor,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Categories grid
                        Expanded(
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return buildCategoryItem(
                                categories[index]['asset']!,
                                categories[index]['label']!,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Confirm button at bottom
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: 138,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: (selectedCategories.isNotEmpty && !_isUpdating && !moodManager.isLoading)
                          ? _handleNext
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.isDarkMode
                            ? Colors.white
                            : context.blackSectionColor,
                        disabledBackgroundColor: context.isDarkMode
                            ? Colors.white.withOpacity(0.3)
                            : context.blackSectionColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating || moodManager.isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.isDarkMode ? context.backgroundColor : Colors.white,
                          ),
                        ),
                      )
                          : Text(
                        'Next'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode ? context.backgroundColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Error display (optional)
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